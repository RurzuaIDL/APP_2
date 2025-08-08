package org.example.BackendApplication.models.dto;

public class SigninDto {
    private String username;
    private String password;

    public String getUsername() {
        return username;
    }

    public void setEmail(String email) {
        this.username = email;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }
}
