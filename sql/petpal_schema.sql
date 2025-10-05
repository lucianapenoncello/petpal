-- PetPal - MySQL Schema and Sample Queries

-- 1) Database
CREATE DATABASE IF NOT EXISTS petpal
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;
USE petpal;

-- 2) Tables
CREATE TABLE IF NOT EXISTS users (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(80) NOT NULL,
  email VARCHAR(120) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS pets (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT NOT NULL,
  name VARCHAR(80) NOT NULL,
  species VARCHAR(40) NOT NULL,
  breed VARCHAR(60),
  birth_date DATE NULL,
  notes VARCHAR(255) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_pets_user FOREIGN KEY (user_id)
    REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS routines (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  pet_id BIGINT NOT NULL,
  activity_type ENUM('ALIMENTACION','PASEO','MEDICACION','HIGIENE','CONTROL_VETERINARIO') NOT NULL,
  frequency ENUM('DIARIA','SEMANAL','MENSUAL') NOT NULL,
  target_time TIME NOT NULL,
  valid_from DATE NOT NULL,
  valid_to DATE NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_routines_pet (pet_id),
  CONSTRAINT fk_routines_pet FOREIGN KEY (pet_id)
    REFERENCES pets(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS reminders (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  routine_id BIGINT NOT NULL,
  channel ENUM('PUSH') NOT NULL,
  minutes_before INT NOT NULL DEFAULT 60,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_reminders_routine (routine_id),
  CONSTRAINT fk_reminders_routine FOREIGN KEY (routine_id)
    REFERENCES routines(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS scheduled_tasks (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  routine_id BIGINT NOT NULL,
  scheduled_at DATETIME NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_tasks_routine_time (routine_id, scheduled_at),
  CONSTRAINT fk_tasks_routine FOREIGN KEY (routine_id)
    REFERENCES routines(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS task_logs (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  task_id BIGINT NOT NULL,
  pet_id BIGINT NOT NULL,
  status ENUM('COMPLETADA','PARCIAL','PENDIENTE') NOT NULL,
  noted_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  note VARCHAR(255) NULL,
  UNIQUE KEY uq_task_logs_task (task_id),
  KEY idx_logs_pet_date (pet_id, noted_at),
  CONSTRAINT fk_logs_task FOREIGN KEY (task_id)
    REFERENCES scheduled_tasks(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_logs_pet FOREIGN KEY (pet_id)
    REFERENCES pets(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 3) Sample data (INSERT)
INSERT INTO users (name, email, password_hash) VALUES
('Luciana', 'luciana@example.com', 'hash1'),
('Juan Pérez', 'juan@example.com', 'hash2');

INSERT INTO pets (user_id, name, species, breed, birth_date) VALUES
(1, 'Luna', 'Perro', 'Mestizo', '2020-05-10'),
(1, 'Milo', 'Gato', 'Siamés', '2022-02-14');

INSERT INTO routines (pet_id, activity_type, frequency, target_time, valid_from)
VALUES
(1, 'ALIMENTACION', 'DIARIA', '08:00:00', CURDATE()),
(1, 'PASEO', 'DIARIA', '18:30:00', CURDATE()),
(2, 'MEDICACION', 'DIARIA', '09:00:00', CURDATE());

INSERT INTO reminders (routine_id, channel, minutes_before) VALUES
(1, 'PUSH', 30),
(2, 'PUSH', 15),
(3, 'PUSH', 60);

-- Generar tareas programadas de ejemplo (manual para demo)
INSERT INTO scheduled_tasks (routine_id, scheduled_at) VALUES
(1, CONCAT(CURDATE(), ' 08:00:00')),
(2, CONCAT(CURDATE(), ' 18:30:00')),
(3, CONCAT(CURDATE(), ' 09:00:00'));

-- Registrar un log (marcar tarea completada)
INSERT INTO task_logs (task_id, pet_id, status, note) VALUES
(1, 1, 'COMPLETADA', 'Desayuno OK');

-- 4) Queries útiles (SELECT)
-- 4.1 Próximas tareas del día por usuario (unión users→pets→routines→scheduled_tasks)
SELECT u.name AS usuario, p.name AS mascota, r.activity_type, t.scheduled_at
FROM users u
JOIN pets p ON p.user_id = u.id
JOIN routines r ON r.pet_id = p.id
JOIN scheduled_tasks t ON t.routine_id = r.id
WHERE DATE(t.scheduled_at) = CURDATE()
  AND u.id = 1
ORDER BY t.scheduled_at;

-- 4.2 Historial de estados por mascota (últimos 30 días)
SELECT p.name AS mascota, r.activity_type, l.status, l.noted_at, l.note
FROM pets p
JOIN routines r ON r.pet_id = p.id
JOIN scheduled_tasks t ON t.routine_id = r.id
JOIN task_logs l ON l.task_id = t.id
WHERE p.id = 1 AND l.noted_at >= (CURDATE() - INTERVAL 30 DAY)
ORDER BY l.noted_at DESC;

-- 5) Borrado
-- Eliminar una mascota (cascada elimina rutinas, recordatorios, tareas y logs)
-- DELETE FROM pets WHERE id = 2;