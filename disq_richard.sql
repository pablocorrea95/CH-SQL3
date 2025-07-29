CREATE SCHEMA IF NOT EXISTS disq_richard;
USE disq_richard;

---## Tablas ##---

CREATE TABLE categoria (
  id_categoria   INT AUTO_INCREMENT PRIMARY KEY,
  nombre         VARCHAR(50) NOT NULL,
  descripcion    VARCHAR(255) NULL
);


CREATE TABLE item (
  id_item INT AUTO_INCREMENT PRIMARY KEY,
  nombre 			VARCHAR(100) NOT NULL,
  marca 			VARCHAR(50) NOT NULL,
  tipo 				VARCHAR(50) NOT NULL,
  id_categoria 		INT NOT NULL,
  precio_unitario 	DECIMAL(10,2) NOT NULL,
  stock 			INT NULL,
  FOREIGN KEY (id_categoria) REFERENCES categoria(id_categoria)
);


CREATE TABLE cliente (
  id_cliente     INT AUTO_INCREMENT PRIMARY KEY,
  nombre         VARCHAR(50) NOT NULL,
  apellido       VARCHAR(50) NOT NULL,
  email          VARCHAR(100) NULL,
  telefono       VARCHAR(20)  NULL,
  direccion      VARCHAR(150) NULL
);


CREATE TABLE venta (
  id_venta       INT AUTO_INCREMENT PRIMARY KEY,
  fecha_venta    DATETIME NOT NULL,
  id_cliente     INT NOT NULL,
  total          DECIMAL(12,2) NOT NULL,
  FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente)
);


CREATE TABLE venta_item (
  id_venta_item  INT AUTO_INCREMENT PRIMARY KEY,
  id_venta       INT NOT NULL,
  id_item        INT NOT NULL,
  cantidad       INT NOT NULL,
  precio_unit    DECIMAL(10,2) NOT NULL,
  FOREIGN KEY (id_venta) REFERENCES venta(id_venta),
  FOREIGN KEY (id_item)  REFERENCES item(id_item)
);


## Inserts ##

INSERT INTO categoria (nombre) VALUES
('Instrumentos'),
('Electrodomésticos'),
('Relojería');


INSERT INTO item (nombre, marca, tipo, id_categoria, precio_unitario, stock) VALUES
('Guitarra Criolla', 'Luthier', 'PRODUCTO', 1, 7500.00,  5),
('Parlante', 'Sony', 'PRODUCTO', 1, 1200.00, 10),
('Licuadora', 'Oster', 'PRODUCTO', 2, 3500.00,  3),
('Reloj de Pared Vintage', 'Casio', 'PRODUCTO', 3, 1800.00,  7),
('Reloj Pulsera Clásico', 'Casio', 'PRODUCTO', 3, 2200.00, 15),
('Reparación Reloj', '', 'SERVICIO', 3,  500.00, NULL),
('Reparación Reloj', '', 'SERVICIO', 3,  700.00, NULL);


INSERT INTO cliente (nombre, apellido, email, telefono, direccion) VALUES
('Ana',   'López',    'ana.lopez@mail.com',    '011-1111-2222', 'Calle Falsa 123'),
('Juan',  'Martínez', 'juan.martinez@mail.com','011-3333-4444', 'Av. Siempre Viva 5'),
('María', 'García',   'maria.garcia@mail.com', '011-5555-6666', 'Pasaje 9 #89');


INSERT INTO venta (fecha_venta, id_cliente, total) VALUES
('2025-07-01 10:15:00', 1,  8700.00),
('2025-07-05 16:30:00', 2,  3500.00),
('2025-07-10 12:00:00', 3,  4050.00);


INSERT INTO venta_item (id_venta, id_item, cantidad, precio_unit) VALUES
(1, 1, 1, 7500.00),   -- guitarra
(2, 3, 1, 3500.00),   -- licuadora
(3, 5, 1, 2200.00),   -- reloj pulsera
(3, 4, 1, 1800.00),   -- reloj pared


## Tablas: item, categoria
CREATE VIEW vista_items_completa AS
SELECT
  i.id_item,
  i.nombre,
  i.marca,
  i.tipo,
  c.nombre
  AS categoria,
  i.precio_unitario,
  i.stock
FROM item i
JOIN categoria c ON i.id_categoria = c.id_categoria;

## Objetivo: Mostrar productos (no servicios) con stock <= 5.
CREATE VIEW vista_stock_bajo AS
SELECT id_item, nombre, marca, stock
FROM item
WHERE tipo = 'PRODUCTO'
  AND stock <= 5;

/* VISTA 3: vista_servicios_ofrecidos
   Objetivo: Listar todos los servicios con su precio.
   Tablas: item */
CREATE VIEW vista_servicios_ofrecidos AS
SELECT id_item, nombre, precio_unitario AS precio
FROM item
WHERE tipo = 'SERVICIO';

/* VISTA 4: vista_ventas_detalladas
   Objetivo: Listar cada venta con cliente, total y descripción de ítems vendidos.
   Tablas: venta, cliente, venta_item, item */
CREATE VIEW vista_ventas_detalladas AS
SELECT
  v.id_venta,
  v.fecha_venta,
  CONCAT(cl.nombre,' ',cl.apellido) AS cliente,
  v.total,
  GROUP_CONCAT(CONCAT(vi.cantidad,'×',it.nombre) SEPARATOR '; ') AS items
FROM venta v
JOIN cliente cl ON v.id_cliente = cl.id_cliente
JOIN venta_item vi ON v.id_venta = vi.id_venta
JOIN item it ON vi.id_item = it.id_item
GROUP BY v.id_venta, v.fecha_venta, cl.nombre, cl.apellido, v.total;

/* VISTA 5: vista_ingresos_por_cliente
   Objetivo: Mostrar el total gastado por cada cliente.
   Tablas: cliente, venta */
CREATE VIEW vista_ingresos_por_cliente AS
SELECT
  cl.id_cliente,
  CONCAT(cl.nombre,' ',cl.apellido) AS cliente,
  SUM(v.total) AS total_gastado
FROM cliente cl
LEFT JOIN venta v ON cl.id_cliente = v.id_cliente
GROUP BY cl.id_cliente;

--------------------------------------------------------------------------------
-- 5. FUNCIONES (2)
--------------------------------------------------------------------------------

DELIMITER //

/* FUNCIÓN 1: fn_total_gastado_cliente
   Objetivo: Calcular el gasto total de un cliente dado.
   Tablas: venta */
CREATE FUNCTION fn_total_gastado_cliente(p_id_cliente INT)
RETURNS DECIMAL(12,2) DETERMINISTIC
BEGIN
  DECLARE total DECIMAL(12,2);
  SELECT IFNULL(SUM(total),0) INTO total
  FROM venta
  WHERE id_cliente = p_id_cliente;
  RETURN total;
END;
//

/* FUNCIÓN 2: fn_valor_stock_categoria
   Objetivo: Calcular el valor monetario del stock para una categoría.
   Tablas: item */
CREATE FUNCTION fn_valor_stock_categoria(p_id_categoria INT)
RETURNS DECIMAL(14,2) DETERMINISTIC
BEGIN
  DECLARE valor DECIMAL(14,2);
  SELECT IFNULL(SUM(precio_unitario * stock),0) INTO valor
  FROM item
  WHERE id_categoria = p_id_categoria
    AND tipo = 'PRODUCTO';
  RETURN valor;
END;
//

DELIMITER ;

--------------------------------------------------------------------------------
-- 6. STORED PROCEDURES (2)
--------------------------------------------------------------------------------

DELIMITER //

/* SP 1: sp_registrar_venta
   Objetivo: Insertar una venta con sus ítems y actualizar total automáticamente.
   Tablas: venta, venta_item */
CREATE PROCEDURE sp_registrar_venta(
  IN p_id_cliente INT,
  IN p_items JSON         -- formato: [{"id_item":1,"cantidad":2}, ...]
)
BEGIN
  DECLARE v_total DECIMAL(12,2) DEFAULT 0;
  DECLARE v_id_venta INT;

  -- Calcular total
  SET v_total = (
    SELECT SUM(jt.cantidad * it.precio_unitario)
    FROM JSON_TABLE(p_items, '$[*]'
      COLUMNS(
        id_item  INT PATH '$.id_item',
        cantidad INT PATH '$.cantidad'
      )
    ) AS jt
    JOIN item it ON jt.id_item = it.id_item
    WHERE jt.cantidad > 0
  );

  -- Insertar cabecera
  INSERT INTO venta(fecha_venta, id_cliente, total)
    VALUES(NOW(), p_id_cliente, v_total);
  SET v_id_venta = LAST_INSERT_ID();

  -- Insertar detalle
  INSERT INTO venta_item(id_venta, id_item, cantidad, precio_unit)
  SELECT
    v_id_venta,
    jt.id_item,
    jt.cantidad,
    it.precio_unitario
  FROM JSON_TABLE(p_items, '$[*]'
    COLUMNS(
      id_item  INT PATH '$.id_item',
      cantidad INT PATH '$.cantidad'
    )
  ) AS jt
  JOIN item it ON jt.id_item = it.id_item;
END;
//

/* SP 2: sp_obtener_ventas_cliente
   Objetivo: Obtener todas las ventas de un cliente con detalle de ítems.
   Tablas: venta, venta_item, item */
CREATE PROCEDURE sp_obtener_ventas_cliente(IN p_id_cliente INT)
BEGIN
  SELECT
    v.id_venta,
    v.fecha_venta,
    v.total,
    GROUP_CONCAT(CONCAT(vi.cantidad,'×',it.nombre) SEPARATOR '; ') AS items
  FROM venta v
  JOIN venta_item vi ON v.id_venta = vi.id_venta
  JOIN item it ON vi.id_item = it.id_item
  WHERE v.id_cliente = p_id_cliente
  GROUP BY v.id_venta, v.fecha_venta, v.total;
END;
//

DELIMITER ;

--------------------------------------------------------------------------------
-- 7. TRIGGERS (2)
--------------------------------------------------------------------------------

DELIMITER //

/* TRIGGER 1: tr_validar_cantidad_item
   Objetivo: Asegurar que cantidad > 0 y stock suficiente en cada venta_item.
   Tablas: venta_item, item */
CREATE TRIGGER tr_validar_cantidad_item
BEFORE INSERT ON venta_item
FOR EACH ROW
BEGIN
  IF NEW.cantidad <= 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La cantidad debe ser mayor que cero';
  END IF;
  IF (SELECT stock FROM item WHERE id_item = NEW.id_item) < NEW.cantidad THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Stock insuficiente para el ítem';
  END IF;
END;
//

/* TRIGGER 2: tr_log_venta
   Objetivo: Registrar en auditoria_venta cada vez que se crea una venta.
   Tablas: venta, auditoria_venta */
CREATE TRIGGER tr_log_venta
AFTER INSERT ON venta
FOR EACH ROW
BEGIN
  INSERT INTO auditoria_venta(id_venta, fecha_auditoria, accion)
    VALUES (NEW.id_venta, NOW(), 'INSERT');
END;
//

DELIMITER ;
