package com.starkgroup.vms.service;

import java.util.List;
import java.util.Locale;

import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import com.starkgroup.vms.repository.AppUserRepository;

/** Lets Spring Security look up users (by email) in the database. */
@Service
public class AppUserDetailsService implements UserDetailsService {

	private final AppUserRepository repository;

	public AppUserDetailsService(AppUserRepository repository) {
		this.repository = repository;
	}

	@Override
	public UserDetails loadUserByUsername(String email) {
		return repository.findByEmail(email.trim().toLowerCase(Locale.ROOT))
				.map(user -> User.withUsername(user.getEmail())
						.password(user.getPasswordHash())
						.authorities(List.of())
						.build())
				.orElseThrow(() -> new UsernameNotFoundException("Unknown user"));
	}
}
