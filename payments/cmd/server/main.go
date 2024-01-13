package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"strings"
	"time"

	"flag"
	"log/slog"
	"os"
	"os/signal"
	"syscall"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	utilsLogger "github.com/nandak522/modular-monolith/utils/pkg/logger"

	"github.com/spf13/viper"
)

type Config struct {
	ServerPort            int    `mapstructure:"server_port"`
	AppName               string `mapstructure:"app_name"`
	LogLevel              string `mapstructure:"log_level"`
	EnableDynamicLogLevel bool   `mapstructure:"enable_dynamic_log_level"`
}

type App struct {
	Logger     *slog.Logger
	HTTPServer *http.Server
	Router     *chi.Mux
	Config     *Config
}

type PaymentInfo struct {
	TransactionID string  `json:"transaction_id"`
	Amount        float64 `json:"amount"`
	Status        string  `json:"status"`
}

func getLogLevelFromString(requiredLogLevel string) (slog.Level, error) {
	var level slog.Level
	switch strings.ToUpper(requiredLogLevel) {
	case "DEBUG":
		level = slog.LevelDebug
	case "INFO":
		level = slog.LevelInfo
	case "WARN":
		level = slog.LevelWarn
	case "ERROR":
		level = slog.LevelError
	default:
		return -1, errors.New("invalid level name")
	}
	return level, nil
}

func (a *App) setLogLevel(w http.ResponseWriter, r *http.Request) {
	if !a.Config.EnableDynamicLogLevel {
		http.Error(w, "Log Level can't be switched dynamically", http.StatusBadRequest)
		return
	}
	requiredLogLevel := r.URL.Query().Get("level")
	level, err := getLogLevelFromString(requiredLogLevel)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	loggingHandler := a.Logger.Handler()
	a.Logger = slog.New(utilsLogger.NewLevelHandler(level, loggingHandler))
	fmt.Fprintf(w, "Log Level switched to %s", requiredLogLevel)
}

func (a *App) getPaymentInfoHandler(w http.ResponseWriter, r *http.Request) {
	// Simulated payment information
	paymentInfo := PaymentInfo{
		TransactionID: "123456789",
		Amount:        59.99,
		Status:        "Success",
	}

	// Convert paymentInfo to JSON
	response, err := json.Marshal(paymentInfo)
	if err != nil {
		a.handleError(w, err, http.StatusInternalServerError)
		return
	}

	// Set response headers
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)

	// Write the JSON response
	w.Write(response)
}

func (a *App) handleError(w http.ResponseWriter, err error, statusCode int) {
	a.Logger.Error("Error:", err)
	http.Error(w, http.StatusText(statusCode), statusCode)
}

func (a *App) setupRouter() {
	r := chi.NewRouter()

	// Use middleware for basic logging and recovery
	r.Use(middleware.Logger)
	// r.Use(middleware.RequestID)
	r.Use(middleware.Recoverer)

	// Add your routes here
	r.Get("/getPaymentInfo", a.getPaymentInfoHandler)
	r.Get("/setLogLevel", a.setLogLevel)

	a.Router = r
}

func (a *App) setupHTTPServer() {
	a.HTTPServer = &http.Server{
		Addr:    fmt.Sprintf(":%d", a.Config.ServerPort),
		Handler: a.Router,
	}
}

func (a *App) startHTTPServer() {
	a.Logger.Info(fmt.Sprintf("%s service listening on %s...", a.Config.AppName, a.HTTPServer.Addr))
	if err := a.HTTPServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		a.Logger.Error("Error starting server:", err)
		os.Exit(1)
	}
}

func (a *App) handleShutdown() {
	signals := make(chan os.Signal, 1)
	signal.Notify(signals, syscall.SIGINT, syscall.SIGTERM)

	// Block until a signal is received
	sigReceived := <-signals

	a.Logger.Debug(fmt.Sprintf("Received signal %v to shut down gracefully. Closing server...", sigReceived))

	// Create a channel to wait for the shutdown to complete
	done := make(chan struct{})

	go func() {
		defer close(done)

		if err := a.HTTPServer.Shutdown(context.TODO()); err != nil {
			a.Logger.Error("Error during server shutdown:", err)
		}
	}()

	// Wait for either the shutdown to complete or a timeout
	select {
	case <-done:
		a.Logger.Debug("Server gracefully shut down.")
	case <-time.After(10 * time.Second): // Adjust the timeout as needed
		a.Logger.Debug("Server shutdown timed out. Forcing exit.")
	}

	// Exit the application
	os.Exit(0)
}

func (a *App) initConfig(configPath string) {
	viper.SetConfigFile(configPath)
	viper.SetConfigType("yaml")
	viper.AutomaticEnv()

	if err := viper.ReadInConfig(); err != nil {
		a.Logger.Error(fmt.Sprintf("Error reading config file: %s\n", err))
		os.Exit(1)
	}
	if err := viper.Unmarshal(&a.Config); err != nil {
		a.Logger.Error(fmt.Sprintf("Error unmarshalling config: %s\n", err))
		os.Exit(1)
	}
}

func main() {
	// Parse command-line arguments
	configPath := flag.String("config", "config.yaml", "Path to the configuration file")
	flag.Parse()

	// Initialize logger
	logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))

	if viper.GetBool("EnableDynamicLogLevel") {
		logLevel := &slog.LevelVar{}
		logger = slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
			Level: logLevel,
		}))
	}
	slog.SetDefault(logger)

	// Create an instance of the App struct
	app := &App{
		Logger: logger,
		Config: &Config{},
	}

	// Initialize configuration
	app.initConfig(*configPath)

	// Set up graceful shutdown
	go app.handleShutdown()

	// Set up router and HTTP server
	app.setupRouter()
	app.setupHTTPServer()
	go app.startHTTPServer()

	// Wait for shutdown signal
	select {}
}
