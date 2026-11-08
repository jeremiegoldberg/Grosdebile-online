-- Registre monétaire persistant du Royaume du Nawak.
-- Les écritures du journal sont immuables ; les soldes sont des projections transactionnelles.
CREATE TABLE IF NOT EXISTS economy_wallets (
    owner_type TEXT NOT NULL CHECK (owner_type IN ('player','guild','kingdom')),
    owner_id TEXT NOT NULL,
    balance BIGINT NOT NULL DEFAULT 0 CHECK (balance >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (owner_type, owner_id)
);

CREATE TABLE IF NOT EXISTS economy_ledger (
    id BIGSERIAL PRIMARY KEY,
    event_id TEXT NOT NULL UNIQUE,
    owner_type TEXT NOT NULL CHECK (owner_type IN ('player','guild','kingdom')),
    owner_id TEXT NOT NULL,
    direction TEXT NOT NULL CHECK (direction IN ('credit','debit')),
    amount BIGINT NOT NULL CHECK (amount > 0),
    reason TEXT NOT NULL,
    reference_type TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS economy_ledger_owner_created
    ON economy_ledger(owner_type, owner_id, created_at DESC);
CREATE INDEX IF NOT EXISTS economy_ledger_created
    ON economy_ledger(created_at DESC);
