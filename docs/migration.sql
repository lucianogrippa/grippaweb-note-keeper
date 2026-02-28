PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
    username TEXT NOT NULL,
    full_name TEXT NOT NULL,
    password_hash TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS categories (
    id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
    user_id TEXT NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS groups (
    id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
    categories_id TEXT NOT NULL,
    name TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (categories_id) REFERENCES categories(id)
);

CREATE TABLE IF NOT EXISTS items (
    id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
    groups_id TEXT NOT NULL,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    is_encrypted INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (groups_id) REFERENCES groups(id)
);

CREATE TABLE IF NOT EXISTS db_version
(
    id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ver TEXT NOT NULL
);

-- if the database is being created for the first time, we need to insert the current version
-- check if the db_version table is empty, if it is, insert the current version
INSERT INTO db_version (ver)
SELECT '1.0.0'
WHERE NOT EXISTS (SELECT 1 FROM db_version);

-- insert autoriti only if the authority table is empty
INSERT INTO authority (name, description)
SELECT 'admin', 'Administrator with full access'
WHERE NOT EXISTS (SELECT 1 FROM authority);

-- insert group only if the groups table is empty
INSERT INTO groups (name, description)
SELECT 'admin', 'Administrators group with full access'
WHERE NOT EXISTS (SELECT 1 FROM groups);

-- insert user only if the user table is empty , default password is "_admin_" hashed with bcrypt
INSERT INTO "user" (autority_id, group_id, full_name, email, is_active, hashed_password)
SELECT (SELECT id FROM authority WHERE name = 'admin'), (SELECT id FROM groups WHERE name = 'admin'), 'Admin User', 'admin@example.com', 1, '$2a$12$aVBW3oj8eWL1WAFDuIvCouf8IQSYICEO4hmd7sg/cKE4IXBvCxj1u';