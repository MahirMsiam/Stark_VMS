package com.starkgroup.vms.config;

import java.util.Locale;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import com.starkgroup.vms.entity.AppUser;
import com.starkgroup.vms.repository.AppUserRepository;

/**
 * Creates the first admin account from ADMIN_EMAIL / ADMIN_PASSWORD (from .env or the environment),
 * so no password is ever written in source code or migrations. Does nothing if the user already exists.
 */
@Component
public class AdminAccountInitializer implements ApplicationRunner {

	private static final Logger log = LoggerFactory.getLogger(AdminAccountInitializer.class);

	private final AppUserRepository users;
	private final PasswordEncoder passwordEncoder;
	private final String email;
	private final String password;

	public AdminAccountInitializer(AppUserRepository users, PasswordEncoder passwordEncoder,
			@Value("${app.admin.email}") String email, @Value("${app.admin.password}") String password) {
		this.users = users;
		this.passwordEncoder = passwordEncoder;
		this.email = email.trim().toLowerCase(Locale.ROOT);
		this.password = password;
	}

	@Override
	public void run(ApplicationArguments args) {
		if (email.isEmpty() || password.isEmpty()) {
			log.info("ADMIN_EMAIL/ADMIN_PASSWORD not set: no admin account created");
			return;
		}
		if (password.length() < 12) {
			throw new IllegalStateException("ADMIN_PASSWORD must be at least 12 characters");
		}
		if (!users.existsByEmail(email)) {
			users.save(AppUser.create(email, passwordEncoder.encode(password)));
			log.info("Created admin account {}", email); // email only, never the password
		}
	}
}
