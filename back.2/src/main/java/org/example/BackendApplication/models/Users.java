    package org.example.BackendApplication.models;

    import jakarta.persistence.*;
    import java.util.List;

    @Entity
    @Table(name = "usuarios")
    public class Users {

        @Id
        @GeneratedValue(strategy = GenerationType.IDENTITY)
        private Long id;

        private String name;
        private String username;
        private String email;
        private String password;

        @ManyToMany(fetch = FetchType.LAZY)
        @JoinTable(name = "usuario_roles",
                joinColumns = @JoinColumn(name = "usuario_id"),
                inverseJoinColumns = @JoinColumn(name = "rol_id"))
        private List<Role> roles;

        public Users() {}

        public Users(String name, String username, String email, String password) {
            this.name = name;
            this.username = username;
            this.email = email;
            this.password = password;
        }


        public Long getId() {
            return id;
        }

        public String getName() {
            return name;
        }

        public void setName(String name) {
            this.name = name;
        }

        public String getUsername() {
            return username;
        }

        public void setUsername(String username) {
            this.username = username;
        }

        public String getEmail() {
            return email;
        }

        public void setEmail(String email) {
            this.email = email;
        }

        public String getPassword() {
            return password;
        }

        public void setPassword(String password) {
            this.password = password;
        }

        public List<Role> getRoles() {
            return roles;
        }

        public void setRoles(List<Role> roles) {
            this.roles = roles;
        }
    }
