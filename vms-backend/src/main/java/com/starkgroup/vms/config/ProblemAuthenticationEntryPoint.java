package com.starkgroup.vms.config;

import java.io.IOException;

import org.springframework.security.core.AuthenticationException;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.stereotype.Component;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

/** 401 for a missing, invalid or expired token — in the same ProblemDetail JSON as every other API error. */
@Component
public class ProblemAuthenticationEntryPoint implements AuthenticationEntryPoint {

	@Override
	public void commence(HttpServletRequest request, HttpServletResponse response,
			AuthenticationException exception) throws IOException {
		response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
		response.setHeader("WWW-Authenticate", "Bearer");
		response.setContentType("application/problem+json");
		response.getWriter().write(
				"{\"status\":401,\"title\":\"Unauthorized\",\"detail\":\"Please sign in to continue\"}");
	}
}
