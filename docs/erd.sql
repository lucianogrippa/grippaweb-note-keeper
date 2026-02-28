CREATE IF NOT EXISTS TABLE "groups" (
  "id" string PRIMARY KEY DEFAULT ((lower(hex(randomblob(16))))),
  "categories_id" string NOT NULL,
  "name" string NOT NULL,
  "created_at" timestamp NOT NULL,
  "updated_at" timestamp NOT NULL
);

CREATE IF NOT EXISTS TABLE "user_profile" (
  "id" string PRIMARY KEY DEFAULT ((lower(hex(randomblob(16))))),
  "full_name" string NOT NULL,
  "password_hash" string NOT NULL,
  "created_at" timestamp NOT NULL,
  "updated_at" timestamp NOT NULL
);

CREATE IF NOT EXISTS TABLE "categories" (
  "id" string PRIMARY KEY DEFAULT ((lower(hex(randomblob(16))))),
  "user_id" string NOT NULL,
  "name" string NOT NULL,
  "description" string,
  "created_at" timestamp NOT NULL,
  "updated_at" timestamp NOT NULL
);

CREATE IF NOT EXISTS TABLE "notes" (
  "id" string PRIMARY KEY DEFAULT ((lower(hex(randomblob(16))))),
  "groups_id" string NOT NULL,
  "title" string NOT NULL,
  "content" string NOT NULL,
  "is_encrypted" boolean NOT NULL DEFAULT false,
  "created_at" timestamp NOT NULL,
  "updated_at" timestamp NOT NULL
);

CREATE IF NOT EXISTS TABLE "db_version" (
  "id" string PRIMARY KEY DEFAULT ((lower(hex(randomblob(16))))),
  "created_at" timestamp NOT NULL DEFAULT (CURRENT_TIMESTAMP),
  "ver" string NOT NULL
);

ALTER TABLE "groups" ADD FOREIGN KEY ("categories_id") REFERENCES "categories" ("id");

ALTER TABLE "categories" ADD FOREIGN KEY ("user_id") REFERENCES "user_profile" ("id");

ALTER TABLE "notes" ADD FOREIGN KEY ("groups_id") REFERENCES "groups" ("id");

COMMENT ON TABLE "groups" IS 'This table represents groups of notes within a category. Each group can contain multiple notes. The created_at and updated_at fields track when the group was created and last updated.';

COMMENT ON TABLE "user_profile" IS 'This table represents the user profile. Each user can have multiple categories of notes. The password_hash field is used to store the hashed password for authentication purposes, and the created_at and updated_at fields track when the user profile was created and last updated.';

COMMENT ON TABLE "categories" IS 'This table represents categories of notes for a user. Each category can have multiple groups of notes. The description field is optional and can be used to provide additional information about the category.';

COMMENT ON TABLE "notes" IS 'This table represents individual notes. Each note belongs to a group, which in turn belongs to a category. The is_encrypted field indicates whether the content of the note is encrypted, which can be useful for sensitive information.';

COMMENT ON TABLE "db_version" IS 'This table is used to track the version of the database schema. It can be useful for managing migrations and ensuring compatibility with different versions of the application.';
