package org.example.BackendApplication.controller;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.*;

@RestController
@RequestMapping("/uploads")
@CrossOrigin(origins = "*")
public class FileUploadController {

    @Value("${file.uploadDir}")
    private String uploadDir;

    @PostMapping("/solicitud")
    public ResponseEntity<String> uploadFile(
            @RequestParam("file") MultipartFile file) {

        try {
            Path uploadPath = Paths.get(uploadDir);
            if (!Files.exists(uploadPath)) {
                Files.createDirectories(uploadPath);
            }

            String originalName = file.getOriginalFilename();
            if (originalName == null || originalName.trim().isEmpty()) {
                return ResponseEntity
                        .badRequest()
                        .body("Nombre de archivo inválido");
            }

            String filename = System.currentTimeMillis()
                    + "_"
                    + originalName.replaceAll("\\s+", "_");
            Path filePath = uploadPath.resolve(filename);
            Files.copy(
                    file.getInputStream(),
                    filePath,
                    StandardCopyOption.REPLACE_EXISTING
            );

            return ResponseEntity.ok(filename);

        } catch (IOException e) {
            e.printStackTrace();
            return ResponseEntity
                    .status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("❌ Error al subir el archivo: " + e.getMessage());
        }
    }
}
