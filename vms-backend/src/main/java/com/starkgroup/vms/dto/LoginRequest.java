package com.starkgroup.vms.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

public record LoginRequest(
		@NotBlank(message = "Email is required")
		@Email(message = "Enter a valid email address")
		String email,

		@NotBlank(message = "Password is required")
		String password) {

	/** Surrounding spaces (common when pasting) are not part of an email. */
	public LoginRequest {
		email = email == null ? null : email.trim();
	}

	/** Never print the password, even if this object ends up in a log or error message. */
	@Override
	public String toString() {
		return "LoginRequest[email=" + email + ", password=***]";
	}
}
