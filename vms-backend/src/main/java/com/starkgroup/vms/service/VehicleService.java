package com.starkgroup.vms.service;

import java.util.List;

import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.starkgroup.vms.dto.VehicleRequest;
import com.starkgroup.vms.dto.VehicleResponse;
import com.starkgroup.vms.entity.Vehicle;
import com.starkgroup.vms.exception.DuplicateVehicleNumberException;
import com.starkgroup.vms.exception.ResourceNotFoundException;
import com.starkgroup.vms.repository.VehicleRepository;

/** Vehicle business rules. The only place vehicles are created, changed or deleted. */
@Service
@Transactional
public class VehicleService {

	private final VehicleRepository repository;

	public VehicleService(VehicleRepository repository) {
		this.repository = repository;
	}

	@Transactional(readOnly = true)
	public List<VehicleResponse> findAll() {
		return repository.findAll(Sort.by("id")).stream().map(VehicleResponse::from).toList();
	}

	@Transactional(readOnly = true)
	public VehicleResponse findById(Long id) {
		return VehicleResponse.from(getVehicle(id));
	}

	public VehicleResponse create(VehicleRequest request) {
		String number = request.vehicleNumber(); // already normalized by VehicleRequest
		if (repository.existsByVehicleNumber(number)) {
			throw new DuplicateVehicleNumberException(number);
		}
		return save(Vehicle.create(number, request.company().trim(), request.type(), request.brand().trim(),
				request.model().trim(), request.status()));
	}

	public VehicleResponse update(Long id, VehicleRequest request) {
		Vehicle vehicle = getVehicle(id);
		String number = request.vehicleNumber(); // already normalized by VehicleRequest
		if (repository.existsByVehicleNumberAndIdNot(number, id)) {
			throw new DuplicateVehicleNumberException(number);
		}
		vehicle.update(number, request.company().trim(), request.type(), request.brand().trim(),
				request.model().trim(), request.status());
		return save(vehicle);
	}

	public void delete(Long id) {
		repository.delete(getVehicle(id));
	}

	private Vehicle getVehicle(Long id) {
		return repository.findById(id)
				.orElseThrow(() -> new ResourceNotFoundException("Vehicle " + id + " not found"));
	}

	/** The database unique key is the final guard: two simultaneous requests can both pass the check above. */
	private VehicleResponse save(Vehicle vehicle) {
		try {
			return VehicleResponse.from(repository.saveAndFlush(vehicle));
		} catch (DataIntegrityViolationException ex) {
			if (isVehicleNumberConflict(ex)) {
				throw new DuplicateVehicleNumberException(vehicle.getVehicleNumber());
			}
			throw ex;
		}
	}

	/** MySQL and H2 both name the violated key in the message; only that key means "duplicate number". */
	private static boolean isVehicleNumberConflict(DataIntegrityViolationException ex) {
		String message = String.valueOf(ex.getMostSpecificCause().getMessage());
		return message.toLowerCase().contains("uk_vehicles_vehicle_number");
	}
}
