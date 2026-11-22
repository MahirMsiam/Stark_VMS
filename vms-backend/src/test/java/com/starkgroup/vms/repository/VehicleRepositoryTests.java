package com.starkgroup.vms.repository;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import com.starkgroup.vms.entity.Vehicle;
import com.starkgroup.vms.entity.VehicleStatus;
import com.starkgroup.vms.entity.VehicleType;

/** Runs against the real schema (Flyway migration on H2): mapping and the unique key. */
@SpringBootTest
@ActiveProfiles("h2")
@Transactional // each test is rolled back
class VehicleRepositoryTests {

	@Autowired
	VehicleRepository repository;

	private static Vehicle vehicle(String number) {
		return Vehicle.create(number, "Stark Motors", VehicleType.SUV, "Mitsubishi", "Pajero Sport",
				VehicleStatus.IN_USE);
	}

	@Test
	void savesAndReadsBackAllFields() {
		Long id = repository.saveAndFlush(vehicle("DHAKA METRO-GHA-13-3310")).getId();

		Vehicle found = repository.findById(id).orElseThrow();
		assertThat(found.getVehicleNumber()).isEqualTo("DHAKA METRO-GHA-13-3310");
		assertThat(found.getType()).isEqualTo(VehicleType.SUV);
		assertThat(found.getStatus()).isEqualTo(VehicleStatus.IN_USE);
		assertThat(repository.existsByVehicleNumber("DHAKA METRO-GHA-13-3310")).isTrue();
		assertThat(repository.existsByVehicleNumberAndIdNot("DHAKA METRO-GHA-13-3310", id)).isFalse();
	}

	@Test
	void databaseRejectsDuplicateVehicleNumber() {
		repository.saveAndFlush(vehicle("SAME-123"));

		assertThatThrownBy(() -> repository.saveAndFlush(vehicle("SAME-123")))
				.isInstanceOf(DataIntegrityViolationException.class)
				.hasMessageContaining("UK_VEHICLES_VEHICLE_NUMBER");
	}
}
