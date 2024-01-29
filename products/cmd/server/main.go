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

	utilsLogger "example.com/modular-monolith/utils/pkg/logger"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"

	"github.com/spf13/viper"
)

type Config struct {
	ServerPort            int    `mapstructure:"server_port"`
	EnableServerAccessLog bool   `mapstructure:"enable_server_access_log"`
	AppName               string `mapstructure:"app_name"`
	LogLevel              string `mapstructure:"log_level"`
}

type App struct {
	Logger     *slog.Logger
	HTTPServer *http.Server
	Router     *chi.Mux
	Config     *Config
}

type Product struct {
	ID    int     `json:"id"`
	Name  string  `json:"name"`
	Price float64 `json:"price"`
}

type HelloUniverseResponse struct {
	Greeting string `json:"greeting"`
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

func (a *App) updateLogLevelDynamically(w http.ResponseWriter, r *http.Request) {
	requiredLogLevel := r.URL.Query().Get("level")
	level, err := getLogLevelFromString(requiredLogLevel)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	loggingHandler := a.Logger.Handler()
	levelVar := new(slog.LevelVar) // INFO
	levelVar.Set(level)
	a.Logger = slog.New(utilsLogger.NewLevelHandler(levelVar, loggingHandler))
	fmt.Fprintf(w, "Log Level switched to %s", requiredLogLevel)
}

func (a *App) homePageHandler(w http.ResponseWriter, r *http.Request) {
	// Write the JSON response
	helloUniverseResponse := HelloUniverseResponse{
		Greeting: "hello, I am products service",
	}
	// Convert paymentInfo to JSON
	response, err := json.Marshal(helloUniverseResponse)
	if err != nil {
		a.handleError(w, err, http.StatusInternalServerError)
		return
	}

	// Set response headers
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)

	// Write the JSON response
	w.Write(response)
	if contextId, isContextIDSet := r.Header["X-Context-Id"]; isContextIDSet {
		if len(contextId) > 0 {
			a.Logger.Debug(fmt.Sprintf("Computed Response for request with id %s", contextId[0]))
		}
	} else {
		a.Logger.Debug("Computed Response")
	}
}

func (a *App) getProductsListHandler(w http.ResponseWriter, r *http.Request) {
	// Simulated list of products
	products := []Product{
		{ID: 1, Name: "Product A", Price: 29.99},
		{ID: 2, Name: "Product B", Price: 49.99},
		// Add more products as needed
	}

	// Convert products to JSON
	response, err := json.Marshal(products)
	if err != nil {
		http.Error(w, "Internal Server Error", http.StatusInternalServerError)
		return
	}

	// Set response headers
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)

	// Write the JSON response
	w.Write(response)
	if contextId, isContextIDSet := r.Header["X-Context-Id"]; isContextIDSet {
		if len(contextId) > 0 {
			a.Logger.Info(fmt.Sprintf("Computed Response for request with id %s", contextId[0]))
		}
	} else {
		a.Logger.Info("Computed Response")
	}
}

func (a *App) handleError(w http.ResponseWriter, err error, statusCode int) {
	a.Logger.Error("Error:", err)
	http.Error(w, http.StatusText(statusCode), statusCode)
}

func (a *App) setupRouter() {
	r := chi.NewRouter()

	if a.Config.EnableServerAccessLog {
		// Use middleware for basic logging
		r.Use(middleware.Logger)
	}
	// r.Use(middleware.RequestID)

	// Use middleware for recovery
	r.Use(middleware.Recoverer)

	// Add your routes here
	r.Get("/", a.homePageHandler)
	r.Get("/products", a.getProductsListHandler)
	r.Get("/setLogLevel", a.updateLogLevelDynamically)

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

	a.Logger.Debug("Waiting for the signal to be received...")
	// Block until a signal is received
	sigReceived := <-signals

	a.Logger.Debug(fmt.Sprintf("Received signal %v to shut down gracefully. Closing server...", sigReceived))

	// Use a context with a timeout for graceful shutdown
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err := a.HTTPServer.Shutdown(ctx); err != nil {
		a.Logger.Error("Error during server shutdown:", err)
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

	// Create an instance of the App struct
	app := &App{
		Config: &Config{},
	}
	// Initialize configuration
	app.initConfig(*configPath)

	logLevel, err := getLogLevelFromString(app.Config.LogLevel)
	if err != nil {
		fmt.Println(err, " Resorting to INFO log-level.")
		logLevel = slog.LevelInfo
	}
	levelVar := new(slog.LevelVar) // INFO
	levelVar.Set(logLevel)
	loggerOptions := &slog.HandlerOptions{
		Level: levelVar,
	}
	app.Logger = slog.New(slog.NewJSONHandler(os.Stdout, loggerOptions))
	slog.SetDefault(app.Logger)

	app.Logger.Debug(fmt.Sprintf("Application Config: %+v", app.Config))

	app.setupRouter()
	app.setupHTTPServer()

	// Set up graceful shutdown
	go app.handleShutdown()

	app.startHTTPServer()
}
