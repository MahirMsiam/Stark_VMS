package com.starkgroup.vms.controller;

import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.WebApplicationContext;

/** Full stack: HTTP -> controller -> service -> H2 database (real Flyway schema). Rolled back after each test. */
@SpringBootTest
@ActiveProfiles("h2")
@Transactional
class VehicleControllerTests {

	@Autowired
	WebApplicationContext context;

	MockMvc mvc;

	@BeforeEach
	void setUp() {
		mvc = MockMvcBuilders.webAppContextSetup(context).build();
	}

	private static String json(String number, String status) {
		return """
				{"vehicleNumber": "%s", "company": "Stark Logistics", "type": "TRUCK",
				 "brand": "Tata", "model": "LPT 1613", "status": "%s"}""".formatted(number, status);
	}

	private ResultActions send(org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder request,
			String body) throws Exception {
		return mvc.perform(request.contentType(MediaType.APPLICATION_JSON).content(body));
	}

	private long createVehicle(String number) throws Exception {
		String location = send(post("/api/vehicles"), json(number, "AVAILABLE"))
				.andExpect(status().isCreated())
				.andReturn().getResponse().getHeader("Location");
		return Long.parseLong(location.substring(location.lastIndexOf('/') + 1));
	}

	@Test
	void fullCrudFlow() throws Exception {
		// Create
		send(post("/api/vehicles"), json(" dhaka metro-ga-11-2345 ", "AVAILABLE"))
				.andExpect(status().isCreated())
				.andExpect(header().exists("Location"))
				.andExpect(jsonPath("$.id").isNumber())
				.andExpect(jsonPath("$.vehicleNumber").value("DHAKA METRO-GA-11-2345"))
				.andExpect(jsonPath("$.type").value("TRUCK"));
		long id = createVehicle("CHATTA-99");

		// Read list + one
		mvc.perform(get("/api/vehicles"))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$", hasSize(2)))
				.andExpect(jsonPath("$[1].vehicleNumber").value("CHATTA-99"));
		mvc.perform(get("/api/vehicles/" + id))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$.status").value("AVAILABLE"));

		// Update
		send(put("/api/vehicles/" + id), json("CHATTA-99", "MAINTENANCE"))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$.status").value("MAINTENANCE"));

		// Delete
		mvc.perform(delete("/api/vehicles/" + id)).andExpect(status().isNoContent());
		mvc.perform(get("/api/vehicles/" + id)).andExpect(status().isNotFound());
	}

	@Test
	void duplicateVehicleNumberIsRejectedOnCreateAndUpdate() throws Exception {
		createVehicle("KA-01-AB-1234");
		long other = createVehicle("KA-02-CD-5678");

		send(post("/api/vehicles"), json("ka-01-ab-1234", "AVAILABLE"))
				.andExpect(status().isConflict())
				.andExpect(jsonPath("$.detail").value("Vehicle number KA-01-AB-1234 is already registered"));
		send(put("/api/vehicles/" + other), json("KA-01-AB-1234", "AVAILABLE"))
				.andExpect(status().isConflict());
	}

	@Test
	void invalidBodyReturnsFieldErrors() throws Exception {
		send(post("/api/vehicles"), """
				{"vehicleNumber": "#", "company": "", "brand": "Tata", "model": "X"}""")
				.andExpect(status().isBadRequest())
				.andExpect(jsonPath("$.errors.vehicleNumber").exists())
				.andExpect(jsonPath("$.errors.company").value("Company is required"))
				.andExpect(jsonPath("$.errors.type").value("Type is required"))
				.andExpect(jsonPath("$.errors.status").value("Status is required"));
	}

	@Test
	void numberTooShortAfterNormalizingIs400AndNotStored() throws Exception {
		send(post("/api/vehicles"), json("A  B", "AVAILABLE"))
				.andExpect(status().isBadRequest())
				.andExpect(jsonPath("$.errors.vehicleNumber").value("Vehicle number must be 4-30 characters"));
		mvc.perform(get("/api/vehicles")).andExpect(jsonPath("$", hasSize(0)));
	}

	@Test
	void unknownTypeOrMalformedJsonIs400() throws Exception {
		send(post("/api/vehicles"), json("KA-03", "PARKED"))
				.andExpect(status().isBadRequest())
				.andExpect(jsonPath("$.errors.status").value("Must be one of: AVAILABLE, IN_USE, MAINTENANCE, INACTIVE"));
		send(post("/api/vehicles"), "{not json")
				.andExpect(status().isBadRequest())
				.andExpect(jsonPath("$.detail").value("Request body is not valid JSON"));
	}

	@Test
	void missingVehicleIs404OnReadUpdateDelete() throws Exception {
		mvc.perform(get("/api/vehicles/999999"))
				.andExpect(status().isNotFound())
				.andExpect(jsonPath("$.detail").value("Vehicle 999999 not found"));
		send(put("/api/vehicles/999999"), json("KA-04", "AVAILABLE")).andExpect(status().isNotFound());
		mvc.perform(delete("/api/vehicles/999999")).andExpect(status().isNotFound());
	}

	@Test
	void nonNumericIdIs400() throws Exception {
		mvc.perform(get("/api/vehicles/abc")).andExpect(status().isBadRequest());
	}
}
