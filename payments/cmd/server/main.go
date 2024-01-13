package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"

	"github.com/spf13/viper"
)

type Config struct {
	ServerPort int    `mapstructure:"server_port"`
	AppName    string `mapstructure:"app_name"`
	LogLevel   string `mapstructure:"log_level"`
}

type App struct {
	Logger     *log.Logger
	HTTPServer *http.Server
	Router     *chi.Mux
	Config     *Config
}

type PaymentInfo struct {
	TransactionID string  `json:"transaction_id"`
	Amount        float64 `json:"amount"`
	Status        string  `json:"status"`
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
	a.Logger.Println("Error:", err)
	http.Error(w, http.StatusText(statusCode), statusCode)
}

func (a *App) setupRouter() {
	r := chi.NewRouter()

	// Use middleware for basic logging and recovery
	r.Use(middleware.Logger)
	r.Use(middleware.Recoverer)

	// Add your routes here
	r.Get("/getPaymentInfo", a.getPaymentInfoHandler)

	a.Router = r
}

func (a *App) setupHTTPServer() {
	a.HTTPServer = &http.Server{
		Addr:    fmt.Sprintf(":%d", a.Config.ServerPort),
		Handler: a.Router,
	}
}

func (a *App) startHTTPServer() {
	go func() {
		a.Logger.Printf("%s listening on %s...\n", a.Config.AppName, a.HTTPServer.Addr)
		if err := a.HTTPServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			a.Logger.Fatal("Error starting server:", err)
		}
	}()
}

func (a *App) handleShutdown() {
	signals := make(chan os.Signal, 1)
	signal.Notify(signals, os.Interrupt, syscall.SIGTERM)

	// Block until a signal is received
	<-signals

	a.Logger.Println("Received signal to shut down gracefully. Closing server...")
	if err := a.HTTPServer.Shutdown(nil); err != nil {
		a.Logger.Println("Error during server shutdown:", err)
	}
}

func (a *App) initConfig(configPath string) {
	viper.SetConfigFile(configPath)
	viper.SetConfigType("yaml")
	viper.AutomaticEnv()

	if err := viper.ReadInConfig(); err != nil {
		a.Logger.Fatalf("Error reading config file: %s\n", err)
	}

	if err := viper.Unmarshal(&a.Config); err != nil {
		a.Logger.Fatalf("Error unmarshalling config: %s\n", err)
	}
}

func main() {
	// Parse command-line arguments
	configPath := flag.String("config", "config.yaml", "Path to the configuration file")
	flag.Parse()

	// Initialize logger
	logger := log.New(os.Stdout, "PaymentService: ", log.Ldate|log.Ltime|log.Lshortfile)

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
	app.startHTTPServer()

	// Wait for shutdown signal
	select {}
}
