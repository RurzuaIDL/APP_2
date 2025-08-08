package org.example.BackendApplication.Security.jwt;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.security.Keys;
import jakarta.servlet.http.HttpServletResponse;
import org.example.BackendApplication.Security.service.UserDetailsImpl;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;
import java.security.Key;
import java.util.Date;
import java.util.List;
import java.util.stream.Collectors;

@Component
public class JwtUtils {

    //private String jwtSecret = "tu_clave_secreta";

    private static final String SECRET = "claveSuperSecretaClaveSuperSecreta1234";
    private static final long EXPIRATION_TIME = 86400000L; // 1 día

    private final Key SECRET_KEY = Keys.hmacShaKeyFor(SECRET.getBytes(StandardCharsets.UTF_8));


    public String generateJwtToken(Authentication authentication) {
        UserDetailsImpl userPrincipal = (UserDetailsImpl) authentication.getPrincipal();

        List<String> roles = userPrincipal.getAuthorities().stream()
                .map(authority -> authority.getAuthority())
                .distinct()
                .collect(Collectors.toList());


        return Jwts.builder()
                .setSubject(userPrincipal.getUsername())
                .claim("roles", roles)
                .setIssuedAt(new Date())
                .setExpiration(new Date(System.currentTimeMillis() + EXPIRATION_TIME))
                .signWith(SECRET_KEY, SignatureAlgorithm.HS256)
                .compact();

    }



    public String getUsernameFromToken(String token) {
        return getClaims(token).getSubject();
    }


    public boolean validateJwtToken(String authToken, HttpServletResponse response) {
        try {
            Jwts.parserBuilder()
                    .setSigningKey(SECRET_KEY)
                    .build()
                    .parseClaimsJws(authToken);
            return true;
        } catch (Exception e) {
            System.out.println("❌ Token inválido: " + e.getMessage());
            return false;
        }
    }


    private Claims getClaims(String token) {
        return Jwts.parserBuilder()
                .setSigningKey(SECRET_KEY)
                .build()
                .parseClaimsJws(token)
                .getBody();
    }


    public boolean validateToken(String token) {
        try {
            Claims claims = getClaims(token);
            Date expirationDate = claims.getExpiration();
            return !expirationDate.before(new Date());
        } catch (Exception e) {
            return false;
        }
    }
}
