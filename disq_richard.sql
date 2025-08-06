-- --------------------------------------------------
-- CREACIÓN DE TABLAS
-- --------------------------------------------------
USE disq_richard2;

CREATE TABLE categoria (
  id_categoria INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100)
);

CREATE TABLE item (
  id_item INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100),
  marca VARCHAR(50),
  tipo ENUM('producto', 'servicio'),
  id_categoria INT,
  precio_unitario DECIMAL(10,2),
  stock INT,
  FOREIGN KEY (id_categoria) REFERENCES categoria(id_categoria)
);

CREATE TABLE cliente (
  id_cliente INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100),
  apellido VARCHAR(100),
  email VARCHAR(100)
);

CREATE TABLE usuario (
  id_usuario INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100),
  rol VARCHAR(50)
);

CREATE TABLE venta (
  id_venta INT AUTO_INCREMENT PRIMARY KEY,
  id_cliente INT,
  id_usuario INT,
  fecha DATETIME,
  total DECIMAL(10,2),
  FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente),
  FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
);

CREATE TABLE detalle_venta (
  id_detalle INT AUTO_INCREMENT PRIMARY KEY,
  id_venta INT,
  id_item INT,
  cantidad INT,
  precio_unitario DECIMAL(10,2),
  subtotal DECIMAL(10,2),
  FOREIGN KEY (id_venta) REFERENCES venta(id_venta),
  FOREIGN KEY (id_item) REFERENCES item(id_item)
);

CREATE TABLE auditoria_venta (
  id_auditoria INT AUTO_INCREMENT PRIMARY KEY,
  id_cliente INT,
  total DECIMAL(10,2),
  fecha DATETIME
);

CREATE TABLE auditoria_modificacion_item (
  id_auditoria INT AUTO_INCREMENT PRIMARY KEY,
  id_item INT,
  fecha_modificacion DATETIME,
  descripcion_cambio TEXT
);

-- --------------------------------------------------
-- VISTAS
-- --------------------------------------------------

CREATE VIEW vista_items_completa AS
SELECT
  i.id_item,
  i.nombre,
  i.marca,
  i.tipo,
  c.nombre AS categoria,
  i.precio_unitario,
  i.stock
FROM item i
JOIN categoria c ON i.id_categoria = c.id_categoria;

CREATE VIEW vista_ventas_con_detalles AS
SELECT
  v.id_venta,
  v.fecha,
  CONCAT(cl.nombre, ' ', cl.apellido) AS cliente,
  u.nombre AS usuario,
  i.nombre AS item,
  dv.cantidad,
  dv.precio_unitario,
  dv.subtotal,
  v.total
FROM venta v
JOIN cliente cl ON v.id_cliente = cl.id_cliente
JOIN usuario u ON v.id_usuario = u.id_usuario
JOIN detalle_venta dv ON v.id_venta = dv.id_venta
JOIN item i ON dv.id_item = i.id_item;

CREATE VIEW vista_stock_bajo AS
SELECT id_item, nombre, stock
FROM item
WHERE stock < 5;

CREATE VIEW vista_totales_por_cliente AS
SELECT
  c.id_cliente,
  CONCAT(c.nombre, ' ', c.apellido) AS cliente,
  SUM(v.total) AS total_gastado
FROM cliente c
JOIN venta v ON c.id_cliente = v.id_cliente
GROUP BY c.id_cliente;

-- --------------------------------------------------
-- FUNCIONES
-- --------------------------------------------------

DELIMITER //
CREATE FUNCTION obtener_stock_actual(id INT) RETURNS INT
DETERMINISTIC
BEGIN
  DECLARE cantidad INT;
  SELECT stock INTO cantidad FROM item WHERE id_item = id;
  RETURN cantidad;
END;
//
DELIMITER ;

-- --------------------------------------------------
-- PROCEDIMIENTOS
-- --------------------------------------------------

DELIMITER //
CREATE PROCEDURE registrar_venta(
  IN p_id_cliente INT,
  IN p_id_usuario INT,
  IN p_total DECIMAL(10,2),
  OUT p_id_venta INT
)
BEGIN
  INSERT INTO venta (id_cliente, id_usuario, fecha, total)
  VALUES (p_id_cliente, p_id_usuario, NOW(), p_total);
  SET p_id_venta = LAST_INSERT_ID();
END;
//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE agregar_detalle_venta(
  IN p_id_venta INT,
  IN p_id_item INT,
  IN p_cantidad INT,
  IN p_precio_unitario DECIMAL(10,2)
)
BEGIN
  DECLARE p_subtotal DECIMAL(10,2);
  SET p_subtotal = p_cantidad * p_precio_unitario;

  INSERT INTO detalle_venta (id_venta, id_item, cantidad, precio_unitario, subtotal)
  VALUES (p_id_venta, p_id_item, p_cantidad, p_precio_unitario, p_subtotal);

  UPDATE item
  SET stock = stock - p_cantidad
  WHERE id_item = p_id_item;
END;
//
DELIMITER ;

-- --------------------------------------------------
-- TRIGGERS
-- --------------------------------------------------

DELIMITER //
CREATE TRIGGER trg_auditar_venta
AFTER INSERT ON venta
FOR EACH ROW
BEGIN
  INSERT INTO auditoria_venta (id_cliente, total, fecha)
  VALUES (NEW.id_cliente, NEW.total, NOW());
END;
//
DELIMITER ;

DELIMITER //
CREATE TRIGGER trg_prevenir_stock_negativo
BEFORE INSERT ON detalle_venta
FOR EACH ROW
BEGIN
  DECLARE stock_actual INT;

  SELECT stock INTO stock_actual
  FROM item
  WHERE id_item = NEW.id_item;

  IF NEW.cantidad > stock_actual THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Error: Stock insuficiente para realizar la venta';
  END IF;
END;
//
DELIMITER ;

DELIMITER //
CREATE TRIGGER trg_auditar_modificacion_item
AFTER UPDATE ON item
FOR EACH ROW
BEGIN
  INSERT INTO auditoria_modificacion_item (id_item, fecha_modificacion, descripcion_cambio)
  VALUES (
    OLD.id_item,
    NOW(),
    CONCAT('Modificación de item. Precio: ', OLD.precio_unitario, ' → ', NEW.precio_unitario, 
           ', Stock: ', OLD.stock, ' → ', NEW.stock)
  );
END;
//
DELIMITER ;
