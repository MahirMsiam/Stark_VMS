package com.starkgroup.vms.exception;

/** A vehicle with this number already exists. Returned as HTTP 409 Conflict. */
public class DuplicateVehicleNumberException extends RuntimeException {

	public DuplicateVehicleNumberException(String vehicleNumber) {
		super("Vehicle number " + vehicleNumber + " is already registered");
	}
}
