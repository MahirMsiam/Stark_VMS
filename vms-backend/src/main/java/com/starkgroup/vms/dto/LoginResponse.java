package com.starkgroup.vms.dto;

import java.time.Instant;

/** Successful login. Send the token on every API call as "Authorization: Bearer <accessToken>". */
public record LoginResponse(String accessToken, String tokenType, Instant expiresAt, String email) {
}
