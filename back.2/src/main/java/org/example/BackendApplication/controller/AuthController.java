package org.example.BackendApplication.controller;

import org.example.BackendApplication.Security.jwt.JwtUtils;
import org.example.BackendApplication.Security.service.UserDetailsImpl;
import org.example.BackendApplication.models.Users;
import org.example.BackendApplication.models.dto.MessageResponse;
import org.example.BackendApplication.models.dto.SigninDto;
import org.example.BackendApplication.models.dto.SigninResponseDto;

import org.example.BackendApplication.repository.RoleRepository;
import org.example.BackendApplication.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/auth")
@CrossOrigin(origins = "*")
public class AuthController {

    @Autowired
    private UserService userService;

   //@Autowired
   // private Role roleService;

    @Autowired
    private PasswordEncoder encoder;

    @Autowired
    private AuthenticationManager authenticationManager;

    @Autowired
    private JwtUtils jwtUtils;

    @Autowired
    private RoleRepository roleRepository;


    @PostMapping("/signin")
    public ResponseEntity<?> signin(@RequestBody SigninDto signinDto) {
        try {
            Authentication authentication = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(
                            signinDto.getUsername(),
                            signinDto.getPassword()
                    )
            );

            SecurityContextHolder.getContext().setAuthentication(authentication);
            UserDetailsImpl userDetails = (UserDetailsImpl) authentication.getPrincipal();

            String jwt = jwtUtils.generateJwtToken(authentication);



            Users user = userService.findByUsername(signinDto.getUsername())
                    .orElseThrow(() -> new RuntimeException("Usuario no encontrado por email"));

            List<String> roles = userDetails.getAuthorities().stream()
                    .map(GrantedAuthority::getAuthority)
                    .collect(Collectors.toList());

            SigninResponseDto res = new SigninResponseDto();
            res.setId(user.getId());
            res.setEmail(user.getEmail());
            res.setJwt(jwt);
            res.setRoles(roles);

            return ResponseEntity.ok(res);

        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(403)
                    .body(new MessageResponse("Error: Credenciales incorrectas"));
        }
    }


    @GetMapping
    public ResponseEntity<List<Users>> getAllUsers(@RequestHeader("Authorization") String authorization) {

        if (authorization != null && authorization.startsWith("Bearer ")) {
            String token = authorization.substring(7);

            if (jwtUtils.validateToken(token)) {
                List<Users> users = userService.obtenerTodoslosusuarios();
                return ResponseEntity.ok(users);
            } else {
                return ResponseEntity.status(403).body(null);
            }
        } else {
            return ResponseEntity.status(401).body(null); 
        }
    }
}
