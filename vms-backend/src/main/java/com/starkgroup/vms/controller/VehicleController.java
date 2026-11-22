package com.starkgroup.vms.controller;

import java.net.URI;
import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.starkgroup.vms.dto.VehicleRequest;
import com.starkgroup.vms.dto.VehicleResponse;
import com.starkgroup.vms.service.VehicleService;

import jakarta.validation.Valid;

/** Vehicle REST API. HTTP only: validation via @Valid, rules live in VehicleService. See API.md. */
@RestController
@RequestMapping("/api/vehicles")
public class VehicleController {

	private final VehicleService service;

	public VehicleController(VehicleService service) {
		this.service = service;
	}

	@GetMapping
	public List<VehicleResponse> list() {
		return service.findAll();
	}

	@GetMapping("/{id}")
	public VehicleResponse get(@PathVariable Long id) {
		return service.findById(id);
	}

	@PostMapping
	public ResponseEntity<VehicleResponse> create(@Valid @RequestBody VehicleRequest request) {
		VehicleResponse created = service.create(request);
		return ResponseEntity.created(URI.create("/api/vehicles/" + created.id())).body(created);
	}

	@PutMapping("/{id}")
	public VehicleResponse update(@PathVariable Long id, @Valid @RequestBody VehicleRequest request) {
		return service.update(id, request);
	}

	@DeleteMapping("/{id}")
	public ResponseEntity<Void> delete(@PathVariable Long id) {
		service.delete(id);
		return ResponseEntity.noContent().build();
	}
}
