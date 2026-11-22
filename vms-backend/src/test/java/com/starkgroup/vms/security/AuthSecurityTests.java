package com.starkgroup.vms.security;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.options;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.time.Duration;
import java.time.Instant;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.WebApplicationContext;

import com.starkgroup.vms.dto.LoginRequest;
import com.starkgroup.vms.repository.AppUserRepository;
import com.starkgroup.vms.service.TokenService;

/** The real security filter chain: login, protected vehicle endpoints, token checks. */
@SpringBootTest(properties = {
		"app.admin.email=Admin@Test.local", // stored lower case
		"app.admin.password=correct-horse-battery-staple" })
@ActiveProfiles("h2")
@Transactional
class AuthSecurityTests {

	private static final String PASSWORD = "correct-horse-battery-staple";

	@Autowired
	WebApplicationContext context;

	@Autowired
	AppUserRepository users;

	@Autowired
	JwtEncoder jwtEncoder;

	MockMvc mvc;

	@BeforeEach
	void setUp() {
		mvc = MockMvcBuilders.webAppContextSetup(context).apply(springSecurity()).build();
	}

	private ResultActions login(String email, String password) throws Exception {
		return mvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
				.content("{\"email\":\"%s\",\"password\":\"%s\"}".formatted(email, password)));
	}

	private String token() throws Exception {
		String body = login("admin@test.local", PASSWORD).andReturn().getResponse().getContentAsString();
		return body.replaceAll(".*\"accessToken\":\"([^\"]+)\".*", "$1");
	}

	@Test
	void validLoginReturnsBearerToken() throws Exception {
		login("  ADMIN@test.local ", PASSWORD)
				.andExpect(status().isOk())
				.andExpect(jsonPath("$.accessToken").isNotEmpty())
				.andExpect(jsonPath("$.tokenType").value("Bearer"))
				.andExpect(jsonPath("$.email").value("admin@test.local"))
				.andExpect(jsonPath("$.expiresAt").isString());
	}

	@Test
	void wrongPasswordAndUnknownEmailGetTheSame401() throws Exception {
		login("admin@test.local", "wrong-password")
				.andExpect(status().isUnauthorized())
				.andExpect(jsonPath("$.detail").value("Invalid email or password"));
		login("nobody@test.local", PASSWORD)
				.andExpect(status().isUnauthorized())
				.andExpect(jsonPath("$.detail").value("Invalid email or password"));
	}

	@Test
	void loginValidatesFields() throws Exception {
		login("not-an-email", "")
				.andExpect(status().isBadRequest())
				.andExpect(jsonPath("$.errors.email").value("Enter a valid email address"))
				.andExpect(jsonPath("$.errors.password").value("Password is required"));
	}

	@Test
	void vehicleOperationsRequireAToken() throws Exception {
		mvc.perform(get("/api/vehicles"))
				.andExpect(status().isUnauthorized())
				.andExpect(header().string(HttpHeaders.WWW_AUTHENTICATE, "Bearer"))
				.andExpect(jsonPath("$.detail").value("Please sign in to continue"));
		mvc.perform(post("/api/vehicles").contentType(MediaType.APPLICATION_JSON).content("{}"))
				.andExpect(status().isUnauthorized());
	}

	@Test
	void vehicleOperationsWorkWithAValidToken() throws Exception {
		String auth = "Bearer " + token();
		mvc.perform(post("/api/vehicles").header(HttpHeaders.AUTHORIZATION, auth)
				.contentType(MediaType.APPLICATION_JSON)
				.content("""
						{"vehicleNumber":"AUTH-0001","company":"Stark Motors","type":"CAR",
						 "brand":"Toyota","model":"Premio","status":"AVAILABLE"}"""))
				.andExpect(status().isCreated());
		mvc.perform(get("/api/vehicles").header(HttpHeaders.AUTHORIZATION, auth))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$[0].vehicleNumber").value("AUTH-0001"));
	}

	@Test
	void forgedOrExpiredTokensAreRejected() throws Exception {
		mvc.perform(get("/api/vehicles").header(HttpHeaders.AUTHORIZATION, "Bearer not.a.token"))
				.andExpect(status().isUnauthorized());

		String tampered = token();
		tampered = tampered.substring(0, tampered.length() - 2) + (tampered.endsWith("AA") ? "BB" : "AA");
		mvc.perform(get("/api/vehicles").header(HttpHeaders.AUTHORIZATION, "Bearer " + tampered))
				.andExpect(status().isUnauthorized());

		Instant past = Instant.now().minus(Duration.ofMinutes(10));
		String expired = jwtEncoder.encode(JwtEncoderParameters.from(JwsHeader.with(MacAlgorithm.HS256).build(),
				JwtClaimsSet.builder().issuer(TokenService.ISSUER).subject("admin@test.local")
						.issuedAt(past).expiresAt(past.plus(Duration.ofMinutes(5))).build()))
				.getTokenValue();
		mvc.perform(get("/api/vehicles").header(HttpHeaders.AUTHORIZATION, "Bearer " + expired))
				.andExpect(status().isUnauthorized());
	}

	@Test
	void passwordIsStoredOnlyAsBcryptHash() {
		String hash = users.findByEmail("admin@test.local").orElseThrow().getPasswordHash();
		assertThat(hash).startsWith("{bcrypt}$2").doesNotContain(PASSWORD);
		assertThat(new LoginRequest("a@b.c", PASSWORD).toString()).doesNotContain(PASSWORD);
	}

	@Test
	void healthAndCorsPreflightArePublic() throws Exception {
		mvc.perform(get("/actuator/health")).andExpect(status().isOk());
		mvc.perform(options("/api/vehicles")
				.header("Origin", "http://localhost:8080")
				.header("Access-Control-Request-Method", "GET")
				.header("Access-Control-Request-Headers", "authorization"))
				.andExpect(status().isOk())
				.andExpect(header().string("Access-Control-Allow-Origin", "http://localhost:8080"));
	}
}
