package org.example.BackendApplication.Security.service;

import org.example.BackendApplication.models.ERole;
import org.example.BackendApplication.models.Role;
import org.example.BackendApplication.repository.RoleRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class RoleService {

    @Autowired
    RoleRepository roleRepository;

    public Role findByName(ERole name) {
        return roleRepository.findByName(name)
                .orElseThrow(() -> new RuntimeException("Error: Rol no encontrado."));
    }

    public Role findByNameString(String name) {
        try {
            ERole roleEnum = ERole.valueOf(name);
            return findByName(roleEnum);
        } catch (IllegalArgumentException e) {
            throw new RuntimeException("Error: Rol inválido → " + name);
        }
    }
}
