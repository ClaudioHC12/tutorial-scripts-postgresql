CREATE DATABASE tymtest;

DROP DATABASE IF EXISTS tymtest;

CREATE TABLE persona(
	idPersona INT NOT NULL,
	nombre VARCHAR(20) NOT NULL,
	cedula VARCHAR(10)
);

INSERT INTO persona (idPersona, nombre, cedula)
	VALUES (1, 'Claudio', 'ASDFGHQWE');
INSERT INTO persona (idPersona, nombre, cedula)
	VALUES (2, 'luis', 'ASDFGHQWE'),
		   (3, 'jose', 'ASDFGHQWE')
		   RETURNING *;
													SELECT * FROM persona;

UPDATE persona
	SET cedula = 'a234567890',
		idPersona = 3
WHERE idPersona = 1 AND nombre = 'jose';

SELECT (p.nombre, p.cedula) AS "Datos" FROM persona AS p;
SELECT p.nombre Nombre FROM persona p;

DELETE FROM persona WHERE idPersona = 1 RETURNING *;

ALTER TABLE persona
	ADD COLUMN test VARCHAR(10) NULL;
ALTER TABLE persona
	RENAME COLUMN test TO apellido;
ALTER TABLE persona
	DROP COLUMN apellido;
ALTER TABLE persona
	ALTER COLUMN nombre TYPE VARCHAR(30);

CREATE TABLE test(
	idTest SERIAL NOT NULL PRIMARY KEY,
	nombre VARCHAR(20) NOT NULL,
	telefono VARCHAR(20) DEFAULT 'Desconocido'
);

ALTER TABLE persona 
	ADD PRIMARY KEY (idPersona);
	
												SELECT * FROM test
INSERT INTO test(nombre, telefono)
	VALUES('claudio', '123456'),
		  ('jose', 123457)
	RETURNING *;
	
DROP TABLE test;
TRUNCATE TABLE test RESTART IDENTITY;

CREATE TABLE nominas(
	pid INTEGER NOT NULL,
	nombre VARCHAR(20) NOT NULL,
	salario INTEGER NOT NULL
);
												SELECT * FROM nominas;

INSERT INTO nominas(pid, nombre, salario)
	SELECT idPersona, nombre, idPersona * 1000 FROM persona
	RETURNING *;
	
SELECT n.pid, n.nombre, n.salario, (n.salario / 7) AS Bono,
	(n.salario + (n.salario / 7) + 120) AS "Salario Final"
	FROM nominas AS  n
	ORDER BY "Salario Final" DESC, Bono ASC;
	
SELECT * FROM nominas WHERE nombre LIKE 'C%';

SELECT COUNT(*) FROM nominas n WHERE n.salario > 1500;

SELECT SUM(n.salario) FROM nominas n;

UPDATE nominas SET 
	salario = (SELECT SUM(n.salario) FROM nominas n)
	WHERE pid = 1
RETURNING *;

SELECT MIN(n.salario) FROM nominas n;

SELECT MAX(n.salario) FROM nominas n;

SELECT ((MAX(n.salario) ) - (MIN(n.salario))) AS diferencia
	FROM nominas n;

SELECT nombre, MIN(salario) FROM nominas
	GROUP BY nombre;

SELECT AVG(salario) FROM nominas;

SELECT nombre, AVG(salario) FROM nominas
	GROUP BY nombre;
	
SELECT COUNT(*), SUM(salario), nombre, salario FROM nominas 
	WHERE nombre NOT LIKE 'Z%'
	GROUP BY nombre, salario
	HAVING SUM(salario) > 2000
	ORDER BY nombre;

INSERT INTO nominas(pid, nombre, salario)
	VALUES(5, 'luis', 2000);
										SELECT * FROM nominas ORDER BY pid;

SELECT DISTINCT nombre FROM nominas;

SELECT COUNT(DISTINCT nombre) FROM nominas;

SELECT * FROM nominas 
	WHERE salario NOT BETWEEN 3000 AND 6000;

ALTER TABLE nominas ADD CONSTRAINT UQ_PId
	UNIQUE(pid);

ALTER TABLE nominas
	DROP CONSTRAINT UQ_PId;
		
CREATE TABLE empresa(
	id INTEGER NOT NULL PRIMARY KEY,
	nombre VARCHAR(30) NOT NULL
);

INSERT INTO empresa(id, nombre)
	VALUES(1, 'Telcel'),
		  (2, 'Femsa'),
		  (3, 'Oxxo');
										SELECT * FROM empresa;
ALTER TABLE nominas
	ADD COLUMN idEmpresa INTEGER NULL;

ALTER TABLE nominas 
	ADD CONSTRAINT FK_Empresa
	FOREIGN KEY (idEmpresa)
	REFERENCES empresa (id);

UPDATE nominas SET
	idEmpresa = 3
WHERE pid = 4;


---		Funciones o Procedimientos Almacenados		--
CREATE OR REPLACE  FUNCTION Suma (num1 INT, num2 INTEGER) RETURNS INTEGER
AS
$$
	SELECT num1 + num2;
$$
LANGUAGE SQL;

--Ejecutar Funcion
SELECT suma(5,3);

CREATE FUNCTION BuscarSalario(VARCHAR(20)) RETURNS INTEGER
AS
$$
	SELECT salario FROM nominas
		WHERE nombre = $1
$$
LANGUAGE SQL;

SELECT buscarsalario('Claudio');

CREATE FUNCTION InsertarEmpresa() RETURNS VOID 
AS
$$
	INSERT INTO empresa (id, nombre) VALUES (4, 'Soriana');
$$
LANGUAGE SQL;

SELECT insertarempresa();
DROP FUNCTION InsertarEmpresa;

CREATE FUNCTION buscarInfo(INT) RETURNS nominas
AS
$$
	SELECT * FROM nominas
		WHERE pid = $1;
$$
LANGUAGE SQL;

SELECT * FROM buscarInfo(1);

SELECT * FROM nominas LIMIT 3;

CREATE TABLE Log_Trigger_nominas(
	pid INTEGER NOT NULL,
	nombre VARCHAR(20) NOT NULL,
	salario INTEGER NOT NULL,
	idEmpresa INTEGER NULL
);
	
CREATE OR REPLACE FUNCTION SP_Log_nominas() RETURNS TRIGGER
AS
$$
BEGIN
	INSERT INTO Log_Trigger_nominas 
		VALUES(old.pid, old.nombre, old.salario, old.idempresa);
	RETURN NEW;
END
$$
LANGUAGE PLPGSQL;		--DROP FUNCTION SP_Log_nominas

CREATE TRIGGER TR_update_Nominas BEFORE UPDATE ON nominas
	FOR EACH ROW
	EXECUTE PROCEDURE SP_Log_nominas();
													SELECT * FROM nominas
											SELECT * FROM Log_Trigger_nominas
UPDATE nominas SET 
	nombre = 'Claudio H',
	salario = 1200
WHERE pid = 4;

CREATE TABLE Log_Trigger_empresa(
	id INTEGER NOT NULL,
	nombre VARCHAR(30) NOT NULL,
	usuario VARCHAR(30) NOT NULL,
	fecha DATE NOT NULL,
	tiempo TIME NOT NULL
);

CREATE FUNCTION SP_TR_Insert_empresa() RETURNS TRIGGER
AS
$$
DECLARE
	usuario VARCHAR(250) := USER;
	fecha DATE := current_date;
	tiempo TIME := current_time;
BEGIN
	INSERT INTO Log_Trigger_empresa
		VALUES (new.id, new.nombre, usuario, fecha, tiempo);
	RETURN NEW;
END
$$ LANGUAGE PLPGSQL;

CREATE TRIGGER TR_Insert_empresa AFTER INSERT ON empresa
FOR EACH ROW
EXECUTE PROCEDURE SP_TR_Insert_empresa();
													SELECT * FROM empresa
											SELECT * FROM Log_Trigger_empresa
INSERT INTO empresa(id, nombre)
	VALUES (5,'Visa');
	
SELECT * FROM empresa WHERE id IN(1,3);	

SELECT * FROM empresa LIMIT 2 OFFSET 3;

CREATE VIEW View_nominas_altas
	AS 
		SELECT * from nominas
		ORDER BY salario DESC
		LIMIT 5;

SELECT * FROM View_nominas_altas;


CREATE VIEW View_Union_empresa
	AS
	SELECT id, nombre, 'empresa' tabla FROM empresa
	UNION ALL
	SELECT 10, 'example', 'none'
	UNION ALL
	SELECT id ,nombre, 'Log_Trigger_empresa' FROM Log_Trigger_empresa
	ORDER BY id, tabla ASC;
	
SELECT * FROM View_Union_empresa;

SELECT * FROM nominas AS n
	INNER JOIN empresa AS e
	ON n.idempresa = e.id;

SELECT * FROM nominas n
	LEFT OUTER JOIN empresa e
	ON n.idempresa = e.id;

SELECT * FROM nominas n RIGHT OUTER JOIN empresa e 
	ON n.idempresa = e.id
	ORDER BY n.pid ASC;

SELECT * FROM nominas n
	FULL OUTER JOIN empresa e
	ON n.idempresa = e.id;

SELECT * FROM nominas n
	CROSS JOIN empresa e;
	
CREATE TABLE PersonaNew(
	nid INTEGER PRIMARY KEY,
	nombre VARCHAR(30) NOT NULL,
	apellido VARCHAR(30) NOT NULL,
	pais VARCHAR(30) NULL,
	id INTEGER NOT NULL
);
INSERT INTO personanew (nid, nombre, apellido, pais, id)
	VALUES(1, 'claudio', 'hc', 'mexico', 1),
		  (2, 'luis', 'hc', 'mexico', 2),
		  (3, 'jose', 'hc', 'usa', 3),
		  (4, 'rosa', 'cs', 'uk', 4),
		  (5, 'ignacio', 'ha', 'esp', 5)
		  RETURNING *;
		  
CREATE VIEW View_personaNew AS
	SELECT * FROM "personanew"
	WHERE pais = 'mexico'
	with check option;
	
SELECT * FROM View_personaNew;
		  
INSERT INTO View_personaNew (nid, nombre, apellido, pais, id)
	VALUES(9, 'claudio', 'hc', 'UK', 1);	
	
---------	Funciones Matematicas	--------
SELECT ABS(-34);
SELECT CBRT(27);
SELECT CEILING(3.1);
SELECT FLOOR(15.9);

SELECT POWER(4,2);
SELECT ROUND(24.48);
SELECT ROUND(24.635, 2);
SELECT SIGN(55);
SELECT SQRT(9);	
	
SELECT MOD(7,2);	
SELECT PI();
SELECT RANDOM();
SELECT TRUNC(-78.987);	
SELECT TRUNC(23.45612, 3);

-----	Funciones para manejar Cadenas	-----
SELECT CHAR_LENGTH('Hola Mundo');
SELECT UPPER('Claudio hc');
SELECT LOWER('Avion Ae');
SELECT POSITION('Mundo' IN 'HOLA Mundo');

SELECT SUBSTRING('Hello World' FROM 2 FOR 3);
SELECT TRIM('     A Q     ');
SELECT TRIM(LEADING '-' FROM '--Claudio Hc--');
SELECT TRIM(TRAILING '-' FROM '--Claudio Hc--');
SELECT TRIM(BOTH '-' FROM '--Claudio Hc--');

SELECT LTRIM('--casa chida', '-');
SELECT RTRIM('casa chida__', '_');
SELECT SUBSTR('Carro Nuevo--', 2, 3);
SELECT LPAD('Hola Mundo', 15, '-');
SELECT RPAD('Hola Mundo', 15, '-');

-----	FUNCIONES PARA FECHAS Y TIEMPO	------
SELECT CURRENT_DATE;
SELECT CURRENT_TIME;
SELECT CURRENT_TIMESTAMP;
SELECT EXTRACT(YEAR FROM CURRENT_TIMESTAMP);
SELECT EXTRACT(MONTH FROM CURRENT_TIMESTAMP);
SELECT EXTRACT(DAY FROM CURRENT_TIMESTAMP);
SELECT EXTRACT(HOUR FROM CURRENT_TIMESTAMP);

SELECT AGE('2024-12-31'::DATE, '2024-01-01'::DATE); -- Calcula la edad entre dos fechas
SELECT TO_DATE('2024-05-31', 'YYYY-MM-DD'); -- Convierte una cadena en una fecha


SELECT * FROM personanew p
	WHERE p.pais IS NOT NULL;

-----	Sequencias	-----
CREATE SEQUENCE sec_indice
START WITH 1
INCREMENT BY 20
MINVALUE 1
MAXVALUE 100
CYCLE;

SELECT * FROM sec_indice;
SELECT NEXTVAL('sec_indice');
DROP SEQUENCE sec_indice;

-------		SUBCONSULTAS	-------
CREATE TABLE precios_pais(
	id INTEGER PRIMARY KEY,
	pais VARCHAR(20) NOT NULL,
	precio VARCHAR(10) NOT NULL
);
INSERT INTO precios_pais(id, pais, precio)
	VALUES(1, 'mexico', '$23.60'),
		  (2, 'mexico', '$28.60'),
		  (3, 'usa', '$29.60'),
		  (4, 'uk', '$33.60'),
		  (5, 'esp', '$27.60');

SELECT p.id, p.nombre, p.apellido, p.pais,
	(SELECT MAX(PP.precio) 
	 	FROM precios_pais pp WHERE pp.pais = p.pais) AS "Precio"
FROM personanew p;

SELECT * FROM personanew
	WHERE pais = (SELECT pais FROM precios_pais 
				  	ORDER BY precio DESC
				  	LIMIT 1 OFFSET 1);

SELECT * FROM personanew
	WHERE pais IN (SELECT DISTINCT pais FROM precios_pais 
						WHERE precio LIKE '_2%');					

													SELECT * FROM personanew;
UPDATE personanew
	SET pais = (SELECT pais FROM precios_pais 
					ORDER BY precio ASC LIMIT 1 OFFSET 2),
		id = (SELECT id FROM precios_pais 
					ORDER BY precio ASC LIMIT 1 OFFSET 2)
WHERE pais IS NULL;

DELETE FROM personanew
	WHERE pais IN (SELECT pais FROM precios_pais WHERE pais LIKE 'zx%');
	
												SELECT * FROM precios_pais;
CREATE TABLE precios_maximos(
	pais VARCHAR(20) NOT NULL UNIQUE,
	precio VARCHAR(10) NOT NULL
);
												SELECT * FROM precios_maximos;
INSERT INTO precios_maximos(pais, precio)
SELECT pais , MAX(precio)
	FROM precios_pais
	--WHERE pais = pais
	GROUP BY pais;

SELECT id || ' : ' || pais || ' = ' || precio AS concatenado
FROM precios_pais;

----	Variables en PostgreSQL		----
DO
$$
	DECLARE
		x INT := 50;
		y INT := 500;
		z INT;
	BEGIN
		z := x * y;
		RAISE NOTICE 'El resultado es : %', z;
	END
$$;

----	CONDICIONAL IF	------
DO
$$
	BEGIN
		IF EXISTS(SELECT * FROM precios_pais WHERE pais = 'mexico') THEN
			RAISE NOTICE 'El pais fue encontrado';
			--DELETE FROM precios_pais WHERE pais = 'mexico';
		ELSE
			RAISE NOTICE 'El pais NO  fue encontrado';
		END IF;
	END
$$;

------	Ciclo WHILE 	-----
DO
$$
	DECLARE
		x INT := (SELECT COUNT(*) FROM precios_pais);
		y INT := 0;
	BEGIN
		WHILE(y < x)
		LOOP
			RAISE NOTICE '%', y;
			y := y + 1;
		END LOOP;
	END
$$;

------	CASE	-----		select * from precios_pais
SELECT p.pais, p.precio,
	CASE 
		WHEN p.pais = 'uk' THEN 'Vuelo con Escalas'
		WHEN p.pais = 'esp' THEN 'Vuelo Retrasado'
		ELSE 'Vuelo Normal'
	END AS "Tipo Viaje"
FROM precios_pais p;

-----	Cursores	--------
DO
$$
	DECLARE
		registro RECORD;
		cursor_precios CURSOR FOR SELECT * FROM precios_pais ORDER BY pais;
	BEGIN
		OPEN cursor_precios;
		FETCH cursor_precios INTO registro;
		WHILE(FOUND)
		LOOP
			RAISE NOTICE 'Id: % , Pais : % , Precio : % ',
				registro.id, registro.pais, registro.precio;
			FETCH cursor_precios INTO registro;
		END LOOP;
	END
$$ LANGUAGE PLPGSQL;

DO
$$
	DECLARE
		registro RECORD;
		cursor_precios CURSOR FOR SELECT * FROM precios_pais ORDER BY pais;
	BEGIN
		FOR registro IN cursor_precios
		LOOP
			RAISE NOTICE 'Id : % , Pais : % , Precio : % ',
				registro.id, registro.pais, registro.precio;
		END LOOP;
	END
$$ LANGUAGE PLPGSQL;

