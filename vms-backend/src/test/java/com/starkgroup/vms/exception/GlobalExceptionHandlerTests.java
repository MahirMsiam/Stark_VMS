package com.starkgroup.vms.exception;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;

import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

class GlobalExceptionHandlerTests {

	record SampleRequest(@NotBlank(message = "Name is required") String name) {
	}

	@RestController
	static class SampleController {

		@GetMapping("/missing")
		String missing() {
			throw new ResourceNotFoundException("Vehicle 42 not found");
		}

		@GetMapping("/boom")
		String boom() {
			throw new IllegalStateException("SQL: SELECT secret FROM internals");
		}

		@GetMapping("/duplicate")
		String duplicate() {
			throw new DuplicateVehicleNumberException("KA-01");
		}

		@PostMapping("/validate")
		String validate(@Valid @RequestBody SampleRequest request) {
			return "ok";
		}
	}

	private final MockMvc mvc = MockMvcBuilders.standaloneSetup(new SampleController())
			.setControllerAdvice(new GlobalExceptionHandler())
			.build();

	@Test
	void notFoundBecomes404ProblemDetail() throws Exception {
		mvc.perform(get("/missing"))
				.andExpect(status().isNotFound())
				.andExpect(jsonPath("$.status").value(404))
				.andExpect(jsonPath("$.detail").value("Vehicle 42 not found"));
	}

	@Test
	void unexpectedErrorBecomes500WithoutLeakingDetails() throws Exception {
		mvc.perform(get("/boom"))
				.andExpect(status().isInternalServerError())
				.andExpect(jsonPath("$.status").value(500))
				.andExpect(jsonPath("$.detail").value("Something went wrong on the server. Please try again later."));
	}

	@Test
	void duplicateVehicleNumberBecomes409() throws Exception {
		mvc.perform(get("/duplicate"))
				.andExpect(status().isConflict())
				.andExpect(jsonPath("$.detail").value("Vehicle number KA-01 is already registered"));
	}

	@Test
	void validationErrorsListEachField() throws Exception {
		mvc.perform(post("/validate").contentType(MediaType.APPLICATION_JSON).content("{\"name\": \"\"}"))
				.andExpect(status().isBadRequest())
				.andExpect(jsonPath("$.detail").value("Validation failed"))
				.andExpect(jsonPath("$.errors.name").value("Name is required"));
	}
}
