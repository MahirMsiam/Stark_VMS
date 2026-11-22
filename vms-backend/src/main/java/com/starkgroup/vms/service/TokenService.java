package com.starkgroup.vms.service;

import java.time.Duration;
import java.time.Instant;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.stereotype.Service;

/** Issues signed access tokens (JWT, HS256). Checking them is Spring Security's job (SecurityConfig). */
@Service
public class TokenService {

	public static final String ISSUER = "vms-backend";

	public record IssuedToken(String value, Instant expiresAt) {
	}

	private final JwtEncoder encoder;
	private final Duration ttl;

	public TokenService(JwtEncoder encoder, @Value("${app.jwt.ttl}") Duration ttl) {
		this.encoder = encoder;
		this.ttl = ttl;
	}

	public IssuedToken issue(String email) {
		Instant now = Instant.now();
		Instant expiresAt = now.plus(ttl);
		JwtClaimsSet claims = JwtClaimsSet.builder()
				.issuer(ISSUER)
				.subject(email)
				.issuedAt(now)
				.expiresAt(expiresAt)
				.build();
		JwsHeader header = JwsHeader.with(MacAlgorithm.HS256).build();
		String token = encoder.encode(JwtEncoderParameters.from(header, claims)).getTokenValue();
		return new IssuedToken(token, expiresAt);
	}
}
