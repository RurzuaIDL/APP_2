package org.example.BackendApplication.repository;

import org.example.BackendApplication.models.ERole;
import org.example.BackendApplication.models.Role;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface RoleRepository extends JpaRepository<Role, Long> {
    Optional<Role> findByName(ERole name);
}
