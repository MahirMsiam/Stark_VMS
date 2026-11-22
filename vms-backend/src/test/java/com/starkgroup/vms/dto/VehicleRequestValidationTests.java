package com.starkgroup.vms.dto;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.Map;
import java.util.stream.Collectors;

import org.junit.jupiter.api.Test;

import com.starkgroup.vms.entity.VehicleStatus;
import com.starkgroup.vms.entity.VehicleType;

import jakarta.validation.ConstraintViolation;
import jakarta.validation.Validation;
import jakarta.validation.Validator;

class VehicleRequestValidationTests {

	private final Validator validator = Validation.buildDefaultValidatorFactory().getValidator();

	private Map<String, String> errors(VehicleRequest request) {
		return validator.validate(request).stream().collect(Collectors.toMap(
				v -> v.getPropertyPath().toString(), ConstraintViolation::getMessage, (a, b) -> a));
	}

	@Test
	void validRequestHasNoErrors() {
		assertThat(errors(new VehicleRequest("KA-01-AB-1234", "Stark Motors", VehicleType.CAR, "Toyota",
				"Premio", VehicleStatus.AVAILABLE))).isEmpty();
	}

	@Test
	void everyMissingFieldGetsAClearMessage() {
		assertThat(errors(new VehicleRequest("", " ", null, "", "", null))).containsKeys(
				"vehicleNumber", "company", "type", "brand", "model", "status")
				.containsEntry("type", "Type is required")
				.containsEntry("company", "Company is required");
	}

	@Test
	void vehicleNumberLengthIsCheckedAfterNormalizing() {
		// "A  B" is 4 characters as typed but "A B" (3) once spaces are collapsed: must be rejected.
		VehicleRequest request = new VehicleRequest("A  B", "Stark Motors", VehicleType.CAR, "Toyota", "Premio",
				VehicleStatus.AVAILABLE);
		assertThat(request.vehicleNumber()).isEqualTo("A B");
		// Any whitespace (tabs too) collapses to one space.
		assertThat(new VehicleRequest(" ka-01\t\tab ", null, null, null, null, null).vehicleNumber())
				.isEqualTo("KA-01 AB");
		assertThat(errors(request)).containsEntry("vehicleNumber", "Vehicle number must be 4-30 characters");
	}

	@Test
	void vehicleNumberRejectsSymbols() {
		assertThat(errors(new VehicleRequest("KA#01$", "Stark Motors", VehicleType.CAR, "Toyota", "Premio",
				VehicleStatus.AVAILABLE)))
				.containsEntry("vehicleNumber", "Vehicle number may only contain letters, numbers, spaces and hyphens");
	}
}
