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
