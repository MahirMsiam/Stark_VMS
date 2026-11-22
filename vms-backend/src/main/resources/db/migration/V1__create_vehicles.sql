-- Vehicle table: the explicit schema (Hibernate only validates against it).
-- Works on MySQL 8 and on H2 (used by tests).
CREATE TABLE vehicles (
    id             BIGINT       NOT NULL AUTO_INCREMENT,
    vehicle_number VARCHAR(30)  NOT NULL, -- stored normalized: trimmed, upper case, single spaces
    company        VARCHAR(100) NOT NULL,
    type           VARCHAR(20)  NOT NULL, -- VehicleType enum name, e.g. 'TRUCK'
    brand          VARCHAR(40)  NOT NULL,
    model          VARCHAR(40)  NOT NULL,
    status         VARCHAR(20)  NOT NULL, -- VehicleStatus enum name, e.g. 'IN_USE'
    CONSTRAINT pk_vehicles PRIMARY KEY (id),
    CONSTRAINT uk_vehicles_vehicle_number UNIQUE (vehicle_number)
);
