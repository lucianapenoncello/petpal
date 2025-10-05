package com.petpal.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class PetController {

	@GetMapping("/petpal/pet/{petName}")
	public String getPet(@PathVariable String petName) {
		return "🐾 Hola, " + petName + "! Bienvenido a PetPal! 🐾";
	}
}