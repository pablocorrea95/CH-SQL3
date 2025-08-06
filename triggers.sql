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
