package org.example.BackendApplication.service;

import org.example.BackendApplication.models.Users;
import org.example.BackendApplication.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class UserService {

    @Autowired
    private UserRepository userRepository;




    public Optional<Users> findByEmail(String email) {
        return userRepository.findByEmail(email);
    }

    public Optional<Users> findByUsername(String username) {
        return userRepository.findByUsername(username);
    }

    public Users saveUser(Users user) {
        return userRepository.save(user);
    }


    public void deleteUser(String username) {
        try {

            Users existingUser = userRepository.findByUsername(username)
                    .orElseThrow(() -> new RuntimeException("Usuario no encontrado con username: " + username));
            userRepository.delete(existingUser);

        } catch (Exception e) {
            throw new RuntimeException("Error al eliminar el usuario", e);
        }
    }

    public List<Users> obtenerTodoslosusuarios() {
        return userRepository.findAll();
    }

    public Users save(Users user) {
        return userRepository.save(user);
    }

}

