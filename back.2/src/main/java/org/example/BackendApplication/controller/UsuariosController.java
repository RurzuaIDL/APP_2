    package org.example.BackendApplication.controller;

    import org.example.BackendApplication.Security.jwt.JwtUtils;
    import org.example.BackendApplication.Security.service.UserDetailsImpl;
    import org.example.BackendApplication.models.ERole;
    import org.example.BackendApplication.models.Role;
    import org.example.BackendApplication.models.Users;
    import org.example.BackendApplication.models.dto.MessageResponse;
    import org.example.BackendApplication.models.dto.SigninResponseDto;
    import org.example.BackendApplication.repository.RoleRepository;
    import org.example.BackendApplication.service.UserService;
    import org.springframework.beans.factory.annotation.Autowired;
    import org.springframework.http.ResponseEntity;
    import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
    import org.springframework.security.core.Authentication;
    import org.springframework.security.crypto.password.PasswordEncoder;
    import org.springframework.web.bind.annotation.*;

    import java.util.List;
    import java.util.Map;
    import java.util.Objects;
    import java.util.stream.Collectors;

    @RestController
    @RequestMapping("/api/usuarios")
    public class UsuariosController {

        @Autowired
        private UserService userService;

        @Autowired
        private PasswordEncoder encoder;

        @Autowired
        private JwtUtils jwtUtils;

        @Autowired
        private RoleRepository roleRepository;



        @PostMapping("/signup")
        public ResponseEntity<?> register(@RequestBody Users user) {
            try {

                if (user.getEmail() == null || user.getPassword() == null || user.getUsername() == null) {
                    return ResponseEntity.badRequest().body(new MessageResponse("Email, username y contraseña son requeridos."));
                }


                if (userService.findByUsername(user.getUsername()).isPresent()) {
                    return ResponseEntity.badRequest().body(new MessageResponse("El nombre de usuario ya existe."));
                }

                if (userService.findByEmail(user.getEmail()).isPresent()) {
                    return ResponseEntity.badRequest().body(new MessageResponse("El correo ya está registrado."));
                }



                if (user.getRoles() != null && !user.getRoles().isEmpty()) {
                    List<Role> resolvedRoles = user.getRoles().stream()
                            .filter(r -> r.getId() != null)
                            .map(r -> roleRepository.findById(r.getId()).orElse(null))
                            .filter(Objects::nonNull)
                            .collect(Collectors.toList());
                    user.setRoles(resolvedRoles);
                } else {

                    Role defaultRole = roleRepository.findByName(ERole.USER)
                            .orElseThrow(() -> new RuntimeException("Rol no encontrado"));
                    user.setRoles(List.of(defaultRole));
                }


                user.setPassword(encoder.encode(user.getPassword()));

                Users savedUser = userService.saveUser(user);

                UserDetailsImpl userDetails = UserDetailsImpl.build(savedUser);
                Authentication authentication = new UsernamePasswordAuthenticationToken(
                        userDetails, null, userDetails.getAuthorities());
                String jwt = jwtUtils.generateJwtToken(authentication);

                SigninResponseDto response = new SigninResponseDto();
                response.setId(savedUser.getId());
                response.setEmail(savedUser.getEmail());
                response.setJwt(jwt);
                response.setRoles(savedUser.getRoles().stream()
                        .map(role -> role.getName().name())
                        .collect(Collectors.toList()));

                return ResponseEntity.ok(response);

            } catch (Exception e) {
                e.printStackTrace();
                return ResponseEntity.status(500).body(new MessageResponse("Error: No se pudo registrar al usuario"));
            }
        }


        @GetMapping("/usuarios")
        public ResponseEntity<?> obtenerUsuarios() {
            return ResponseEntity.ok(userService.obtenerTodoslosusuarios());
        }

        @PutMapping("/{username}")
        public ResponseEntity<?> updateUser(@PathVariable String username, @RequestBody Users user) {
            try {
                Users existingUser = userService.findByUsername(username).orElse(null);
                if (existingUser == null) {
                    return ResponseEntity.notFound().build();
                }

                if (user.getEmail() != null && !user.getEmail().isEmpty()) {
                    existingUser.setEmail(user.getEmail());
                }

                if (user.getPassword() != null && !user.getPassword().isEmpty()) {
                    existingUser.setPassword(encoder.encode(user.getPassword()));
                }

                if (user.getRoles() != null) {
                    resolveRoles(user);
                    existingUser.setRoles(user.getRoles());
                }

                return ResponseEntity.ok(userService.saveUser(existingUser));
            } catch (Exception e) {
                e.printStackTrace();
                return ResponseEntity.status(500).body("Error: No se pudo actualizar el usuario");
            }
        }

        @DeleteMapping("/{username}")
        public ResponseEntity<?> deleteUser(@PathVariable String username) {
            try {
                Users user = userService.findByUsername(username).orElse(null);
                if (user == null) {
                    return ResponseEntity.status(404).body("Usuario no encontrado");
                }

                userService.deleteUser(username);
                return ResponseEntity.ok("Usuario eliminado con éxito");
            } catch (Exception e) {
                e.printStackTrace();
                return ResponseEntity.status(500).body("Error: No se pudo eliminar el usuario");
            }
        }


        private void resolveRoles(Users user) {
            if (user.getRoles() != null) {
                List<Role> resolvedRoles = user.getRoles().stream()
                        .filter(r -> r.getId() != null)
                        .map(r -> roleRepository.findById(r.getId()).orElse(null))
                        .filter(Objects::nonNull)
                        .collect(Collectors.toList());
                user.setRoles(resolvedRoles);
            }
        }

        @PutMapping("/{username}/password")
        public ResponseEntity<?> actualizarPassword(
                @PathVariable String username,
                @RequestBody Map<String, String> body
        ) {
            try {
                String nuevaPassword = body.get("password");
                if (nuevaPassword == null || nuevaPassword.isBlank()) {
                    return ResponseEntity.badRequest().body("La nueva contraseña es requerida");
                }

                Users user = userService.findByUsername(username).orElse(null);
                if (user == null) {
                    return ResponseEntity.status(404).body("Usuario no encontrado");
                }

                // ✅ Hash con PasswordEncoder
                user.setPassword(encoder.encode(nuevaPassword));

                // Usa el mismo método que en signup/update para evitar incoherencias
                userService.saveUser(user);

                return ResponseEntity.ok("Contraseña actualizada con éxito");
            } catch (Exception e) {
                return ResponseEntity.status(500).body("Error al actualizar contraseña");
            }
        }


    }

