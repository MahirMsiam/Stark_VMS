package com.starkgroup.vms.entity;

import java.util.Objects;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

/** A vehicle row in the "vehicles" table (see db/migration/V1__create_vehicles.sql). */
@Entity
@Table(name = "vehicles")
public class Vehicle {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@Column(name = "vehicle_number", nullable = false, unique = true, length = 30)
	private String vehicleNumber;

	@Column(nullable = false, length = 100)
	private String company;

	// VARCHAR, not MySQL's native ENUM, so adding a type later needs no schema change.
	@Enumerated(EnumType.STRING)
	@JdbcTypeCode(SqlTypes.VARCHAR)
	@Column(nullable = false, length = 20)
	private VehicleType type;

	@Column(nullable = false, length = 40)
	private String brand;

	@Column(nullable = false, length = 40)
	private String model;

	@Enumerated(EnumType.STRING)
	@JdbcTypeCode(SqlTypes.VARCHAR)
	@Column(nullable = false, length = 20)
	private VehicleStatus status;

	/** For JPA only. Application code uses {@link #create}, so a Vehicle is never half-built. */
	protected Vehicle() {
	}

	/** Factory method: the only way to make a new vehicle, with every required field. */
	public static Vehicle create(String vehicleNumber, String company, VehicleType type, String brand,
			String model, VehicleStatus status) {
		Vehicle vehicle = new Vehicle();
		vehicle.update(vehicleNumber, company, type, brand, model, status);
		return vehicle;
	}

	/** Replaces all details at once (matches PUT semantics); no field can be left unset. */
	public void update(String vehicleNumber, String company, VehicleType type, String brand, String model,
			VehicleStatus status) {
		this.vehicleNumber = Objects.requireNonNull(vehicleNumber, "vehicleNumber");
		this.company = Objects.requireNonNull(company, "company");
		this.type = Objects.requireNonNull(type, "type");
		this.brand = Objects.requireNonNull(brand, "brand");
		this.model = Objects.requireNonNull(model, "model");
		this.status = Objects.requireNonNull(status, "status");
	}

	public Long getId() { return id; }
	public String getVehicleNumber() { return vehicleNumber; }
	public String getCompany() { return company; }
	public VehicleType getType() { return type; }
	public String getBrand() { return brand; }
	public String getModel() { return model; }
	public VehicleStatus getStatus() { return status; }
}
