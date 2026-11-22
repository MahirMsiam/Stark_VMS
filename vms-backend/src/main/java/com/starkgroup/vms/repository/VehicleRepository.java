package com.starkgroup.vms.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.starkgroup.vms.entity.Vehicle;

public interface VehicleRepository extends JpaRepository<Vehicle, Long> {

	boolean existsByVehicleNumber(String vehicleNumber);

	/** For updates: is the number used by a vehicle other than this one? */
	boolean existsByVehicleNumberAndIdNot(String vehicleNumber, Long id);
}
