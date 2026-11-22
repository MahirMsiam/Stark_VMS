package com.starkgroup.vms.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.starkgroup.vms.entity.AppUser;

public interface AppUserRepository extends JpaRepository<AppUser, Long> {

	Optional<AppUser> findByEmail(String email);

	boolean existsByEmail(String email);
}
