package economy

import (
	"context"
	"errors"
	"fmt"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

var ErrEventConflict = errors.New("event id already exists with different data")

type Store struct { db *pgxpool.Pool }

func NewStore(db *pgxpool.Pool) *Store { return &Store{db:db} }
func (s *Store) Ping(ctx context.Context) error { return s.db.Ping(ctx) }

func (s *Store) Balance(ctx context.Context, player string) (int64, error) {
	var balance int64
	err := s.db.QueryRow(ctx, `SELECT balance FROM economy_wallets WHERE owner_type='player' AND owner_id=$1`, player).Scan(&balance)
	if err == pgx.ErrNoRows { return 0, nil }
	return balance, err
}

// AwardMob records a single server-authoritative reward. eventID makes retries safe.
func (s *Store) AwardMob(ctx context.Context, player, eventID, mobType string, amount int64) (int64, bool, error) {
	tx, err := s.db.Begin(ctx); if err != nil { return 0, false, err }
	defer func(){ _ = tx.Rollback(ctx) }()

	tag, err := tx.Exec(ctx, `INSERT INTO economy_wallets(owner_type, owner_id, balance)
		VALUES ('player',$1,0) ON CONFLICT (owner_type,owner_id) DO NOTHING`, player)
	if err != nil { return 0, false, err }; _ = tag

	var existingPlayer, existingType string
	var existingAmount int64
	err = tx.QueryRow(ctx, `SELECT owner_id, reference_type, amount FROM economy_ledger WHERE event_id=$1`, eventID).Scan(&existingPlayer,&existingType,&existingAmount)
	if err == nil {
		if existingPlayer != player || existingType != "mob:"+mobType || existingAmount != amount { return 0, false, ErrEventConflict }
		var balance int64
		if err = tx.QueryRow(ctx, `SELECT balance FROM economy_wallets WHERE owner_type='player' AND owner_id=$1`,player).Scan(&balance); err != nil { return 0,false,err }
		if err = tx.Commit(ctx); err != nil { return 0,false,err }
		return balance, false, nil
	}
	if err != pgx.ErrNoRows { return 0,false,err }

	var balance int64
	err = tx.QueryRow(ctx, `UPDATE economy_wallets SET balance=balance+$2, updated_at=now()
		WHERE owner_type='player' AND owner_id=$1 RETURNING balance`, player, amount).Scan(&balance)
	if err != nil { return 0,false,err }
	_, err = tx.Exec(ctx, `INSERT INTO economy_ledger(event_id, owner_type, owner_id, direction, amount, reason, reference_type)
		VALUES ($1,'player',$2,'credit',$3,'Récompense de monstre',$4)`, eventID, player, amount, "mob:"+mobType)
	if err != nil { return 0,false,fmt.Errorf("insert ledger entry: %w",err) }
	if err = tx.Commit(ctx); err != nil { return 0,false,err }
	return balance, true, nil
}
