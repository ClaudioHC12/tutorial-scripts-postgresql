--	Creacion de BD	--
DROP DATABASE IF EXISTS hotel;
CREATE DATABASE hotel;

--	Creacion de tabla Clientes	--
DROP TABLE IF EXISTS clientes;
CREATE TABLE clientes(
	id SERIAL PRIMARY KEY,
	nombre VARCHAR(30) NOT NULL,
	apellido_paterno VARCHAR(30) NOT NULL,
	apellido_materno VARCHAR(30) NULL,
	telefono CHAR(10) NOT NULL CHECK(LENGTH(telefono) = 10),
	email VARCHAR(40) NOT NULL CHECK(CHAR_LENGTH(email) >= 5),
	pais VARCHAR(30) NULL DEFAULT 'desconocido'
);

--	Creacion de tabla Credito Cliente	--
DROP TABLE IF EXISTS credito_cliente;
CREATE TABLE credito_cliente(
	id SERIAL PRIMARY KEY,
	id_cliente INTEGER NOT NULL,
	cantidad DECIMAL(6,2) NOT NULL CHECK(cantidad >= 0),
	fecha DATE NOT NULL DEFAULT CURRENT_DATE CHECK(fecha = CURRENT_DATE),
	FOREIGN KEY (id_cliente) REFERENCES clientes(id)
);

--	Creacion de tabla Tipo de Habitacion	--
DROP TABLE IF EXISTS tipo_habitacion;
CREATE TABLE tipo_habitacion(
	id SERIAL PRIMARY KEY,
	descripcion VARCHAR(30) NOT NULL UNIQUE
);

--	Creacion de tabla Habitaciones	--
DROP TABLE IF EXISTS habitaciones;
CREATE TABLE habitaciones(
	id SERIAL PRIMARY KEY,
	id_tipo_habitacion INTEGER NOT NULL,
	cantidad_personas SMALLINT NOT NULL CHECK(cantidad_personas > 0),
	costo_dia NUMERIC(6,2) NOT NULL CHECK(costo_dia > 0),
	FOREIGN KEY (id_tipo_habitacion) REFERENCES tipo_habitacion(id)
);

--	Creacion de tabla Forma de Pago	--
DROP TABLE IF EXISTS forma_pago;
CREATE TABLE forma_pago(
	id SERIAL PRIMARY KEY,
	descripcion VARCHAR(30) NOT NULL UNIQUE
);

--	Creacion de tabla Tipo de Factura	--
DROP TABLE IF EXISTS tipo_factura;
CREATE TABLE tipo_factura(
	id SERIAL PRIMARY KEY,
	descripcion VARCHAR(30) NOT NULL UNIQUE
);

--	Creacion de tabla Reservaciones	--
DROP TABLE IF EXISTS reservaciones;
CREATE TABLE reservaciones(
	id SERIAL PRIMARY KEY,
	id_cliente INTEGER NOT NULL,
	id_habitacion INTEGER NOT NULL,
	cantidad_dias SMALLINT NOT NULL CHECK(cantidad_dias > 0),
	fecha_reservacion DATE NOT NULL 
		DEFAULT CURRENT_DATE CHECK(fecha_reservacion >= CURRENT_DATE),
	costo_total DECIMAL(6,2) NOT NULL CHECK(costo_total >= 0),
	id_forma_pago INTEGER NOT NULL,
	id_tipo_factura INTEGER NOT NULL,
	FOREIGN KEY (id_cliente) REFERENCES clientes(id),
	FOREIGN KEY (id_habitacion) REFERENCES habitaciones(id),
	FOREIGN KEY (id_forma_pago) REFERENCES forma_pago(id),
	FOREIGN KEY (id_tipo_factura) REFERENCES tipo_factura(id)
);

--	Creacion de TRIGGER para registrar Reservaciones
CREATE OR REPLACE FUNCTION SP_TR_registrar_reservaciones() RETURNS TRIGGER
AS
$$
DECLARE
	costo_final DECIMAL(6,2);
	cantidad_dias INTEGER;
	costo_dia_habitacion INTEGER;
	cantidad_credito DECIMAL(6,2);
BEGIN
	cantidad_dias := NEW.cantidad_dias;
	costo_dia_habitacion := (SELECT costo_dia FROM habitaciones 
								WHERE id = NEW.id_habitacion);
	costo_final := (cantidad_dias * costo_dia_habitacion);
	cantidad_credito := (SELECT cantidad FROM credito_cliente
							WHERE id_cliente = NEW.id_cliente);
	
	IF(cantidad_credito >= costo_final) THEN
		UPDATE credito_cliente
			SET cantidad = cantidad_credito - costo_final
		WHERE id_cliente = NEW.id_cliente; 
		
		NEW.costo_total = costo_final;
			
		--COMMIT;
	ELSE
		RAISE EXCEPTION 'El crédito del cliente no es suficiente para 
			cubrir el costo total de la reservación.';
		ROLLBACK;
	END IF;
	
	RETURN NEW;
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE TRIGGER TR_registrar_reservaciones BEFORE INSERT ON reservaciones
	FOR EACH ROW
	EXECUTE PROCEDURE SP_TR_registrar_reservaciones();
	
--	INSERT Tabla Clientes	--
INSERT INTO clientes
	(nombre, apellido_paterno, apellido_materno, telefono, email, pais)
	VALUES
		('claudio', 'hdz', 'cst', '1234567890', 'claudio@gmail.com', 'mx'),
		('luis', 'hdz', 'cst', '2234567890', 'luis@gmail.com', 'mx'),
		('jose', 'hdz', 'cst', '3234567890', 'jose@gmail.com', 'mx'),
		('rosa', 'cst', 'shn', '4234567890', 'rosa@gmail.com', 'mx'),
		('ignacio', 'hdz', 'ava', '5234567890', 'ign@gmail.com', 'mx')
		RETURNING *;
SELECT * FROM clientes;
		
--	INSERT Tabla Credito Cliente	--
INSERT INTO credito_cliente(id_cliente, cantidad, fecha)
	VALUES
		(1, 2500, '2024-05-07'),
		(2, 3000, '2024-05-07'),
		(3, 3500, '2024-05-07'),
		(4, 4000, '2024-05-07')
		RETURNING *;
TRUNCATE TABLE credito_cliente RESTART IDENTITY;
SELECT * FROM credito_cliente;

--	INSERT Tabla Tipo de Habitacion	--
INSERT INTO tipo_habitacion(descripcion)
	VALUES
	('sencilla'),
	('doble'),
	('premium')
	RETURNING *;
SELECT * FROM tipo_habitacion;

--	INSERT Tabla Habitaciones	--
INSERT INTO habitaciones(id_tipo_habitacion, cantidad_personas, costo_dia)
	VALUES
		(1, 2, 650),
		(1, 2, 650),
		(1, 3, 750),
		(1, 3, 750),
		(2, 4, 850),
		(2, 4, 850),
		(3, 5, 950),
		(3, 5, 950),
		(3, 6, 1100)
		RETURNING *;
SELECT * FROM habitaciones;

--	INSERT Tabla Forma de Pago	--
INSERT INTO forma_pago(descripcion)
	VALUES
		('tarjeta de credito'),
		('tarjeta de debito'),
		('efectivo')
		RETURNING *;
SELECT * FROM forma_pago;

--	INSERT Tabla Tipo Factura	--
INSERT INTO tipo_factura(descripcion)
	VALUES
		('electronica'),
		('impresa'),
		('electronica e impresa')
		RETURNING *;
SELECT * FROM tipo_factura;

--	INSERT Tabla Reservaciones	--
INSERT INTO reservaciones
	(id_cliente, id_habitacion, cantidad_dias, fecha_reservacion,
		costo_total, id_forma_pago,id_tipo_factura)
	VALUES
	(1, 1, 2, '2024-05-07', 12, 1, 1),
	(2, 3, 2, '2024-05-07', 12, 1, 2),
	(3, 9, 2, '2024-05-07', 12, 1, 3)
	RETURNING *;
----	Consultas para Pruebas	----
SELECT * FROM reservaciones;
SELECT * FROM credito_cliente;
TRUNCATE TABLE reservaciones RESTART IDENTITY;
UPDATE credito_cliente SET cantidad = 2500 WHERE id_cliente = 1 RETURNING *;

------		JOIN's		--------
SELECT c.id "ID Cliente", 
	INITCAP(c.nombre) || ' ' || UPPER(c.apellido_paterno) || ' ' || 
	UPPER(c.apellido_materno) "Nombre Cliente", cc.cantidad "Cantidad", 
	cc.fecha "Fecha Registro"
FROM clientes c
INNER JOIN credito_cliente cc
ON cc.id_cliente = c.id
	ORDER BY c.id ASC;

SELECT h.id "ID Habitacion", h.cantidad_personas "Cantidad Personas",
	   h.costo_dia "Costo Dia", th.id "ID Tipo Habitacion",
	   th.descripcion "Descripcion"
FROM habitaciones h
INNER JOIN tipo_habitacion th
ON h.id_tipo_habitacion = th.id
ORDER BY h.id ASC;

SELECT r.id , r.id_cliente, r.id_habitacion, r.cantidad_dias, r.fecha_reservacion,
	   r.costo_total, fp.descripcion "Forma Pago", tf.descripcion "Tipo Factura"
FROM reservaciones r
INNER JOIN forma_pago fp
ON r.id_forma_pago = fp.id
INNER JOIN tipo_factura tf
ON r.id_tipo_factura = tf.id;

SELECT r.id "ID Res.", r.id_cliente "ID Cliente",c.nombre "Cliente", 
	   cc.cantidad "Credito", r.id_habitacion, 
	   (th.descripcion || ' ' || h.cantidad_personas) "Cant. Personas",
	   h.costo_dia "Costo Dia", r.cantidad_dias, r.fecha_reservacion, 
	   r.costo_total, fp.descripcion "Forma Pago", 
	   tf.descripcion "Tipo Factura"
FROM reservaciones r
INNER JOIN forma_pago fp
	ON r.id_forma_pago = fp.id
INNER JOIN tipo_factura tf
	ON r.id_tipo_factura = tf.id
INNER JOIN clientes c
	ON r.id_cliente = c.id
INNER JOIN credito_cliente cc
	ON c.id = cc.id_cliente
INNER JOIN habitaciones h
	ON r.id_habitacion = h.id
INNER JOIN tipo_habitacion th
	ON h.id_tipo_habitacion = th.id;
	
--- Calcular Credito Inicial del Cliente ---
SELECT c.id "ID Cliente", c.nombre "Cliente", 
	SUM(r.costo_total) "Total de Reservaciones",
	cc.cantidad "Credito Disponible",
	(SUM(r.costo_total) + cc.cantidad) "Credito Inicial" 
FROM clientes c
INNER JOIN credito_cliente cc
	ON c.id = cc.id_cliente
INNER JOIN reservaciones r
	ON c.id = r.id_cliente
GROUP BY c.id, c.nombre, cc.cantidad
	ORDER BY c.id;
	
--	Clientes sin Reservaciones	--
SELECT c.id "Id Cliente", c.nombre "Cliente", COUNT(r.id) "Cantidad"
FROM clientes c
LEFT JOIN reservaciones r
	ON r.id_cliente = c.id
GROUP BY c.id, c.nombre
	ORDER BY c.id ASC;
	
--	Insertar Credito y Reservaciones	--
INSERT INTO credito_cliente(id_cliente, cantidad, fecha)
	VALUES (5, 5000, '2024-05-08')
	RETURNING *;
	
INSERT INTO reservaciones
	(id_cliente, id_habitacion, cantidad_dias, fecha_reservacion,
		costo_total, id_forma_pago,id_tipo_factura)
	VALUES 
		(5, 8, 1, '2024-05-08', 12, 1, 3),
		(5, 9, 2, '2024-05-12', 12, 1, 3)
	RETURNING *;

---	Calcular diferencia entre fecha reservacion y fecha actual	---
SELECT r.id "Id Reservacion", r.fecha_reservacion, CURRENT_DATE ,
	AGE(r.fecha_reservacion, CURRENT_DATE) "Diferencia"
FROM reservaciones r;

SELECT r.id "Id Reservacion", r.fecha_reservacion, CURRENT_DATE ,
	(r.fecha_reservacion - CURRENT_DATE) "Diferencia de dias",
	CASE
		WHEN (r.fecha_reservacion - CURRENT_DATE) > 0 
			THEN 'Faltan: ' || ABS(r.fecha_reservacion - CURRENT_DATE) || ' dias'
		WHEN (r.fecha_reservacion - CURRENT_DATE) < 0 
			THEN 'Pasaron: ' || ABS(r.fecha_reservacion - CURRENT_DATE) || ' dias'
		ELSE
			'Actual'
	END "Determinacion dias"
FROM reservaciones r;

---	Reporte de Ingresos totales del Mes ---

---	Cantidad total de ingresos en las reservaciones del mes actual ---
SELECT SUM(r.costo_total) "Ingresos Totales", CURRENT_DATE "Fecha Actual",
	EXTRACT(YEAR FROM CURRENT_DATE) "Año",
	EXTRACT(MONTH FROM CURRENT_DATE) "Mes"
FROM reservaciones r 
	WHERE 
		EXTRACT(YEAR FROM r.fecha_reservacion) = EXTRACT(YEAR FROM CURRENT_DATE)
		AND
		EXTRACT(MONTH FROM r.fecha_reservacion) = EXTRACT(MONTH FROM CURRENT_DATE);

--- Cantidad de Clientes en el mes actual ---
SELECT COUNT(DISTINCT(r.id_cliente)) "Total de Clientes",
	EXTRACT(YEAR FROM CURRENT_DATE) "Año",
	EXTRACT(MONTH FROM CURRENT_DATE) "Mes"
FROM reservaciones r
WHERE 
	EXTRACT(YEAR FROM r.fecha_reservacion) = EXTRACT(YEAR FROM CURRENT_DATE)
	AND
	EXTRACT(MONTH FROM r.fecha_reservacion) = EXTRACT(MONTH FROM CURRENT_DATE);

---	Habitaciones que se reservaron en el mes ---
SELECT COUNT(r.id_habitacion) "Cantidad de Reservaciones",
	r.id_habitacion, th.descripcion || ' ' || h.cantidad_personas "Tipo Habitacion",
	h.costo_dia, (COUNT(r.id_habitacion) * h.costo_dia) "Total x Habitacion"
FROM reservaciones r
INNER JOIN habitaciones h
	ON r.id_habitacion = h.id
INNER JOIN tipo_habitacion th
	ON h.id_tipo_habitacion = th.id
GROUP BY r.id_habitacion, th.descripcion, 
	h.cantidad_personas, h.costo_dia
ORDER BY r.id_habitacion ASC;

select '2024-05-07'::DATE - '2024-04-01'::DATE