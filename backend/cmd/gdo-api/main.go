package main

import (
	"context"
	"crypto/subtle"
	"encoding/json"
	"errors"
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/jeremiegoldberg/Grosdebile-online/backend/internal/economy"
)

type server struct {
	store  *economy.Store
	secret []byte
}

type rewardRequest struct {
	EventID  string `json:"event_id"`
	Player   string `json:"player"`
	MobType  string `json:"mob_type"`
}

type walletResponse struct {
	Player  string `json:"player"`
	Balance int64  `json:"balance"`
	Currency string `json:"currency"`
}

func main() {
	dsn := os.Getenv("DATABASE_URL")
	secret := os.Getenv("GDO_GAME_SERVER_TOKEN")
	if dsn == "" || secret == "" {
		log.Fatal("DATABASE_URL and GDO_GAME_SERVER_TOKEN are required")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	pool, err := pgxpool.New(ctx, dsn)
	if err != nil { log.Fatalf("connect PostgreSQL: %v", err) }
	defer pool.Close()
	if err := pool.Ping(ctx); err != nil { log.Fatalf("ping PostgreSQL: %v", err) }

	s := &server{store: economy.NewStore(pool), secret: []byte(secret)}
	mux := http.NewServeMux()
	mux.HandleFunc("GET /healthz", s.health)
	mux.HandleFunc("POST /v1/internal/economy/mob-reward", s.mobReward)
	mux.HandleFunc("GET /v1/internal/economy/wallet/{player}", s.wallet)
	addr := os.Getenv("HTTP_ADDR")
	if addr == "" { addr = ":8080" }
	log.Printf("GDO economy API listening on %s", addr)
	log.Fatal(http.ListenAndServe(addr, securityHeaders(mux)))
}

func securityHeaders(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("X-Content-Type-Options", "nosniff")
		w.Header().Set("Cache-Control", "no-store")
		next.ServeHTTP(w, r)
	})
}

func (s *server) authorized(r *http.Request) bool {
	got := strings.TrimPrefix(r.Header.Get("Authorization"), "Bearer ")
	return got != "" && subtle.ConstantTimeCompare([]byte(got), s.secret) == 1
}

func (s *server) health(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithTimeout(r.Context(), 2*time.Second); defer cancel()
	if err := s.store.Ping(ctx); err != nil { http.Error(w, "database unavailable", http.StatusServiceUnavailable); return }
	writeJSON(w, http.StatusOK, map[string]string{"status":"ok"})
}

func (s *server) mobReward(w http.ResponseWriter, r *http.Request) {
	if !s.authorized(r) { http.Error(w, "unauthorized", http.StatusUnauthorized); return }
	r.Body = http.MaxBytesReader(w, r.Body, 4096)
	var req rewardRequest
	dec := json.NewDecoder(r.Body); dec.DisallowUnknownFields()
	if err := dec.Decode(&req); err != nil { http.Error(w, "invalid JSON", http.StatusBadRequest); return }
	if strings.TrimSpace(req.Player) == "" || len(req.Player) > 32 || strings.ContainsAny(req.Player, "/\\\x00") {
		http.Error(w, "invalid player", http.StatusBadRequest); return
	}
	if len(req.EventID) < 8 || len(req.EventID) > 128 || strings.TrimSpace(req.EventID) != req.EventID {
		http.Error(w, "invalid event_id", http.StatusBadRequest); return
	}
	// Amounts are deliberately selected by the authoritative backend, never supplied by a client.
	rewards := map[string]int64{"common":3, "unusual":12, "dangerous":40, "elite":120, "boss":500}
	amount, ok := rewards[req.MobType]
	if !ok { http.Error(w, "unknown mob_type", http.StatusBadRequest); return }
	balance, created, err := s.store.AwardMob(r.Context(), req.Player, req.EventID, req.MobType, amount)
	if err != nil {
		if errors.Is(err, economy.ErrEventConflict) { http.Error(w, "event_id already used for another reward", http.StatusConflict); return }
		log.Printf("award mob reward: %v", err); http.Error(w, "could not record reward", http.StatusInternalServerError); return
	}
	writeJSON(w, http.StatusOK, map[string]any{"player":req.Player,"amount":amount,"balance":balance,"currency":"NAWAK","created":created})
}

func (s *server) wallet(w http.ResponseWriter, r *http.Request) {
	if !s.authorized(r) { http.Error(w, "unauthorized", http.StatusUnauthorized); return }
	player := r.PathValue("player")
	if player == "" || len(player) > 32 { http.Error(w, "invalid player", http.StatusBadRequest); return }
	balance, err := s.store.Balance(r.Context(), player)
	if err != nil { log.Printf("read wallet: %v", err); http.Error(w, "could not read wallet", http.StatusInternalServerError); return }
	writeJSON(w, http.StatusOK, walletResponse{Player:player, Balance:balance, Currency:"NAWAK"})
}

func writeJSON(w http.ResponseWriter, status int, value any) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(value)
}

var _ = strconv.IntSize
