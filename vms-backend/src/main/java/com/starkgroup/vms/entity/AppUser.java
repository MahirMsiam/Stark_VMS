package com.starkgroup.vms.entity;

import java.util.Objects;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/** A user who can sign in (table "users", see V2__create_users.sql). Holds only a password hash. */
@Entity
@Table(name = "users")
public class AppUser {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@Column(nullable = false, unique = true, length = 254)
	private String email;

	@Column(name = "password_hash", nullable = false, length = 100)
	private String passwordHash;

	/** For JPA only. */
	protected AppUser() {
	}

	/** Factory method: callers must pass an already-hashed password. */
	public static AppUser create(String email, String passwordHash) {
		AppUser user = new AppUser();
		user.email = Objects.requireNonNull(email, "email");
		user.passwordHash = Objects.requireNonNull(passwordHash, "passwordHash");
		return user;
	}

	public Long getId() { return id; }
	public String getEmail() { return email; }
	public String getPasswordHash() { return passwordHash; }
}
