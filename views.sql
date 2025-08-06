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
