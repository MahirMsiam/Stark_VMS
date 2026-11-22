package com.starkgroup.vms.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.sql.SQLIntegrityConstraintViolationException;
import java.util.Optional;

import org.junit.jupiter.api.Test;
import org.springframework.dao.DataIntegrityViolationException;

import com.starkgroup.vms.dto.VehicleRequest;
import com.starkgroup.vms.dto.VehicleResponse;
import com.starkgroup.vms.entity.Vehicle;
import com.starkgroup.vms.entity.VehicleStatus;
import com.starkgroup.vms.entity.VehicleType;
import com.starkgroup.vms.exception.DuplicateVehicleNumberException;
import com.starkgroup.vms.repository.VehicleRepository;

/** Focused unit tests for the duplicate Vehicle Number rule. No database involved. */
class VehicleServiceTests {

	private final VehicleRepository repository = mock(VehicleRepository.class);
	private final VehicleService service = new VehicleService(repository);

	private static VehicleRequest request(String number) {
		return new VehicleRequest(number, "Stark Logistics", VehicleType.TRUCK, "Tata", "LPT 1613",
				VehicleStatus.AVAILABLE);
	}

	private static Vehicle existing() {
		return Vehicle.create("OLD-1", "Stark Motors", VehicleType.CAR, "Toyota", "Premio", VehicleStatus.AVAILABLE);
	}

	@Test
	void createRejectsExistingVehicleNumber() {
		when(repository.existsByVehicleNumber("DHAKA METRO-GA-11-2345")).thenReturn(true);

		assertThatThrownBy(() -> service.create(request("DHAKA METRO-GA-11-2345")))
				.isInstanceOf(DuplicateVehicleNumberException.class)
				.hasMessage("Vehicle number DHAKA METRO-GA-11-2345 is already registered");
		verify(repository, never()).saveAndFlush(any());
	}

	@Test
	void createRejectsDuplicateWrittenDifferently() {
		// Same plate typed in lower case with extra spaces is still a duplicate.
		when(repository.existsByVehicleNumber("DHAKA METRO-GA-11-2345")).thenReturn(true);

		assertThatThrownBy(() -> service.create(request("  dhaka   metro-ga-11-2345 ")))
				.isInstanceOf(DuplicateVehicleNumberException.class);
		verify(repository, never()).saveAndFlush(any());
	}

	@Test
	void createSavesNewVehicleWithNormalizedNumber() {
		when(repository.existsByVehicleNumber("KA-01 AB 1234")).thenReturn(false);
		when(repository.saveAndFlush(any())).thenAnswer(call -> call.getArgument(0));

		VehicleResponse saved = service.create(request(" ka-01  ab 1234"));

		assertThat(saved.vehicleNumber()).isEqualTo("KA-01 AB 1234");
	}

	@Test
	void createTurnsDatabaseUniqueViolationIntoDuplicateError() {
		// Race: two requests pass the check at the same time; the database key catches the second.
		when(repository.existsByVehicleNumber(any())).thenReturn(false);
		when(repository.saveAndFlush(any())).thenThrow(new DataIntegrityViolationException("insert failed",
				new SQLIntegrityConstraintViolationException(
						"Duplicate entry 'KA-01' for key 'vehicles.uk_vehicles_vehicle_number'")));

		assertThatThrownBy(() -> service.create(request("KA-01")))
				.isInstanceOf(DuplicateVehicleNumberException.class);
	}

	@Test
	void otherDatabaseErrorsAreNotReportedAsDuplicates() {
		when(repository.existsByVehicleNumber(any())).thenReturn(false);
		when(repository.saveAndFlush(any())).thenThrow(new DataIntegrityViolationException("insert failed",
				new SQLIntegrityConstraintViolationException("Column 'brand' cannot be null")));

		assertThatThrownBy(() -> service.create(request("KA-01")))
				.isInstanceOf(DataIntegrityViolationException.class);
	}

	@Test
	void updateRejectsNumberUsedByAnotherVehicle() {
		when(repository.findById(1L)).thenReturn(Optional.of(existing()));
		when(repository.existsByVehicleNumberAndIdNot("TAKEN-1", 1L)).thenReturn(true);

		assertThatThrownBy(() -> service.update(1L, request("taken-1")))
				.isInstanceOf(DuplicateVehicleNumberException.class);
		verify(repository, never()).saveAndFlush(any());
	}

	@Test
	void updateMayKeepItsOwnNumber() {
		when(repository.findById(1L)).thenReturn(Optional.of(existing()));
		when(repository.existsByVehicleNumberAndIdNot("MINE-1", 1L)).thenReturn(false);
		when(repository.saveAndFlush(any())).thenAnswer(call -> call.getArgument(0));

		assertThat(service.update(1L, request("MINE-1")).vehicleNumber()).isEqualTo("MINE-1");
	}
}
