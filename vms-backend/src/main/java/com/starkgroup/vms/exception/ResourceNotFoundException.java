package com.starkgroup.vms.exception;

/** Throw from a service when a requested record does not exist. Returned as HTTP 404. */
public class ResourceNotFoundException extends RuntimeException {

	public ResourceNotFoundException(String message) {
		super(message);
	}
}
