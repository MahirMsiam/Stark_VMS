package com.starkgroup.vms.dto;

import java.util.Locale;

import com.starkgroup.vms.entity.VehicleStatus;
import com.starkgroup.vms.entity.VehicleType;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/** Body for creating or updating a vehicle. Limits match the database columns and the Flutter form. */
public record VehicleRequest(
		@NotBlank(message = "Vehicle number is required")
		@Size(min = 4, max = 30, message = "Vehicle number must be 4-30 characters")
		@Pattern(regexp = "^[A-Za-z0-9 -]*$", message = "Vehicle number may only contain letters, numbers, spaces and hyphens")
		String vehicleNumber,

		@NotBlank(message = "Company is required")
		@Size(max = 100, message = "Company must be 100 characters or fewer")
		String company,

		@NotNull(message = "Type is required")
		VehicleType type,

		@NotBlank(message = "Brand is required")
		@Size(max = 40, message = "Brand must be 40 characters or fewer")
		String brand,

		@NotBlank(message = "Model is required")
		@Size(max = 40, message = "Model must be 40 characters or fewer")
		String model,

		@NotNull(message = "Status is required")
		VehicleStatus status) {

	/**
	 * Normalizes the number before validation runs, so the rules check exactly what gets stored:
	 * "dhaka  metro-ga 11 " -> "DHAKA METRO-GA 11" (and the same plate can't be stored twice in different spellings).
	 */
	public VehicleRequest {
		vehicleNumber = vehicleNumber == null ? null
				: vehicleNumber.trim().toUpperCase(Locale.ROOT).replaceAll("\\s+", " ");
	}
}
