-- Users who may sign in. Passwords are stored only as hashes ({bcrypt}$2a$...), never in plain text.
CREATE TABLE users (
    id            BIGINT       NOT NULL AUTO_INCREMENT,
    email         VARCHAR(254) NOT NULL, -- stored lower case
    password_hash VARCHAR(100) NOT NULL,
    CONSTRAINT pk_users PRIMARY KEY (id),
    CONSTRAINT uk_users_email UNIQUE (email)
);
