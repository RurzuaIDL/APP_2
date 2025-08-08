package org.example.BackendApplication.initializer;


import org.example.BackendApplication.models.ERole;
import org.example.BackendApplication.models.Role;
import org.example.BackendApplication.models.Users;
import org.example.BackendApplication.repository.RoleRepository;
import org.example.BackendApplication.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.ApplicationListener;
import org.springframework.context.event.ContextRefreshedEvent;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.util.Arrays;
import java.util.List;

@Component
public class DataInitializer implements ApplicationListener<ContextRefreshedEvent> {

    private final RoleRepository roleRepository;
    private final UserRepository userRepository;

    @Autowired
    PasswordEncoder encoder;

    public DataInitializer(RoleRepository roleRepository, UserRepository userRepository) {
        this.roleRepository = roleRepository;
        this.userRepository = userRepository;
    }

    @Override
    public void onApplicationEvent(ContextRefreshedEvent event) {
        initializeRoles();
        initializeUser();
    }

    private void initializeRoles() {
        Arrays.stream(ERole.values()).forEach(role -> {
            if (roleRepository.findByName(role).isEmpty()) {
                roleRepository.save(new Role(role));
                System.out.println("✔ Rol creado: " + role.name());
            } else {
                System.out.println("ℹ Rol ya existe: " + role.name());
            }
        });
    }


    private void initializeUser() {
        if (userRepository.findByEmail("Admin@id-logistics.com").isEmpty()) {
            Users adminUser = new Users(
                    "Admin",
                    "Admin",
                    "Admin@id-logistics.com",

                    encoder.encode("Admin2025")
            );
            adminUser.setRoles(List.of(

                    roleRepository.findByName(ERole.ADMIN).orElseThrow()
            ));

            userRepository.save(adminUser);
        }


    }
}
