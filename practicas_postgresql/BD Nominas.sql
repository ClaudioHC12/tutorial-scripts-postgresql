--- Creacion de Base de Datos ---
DROP DATABASE IF EXISTS nominas;
CREATE DATABASE nominas;

--- Creacion de Tabla Empresa ---
DROP TABLE IF EXISTS empresa;
CREATE TABLE empresa(
	id_empresa SERIAL PRIMARY KEY,
	nombre VARCHAR(30) NOT NULL UNIQUE
);

--- Creacion de Tabla Departamento ---
DROP TABLE IF EXISTS departamento;
CREATE TABLE departamento(
	id_departamento SERIAL PRIMARY KEY,
	nombre VARCHAR(30) NOT NULL UNIQUE
);

--- Creacion de Tabla Personal ---
DROP TABLE IF EXISTS personal;
CREATE TABLE personal(
	id_personal SERIAL PRIMARY KEY,
	nombre VARCHAR(30) NOT NULL,
	apellido_paterno VARCHAR(30) NOT NULL,
	apellido_materno VARCHAR(30) NOT NULL,
	telefono CHAR(10) NOT NULL CHECK(CHAR_LENGTH(telefono) = 10),
	email VARCHAR(30) NOT NULL CHECK (email ~* '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'),
	id_departamento INTEGER NOT NULL REFERENCES departamento(id_departamento),
	id_empresa INTEGER NOT NULL REFERENCES empresa(id_empresa),
	puesto VARCHAR(30) NOT NULL
);

--- Creacion de Tabla Sueldo ---
DROP TABLE IF EXISTS sueldo;
CREATE TABLE sueldo(
	id_sueldo SERIAL PRIMARY KEY,
	salario_diario DECIMAL(6,2) NOT NULL,
	id_personal INTEGER NOT NULL UNIQUE,
	FOREIGN KEY(id_personal) REFERENCES personal(id_personal)
);

--- Creacion de Tabla Bono ---
DROP TABLE IF EXISTS bono;
CREATE TABLE bono(
	id_bono SERIAL PRIMARY KEY,
	nombre VARCHAR(30) NOT NULL UNIQUE,
	porcentaje SMALLINT NOT NULL CHECK(porcentaje > 1)
);

--- Creacion de Tabla Personal-Bono
DROP TABLE IF EXISTS personal_bono;
CREATE TABLE personal_bono(
	id_personal_bono SERIAL PRIMARY KEY,
	id_personal INTEGER NOT NULL REFERENCES personal(id_personal),
	id_bono INTEGER NOT NULL REFERENCES bono(id_bono)
);

--- Creacion de Tabla Retencion ---
DROP TABLE IF EXISTS retencion;
CREATE TABLE retencion(
	id_retencion SERIAL PRIMARY KEY,
	nombre VARCHAR(30) NOT NULL UNIQUE,
	porcentaje SMALLINT NOT NULL CHECK(porcentaje > 0)
);

--- Creacion de Tabla Personal-Retencion
DROP TABLE IF EXISTS personal_retencion;
CREATE TABLE personal_retencion(
	id_personal INTEGER NOT NULL REFERENCES personal(id_personal),
	id_retencion INTEGER NOT NULL REFERENCES retencion(id_retencion),
	PRIMARY KEY (id_personal, id_retencion)
);

--- Insert en Tabla Empresa ---
INSERT INTO empresa(nombre)
	VALUES
		('google'),
		('microsoft'),
		('open ia'),
		('femsa'),
		('oxxo')
		RETURNING *;
		
--- Insert en Tabla Departamento ---
INSERT INTO departamento(nombre)
	VALUES
		('finanzas'),
		('administracion'),
		('logistica'),
		('desarrollo'),
		('operaciones')
		RETURNING *;
		
--- Insert en Tabla Personal ---
INSERT INTO personal(
	nombre, 
	apellido_paterno, 
	apellido_materno, 
	telefono, 
	email,
	id_departamento, 
	id_empresa, 
	puesto
)
VALUES
	('claudio', 'hdz', 'cst', '1234567890', 'claudio@gmail.com', 4, 1, 'programador'),
	('luis', 'hdz', 'cst', '2234567890', 'luis@gmail.com', 3, 5, 'supervisor'),
	('jose', 'hdz', 'cst', '3234567890', 'jose@gmail.com', 5, 2, 'gerente'),
	('rosa', 'cst', 'shz', '4234567890', 'rosa@gmail.com', 2, 3, 'contador'),
	('ignacio', 'hdz', 'ava', '5234567890', 'ignacio@gmail.com', 1, 4, 'lider')
	RETURNING *;
TRUNCATE TABLE personal RESTART IDENTITY CASCADE;

--- Insert en Tabla Sueldo ---
INSERT INTO sueldo(salario_diario, id_personal)
	VALUES
		(937, 1),
		(585, 2),
		(1200, 3),
		(850, 4),
		(1350, 5)
		RETURNING *;
		
--- Insert en Tabla Bono ---
INSERT INTO bono(nombre, porcentaje)
	VALUES
		('vales despensa', 10),
		('asistencia', 8),
		('adeudo', 3),
		('transporte', 6)
		RETURNING *;
		
--- Insert en Tabla Personal-Bono ---
INSERT INTO personal_bono(id_personal, id_bono)
	VALUES
		(1, 1),
		(1, 2),
		(1, 3),
		(2, 1),
		(2, 2),
		(2, 4),
		(3, 1),
		(3, 2),
		(3, 3),
		(3, 4),
		(4, 1),
		(4, 2),
		(4, 3)
		RETURNING *;

--- Insert en Tabla Retencion ---
INSERT INTO retencion(nombre, porcentaje)
	VALUES
		('isr', 7),
		('imss', 4),
		('infonavit', 15),
		('fonacot', 9)
		RETURNING *;
		
--- Insert en Tabla Personal-Retencion ---
INSERT INTO personal_retencion(id_personal, id_retencion)
	VALUES
		(1, 1),
		(1, 2),
		(2, 1),
		(2, 2),
		(2, 3),
		(3, 1),
		(3, 2),
		(4, 1),
		(4, 2),
		(4, 3),
		(5, 1),
		(5, 2),
		(5, 3),
		(5, 4)
		RETURNING *;
		
---- Consultas Select ----
SELECT 
	p.id_personal, 
	INITCAP(p.nombre) || ' ' || UPPER(p.apellido_paterno) ||
	' ' || UPPER(p.apellido_materno) "Nombre",
	p.email, p.telefono, p.puesto, p.id_departamento, d.nombre "Departamento",
	p.id_empresa, e.nombre "Empresa"
FROM personal p
INNER JOIN empresa e
	ON p.id_empresa = e.id_empresa
INNER JOIN departamento d
	ON p.id_departamento = d.id_departamento
ORDER BY p.id_personal;

SELECT 
	p.id_personal, INITCAP(p.nombre) "Nombre", p.telefono, p.puesto, 
	s.id_sueldo, s.salario_diario, e.id_empresa, e.nombre
FROM personal p
INNER JOIN sueldo s
	ON p.id_personal = s.id_personal
INNER JOIN empresa e
	ON p.id_empresa = e.id_empresa;

---  Calculo de Bonos en Personal , Bono por individual---
SELECT 
	p.id_personal, p.nombre, pb.id_personal_bono, pb.id_bono,
	b.nombre, b.porcentaje, s.salario_diario, 
	TRUNC(((((s.salario_diario * 30) * b.porcentaje)/100)/4), 2) "Cantidad Bono"
FROM personal p
INNER JOIN personal_bono pb
	ON p.id_personal = pb.id_personal
INNER JOIN bono b
	ON pb.id_bono = b.id_bono
INNER JOIN sueldo s
	ON p.id_personal = s.id_personal
ORDER BY p.id_personal ASC;

SELECT * FROM bono
	
---  Calculo de Bonos por Persona, pago semanal  ---
SELECT 
	p.id_personal, p.nombre,
	s.salario_diario, 
	TRUNC(SUM((((s.salario_diario * 30) * b.porcentaje)/100)/4), 2) "Bonos x Semana"
FROM personal p
INNER JOIN personal_bono pb
	ON p.id_personal = pb.id_personal
INNER JOIN bono b
	ON pb.id_bono = b.id_bono
INNER JOIN sueldo s
	ON p.id_personal = s.id_personal
GROUP BY p.id_personal, p.nombre, s.salario_diario
ORDER BY p.id_personal ASC;

---  Calculo de Sueldo por Persona, pago semanal  ---
SELECT 
	p.id_personal, INITCAP(p.nombre) || ' ' || UPPER(p.apellido_paterno) "Nombre",
	s.salario_diario, (s.salario_diario * 7) "Sueldo Semanal"
FROM personal p
INNER JOIN sueldo s 
	ON p.id_personal = s.id_personal;
	
---  Calculo de Retenciones en Personal , Retencion por individual---
SELECT 
	p.id_personal, p.nombre, r.id_retencion, r.nombre, r.porcentaje, s.salario_diario,
	TRUNC(((((s.salario_diario * 30) * r.porcentaje)/100)/4),2) "Cantidad Retencion"
FROM public.personal p
INNER JOIN PUBLIC.personal_retencion pr
	ON p.id_personal = pr.id_personal
INNER JOIN PUBLIC.retencion r
	ON pr.id_retencion = r.id_retencion
INNER JOIN PUBLIC.sueldo s
	ON s.id_personal = p.id_personal;

---  Calculo de Retenciones por Persona , Retenciones totales---
SELECT 
	p.id_personal, p.nombre, s.salario_diario,
	TRUNC(SUM((((s.salario_diario * 30) * r.porcentaje)/100)/4),2) "Cantidad $ Retenciones"
FROM PUBLIC.personal p
INNER JOIN PUBLIC.personal_retencion pr
	ON p.id_personal = pr.id_personal
INNER JOIN PUBLIC.retencion r
	ON pr.id_retencion = r.id_retencion
INNER JOIN PUBLIC.sueldo s
	ON s.id_personal = p.id_personal
GROUP BY p.id_personal, p.nombre, s.salario_diario
	ORDER BY p.id_personal ASC;

--- Calculo de Salario Semamal por Persona, Salario Bruto, Bonos y Retenciones --- BUG
SELECT 
	p.id_personal, p.nombre,
	s.salario_diario, 
	(s.salario_diario * 7) "Sueldo Semanal Bruto",
	TRUNC(SUM((((s.salario_diario * 30) * (pb.porcentaje))/100)/4), 2) "Bonos x Semana",
	TRUNC(SUM((((s.salario_diario * 30) * pr.porcentaje)/100)/4),2) "Cantidad $ Retenciones"
FROM personal p
LEFT JOIN 
	(SELECT pb.id_personal, SUM(b.porcentaje) AS "porcentaje"
	  FROM personal_bono pb
	 LEFT JOIN bono b
		ON pb.id_bono = b.id_bono
	 GROUP BY pb.id_personal
	 ORDER BY pb.id_personal ASC
	) AS pb ON p.id_personal = pb.id_personal
INNER JOIN sueldo s
	ON p.id_personal = s.id_personal
INNER JOIN
	(SELECT pr.id_personal, SUM(r.porcentaje) AS porcentaje
	 	FROM PUBLIC.personal_retencion pr
	 	INNER JOIN PUBLIC.retencion r
			ON pr.id_retencion = r.id_retencion
	  GROUP BY pr.id_personal
	 	ORDER BY pr.id_personal
	) AS pr ON p.id_personal = pr.id_personal
GROUP BY p.id_personal, p.nombre, s.salario_diario
	ORDER BY p.id_personal ASC;
	
--- Personas que no cuentan con bonos ---
SELECT p.id_personal, p.nombre, b.id_bono, b.nombre, b.porcentaje
FROM personal p
LEFT  JOIN personal_bono pb
	ON p.id_personal = pb.id_personal
LEFT JOIN bono b
	ON pb.id_bono = b.id_bono;

--- Calculo de Salario Semamal por Persona, Salario Libre, Salario Total ---
--		Salario libre: Salario Bruto - Retenciones
--		Salario Total: Salario libre + Bonos
SELECT 
	p.id_personal, p.nombre,
	s.salario_diario, 
	(s.salario_diario * 7) "Sueldo Semanal Bruto",
	COALESCE(TRUNC(SUM((((s.salario_diario * 30) * b.porcentaje)/100)/4), 2), 0) 
	AS "Bonos x Semana",
	TRUNC(SUM((((s.salario_diario * 30) * r.porcentaje)/100)/4),2) 
	AS "Retenciones x Semana",
	(
		(s.salario_diario * 7) - 
	 	TRUNC(SUM((((s.salario_diario * 30) * r.porcentaje)/100)/4),2)
	)
	AS "Salario Libre",
	(
		(
			(s.salario_diario * 7) - 
	 		TRUNC(SUM((((s.salario_diario * 30) * r.porcentaje)/100)/4),2)
		) + 
		COALESCE(TRUNC(SUM((((s.salario_diario * 30) * b.porcentaje)/100)/4), 2), 0)    
	)
	AS "Salario Total"
FROM personal p
LEFT JOIN
	(SELECT 
	 	pb.id_personal, SUM(b.porcentaje) AS porcentaje
	 FROM 
		personal_bono pb
 	 LEFT JOIN bono b
		ON pb.id_bono = b.id_bono
	 GROUP BY pb.id_personal
 		ORDER BY pb.id_personal ASC
	) AS b ON p.id_personal = b.id_personal
INNER JOIN sueldo s
	ON p.id_personal = s.id_personal
INNER JOIN 
	(SELECT 
	 	pr.id_personal, SUM(r.porcentaje) AS porcentaje
	 FROM 
	 	PUBLIC.personal_retencion pr
	 INNER JOIN PUBLIC.retencion r
			ON pr.id_retencion = r.id_retencion
	 GROUP BY pr.id_personal
	 	ORDER BY pr.id_personal
	) AS r ON p.id_personal = r.id_personal
GROUP BY p.id_personal, p.nombre, s.salario_diario
	ORDER BY p.id_personal ASC;
	
---	Nomenclatura Objetos DB	---
--Vistas: VIEW -> VW_productos_vencidos
--Disparadores: TRIGGER -> TR_validar_fecha_nomina
--Procedimientos A.: STORED PROCEDURE -> SP_cliente_insertar
--Funciones: FUNCTION -> FN_calcular_inventario.

------	Creacion de Tabla Nomina	------
DROP TABLE IF EXISTS nomina;
CREATE TABLE nomina(
	id_nomina SERIAL PRIMARY KEY,
	id_personal INTEGER NOT NULL,
	nombre_persona VARCHAR(75) NOT NULL,
	salario_diario NUMERIC(6,2) NOT NULL CHECK(salario_diario > 0),
	sueldo_semanal_bruto NUMERIC(6,2) NOT NULL CHECK(sueldo_semanal_bruto > 0),
	bonos_total_semana NUMERIC(6,2) NOT NULL CHECK(bonos_total_semana >= 0),
	retenciones_total_semana NUMERIC(6,2) NOT NULL CHECK(retenciones_total_semana >= 0),
	salario_libre NUMERIC(6,2) NOT NULL CHECK(salario_libre > 0),
	salario_total NUMERIC(6,2) NOT NULL CHECK(salario_total > 0),
	fecha_creacion DATE NOT NULL DEFAULT CURRENT_DATE CHECK(fecha_creacion = CURRENT_DATE)
);

-----	Creacion de SP para insertar en tabla Nomina	-----
DROP FUNCTION IF EXISTS SP_nomina_insertar;
CREATE OR REPLACE FUNCTION SP_nomina_insertar()
RETURNS SETOF nomina AS $$
	DECLARE
		
	BEGIN
		RETURN QUERY
		INSERT INTO PUBLIC.nomina(id_personal, nombre_persona, salario_diario, sueldo_semanal_bruto,
								 bonos_total_semana, retenciones_total_semana, salario_libre, 
								 salario_total, fecha_creacion)
			SELECT 
				p.id_personal, p.nombre,
				s.salario_diario, 
				(s.salario_diario * 7) "Sueldo Semanal Bruto",
				COALESCE(TRUNC(SUM((((s.salario_diario * 30) * b.porcentaje)/100)/4), 2), 0) 
				AS "Bonos x Semana",
				TRUNC(SUM((((s.salario_diario * 30) * r.porcentaje)/100)/4),2) 
				AS "Retenciones x Semana",
				(
					(s.salario_diario * 7) - 
	 				TRUNC(SUM((((s.salario_diario * 30) * r.porcentaje)/100)/4),2)
				)
				AS "Salario Libre",
				(
					(
						(s.salario_diario * 7) - 
	 					TRUNC(SUM((((s.salario_diario * 30) * r.porcentaje)/100)/4),2)
					) + 
					COALESCE(TRUNC(SUM((((s.salario_diario * 30) * b.porcentaje)/100)/4), 2), 0)    
				)
				AS "Salario Total",
				CURRENT_DATE AS fecha_creacion
			FROM personal p
			LEFT JOIN 
				(
					SELECT pb.id_personal, SUM(b.porcentaje) AS porcentaje
				 	FROM personal_bono pb
				 	LEFT JOIN bono b
				  		ON pb.id_bono = b.id_bono
					GROUP BY pb.id_personal
						ORDER BY pb.id_personal
				) AS b ON p.id_personal = b.id_personal
				INNER JOIN sueldo s
				ON p.id_personal = s.id_personal
			INNER JOIN 
			(
				SELECT 
					pr.id_personal, SUM(r.porcentaje) AS porcentaje
				FROM 
					PUBLIC.personal_retencion pr
				INNER JOIN PUBLIC.retencion r
					ON pr.id_retencion = r.id_retencion
				GROUP BY pr.id_personal
					ORDER BY pr.id_personal
			) AS r ON p.id_personal = r.id_personal
			GROUP BY p.id_personal, p.nombre, s.salario_diario
				ORDER BY p.id_personal ASC
			RETURNING *;
	END;
$$ LANGUAGE PLPGSQL; 

TRUNCATE TABLE nomina RESTART IDENTITY;
SELECT * FROM nomina;
SELECT * FROM PUBLIC.sp_nomina_insertar();

-----	Creacion de CURSOR para insertar en tabla Nomina	-----
DROP FUNCTION IF EXISTS SP_nomina_cursor_registrar;
CREATE OR REPLACE FUNCTION SP_nomina_cursor_registrar()
RETURNS SETOF nomina AS $$
	DECLARE 
		registro RECORD;
		cursor_persona CURSOR FOR SELECT * FROM PUBLIC.personal;
		
		salario_diario_cal NUMERIC(6,2);
		sueldo_bruto_cal NUMERIC(6,2);
		bonos_total_cal NUMERIC(6,2);
		retenciones_total_cal NUMERIC(6,2);
		salario_libre_cal NUMERIC(6,2);
		salario_total_cal NUMERIC(6,2);
	BEGIN
		FOR registro IN cursor_persona
		LOOP
			salario_diario_cal := (SELECT s.salario_diario FROM PUBLIC.sueldo s 
									WHERE s.id_personal = registro.id_personal);
			
			sueldo_bruto_cal := salario_diario_cal * 7;
			bonos_total_cal := (SELECT 
									COALESCE(TRUNC(SUM((((salario_diario_cal * 30) * b.porcentaje)/100)/4), 2), 0) 
									AS "Bonos x Semana" 
								FROM personal_bono pb INNER JOIN bono b 
									ON pb.id_bono = b.id_bono
								WHERE pb.id_personal = registro.id_personal);
			retenciones_total_cal := (SELECT 
										COALESCE(TRUNC(SUM((((salario_diario_cal * 30) * r.porcentaje)/100)/4), 2), 0) 
										AS "retenciones x Semana" 
										FROM personal_retencion pr INNER JOIN retencion r 
											ON pr.id_retencion = r.id_retencion
										WHERE pr.id_personal = registro.id_personal);
			salario_libre_cal := (sueldo_bruto_cal - retenciones_total_cal);
			salario_total_cal := (salario_libre_cal + bonos_total_cal);
			
			INSERT INTO nomina(id_personal, nombre_persona, salario_diario, sueldo_semanal_bruto,
							  	bonos_total_semana, retenciones_total_semana, salario_libre,
							  	salario_total, fecha_creacion
							  )
			VALUES
				(registro.id_personal, registro.nombre, salario_diario_cal, sueldo_bruto_cal,
					bonos_total_cal, retenciones_total_cal, salario_libre_cal, salario_total_cal,
					CURRENT_DATE
				);
		END LOOP;
		
		RETURN QUERY 
		SELECT * FROM nomina n WHERE n.fecha_creacion = CURRENT_DATE 
			ORDER BY n.id_personal ASC; 
	END;
$$ LANGUAGE PLPGSQL;

SELECT * FROM PUBLIC.sp_nomina_cursor_registrar();

---	Creacion de Funcion para retornar dia actual	---
DROP FUNCTION IF EXISTS FN_get_dia_actual;
CREATE OR REPLACE FUNCTION FN_get_dia_actual()
RETURNS VARCHAR AS $$
	DECLARE 
		dia_actual VARCHAR;
	BEGIN
		CASE EXTRACT(DOW FROM CURRENT_DATE)
        	WHEN 0 THEN dia_actual := 'Domingo';
        	WHEN 1 THEN dia_actual := 'Lunes';
        	WHEN 2 THEN dia_actual := 'Martes';
        	WHEN 3 THEN dia_actual := 'Miércoles';
        	WHEN 4 THEN dia_actual := 'Jueves';
        	WHEN 5 THEN dia_actual := 'Viernes';
        	WHEN 6 THEN dia_actual := 'Sábado';
    		END CASE;
		RETURN dia_actual;
	END;
$$ LANGUAGE PLPGSQL;

SELECT PUBLIC.FN_get_dia_actual();

--- Creacion de Trigger para validar registros de nominas ---
DROP FUNCTION IF EXISTS SP_TR_nomina_validar_fecha;
CREATE OR REPLACE FUNCTION SP_TR_nomina_validar_fecha()
RETURNS TRIGGER AS $$
	DECLARE
		dia_actual VARCHAR;
		fecha_ultima_creacion DATE;
		diferencia_dias SMALLINT;
	BEGIN 
		dia_actual := (SELECT PUBLIC.FN_get_dia_actual());
		fecha_ultima_creacion := (SELECT MAX(fecha_creacion) FROM nomina 
								  	WHERE id_personal = NEW.id_personal);
		IF NOT (fecha_ultima_creacion IS NULL)THEN
			--diferencia_dias := (CURRENT_DATE - fecha_ultima_creacion);
			diferencia_dias := EXTRACT(DAY FROM CURRENT_DATE - fecha_ultima_creacion);
			IF NOT ((dia_actual = 'Jueves' OR  dia_actual = 'Viernes' 
			   	OR dia_actual = 'Sábado') AND (diferencia_dias >= 5)) THEN
					RAISE EXCEPTION 'No es posible registrar la nomina por calculos de fechas.';
					ROLLBACK;
			END IF;
		END IF;
		
		RETURN NEW;
	END;
$$ LANGUAGE PLPGSQL;

DROP TRIGGER IF EXISTS TR_nomina_validar_fecha ON nomina;
CREATE OR REPLACE TRIGGER TR_nomina_validar_fecha BEFORE INSERT ON nomina
FOR EACH ROW
EXECUTE PROCEDURE SP_TR_nomina_validar_fecha();


SELECT * FROM nomina
SELECT ('2024-05-16'::DATE - '2024-05-11'::DATE)

