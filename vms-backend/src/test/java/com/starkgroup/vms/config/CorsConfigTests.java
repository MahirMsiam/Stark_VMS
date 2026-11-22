package com.starkgroup.vms.config;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.options;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;

@SpringBootTest
@ActiveProfiles("h2")
class CorsConfigTests {

	@Autowired
	WebApplicationContext context;

	private MockMvc mvc() {
		return MockMvcBuilders.webAppContextSetup(context).build();
	}

	@Test
	void localFlutterDevServerMayCallTheApi() throws Exception {
		mvc().perform(options("/api/vehicles")
				.header("Origin", "http://localhost:53124")
				.header("Access-Control-Request-Method", "POST"))
				.andExpect(status().isOk())
				.andExpect(header().string("Access-Control-Allow-Origin", "http://localhost:53124"));
	}

	@Test
	void unknownOriginIsRejected() throws Exception {
		mvc().perform(options("/api/vehicles")
				.header("Origin", "https://evil.example.com")
				.header("Access-Control-Request-Method", "DELETE"))
				.andExpect(status().isForbidden());
	}
}
