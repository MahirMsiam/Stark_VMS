package com.starkgroup.vms.dto;

import com.starkgroup.vms.entity.Vehicle;
import com.starkgroup.vms.entity.VehicleStatus;
import com.starkgroup.vms.entity.VehicleType;

/** What the API returns for a vehicle. Keeps the entity itself out of the JSON contract. */
public record VehicleResponse(
		Long id,
		String vehicleNumber,
		String company,
		VehicleType type,
		String brand,
		String model,
		VehicleStatus status) {

	public static VehicleResponse from(Vehicle v) {
		return new VehicleResponse(v.getId(), v.getVehicleNumber(), v.getCompany(), v.getType(),
				v.getBrand(), v.getModel(), v.getStatus());
	}
}
