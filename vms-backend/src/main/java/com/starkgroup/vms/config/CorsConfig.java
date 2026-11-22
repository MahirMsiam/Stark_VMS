package com.starkgroup.vms.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * Lets the Flutter web app (a different origin) call the API from the browser.
 * Allowed origins come from configuration (CORS_ALLOWED_ORIGINS), so production
 * can allow only the deployed frontend URL without a code change.
 */
@Configuration
public class CorsConfig implements WebMvcConfigurer {

	private final String[] allowedOrigins;

	public CorsConfig(@Value("${app.cors.allowed-origins}") String[] allowedOrigins) {
		this.allowedOrigins = allowedOrigins;
	}

	@Override
	public void addCorsMappings(CorsRegistry registry) {
		registry.addMapping("/api/**")
				.allowedOriginPatterns(allowedOrigins)
				.allowedMethods("GET", "POST", "PUT", "DELETE")
				.exposedHeaders("Location");
	}
}
