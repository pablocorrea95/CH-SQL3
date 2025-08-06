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
