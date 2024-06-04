--- Creacion de Base de Batos ---
DROP DATABASE IF EXISTS e_commerce;
CREATE DATABASE e_commerce;

--- Creacion de Tabla Cliente ---
DROP TABLE IF EXISTS cliente;
CREATE TABLE cliente(
	id_cliente SERIAL PRIMARY KEY,
	nombre VARCHAR(30) NOT NULL,
	apellido_paterno VARCHAR(30) NOT NULL,
	apellido_materno VARCHAR(30) NULL,
	telefono CHAR(10) NOT NULL CHECK(LENGTH(telefono) = 10),
	email VARCHAR(40) NOT NULL CHECK (email ~* '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'),
	fecha_registro DATE NOT NULL DEFAULT CURRENT_DATE CHECK(fecha_registro = CURRENT_DATE)
);

---	Creacion de Tabla Proveedor ---
DROP TABLE IF EXISTS proveedor;
CREATE TABLE proveedor(
	id_proveedor SERIAL PRIMARY KEY, 
	nombre VARCHAR(30) NOT NULL UNIQUE,
	fecha_registro DATE NOT NULL DEFAULT CURRENT_DATE CHECK(fecha_registro = CURRENT_DATE)
);

---	Creacion de Tabla Producto ---
DROP TABLE IF EXISTS producto;
CREATE TABLE producto(
	id_producto SERIAL PRIMARY KEY, 
	nombre VARCHAR(30) NOT NULL UNIQUE,
	fecha_registro DATE NOT NULL DEFAULT CURRENT_DATE CHECK(fecha_registro = CURRENT_DATE)
);

--- Creacion de Tabla Proveedor-Producto ---
DROP TABLE IF EXISTS proveedor_producto;
CREATE TABLE proveedor_producto(
	id_proveedor INTEGER NOT NULL REFERENCES proveedor(id_proveedor),
	id_producto INTEGER NOT NULL REFERENCES producto(id_producto),
	PRIMARY KEY(id_proveedor, id_producto)
);

--- Creacion de Tabla Stock ---
DROP TABLE IF EXISTS stock;
CREATE TABLE stock(
	id_proveedor INTEGER NOT NULL REFERENCES proveedor(id_proveedor), 
	id_producto INTEGER NOT NULL REFERENCES producto(id_producto),
	cantidad INTEGER NOT NULL CHECK(cantidad >= 0),
	precio_producto NUMERIC(10,2) NOT NULL CHECK(precio_producto >= 0),
	fecha_ultimo_suministro DATE NOT NULL DEFAULT CURRENT_DATE 
		CHECK(fecha_ultimo_suministro = CURRENT_DATE),
	full_estado BOOLEAN NOT NULL DEFAULT FALSE 
);

--- Creacion de Tabla Estado-Compra ---
DROP TABLE IF EXISTS estado_compra;
CREATE TABLE estado_compra(
	id_estado_compra SERIAL PRIMARY KEY,
	descripcion VARCHAR(30) NOT NULL UNIQUE
);

--- Creacion de Tabla Tipo-Pago ---
DROP TABLE IF EXISTS tipo_pago;
CREATE TABLE tipo_pago(
	id_tipo_pago SERIAL PRIMARY KEY,
	descripcion VARCHAR(30) NOT NULL UNIQUE
);

--- Creacion de Tabla Orden-Compra ---
DROP TABLE IF EXISTS orden_compra;
CREATE TABLE orden_compra(
	id_orden_compra SERIAL PRIMARY KEY,
	id_cliente INTEGER NOT NULL REFERENCES cliente(id_cliente),
	fecha_compra DATE NOT NULL DEFAULT CURRENT_DATE CHECK(fecha_compra = CURRENT_DATE),
	id_estado_compra INTEGER NOT NULL REFERENCES estado_compra(id_estado_compra),
	id_tipo_pago INTEGER NOT NULL REFERENCES tipo_pago(id_tipo_pago),
	costo_total_compra NUMERIC(10,2) NOT NULL CHECK(costo_total_compra >= 0)
);

--- Creacion de Tabla Orden-Compra-Producto ---
DROP TABLE IF EXISTS orden_compra_producto;
CREATE TABLE orden_compra_producto(
	id_orden_compra INTEGER NOT NULL REFERENCES orden_compra(id_orden_compra),
	id_producto INTEGER NOT NULL REFERENCES producto(id_producto),
	id_proveedor INTEGER NOT NULL REFERENCES proveedor(id_proveedor),
	cantidad_producto INTEGER NOT NULL CHECK(cantidad_producto >= 0),
	costo_total_producto NUMERIC(10,2) NOT NULL CHECK(costo_total_producto >= 0),
	PRIMARY KEY (id_orden_compra, id_producto, id_proveedor)
);

--- Creacion de TRIGGER para validar Stock de producto ---
DROP FUNCTION IF EXISTS SP_TR_validar_stock;
CREATE OR REPLACE FUNCTION SP_TR_validar_stock() RETURNS TRIGGER
AS $$
	DECLARE
		cantidad_producto_venta INTEGER;
		stock_producto INTEGER;
	BEGIN
		cantidad_producto_venta := NEW.cantidad_producto;
		stock_producto := (SELECT cantidad FROM stock s 
							WHERE s.id_proveedor = NEW.id_proveedor AND
								  s.id_producto = NEW.id_producto);
		IF(cantidad_producto_venta > stock_producto) THEN
			RAISE EXCEPTION 'Stock insuficiente para completar la orden de compra';
			--DELETE FROM orden_compra WHERE id_orden_compra = NEW.id_orden_compra;
			ROLLBACK;
		ELSE
			UPDATE stock
			SET
				cantidad = stock_producto - cantidad_producto_venta
			WHERE 
				id_proveedor = NEW.id_proveedor
				AND
				id_producto = NEW.id_producto;
		END IF;
		RETURN NEW;
	END;
$$ LANGUAGE PLPGSQL;

DROP TRIGGER IF EXISTS TR_validar_stock ON stock;
CREATE OR REPLACE TRIGGER TR_validar_stock BEFORE INSERT ON orden_compra_producto
	FOR EACH ROW
	EXECUTE PROCEDURE SP_TR_validar_stock();

--- Creacion de TRIGGER para calcular Costos de producto y compra ---
DROP FUNCTION IF EXISTS SP_TR_calcular_costo_compra;
CREATE OR REPLACE FUNCTION SP_TR_calcular_costo_compra() RETURNS TRIGGER
AS $$
	DECLARE
		precio_producto_cal NUMERIC(10,2);
		costo_total_producto_cal NUMERIC(10,2);
		costo_total_compra_cal NUMERIC(10,2);
		
	BEGIN
		precio_producto_cal := (SELECT s.precio_producto FROM stock s
								WHERE s.id_producto = NEW.id_producto
								AND s.id_proveedor = NEW.id_proveedor);
		costo_total_producto_cal := (precio_producto_cal * NEW.cantidad_producto);
		--NEW.costo_total_producto = costo_total_producto_cal;
		
		UPDATE orden_compra_producto
			SET costo_total_producto = costo_total_producto_cal
		WHERE id_producto = NEW.id_producto
			  AND id_proveedor = NEW.id_proveedor;
		
		costo_total_compra_cal := (SELECT SUM(costo_total_producto) 
									FROM orden_compra_producto
									WHERE id_orden_compra = NEW.id_orden_compra);
		UPDATE orden_compra
		SET
			costo_total_compra = costo_total_compra_cal
		WHERE id_orden_compra = NEW.id_orden_compra;
		
		RETURN NEW;
	END;
$$ LANGUAGE PLPGSQL;

DROP TRIGGER IF EXISTS TR_calcular_costo_compra ON orden_compra_producto;
CREATE OR REPLACE TRIGGER TR_calcular_costo_compra AFTER INSERT 
	ON orden_compra_producto
FOR EACH ROW
EXECUTE PROCEDURE SP_TR_calcular_costo_compra();

--- Insert en Tabla Cliente ---
INSERT INTO cliente(nombre, apellido_paterno, apellido_materno, telefono, email,
				   	fecha_registro)
VALUES
	('claudio', 'hdz', 'cst', '1234567890', 'claudio@gmail.com', CURRENT_DATE),
	('luis', 'hdz', 'cst', '2234567890', 'luis@gmail.com', CURRENT_DATE),
	('jose', 'hdz', 'cst', '3234567890', 'jose@gmail.com', CURRENT_DATE),
	('rosa', 'cst', 'shz', '4234567890', 'rosa@gmail.com', CURRENT_DATE),
	('ignacio', 'hdz', 'ava', '5234567890', 'ignacio@gmail.com', CURRENT_DATE)
	RETURNING *;

--- Insert en Tabla Proveedor ---
INSERT INTO proveedor(nombre, fecha_registro)
VALUES
	('apple', CURRENT_DATE),
	('hp', CURRENT_DATE),
	('dell', CURRENT_DATE),
	('samsung', CURRENT_DATE),
	('telcel', CURRENT_DATE)
	RETURNING *;
	
TRUNCATE TABLE proveedor RESTART IDENTITY CASCADE;

--- Insert en Tabla Producto ---
INSERT INTO producto(nombre, fecha_registro)
VALUES
	('iphone 15 plus', CURRENT_DATE),
	('teclado mecanico', CURRENT_DATE),
	('base laptop', CURRENT_DATE),
	('smart tv 65"', CURRENT_DATE),
	('lavadora 20 kg', CURRENT_DATE),
	('s24 plus', CURRENT_DATE),
	('refrigerador 11 pies', CURRENT_DATE),
	('smart watch 5mm', CURRENT_DATE)
	RETURNING *;

--- Insert en Tabla Proveedor-Producto ---
INSERT INTO proveedor_producto(id_proveedor, id_producto)
VALUES
	(1, 1),
	(1, 8),
	(2, 2),
	(2, 3),
	(3, 2),
	(3, 3),
	(4, 4),
	(4, 5),
	(4, 6),
	(4, 7),
	(4, 8),
	(5, 1),
	(5, 6)
	RETURNING *;
	
--- Insert en Tabla Stock ---
INSERT INTO stock(id_proveedor, id_producto, cantidad, precio_producto, 
				  	fecha_ultimo_suministro, full_estado)
VALUES
	(1, 1, 20, 15000, CURRENT_DATE, TRUE),
	(1, 8, 10, 5000, CURRENT_DATE, TRUE),
	(2, 2, 15, 1500, CURRENT_DATE, TRUE),
	(2, 3, 15, 1000, CURRENT_DATE, FALSE),
	(3, 2, 20, 1700, CURRENT_DATE, TRUE),
	(3, 3, 15, 1200, CURRENT_DATE, FALSE),
	(4, 4, 25, 13000, CURRENT_DATE, TRUE),
	(4, 5, 20, 11000, CURRENT_DATE, TRUE),
	(4, 6, 25, 14000, CURRENT_DATE, FALSE),
	(4, 7, 15, 12500, CURRENT_DATE, TRUE),
	(4, 8, 30, 4500, CURRENT_DATE, FALSE),
	(5, 1, 15, 15500, CURRENT_DATE, TRUE),
	(5, 6, 20, 15500, CURRENT_DATE, TRUE)
	RETURNING *;

TRUNCATE TABLE stock RESTART IDENTITY;

--- Insert en Tabla Estado-Compra ---
INSERT INTO estado_compra(descripcion)
VALUES
	('en proceso'),
	('enviado'),
	('entregado')
	RETURNING *;
	
--- Insert en Tabla Tipo-Pago ---
INSERT INTO tipo_pago(descripcion)
VALUES
	('tarjeta credito'),
	('tarjeta debito'),
	('deposito efectivo')
	RETURNING *;
	
--- Insert en Tabla  Orden-Compra ---
INSERT INTO orden_compra(id_cliente, fecha_compra, id_estado_compra, 
						 	id_tipo_pago, costo_total_compra)
VALUES
	(1, CURRENT_DATE, 2, 2, 0),
	(1, CURRENT_DATE, 3, 1, 0),
	(2, CURRENT_DATE, 1, 1, 0),
	(3, CURRENT_DATE, 1, 3, 0),
	(4, CURRENT_DATE, 2, 3, 0),
	(5, CURRENT_DATE, 3, 2, 0)
	RETURNING *;
	
--- Insert en Tabla Orden-Compra-Producto ---
INSERT INTO orden_compra_producto(id_orden_compra, id_producto, id_proveedor,
								 	cantidad_producto, costo_total_producto)
VALUES
	(1, 1, 1, 1, 0),
	(1, 8, 1, 1, 0),
	(2, 2, 3, 1, 0),
	(2, 3, 2, 1, 0),
	(3, 5, 4, 1, 0),
	(4, 6, 4, 1, 0),
	(4, 8, 4, 1, 0),
	(5, 4, 4, 1, 0),
	(5, 5, 4, 1, 0),
	(6, 6, 5, 1, 0),
	(6, 7, 4, 1, 0)
	RETURNING *;
	
TRUNCATE TABLE orden_compra RESTART IDENTITY CASCADE

--- Consultas Select ---

--- Consultar Productos por Proveedor ---
SELECT p.id_producto, pv.id_proveedor, p.nombre "producto",  pv.nombre "proveedor"
FROM producto p INNER JOIN proveedor_producto pp
	ON p.id_producto = pp.id_producto
INNER JOIN proveedor pv
	ON pp.id_proveedor = pv.id_proveedor
	ORDER BY pv.id_proveedor, p.id_producto;
	
--- Consultar cantidad, precio... de Producto por Proveedor ---
SELECT pv.id_proveedor,pv.nombre AS "Proveedor", p.id_producto, 
	p.nombre AS "Producto", s.cantidad "Stock", s.precio_producto AS "Precio"
FROM producto p
INNER JOIN stock s
	ON p.id_producto = s.id_producto
INNER JOIN proveedor pv
	ON s.id_proveedor = pv.id_proveedor
	ORDER BY pv.id_proveedor, p.id_producto;
	
--- Consultar el Calculo de ganancia y costo por Producto-Proveedor ---
--- Ganancia es el 45% del costo total del producto y 55% valor inversion ---
SELECT pv.id_proveedor,pv.nombre AS "Proveedor", p.id_producto, 
	p.nombre AS "Producto", s.cantidad "Stock", s.precio_producto AS "Precio",
	s.cantidad * s.precio_producto "Costo total",
	TRUNC(((s.cantidad * s.precio_producto) * 45)/100, 2) "Ganancia 45%",
	TRUNC(((s.cantidad * s.precio_producto) * 55)/100, 2) "Gasto Inversion 55%"
FROM producto p
INNER JOIN stock s
	ON p.id_producto = s.id_producto
INNER JOIN proveedor pv
	ON s.id_proveedor = pv.id_proveedor
	ORDER BY pv.id_proveedor, p.id_producto;

--- Consultar Calculo de Ganancia e Inversion Total en Stock productos full ---
SELECT 
	SUM(s.cantidad * s.precio_producto) "Costo total",
	TRUNC((SUM(s.cantidad * s.precio_producto) * 45)/100, 2) "Ganancia Total 45%",
	TRUNC((SUM(s.cantidad * s.precio_producto) * 55)/100, 2) "Inversion Total 55%"
FROM producto p
INNER JOIN stock s
	ON p.id_producto = s.id_producto
INNER JOIN proveedor pv
	ON s.id_proveedor = pv.id_proveedor
	WHERE s.full_estado = true;

--- Consultar Ordenes de compra de clientes ---
SELECT c.id_cliente, 
	INITCAP(c.nombre) || ' ' || UPPER(c.apellido_paterno) || 
		' ' || UPPER(c.apellido_materno) as  "Cliente",
	c.telefono , c.email, oc.id_orden_compra , oc.costo_total_compra, oc.fecha_compra,
	ec.descripcion "Estado Compra", tp.descripcion "Tipo Pago"
FROM cliente c
INNER JOIN orden_compra oc
	ON c.id_cliente = oc.id_cliente
INNER JOIN estado_compra ec
	ON oc.id_estado_compra = ec.id_estado_compra
INNER JOIN tipo_pago tp
	ON oc.id_tipo_pago = tp.id_tipo_pago;
	
--- Agrupar Ordenes de compra por cliente y calcular compra total ---
SELECT c.id_cliente, 
	INITCAP(c.nombre) || ' ' || UPPER(c.apellido_paterno) || 
		' ' || UPPER(c.apellido_materno) as  "Cliente",
	c.telefono , c.email, COUNT(oc.id_orden_compra) "Cantidad compras", 
	SUM(oc.costo_total_compra) "Compra Total"
FROM cliente c
INNER JOIN orden_compra oc
	ON c.id_cliente = oc.id_cliente
INNER JOIN estado_compra ec
	ON oc.id_estado_compra = ec.id_estado_compra
INNER JOIN tipo_pago tp
	ON oc.id_tipo_pago = tp.id_tipo_pago
GROUP BY c.id_cliente, c.nombre, c.apellido_paterno, c.apellido_materno, 
	c.telefono, c.email
ORDER BY c.id_cliente ASC;

--- Consultar Producto-Proveedor por orden de compra de cada cliente ---
SELECT c.id_cliente, 
	INITCAP(c.nombre) "Cliente",
	oc.id_orden_compra , 
	p.nombre "Producto", pv.nombre "Proveedor", ocp.cantidad_producto, 
	ocp.costo_total_producto, oc.fecha_compra,
	ec.descripcion "Estado Compra", tp.descripcion "Tipo Pago"
FROM cliente c
INNER JOIN orden_compra oc
	ON c.id_cliente = oc.id_cliente
INNER JOIN estado_compra ec
	ON oc.id_estado_compra = ec.id_estado_compra
INNER JOIN tipo_pago tp
	ON oc.id_tipo_pago = tp.id_tipo_pago
INNER JOIN orden_compra_producto ocp
	ON oc.id_orden_compra = ocp.id_orden_compra
INNER JOIN producto p 
	ON ocp.id_producto = p.id_producto
INNER JOIN proveedor pv
	ON ocp.id_proveedor = pv.id_proveedor
ORDER BY c.id_cliente, oc.id_orden_compra;
	
--- Ventas por mes y año ---
--- Reporte de ventas de productos por orden de compra ---
SELECT oc.id_orden_compra, oc.fecha_compra, oc.costo_total_compra,
	p.id_producto, p.nombre "Producto",
	pv.id_proveedor, pv.nombre "Proveedor",
	ocp.cantidad_producto, ocp.costo_total_producto
FROM orden_compra oc
INNER JOIN orden_compra_producto ocp
	ON oc.id_orden_compra = ocp.id_orden_compra
INNER JOIN producto p
	ON ocp.id_producto = p.id_producto
INNER JOIN proveedor pv
	ON ocp.id_proveedor = pv.id_proveedor
WHERE 
	EXTRACT(YEAR FROM oc.fecha_compra) = EXTRACT(YEAR FROM CURRENT_DATE)
	AND
	EXTRACT(MONTH FROM oc.fecha_compra) = EXTRACT(MONTH FROM CURRENT_DATE)
ORDER BY oc.id_orden_compra ASC;

--- Cantidad total de ventas y su monto total en el mes actual ---
SELECT COUNT(*) "Cantidad ventas", 
	SUM(oc.costo_total_compra) "Monto Total ventas",
	CURRENT_DATE "Fecha Actual"
FROM orden_compra oc
WHERE 
	EXTRACT(YEAR FROM oc.fecha_compra) = EXTRACT(YEAR FROM CURRENT_DATE)
	AND
	EXTRACT(MONTH FROM oc.fecha_compra) = EXTRACT(MONTH FROM CURRENT_DATE);
--- los 3 clientes con mayor monto de compra ---
SELECT c.id_cliente, c.nombre "Cliente", 
	SUM(oc.costo_total_compra) "Monto Compra Total"
FROM cliente c
INNER JOIN orden_compra oc
	ON c.id_cliente = oc.id_cliente
WHERE 
	EXTRACT(YEAR FROM oc.fecha_compra) = EXTRACT(YEAR FROM CURRENT_DATE)
	AND
	EXTRACT(MONTH FROM oc.fecha_compra) = EXTRACT(MONTH FROM CURRENT_DATE)
GROUP BY c.id_cliente, c.nombre
ORDER BY SUM(oc.costo_total_compra) DESC
LIMIT 3;

--- Productos con ventas en el mes ---
SELECT p.id_producto, p.nombre "Producto", pv.id_proveedor, pv.nombre "Proveedor",
	SUM(ocp.cantidad_producto) "Cantidad Venta Producto", 
	SUM(ocp.costo_total_producto) "Monto Total Producto"
FROM orden_compra_producto ocp
INNER JOIN producto p
	ON p.id_producto = ocp.id_producto
INNER JOIN proveedor pv
	ON pv.id_proveedor = ocp.id_proveedor
INNER JOIN orden_compra oc
	ON oc.id_orden_compra = ocp.id_orden_compra
WHERE 
	EXTRACT(YEAR FROM oc.fecha_compra) = EXTRACT(YEAR FROM CURRENT_DATE)
	AND
	EXTRACT(MONTH FROM oc.fecha_compra) = EXTRACT(MONTH FROM CURRENT_DATE)
GROUP BY p.id_producto, p.nombre, pv.id_proveedor, pv.nombre;

--- Productos sin ventas en el mes ---
SELECT p.id_producto, p.nombre "Producto", COALESCE(oc.id_orden_compra::VARCHAR, 'Sin ventas'),
	pv.id_proveedor, pv.nombre "Proveedor"
FROM orden_compra_producto ocp
RIGHT JOIN proveedor_producto pp
	ON ocp.id_producto = pp.id_producto
	AND ocp.id_proveedor = pp.id_proveedor
INNER JOIN producto p
	ON p.id_producto = pp.id_producto
INNER JOIN proveedor pv
	ON pv.id_proveedor = pp.id_proveedor
LEFT JOIN orden_compra oc
	ON ocp.id_orden_compra = oc.id_orden_compra
WHERE oc.id_orden_compra IS NULL;

--- Funciones de Agregado en WHERE ---
SELECT p.id_producto , p.nombre,
	SUM(ocp.cantidad_producto) "Cantidad Producto",
	SUM(ocp.costo_total_producto) "Costo Total"
FROM PUBLIC.orden_compra_producto ocp 
INNER JOIN PUBLIC.producto p
	ON ocp.id_producto = p.id_producto
WHERE 
	p.nombre NOT LIKE '_Zxw%'
GROUP BY p.id_producto, p.nombre
HAVING 
	SUM(ocp.cantidad_producto) > 1
ORDER BY "Costo Total" DESC;

--- Union de tablas sin Join (Combinacion Implicita)---
SELECT 
	pv.id_proveedor, pv.nombre "proveedor", 
	p.id_producto, p.nombre "producto"
FROM
	PUBLIC.proveedor pv, PUBLIC.proveedor_producto pp, PUBLIC.producto p
WHERE
	pv.id_proveedor = pp.id_proveedor
	AND
	p.id_producto = pp.id_producto;
	
--- SubConsultas en Select---
SELECT 
	ocp.id_orden_compra, 
	ocp.id_producto,
	(SELECT p.nombre FROM producto p WHERE p.id_producto = ocp.id_producto)
	"Producto",
	ocp.id_proveedor,
	(SELECT pv.nombre FROM proveedor pv WHERE pv.id_proveedor = ocp.id_proveedor)
	"Proveedor",
	ocp.cantidad_producto,
	(SELECT s.precio_producto FROM stock s WHERE s.id_producto = ocp.id_producto
		AND s.id_proveedor = ocp.id_proveedor)
	"Precio",
	((SELECT s.precio_producto FROM stock s WHERE s.id_producto = ocp.id_producto
		AND s.id_proveedor = ocp.id_proveedor) * ocp.cantidad_producto)
	AS "Total",
	TRUNC(((SELECT s.precio_producto FROM stock s WHERE s.id_producto = ocp.id_producto
		AND s.id_proveedor = ocp.id_proveedor) * ocp.cantidad_producto) * 1.8 /100, 2)::MONEY
	AS "IVA"
FROM orden_compra_producto ocp


--- SubConsultas en Join---
SELECT * FROM 
(
	SELECT c.id_cliente, c.nombre "cliente",
		oc.id_orden_compra, oc.costo_total_compra
	FROM cliente c
 	INNER JOIN orden_compra oc
 		ON c.id_cliente = oc.id_cliente
) AS cliente_compra
INNER JOIN 
(
	SELECT 
		oc.id_orden_compra,
		SUM(ocp.cantidad_producto) AS "Cantidad Productos"
	FROM 
		orden_compra oc
	INNER JOIN orden_compra_producto  ocp
		ON oc.id_orden_compra = ocp.id_orden_compra
	GROUP BY oc.id_orden_compra, oc.costo_total_compra
) AS compra_productos
ON	cliente_compra.id_orden_compra =  compra_productos.id_orden_compra;

