package com.starkgroup.vms.service;

import java.util.Locale;

import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Service;

import com.starkgroup.vms.dto.LoginRequest;
import com.starkgroup.vms.dto.LoginResponse;

/**
 * Login use case: check the password (Spring Security, BCrypt) and issue a token.
 * Wrong email and wrong password fail the same way (AuthenticationException -> 401),
 * so callers can't find out which emails exist.
 */
@Service
public class AuthService {

	private final AuthenticationManager authenticationManager;
	private final TokenService tokenService;

	public AuthService(AuthenticationManager authenticationManager, TokenService tokenService) {
		this.authenticationManager = authenticationManager;
		this.tokenService = tokenService;
	}

	public LoginResponse login(LoginRequest request) {
		String email = request.email().trim().toLowerCase(Locale.ROOT);
		Authentication authentication = authenticationManager.authenticate(
				UsernamePasswordAuthenticationToken.unauthenticated(email, request.password()));
		TokenService.IssuedToken token = tokenService.issue(authentication.getName());
		return new LoginResponse(token.value(), "Bearer", token.expiresAt(), authentication.getName());
	}
}
