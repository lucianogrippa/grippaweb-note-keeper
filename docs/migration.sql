
CREATE TABLE IF NOT EXISTS authority
(
    id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
    name TEXT NOT NULL,
    description TEXT
);

CREATE TABLE IF NOT EXISTS groups
(
    id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
    name TEXT NOT NULL,
    description TEXT
);

CREATE TABLE IF NOT EXISTS "user"
(
    id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
    autority_id TEXT NOT NULL,
    group_id TEXT NOT NULL,
    full_name TEXT,
    email TEXT NOT NULL,
    is_active BOOLEAN NOT NULL,
    hashed_password TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP,
    FOREIGN KEY (autority_id) REFERENCES authority (id) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (group_id) REFERENCES groups (id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS category
(
    id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
    user_id TEXT NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    crypted BOOLEAN NOT NULL DEFAULT 0,
    create_at TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES "user" (id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS item
(
    id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
    category_id TEXT NOT NULL,
    description TEXT,
    title TEXT NOT NULL,
    created_at TIMESTAMP,
    content JSON,
    crypted BOOLEAN NOT NULL DEFAULT 0,
    FOREIGN KEY (category_id) REFERENCES category (id) ON UPDATE CASCADE ON DELETE CASCADE
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