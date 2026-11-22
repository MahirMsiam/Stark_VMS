package com.starkgroup.vms.exception;

import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.stream.Collectors;

import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.ProblemDetail;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.context.request.WebRequest;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;

import tools.jackson.databind.exc.InvalidFormatException;

/**
 * Turns exceptions into one consistent JSON error format for every endpoint:
 * the standard ProblemDetail (RFC 9457) - {"status", "title", "detail", ...}.
 * Spring's own errors (bad JSON, wrong method, unknown URL...) are handled by the parent class.
 */
@RestControllerAdvice
public class GlobalExceptionHandler extends ResponseEntityExceptionHandler {

	@ExceptionHandler(ResourceNotFoundException.class)
	public ProblemDetail handleNotFound(ResourceNotFoundException ex) {
		return ProblemDetail.forStatusAndDetail(HttpStatus.NOT_FOUND, ex.getMessage());
	}

	/**
	 * Anything unexpected: same JSON shape as every other error, full details only in the server log
	 * (never stack traces or SQL in the response).
	 */
	@ExceptionHandler(Exception.class)
	public ProblemDetail handleUnexpected(Exception ex) {
		logger.error("Unexpected error", ex);
		return ProblemDetail.forStatusAndDetail(HttpStatus.INTERNAL_SERVER_ERROR,
				"Something went wrong on the server. Please try again later.");
	}

	/** Wrong email or wrong password: one message for both, so emails can't be probed. */
	@ExceptionHandler(AuthenticationException.class)
	public ProblemDetail handleLoginFailure(AuthenticationException ex) {
		return ProblemDetail.forStatusAndDetail(HttpStatus.UNAUTHORIZED, "Invalid email or password");
	}

	@ExceptionHandler(DuplicateVehicleNumberException.class)
	public ProblemDetail handleDuplicate(DuplicateVehicleNumberException ex) {
		return ProblemDetail.forStatusAndDetail(HttpStatus.CONFLICT, ex.getMessage());
	}

	/**
	 * Unreadable body. For an unknown enum value (e.g. "type": "PLANE") say which field and what is allowed,
	 * in the same "errors" shape as validation failures; otherwise a generic message (no parser internals).
	 */
	@Override
	protected ResponseEntity<Object> handleHttpMessageNotReadable(HttpMessageNotReadableException ex,
			HttpHeaders headers, HttpStatusCode status, WebRequest request) {
		ProblemDetail problem = ProblemDetail.forStatusAndDetail(status, "Request body is not valid JSON");
		if (ex.getMostSpecificCause() instanceof InvalidFormatException invalid
				&& invalid.getTargetType().isEnum() && !invalid.getPath().isEmpty()) {
			String field = invalid.getPath().getLast().getPropertyName();
			String allowed = Arrays.stream(invalid.getTargetType().getEnumConstants())
					.map(Object::toString).collect(Collectors.joining(", "));
			problem.setDetail("Validation failed");
			problem.setProperty("errors", Map.of(field, "Must be one of: " + allowed));
		}
		return ResponseEntity.status(status).headers(headers).body(problem);
	}

	/** Adds field-level messages, e.g. {"errors": {"vehicleNumber": "must not be blank"}}, so the UI can show them. */
	@Override
	protected ResponseEntity<Object> handleMethodArgumentNotValid(MethodArgumentNotValidException ex,
			HttpHeaders headers, HttpStatusCode status, WebRequest request) {
		Map<String, String> errors = new LinkedHashMap<>();
		ex.getBindingResult().getFieldErrors()
				.forEach(error -> errors.putIfAbsent(error.getField(), error.getDefaultMessage()));

		ProblemDetail problem = ProblemDetail.forStatusAndDetail(status, "Validation failed");
		problem.setProperty("errors", errors);
		return ResponseEntity.status(status).headers(headers).body(problem);
	}
}
