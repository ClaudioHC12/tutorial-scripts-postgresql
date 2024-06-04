select * from actor a;

--	Distintos registros	--
select distinct a.last_name from actor a; 
select distinct a.first_name ,a.last_name from actor a;
select distinct on (a.last_name) last_name, a.first_name  from actor a;

--	Alias de tablas y columnas 	--
select a.first_name as "Primer Nombre" from actor as a;

--	Ordenar ASC y DESC	--
select * from actor a order by a.first_name asc;

--	Clausula Where	--
select * from rental r 
	where (r.customer_id > 305 and r.customer_id <= 310) 
		or r.customer_id = 459;
select c.first_name , c.last_name  from customer c 
	where c.first_name = 'Jamie';
select c.first_name , c.last_name  from customer c 
	where c.first_name not in ('Ann', 'Anne');

--	SubConsulta	--
select * from customer c 
	where c.customer_id in (select customer_id  from customer c2 where c2.last_name = 'Ely');

--	Operador Between	--
select * from payment p 
	where p.amount between 8 and 9;

--	Operador Like	--
select c.first_name from customer c 
	where c.first_name like 'A%';
select c.first_name from customer c 
	where c.first_name like '_her%'
	order by c.first_name;

--	Operador IS NULL	--
select * from address a where a.address2 is null; 

--	Sentencia Insert	--
insert into country(country_id, country, last_update)
	values(116, 'Mexico', now());
insert into country(country_id, country, last_update)
	values(117, 'Pais 117', now()),
		  (118, 'Pais 118', now())
		   returning *;	  
--Formato de fecha yyyy-mm-dd
		  
--	Sentencia UPDATE 
update country set country = 'nuevo pais'
	where country_id = 117 returning *;

--	Sentencia DELETE  --
delete from country  
	where  country_id > 115 returning *;

select * from country  where  country_id > 115

--	Sentencia Create	--
Create DATABASE dvdrental_dev;

Create SCHEMA test;

CREATE TABLE test.customer (
	customer_id serial4 NOT NULL,
	store_id int2 NOT NULL,
	first_name varchar(45) NOT NULL,
	last_name varchar(45) NOT NULL,
	email varchar(50) NULL,
	address_id int2 NOT NULL,
	activebool bool DEFAULT true NOT NULL,
	create_date date DEFAULT 'now'::text::date NOT NULL,
	last_update timestamp DEFAULT now() NULL,
	active int4 NULL
	);

--	Restricciones CONSTRAINTS	--
create table invoices(
	id serial PRIMARY KEY,
	product_id INT NOT NULL,
	qty numeric NOT NULL CHECK(qty > 0),
	net_price numeric CHECK(net_price > 0)
);
-- opcion de agregar constraint alterando la tabla
ALTER TABLE invoices ADD PRIMARY KEY(id);
ALTER TABLE invoices ADD CONSTRAINT invoices_pk primary key(id);

-- 	Sentencia DROP	--
DROP TABLE invoices;

DROP DATABASE dvdrental_dev;

ALTER TABLE nombre_tabla DROP CONSTRAINT nombre_constraint;
