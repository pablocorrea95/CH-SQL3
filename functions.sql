CREATE FUNCTION obtener_stock_actual(id INT) RETURNS INT
DETERMINISTIC
BEGIN
  DECLARE cantidad INT;
  SELECT stock INTO cantidad FROM item WHERE id_item = id;
  RETURN cantidad;
END;
