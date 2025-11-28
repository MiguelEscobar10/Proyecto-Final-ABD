------------------------------------------------------------
-- 1. Creación de base de datos
------------------------------------------------------------
CREATE DATABASE TECHOSV;
GO

USE TECHOSV;
GO

------------------------------------------------------------
-- 2. Creación de esquemas
------------------------------------------------------------
CREATE SCHEMA cat;   -- catálogos (departamento, municipio, etc.)
GO

CREATE SCHEMA core;  -- entidades operativas (donante, proyecto, etc.)
GO

CREATE SCHEMA seg;   -- reservado para tablas de auditoría / seguridad
GO


------------------------------------------------------------
-- 3. Tablas de catálogo (esquema cat)
------------------------------------------------------------

CREATE TABLE cat.Departamento (
    departamentoId INT PRIMARY KEY IDENTITY(1,1),
    nombre NVARCHAR(100) NOT NULL
);
GO

CREATE TABLE cat.Municipio (
    municipioId INT PRIMARY KEY IDENTITY(1,1),
    nombre NVARCHAR(100) NOT NULL,
    FK_departamento INT NOT NULL,
    CONSTRAINT FK_Municipio_Departamento 
        FOREIGN KEY (FK_departamento) 
        REFERENCES cat.Departamento(departamentoId)
);
GO

CREATE TABLE cat.Comunidad (
    comunidadId INT PRIMARY KEY IDENTITY(1,1),
    nombre NVARCHAR(100) NOT NULL,
    FK_municipio INT NOT NULL,
    CONSTRAINT FK_Comunidad_Municipio 
        FOREIGN KEY (FK_municipio) 
        REFERENCES cat.Municipio(municipioId)
);
GO

CREATE TABLE cat.TipoDonante (
   TipoDonanteId INT IDENTITY(1,1) PRIMARY KEY NOT NULL , 
   Nombre NVARCHAR(40) NOT NULL UNIQUE
);
GO

CREATE TABLE cat.MetodoDonacion (
    MetodoId INT IDENTITY(1,1) PRIMARY KEY NOT NULL ,
    Nombre  NVARCHAR(40) NOT NULL
);
GO

CREATE TABLE cat.EstadoProyecto (
    EstadoId INT IDENTITY(1,1) PRIMARY KEY NOT NULL ,
    Nombre NVARCHAR(30) NOT NULL UNIQUE
);
GO


------------------------------------------------------------
-- 4. Tablas de entidades principales (esquema core)
------------------------------------------------------------

CREATE TABLE core.Donante (
    DonanteId INT IDENTITY(1,1) PRIMARY KEY,
    Nombre NVARCHAR(120) NOT NULL,
    Email NVARCHAR(255) NULL,
    Telefono NVARCHAR(25) NULL,
    TipoDonanteId INT NOT NULL,
    CONSTRAINT FK_Donante_TipoDonante 
        FOREIGN KEY (TipoDonanteId) 
        REFERENCES cat.TipoDonante(TipoDonanteId)
);
GO

CREATE TABLE core.Voluntario (
    VoluntarioId INT IDENTITY(1,1) PRIMARY KEY,
    Nombre NVARCHAR(120) NOT NULL,
    Email NVARCHAR(255) NULL, 
    Telefono NVARCHAR(25) NULL  
);
GO

CREATE TABLE core.Beneficiario (
    BeneficiarioId INT IDENTITY(1,1) PRIMARY KEY,
    Nombre NVARCHAR(120) NOT NULL,
    Edad INT NULL,
    FK_Comunidad INT NOT NULL,
    CONSTRAINT FK_Beneficiario_Comunidad 
        FOREIGN KEY (FK_Comunidad) 
        REFERENCES cat.Comunidad(comunidadId)
);
GO

CREATE TABLE core.Proyecto (
    ProyectoId INT IDENTITY(1,1) PRIMARY KEY,
    Nombre NVARCHAR(150) NOT NULL,
    FechaInicio DATE NULL,
    FechaFin DATE NULL,
    Descripcion NVARCHAR(500) NULL,
    presupuesto DECIMAL(18, 2),
    EstadoId INT NOT NULL,
    LiderVoluntarioId INT NOT NULL,
    CONSTRAINT FK_Proyecto_EstadoProyecto 
        FOREIGN KEY (EstadoId) 
        REFERENCES cat.EstadoProyecto(EstadoId),
    CONSTRAINT FK_Proyecto_LiderVoluntario 
        FOREIGN KEY (LiderVoluntarioId) 
        REFERENCES core.Voluntario(VoluntarioId)
);
GO

CREATE TABLE core.Donacion (
    DonacionId INT IDENTITY(1,1) PRIMARY KEY,
    Fecha DATETIME NOT NULL DEFAULT GETDATE(),
    Monto DECIMAL(14,2) NOT NULL,
    Usado DECIMAL(18, 2) NOT NULL DEFAULT 0.00,
    Disponible AS (Monto - Usado) PERSISTED,
    DonanteId INT NOT NULL,
    MetodoDonacionId INT NOT NULL,
    VoluntarioRegistroId INT NOT NULL,
    CONSTRAINT FK_Donacion_Donante 
        FOREIGN KEY (DonanteId) 
        REFERENCES core.Donante(DonanteId),
    CONSTRAINT FK_Donacion_VoluntarioRegistro 
        FOREIGN KEY (VoluntarioRegistroId) 
        REFERENCES core.Voluntario(VoluntarioId),
    CONSTRAINT FK_Donacion_MetodoDonacion 
        FOREIGN KEY (MetodoDonacionId) 
        REFERENCES cat.MetodoDonacion(MetodoId)
);
GO

-- Tablas M:N
CREATE TABLE core.BeneficiarioProyecto (
    BeneficiarioId INT NOT NULL,
    ProyectoId INT NOT NULL, 
    PRIMARY KEY (BeneficiarioId, ProyectoId), 
    CONSTRAINT FK_BeneficiarioProyecto_Beneficiario 
        FOREIGN KEY (BeneficiarioId) 
        REFERENCES core.Beneficiario(BeneficiarioId),
    CONSTRAINT FK_BeneficiarioProyecto_Proyecto 
        FOREIGN KEY (ProyectoId) 
        REFERENCES core.Proyecto(ProyectoId)
);
GO

CREATE TABLE core.Financiamiento (
    DonacionId INT NOT NULL,
    ProyectoId INT NOT NULL,
    Fecha DATE NOT NULL,
    Desembolso DECIMAL(18, 2) NOT NULL,
    CONSTRAINT PK_Financiamiento PRIMARY KEY (DonacionId, ProyectoId),
    CONSTRAINT FK_Financiamiento_Donacion 
        FOREIGN KEY (DonacionId) 
        REFERENCES core.Donacion(DonacionId),
    CONSTRAINT FK_Financiamiento_Proyecto 
        FOREIGN KEY (ProyectoId) 
        REFERENCES core.Proyecto(ProyectoId)
);
GO


------------------------------------------------------------
-- 5. Datos iniciales (INSERTS con esquemas)
------------------------------------------------------------

------------------------------------------------------------
-- Departamentos (14)
------------------------------------------------------------
INSERT INTO cat.Departamento (nombre) VALUES
('Ahuachapan'),
('Santa Ana'),
('Sonsonate'),
('Chalatenango'),
('La Libertad'),
('San Salvador'),
('Cuscatlan'),
('La Paz'),
('Cabanas'),
('San Vicente'),
('Usulutan'),
('San Miguel'),
('Morazan'),
('La Union');

------------------------------------------------------------
-- Municipios (2 por departamento)
------------------------------------------------------------

INSERT INTO cat.Municipio (nombre, FK_departamento) VALUES
-- Ahuachapan
('Ahuachapan', (SELECT departamentoId FROM cat.Departamento WHERE nombre = 'Ahuachapan')),
('Atiquizaya', (SELECT departamentoId FROM cat.Departamento WHERE nombre = 'Ahuachapan')),

-- Santa Ana
('Santa Ana',  (SELECT departamentoId FROM cat.Departamento WHERE nombre = 'Santa Ana')),
('Metapan',    (SELECT departamentoId FROM cat.Departamento WHERE nombre = 'Santa Ana')),

-- Sonsonate
('Sonsonate',  (SELECT departamentoId FROM cat.Departamento WHERE nombre = 'Sonsonate')),
('Acajutla',   (SELECT departamentoId FROM cat.Departamento WHERE nombre = 'Sonsonate')),

-- Chalatenango
('Chalatenango', (SELECT departamentoId FROM cat.Departamento WHERE nombre = 'Chalatenango')),
('La Palma',     (SELECT departamentoId FROM cat.Departamento WHERE nombre = 'Chalatenango')),

-- La Libertad
('Santa Tecla',  (SELECT departamentoId FROM cat.Departamento WHERE nombre = 'La Libertad')),
('Tepecoyo',     (SELECT departamentoId FROM cat.Departamento WHERE nombre = 'La Libertad')),

-- San Salvador
('San Salvador', (SELECT departamentoId FROM cat.Departamento WHERE nombre = 'San Salvador')),
('Ilopango',     (SELECT departamentoId FROM cat.Departamento WHERE nombre = 'San Salvador')),

-- Cuscatlan
('Cojutepeque',  (SELECT departamentoId FROM cat.Departamento WHERE nombre = 'Cuscatlan')),
('Suchitoto',    (SELECT departamentoId FROM cat.Departamento WHERE nombre = 'Cuscatlan')),

-- La Paz
('Zacatecoluca', (SELECT departamentoId FROM cat.Departamento WHERE nombre = 'La Paz')),
('Olocuilta',    (SELECT departamentoId FROM cat.Departamento WHERE nombre = 'La Paz')),

-- Cabanas
('Sensuntepeque',(SELECT departamentoId FROM cat.Departamento WHERE nombre = 'Cabanas')),
('Ilobasco',     (SELECT departamentoId FROM cat.Departamento WHERE nombre = 'Cabanas')),

-- San Vicente
('San Vicente',  (SELECT departamentoId FROM cat.Departamento WHERE nombre = 'San Vicente')),
('Tecoluca',     (SELECT departamentoId FROM cat.Departamento WHERE nombre = 'San Vicente')),

-- Usulutan
('Usulutan',     (SELECT departamentoId FROM cat.Departamento WHERE nombre = 'Usulutan')),
('Jiquilisco',   (SELECT departamentoId FROM cat.Departamento WHERE nombre = 'Usulutan')),

-- San Miguel
('San Miguel',   (SELECT departamentoId FROM cat.Departamento WHERE nombre = 'San Miguel')),
('Chinameca',    (SELECT departamentoId FROM cat.Departamento WHERE nombre = 'San Miguel')),

-- Morazan
('San Francisco Gotera', (SELECT departamentoId FROM cat.Departamento WHERE nombre = 'Morazan')),
('Jocoro',               (SELECT departamentoId FROM cat.Departamento WHERE nombre = 'Morazan')),

-- La Union
('La Union',      (SELECT departamentoId FROM cat.Departamento WHERE nombre = 'La Union')),
('Santa Rosa de Lima', (SELECT departamentoId FROM cat.Departamento WHERE nombre = 'La Union'));
GO

------------------------------------------------------------
-- Comunidades (varias por municipio)
------------------------------------------------------------

INSERT INTO cat.Comunidad (nombre, FK_municipio) VALUES
-- Ahuachapan
('Comunidad Las Violetas Ahuachapan',
 (SELECT municipioId FROM cat.Municipio WHERE nombre = 'Ahuachapan')),
('Comunidad El Carmen Ahuachapan',
 (SELECT municipioId FROM cat.Municipio WHERE nombre = 'Ahuachapan')),
('Comunidad Los Naranjos Atiquizaya',
 (SELECT municipioId FROM cat.Municipio WHERE nombre = 'Atiquizaya')),

-- Santa Ana
('Comunidad Santa Lucia Santa Ana',
 (SELECT municipioId FROM cat.Municipio WHERE nombre = 'Santa Ana')),
('Comunidad El Palmar Santa Ana',
 (SELECT municipioId FROM cat.Municipio WHERE nombre = 'Santa Ana')),
('Comunidad San Miguelito Metapan',
 (SELECT municipioId FROM cat.Municipio WHERE nombre = 'Metapan')),

-- Sonsonate
('Comunidad El Milagro Sonsonate',
 (SELECT municipioId FROM cat.Municipio WHERE nombre = 'Sonsonate')),
('Comunidad Las Brisas Sonsonate',
 (SELECT municipioId FROM cat.Municipio WHERE nombre = 'Sonsonate')),
('Comunidad Puerto Libre Acajutla',
 (SELECT municipioId FROM cat.Municipio WHERE nombre = 'Acajutla')),

-- Chalatenango
('Comunidad La Esperanza Chalatenango',
 (SELECT municipioId FROM cat.Municipio WHERE nombre = 'Chalatenango')),
('Comunidad El Pital La Palma',
 (SELECT municipioId FROM cat.Municipio WHERE nombre = 'La Palma')),

-- La Libertad
('Comunidad Las Delicias Santa Tecla',
 (SELECT municipioId FROM cat.Municipio WHERE nombre = 'Santa Tecla')),
('Comunidad El Pino Tepecoyo',
 (SELECT municipioId FROM cat.Municipio WHERE nombre = 'Tepecoyo')),

-- San Salvador
('Comunidad Iberia San Salvador',
 (SELECT municipioId FROM cat.Municipio WHERE nombre = 'San Salvador')),
('Comunidad San Luis San Salvador',
 (SELECT municipioId FROM cat.Municipio WHERE nombre = 'San Salvador')),
('Comunidad Changallo Ilopango',
 (SELECT municipioId FROM cat.Municipio WHERE nombre = 'Ilopango')),

-- Cuscatlan
('Comunidad El Carmen Cojutepeque',
 (SELECT municipioId FROM cat.Municipio WHERE nombre = 'Cojutepeque')),
('Comunidad El Sitio Suchitoto',
 (SELECT municipioId FROM cat.Municipio WHERE nombre = 'Suchitoto')),

-- La Paz
('Comunidad Santa Elena Zacatecoluca',
 (SELECT municipioId FROM cat.Municipio WHERE nombre = 'Zacatecoluca')),
('Comunidad El Amate Olocuilta',
 (SELECT municipioId FROM cat.Municipio WHERE nombre = 'Olocuilta')),

-- Cabanas
('Comunidad El Molino Sensuntepeque',
 (SELECT municipioId FROM cat.Municipio WHERE nombre = 'Sensuntepeque')),
('Comunidad Las Colinas Ilobasco',
 (SELECT municipioId FROM cat.Municipio WHERE nombre = 'Ilobasco')),

-- San Vicente
('Comunidad San Antonio San Vicente',
 (SELECT municipioId FROM cat.Municipio WHERE nombre = 'San Vicente')),
('Comunidad El Papalon Tecoluca',
 (SELECT municipioId FROM cat.Municipio WHERE nombre = 'Tecoluca')),

-- Usulutan
('Comunidad El Espino Usulutan',
 (SELECT municipioId FROM cat.Municipio WHERE nombre = 'Usulutan')),
('Comunidad Puerto Parada Jiquilisco',
 (SELECT municipioId FROM cat.Municipio WHERE nombre = 'Jiquilisco')),

-- San Miguel
('Comunidad Milagro de la Paz San Miguel',
 (SELECT municipioId FROM cat.Municipio WHERE nombre = 'San Miguel')),
('Comunidad La Cruz Chinameca',
 (SELECT municipioId FROM cat.Municipio WHERE nombre = 'Chinameca')),

-- Morazan
('Comunidad El Rosario SFG',
 (SELECT municipioId FROM cat.Municipio WHERE nombre = 'San Francisco Gotera')),
('Comunidad Los Planes Jocoro',
 (SELECT municipioId FROM cat.Municipio WHERE nombre = 'Jocoro')),

-- La Union
('Comunidad Puerto Cutuco La Union',
 (SELECT municipioId FROM cat.Municipio WHERE nombre = 'La Union')),
('Comunidad El Tamarindo SRL',
 (SELECT municipioId FROM cat.Municipio WHERE nombre = 'Santa Rosa de Lima'));
GO


------------------------------------------------------------
-- TABLAS DE CATALOGO: TipoDonante, MetodoDonacion, EstadoProyecto
------------------------------------------------------------
INSERT INTO cat.TipoDonante (Nombre) VALUES
('Individual'),
('Empresa'),
('Organizacion');

INSERT INTO cat.MetodoDonacion (Nombre) VALUES
('Efectivo'),
('Transferencia bancaria'),
('Tarjeta de Credito'),
('Cheque');

INSERT INTO cat.EstadoProyecto (Nombre) VALUES
('Planificado'),
('En ejecucion'),
('Finalizado');
GO
------------------------------------------------------------
-- Donantes (Empresas y personas salvadoreñas)
------------------------------------------------------------
INSERT INTO core.Donante (Nombre, Email, Telefono, TipoDonanteId) VALUES
('Super Selectos S.A. de C.V.', 'donaciones@superselectos.com', '2221-0000',
 (SELECT TipoDonanteId FROM cat.TipoDonante WHERE Nombre = 'Empresa')),
('Tigo El Salvador', 'rsocial@tigo.com.sv', '2500-0000',
 (SELECT TipoDonanteId FROM cat.TipoDonante WHERE Nombre = 'Empresa')),
('La Constancia S.A. de C.V.', 'fundacion@laconstancia.com', '2210-5000',
 (SELECT TipoDonanteId FROM cat.TipoDonante WHERE Nombre = 'Empresa')),
('Ferreteria El Volcan', 'contacto@elvolcan.com.sv', '2334-1122',
 (SELECT TipoDonanteId FROM cat.TipoDonante WHERE Nombre = 'Empresa')),
('Panaderia La Bendicion', 'labendicion@panes.com', '7283-4411',
 (SELECT TipoDonanteId FROM cat.TipoDonante WHERE Nombre = 'Empresa')),
('Distribuidora San Miguel S.A. de C.V.', 'info@distsanmiguel.com', '2660-8899',
 (SELECT TipoDonanteId FROM cat.TipoDonante WHERE Nombre = 'Empresa')),
('Farmacia San Jose S.A. de C.V.', 'donaciones@farmaciasanjose.com', '2256-9900',
 (SELECT TipoDonanteId FROM cat.TipoDonante WHERE Nombre = 'Empresa')),
('Fundacion Manos Unidas SV', 'info@manosunidassv.org', '2225-7788',
 (SELECT TipoDonanteId FROM cat.TipoDonante WHERE Nombre = 'Organizacion')),
('Fundacion Luz y Esperanza', 'contacto@luzyesperanza.org', '2260-3344',
 (SELECT TipoDonanteId FROM cat.TipoDonante WHERE Nombre = 'Organizacion')),
('Fundacion Techo Digno', 'info@techodigno.org', '2233-5599',
 (SELECT TipoDonanteId FROM cat.TipoDonante WHERE Nombre = 'Organizacion')),
('Carlos Mejia', 'carlos.mejia75@gmail.com', '7770-9001',
 (SELECT TipoDonanteId FROM cat.TipoDonante WHERE Nombre = 'Individual')),
('Karla Hernandez', 'karla.hernandez84@gmail.com', '7892-1144',
 (SELECT TipoDonanteId FROM cat.TipoDonante WHERE Nombre = 'Individual')),
('Familia Lopez de Sonsonate', 'fam.lopez.sonsonate@gmail.com', '7690-2211',
 (SELECT TipoDonanteId FROM cat.TipoDonante WHERE Nombre = 'Individual')),
('Ricardo Chavez', 'ricardo.chavez.sv@gmail.com', '7600-4411',
 (SELECT TipoDonanteId FROM cat.TipoDonante WHERE Nombre = 'Individual')),
('Ana Maria Campos', 'ana.campos.sv@gmail.com', '7890-3322',
 (SELECT TipoDonanteId FROM cat.TipoDonante WHERE Nombre = 'Individual'));
GO


------------------------------------------------------------
-- Voluntarios
------------------------------------------------------------
INSERT INTO core.Voluntario (Nombre, Email, Telefono) VALUES
('Alejandra Rivera', 'alejandra.rivera@techosv.org', '7030-1122'),
('Mario Molina', 'mario.molina@techosv.org', '7055-3344'),
('Miguel Escobar', 'miguel.escobar@techosv.org', '7122-5588'),
('Juan Sanchez', 'juan.sanchez@techosv.org', '7133-4499'),
('Karla Martinez', 'karla.martinez@techosv.org', '7144-6677'),
('Luis Hernandez', 'luis.hernandez@techosv.org', '7155-7788'),
('Daniela Campos', 'daniela.campos@techosv.org', '7166-8899'),
('Oscar Rivera', 'oscar.rivera@techosv.org', '7177-9900'),
('Claudia Torres', 'claudia.torres@techosv.org', '7188-2211'),
('Jose Antonio Chavez', 'jose.chavez@techosv.org', '7199-3322');
GO


------------------------------------------------------------
-- Beneficiarios (Familias en comunidades)
------------------------------------------------------------
INSERT INTO core.Beneficiario (Nombre, Edad, FK_Comunidad) VALUES
('Familia Gomez', 34,
 (SELECT comunidadId FROM cat.Comunidad WHERE nombre = 'Comunidad Las Violetas Ahuachapan')),
('Familia Rivas', 29,
 (SELECT comunidadId FROM cat.Comunidad WHERE nombre = 'Comunidad El Carmen Ahuachapan')),
('Familia Castillo', 31,
 (SELECT comunidadId FROM cat.Comunidad WHERE nombre = 'Comunidad Los Naranjos Atiquizaya')),
('Familia Martinez', 28,
 (SELECT comunidadId FROM cat.Comunidad WHERE nombre = 'Comunidad Santa Lucia Santa Ana')),
('Familia Lopez', 42,
 (SELECT comunidadId FROM cat.Comunidad WHERE nombre = 'Comunidad El Palmar Santa Ana')),
('Familia Campos', 37,
 (SELECT comunidadId FROM cat.Comunidad WHERE nombre = 'Comunidad San Miguelito Metapan')),
('Familia Pineda', 35,
 (SELECT comunidadId FROM cat.Comunidad WHERE nombre = 'Comunidad El Milagro Sonsonate')),
('Familia Alvarado', 33,
 (SELECT comunidadId FROM cat.Comunidad WHERE nombre = 'Comunidad Las Brisas Sonsonate')),
('Familia Soto', 39,
 (SELECT comunidadId FROM cat.Comunidad WHERE nombre = 'Comunidad Puerto Libre Acajutla')),
('Familia Hernandez', 30,
 (SELECT comunidadId FROM cat.Comunidad WHERE nombre = 'Comunidad La Esperanza Chalatenango')),
('Familia Guzman', 32,
 (SELECT comunidadId FROM cat.Comunidad WHERE nombre = 'Comunidad El Pital La Palma')),
('Familia Melendez', 36,
 (SELECT comunidadId FROM cat.Comunidad WHERE nombre = 'Comunidad Las Delicias Santa Tecla')),
('Familia Romero', 27,
 (SELECT comunidadId FROM cat.Comunidad WHERE nombre = 'Comunidad El Pino Tepecoyo')),
('Familia Aguilar', 38,
 (SELECT comunidadId FROM cat.Comunidad WHERE nombre = 'Comunidad Iberia San Salvador')),
('Familia Flores', 40,
 (SELECT comunidadId FROM cat.Comunidad WHERE nombre = 'Comunidad San Luis San Salvador')),
('Familia Barrera', 31,
 (SELECT comunidadId FROM cat.Comunidad WHERE nombre = 'Comunidad Changallo Ilopango')),
('Familia Argueta', 29,
 (SELECT comunidadId FROM cat.Comunidad WHERE nombre = 'Comunidad El Carmen Cojutepeque')),
('Familia Villalta', 41,
 (SELECT comunidadId FROM cat.Comunidad WHERE nombre = 'Comunidad El Sitio Suchitoto')),
('Familia Sorto', 33,
 (SELECT comunidadId FROM cat.Comunidad WHERE nombre = 'Comunidad Santa Elena Zacatecoluca')),
('Familia Fuentes', 35,
 (SELECT comunidadId FROM cat.Comunidad WHERE nombre = 'Comunidad El Amate Olocuilta')),
('Familia Amaya', 37,
 (SELECT comunidadId FROM cat.Comunidad WHERE nombre = 'Comunidad El Molino Sensuntepeque')),
('Familia Carranza', 26,
 (SELECT comunidadId FROM cat.Comunidad WHERE nombre = 'Comunidad Las Colinas Ilobasco')),
('Familia Monterrosa', 34,
 (SELECT comunidadId FROM cat.Comunidad WHERE nombre = 'Comunidad San Antonio San Vicente')),
('Familia Bonilla', 30,
 (SELECT comunidadId FROM cat.Comunidad WHERE nombre = 'Comunidad El Papalon Tecoluca')),
('Familia Chavez', 32,
 (SELECT comunidadId FROM cat.Comunidad WHERE nombre = 'Comunidad El Espino Usulutan')),
('Familia Guardado', 39,
 (SELECT comunidadId FROM cat.Comunidad WHERE nombre = 'Comunidad Puerto Parada Jiquilisco')),
('Familia Delgado', 31,
 (SELECT comunidadId FROM cat.Comunidad WHERE nombre = 'Comunidad Milagro de la Paz San Miguel')),
('Familia Vasquez', 28,
 (SELECT comunidadId FROM cat.Comunidad WHERE nombre = 'Comunidad La Cruz Chinameca')),
('Familia Molina', 36,
 (SELECT comunidadId FROM cat.Comunidad WHERE nombre = 'Comunidad El Rosario SFG')),
('Familia Rivera', 33,
 (SELECT comunidadId FROM cat.Comunidad WHERE nombre = 'Comunidad Los Planes Jocoro')),
('Familia Quintanilla', 38,
 (SELECT comunidadId FROM cat.Comunidad WHERE nombre = 'Comunidad Puerto Cutuco La Union')),
('Familia Lopez SRL', 29,
 (SELECT comunidadId FROM cat.Comunidad WHERE nombre = 'Comunidad El Tamarindo SRL'));
GO


------------------------------------------------------------
-- Proyectos
------------------------------------------------------------
INSERT INTO core.Proyecto (Nombre, FechaInicio, FechaFin, Descripcion, presupuesto, EstadoId, LiderVoluntarioId) VALUES
('Techo Seguro Ahuachapan', '2024-01-15', '2024-12-15',
 'Reparacion y reemplazo de techos en comunidades rurales de Ahuachapan',
 20000.00,
 (SELECT EstadoId FROM cat.EstadoProyecto WHERE Nombre = 'En ejecucion'),
 (SELECT VoluntarioId FROM core.Voluntario WHERE Nombre = 'Alejandra Rivera')),

('Agua Segura Chalatenango', '2024-02-01', '2024-11-30',
 'Instalacion de sistemas de captacion de agua lluvia y filtros familiares',
 18000.00,
 (SELECT EstadoId FROM cat.EstadoProyecto WHERE Nombre = 'En ejecucion'),
 (SELECT VoluntarioId FROM core.Voluntario WHERE Nombre = 'Mario Molina')),

('Viviendas Transitorias Sonsonate', '2024-03-10', '2025-03-10',
 'Construccion de viviendas transitorias para familias en alto riesgo',
 25000.00,
 (SELECT EstadoId FROM cat.EstadoProyecto WHERE Nombre = 'Planificado'),
 (SELECT VoluntarioId FROM core.Voluntario WHERE Nombre = 'Miguel Escobar')),

('Rehabilitacion de Pisos Santa Ana', '2024-04-01', '2024-10-31',
 'Cambio de pisos de tierra por pisos firmes en viviendas vulnerables',
 15000.00,
 (SELECT EstadoId FROM cat.EstadoProyecto WHERE Nombre = 'En ejecucion'),
 (SELECT VoluntarioId FROM core.Voluntario WHERE Nombre = 'Juan Sanchez')),

('Mejora de Viviendas San Salvador', '2024-02-20', '2025-02-20',
 'Refuerzo estructural y mejora habitacional en comunidades urbanas',
 30000.00,
 (SELECT EstadoId FROM cat.EstadoProyecto WHERE Nombre = 'En ejecucion'),
 (SELECT VoluntarioId FROM core.Voluntario WHERE Nombre = 'Karla Martinez')),

('Proyecto Costero La Union', '2024-05-05', '2025-01-31',
 'Reparacion de techos y pisos en comunidades costeras de La Union',
 22000.00,
 (SELECT EstadoId FROM cat.EstadoProyecto WHERE Nombre = 'Planificado'),
 (SELECT VoluntarioId FROM core.Voluntario WHERE Nombre = 'Luis Hernandez')),

('Viviendas Dignas Usulutan', '2024-03-01', '2024-12-20',
 'Construccion de modulos habitacionales en comunidades rurales de Usulutan',
 24000.00,
 (SELECT EstadoId FROM cat.EstadoProyecto WHERE Nombre = 'En ejecucion'),
 (SELECT VoluntarioId FROM core.Voluntario WHERE Nombre = 'Daniela Campos')),

('Mejoramiento Integral San Miguel', '2024-04-15', '2025-04-15',
 'Mejoras de techos, pisos y servicios basicos en viviendas',
 28000.00,
 (SELECT EstadoId FROM cat.EstadoProyecto WHERE Nombre = 'En ejecucion'),
 (SELECT VoluntarioId FROM core.Voluntario WHERE Nombre = 'Oscar Rivera')),

('Proyecto Morazan Solidario', '2024-06-01', '2025-05-31',
 'Apoyo integral a viviendas vulnerables en Morazan',
 21000.00,
 (SELECT EstadoId FROM cat.EstadoProyecto WHERE Nombre = 'Planificado'),
 (SELECT VoluntarioId FROM core.Voluntario WHERE Nombre = 'Claudia Torres')),

('Techo y Piso Cabanas', '2024-05-10', '2024-12-10',
 'Intervenciones en techos y pisos en comunidades de Cabanas',
 16000.00,
 (SELECT EstadoId FROM cat.EstadoProyecto WHERE Nombre = 'En ejecucion'),
 (SELECT VoluntarioId FROM core.Voluntario WHERE Nombre = 'Jose Antonio Chavez'));
GO

------------------------------------------------------------
-- Donaciones
-- Usaremos montos y "Usado" coherentes con financiamientos posteriores
------------------------------------------------------------

INSERT INTO core.Donacion (Fecha, Monto, Usado, DonanteId, MetodoDonacionId, VoluntarioRegistroId) VALUES
('2024-01-20', 5000.00, 3000.00,
 (SELECT DonanteId FROM core.Donante WHERE Nombre = 'Super Selectos S.A. de C.V.'),
 (SELECT MetodoId  FROM cat.MetodoDonacion WHERE Nombre = 'Transferencia bancaria'),
 (SELECT VoluntarioId FROM core.Voluntario WHERE Nombre = 'Alejandra Rivera')),

('2024-01-25', 4000.00, 2500.00,
 (SELECT DonanteId FROM core.Donante WHERE Nombre = 'Tigo El Salvador'),
 (SELECT MetodoId  FROM cat.MetodoDonacion WHERE Nombre = 'Transferencia bancaria'),
 (SELECT VoluntarioId FROM core.Voluntario WHERE Nombre = 'Mario Molina')),

('2024-02-05', 3500.00, 2000.00,
 (SELECT DonanteId FROM core.Donante WHERE Nombre = 'La Constancia S.A. de C.V.'),
 (SELECT MetodoId  FROM cat.MetodoDonacion WHERE Nombre = 'Cheque'),
 (SELECT VoluntarioId FROM core.Voluntario WHERE Nombre = 'Miguel Escobar')),

('2024-02-15', 2500.00, 1500.00,
 (SELECT DonanteId FROM core.Donante WHERE Nombre = 'Ferreteria El Volcan'),
 (SELECT MetodoId  FROM cat.MetodoDonacion WHERE Nombre = 'Efectivo'),
 (SELECT VoluntarioId FROM core.Voluntario WHERE Nombre = 'Juan Sanchez')),

('2024-02-28', 1800.00, 800.00,
 (SELECT DonanteId FROM core.Donante WHERE Nombre = 'Panaderia La Bendicion'),
 (SELECT MetodoId  FROM cat.MetodoDonacion WHERE Nombre = 'Efectivo'),
 (SELECT VoluntarioId FROM core.Voluntario WHERE Nombre = 'Karla Martinez')),

('2024-03-05', 4200.00, 3000.00,
 (SELECT DonanteId FROM core.Donante WHERE Nombre = 'Fundacion Manos Unidas SV'),
 (SELECT MetodoId  FROM cat.MetodoDonacion WHERE Nombre = 'Transferencia bancaria'),
 (SELECT VoluntarioId FROM core.Voluntario WHERE Nombre = 'Luis Hernandez')),

('2024-03-12', 3200.00, 2000.00,
 (SELECT DonanteId FROM core.Donante WHERE Nombre = 'Fundacion Luz y Esperanza'),
 (SELECT MetodoId  FROM cat.MetodoDonacion WHERE Nombre = 'Transferencia bancaria'),
 (SELECT VoluntarioId FROM core.Voluntario WHERE Nombre = 'Daniela Campos')),

('2024-03-20', 2800.00, 1500.00,
 (SELECT DonanteId FROM core.Donante WHERE Nombre = 'Fundacion Techo Digno'),
 (SELECT MetodoId  FROM cat.MetodoDonacion WHERE Nombre = 'Transferencia bancaria'),
 (SELECT VoluntarioId FROM core.Voluntario WHERE Nombre = 'Oscar Rivera')),

('2024-04-01', 1500.00, 700.00,
 (SELECT DonanteId FROM core.Donante WHERE Nombre = 'Carlos Mejia'),
 (SELECT MetodoId  FROM cat.MetodoDonacion WHERE Nombre = 'Tarjeta de Credito'),
 (SELECT VoluntarioId FROM core.Voluntario WHERE Nombre = 'Claudia Torres')),

('2024-04-10', 1700.00, 900.00,
 (SELECT DonanteId FROM core.Donante WHERE Nombre = 'Karla Hernandez'),
 (SELECT MetodoId  FROM cat.MetodoDonacion WHERE Nombre = 'Tarjeta de Credito'),
 (SELECT VoluntarioId FROM core.Voluntario WHERE Nombre = 'Jose Antonio Chavez')),

('2024-04-18', 3600.00, 2000.00,
 (SELECT DonanteId FROM core.Donante WHERE Nombre = 'Distribuidora San Miguel S.A. de C.V.'),
 (SELECT MetodoId  FROM cat.MetodoDonacion WHERE Nombre = 'Cheque'),
 (SELECT VoluntarioId FROM core.Voluntario WHERE Nombre = 'Alejandra Rivera')),

('2024-05-02', 3000.00, 1800.00,
 (SELECT DonanteId FROM core.Donante WHERE Nombre = 'Farmacia San Jose S.A. de C.V.'),
 (SELECT MetodoId  FROM cat.MetodoDonacion WHERE Nombre = 'Transferencia bancaria'),
 (SELECT VoluntarioId FROM core.Voluntario WHERE Nombre = 'Mario Molina'));
GO

------------------------------------------------------------
-- Beneficiario - Proyecto (Relaciones)--
------------------------------------------------------------
INSERT INTO core.BeneficiarioProyecto (BeneficiarioId, ProyectoId) VALUES
((SELECT BeneficiarioId FROM core.Beneficiario WHERE Nombre = 'Familia Gomez'),
 (SELECT ProyectoId     FROM core.Proyecto     WHERE Nombre = 'Techo Seguro Ahuachapan')),
((SELECT BeneficiarioId FROM core.Beneficiario WHERE Nombre = 'Familia Rivas'),
 (SELECT ProyectoId     FROM core.Proyecto     WHERE Nombre = 'Techo Seguro Ahuachapan')),
((SELECT BeneficiarioId FROM core.Beneficiario WHERE Nombre = 'Familia Castillo'),
 (SELECT ProyectoId     FROM core.Proyecto     WHERE Nombre = 'Techo Seguro Ahuachapan')),

((SELECT BeneficiarioId FROM core.Beneficiario WHERE Nombre = 'Familia Hernandez'),
 (SELECT ProyectoId     FROM core.Proyecto     WHERE Nombre = 'Agua Segura Chalatenango')),
((SELECT BeneficiarioId FROM core.Beneficiario WHERE Nombre = 'Familia Guzman'),
 (SELECT ProyectoId     FROM core.Proyecto     WHERE Nombre = 'Agua Segura Chalatenango')),

((SELECT BeneficiarioId FROM core.Beneficiario WHERE Nombre = 'Familia Martinez'),
 (SELECT ProyectoId     FROM core.Proyecto     WHERE Nombre = 'Rehabilitacion de Pisos Santa Ana')),
((SELECT BeneficiarioId FROM core.Beneficiario WHERE Nombre = 'Familia Lopez'),
 (SELECT ProyectoId     FROM core.Proyecto     WHERE Nombre = 'Rehabilitacion de Pisos Santa Ana')),

((SELECT BeneficiarioId FROM core.Beneficiario WHERE Nombre = 'Familia Pineda'),
 (SELECT ProyectoId     FROM core.Proyecto     WHERE Nombre = 'Viviendas Transitorias Sonsonate')),
((SELECT BeneficiarioId FROM core.Beneficiario WHERE Nombre = 'Familia Alvarado'),
 (SELECT ProyectoId     FROM core.Proyecto     WHERE Nombre = 'Viviendas Transitorias Sonsonate')),

((SELECT BeneficiarioId FROM core.Beneficiario WHERE Nombre = 'Familia Aguilar'),
 (SELECT ProyectoId     FROM core.Proyecto     WHERE Nombre = 'Mejora de Viviendas San Salvador')),
((SELECT BeneficiarioId FROM core.Beneficiario WHERE Nombre = 'Familia Flores'),
 (SELECT ProyectoId     FROM core.Proyecto     WHERE Nombre = 'Mejora de Viviendas San Salvador')),
((SELECT BeneficiarioId FROM core.Beneficiario WHERE Nombre = 'Familia Barrera'),
 (SELECT ProyectoId     FROM core.Proyecto     WHERE Nombre = 'Mejora de Viviendas San Salvador')),

((SELECT BeneficiarioId FROM core.Beneficiario WHERE Nombre = 'Familia Chavez'),
 (SELECT ProyectoId     FROM core.Proyecto     WHERE Nombre = 'Viviendas Dignas Usulutan')),
((SELECT BeneficiarioId FROM core.Beneficiario WHERE Nombre = 'Familia Guardado'),
 (SELECT ProyectoId     FROM core.Proyecto     WHERE Nombre = 'Viviendas Dignas Usulutan')),

((SELECT BeneficiarioId FROM core.Beneficiario WHERE Nombre = 'Familia Delgado'),
 (SELECT ProyectoId     FROM core.Proyecto     WHERE Nombre = 'Mejoramiento Integral San Miguel')),
((SELECT BeneficiarioId FROM core.Beneficiario WHERE Nombre = 'Familia Vasquez'),
 (SELECT ProyectoId     FROM core.Proyecto     WHERE Nombre = 'Mejoramiento Integral San Miguel')),

((SELECT BeneficiarioId FROM core.Beneficiario WHERE Nombre = 'Familia Molina'),
 (SELECT ProyectoId     FROM core.Proyecto     WHERE Nombre = 'Proyecto Morazan Solidario')),
((SELECT BeneficiarioId FROM core.Beneficiario WHERE Nombre = 'Familia Rivera'),
 (SELECT ProyectoId     FROM core.Proyecto     WHERE Nombre = 'Proyecto Morazan Solidario')),

((SELECT BeneficiarioId FROM core.Beneficiario WHERE Nombre = 'Familia Quintanilla'),
 (SELECT ProyectoId     FROM core.Proyecto     WHERE Nombre = 'Proyecto Costero La Union')),
((SELECT BeneficiarioId FROM core.Beneficiario WHERE Nombre = 'Familia Lopez SRL'),
 (SELECT ProyectoId     FROM core.Proyecto     WHERE Nombre = 'Proyecto Costero La Union')),
((SELECT BeneficiarioId FROM core.Beneficiario WHERE Nombre = 'Familia Sorto'),
 (SELECT ProyectoId     FROM core.Proyecto     WHERE Nombre = 'Techo y Piso Cabanas')),
((SELECT BeneficiarioId FROM core.Beneficiario WHERE Nombre = 'Familia Fuentes'),
 (SELECT ProyectoId     FROM core.Proyecto     WHERE Nombre = 'Techo y Piso Cabanas'));
GO

------------------------------------------------------------
-- Financiamiento (Coherente con donaciones y proyectos)
------------------------------------------------------------
INSERT INTO core.Financiamiento (DonacionId, ProyectoId, Fecha, Desembolso) VALUES
-- Donacion 1: Super Selectos (5000, usado 3000)
(1, (SELECT ProyectoId FROM core.Proyecto WHERE Nombre = 'Techo Seguro Ahuachapan'),
 '2024-02-01', 1500.00),
(1, (SELECT ProyectoId FROM core.Proyecto WHERE Nombre = 'Rehabilitacion de Pisos Santa Ana'),
 '2024-02-10', 1000.00),
(1, (SELECT ProyectoId FROM core.Proyecto WHERE Nombre = 'Techo y Piso Cabanas'),
 '2024-02-20', 500.00),

-- Donacion 2: Tigo (4000, usado 2500)
(2, (SELECT ProyectoId FROM core.Proyecto WHERE Nombre = 'Agua Segura Chalatenango'),
 '2024-02-05', 1200.00),
(2, (SELECT ProyectoId FROM core.Proyecto WHERE Nombre = 'Viviendas Transitorias Sonsonate'),
 '2024-02-18', 800.00),
(2, (SELECT ProyectoId FROM core.Proyecto WHERE Nombre = 'Techo Seguro Ahuachapan'),
 '2024-02-25', 500.00),

-- Donacion 3: La Constancia (3500, usado 2000)
(3, (SELECT ProyectoId FROM core.Proyecto WHERE Nombre = 'Mejora de Viviendas San Salvador'),
 '2024-02-20', 1200.00),
(3, (SELECT ProyectoId FROM core.Proyecto WHERE Nombre = 'Agua Segura Chalatenango'),
 '2024-02-28', 800.00),

-- Donacion 4: El Volcan (2500, usado 1500)
(4, (SELECT ProyectoId FROM core.Proyecto WHERE Nombre = 'Rehabilitacion de Pisos Santa Ana'),
 '2024-03-05', 900.00),
(4, (SELECT ProyectoId FROM core.Proyecto WHERE Nombre = 'Techo y Piso Cabanas'),
 '2024-03-15', 600.00),

-- Donacion 5: Panaderia (1800, usado 800)
(5, (SELECT ProyectoId FROM core.Proyecto WHERE Nombre = 'Techo Seguro Ahuachapan'),
 '2024-03-10', 400.00),
(5, (SELECT ProyectoId FROM core.Proyecto WHERE Nombre = 'Agua Segura Chalatenango'),
 '2024-03-18', 400.00),

-- Donacion 6: Manos Unidas (4200, usado 3000)
(6, (SELECT ProyectoId FROM core.Proyecto WHERE Nombre = 'Proyecto Costero La Union'),
 '2024-03-25', 1500.00),
(6, (SELECT ProyectoId FROM core.Proyecto WHERE Nombre = 'Viviendas Dignas Usulutan'),
 '2024-04-02', 1000.00),
(6, (SELECT ProyectoId FROM core.Proyecto WHERE Nombre = 'Proyecto Morazan Solidario'),
 '2024-04-08', 500.00),

-- Donacion 7: Luz y Esperanza (3200, usado 2000)
(7, (SELECT ProyectoId FROM core.Proyecto WHERE Nombre = 'Viviendas Dignas Usulutan'),
 '2024-04-12', 1000.00),
(7, (SELECT ProyectoId FROM core.Proyecto WHERE Nombre = 'Mejoramiento Integral San Miguel'),
 '2024-04-20', 1000.00),

-- Donacion 8: Techo Digno (2800, usado 1500)
(8, (SELECT ProyectoId FROM core.Proyecto WHERE Nombre = 'Viviendas Transitorias Sonsonate'),
 '2024-04-25', 800.00),
(8, (SELECT ProyectoId FROM core.Proyecto WHERE Nombre = 'Proyecto Morazan Solidario'),
 '2024-05-01', 700.00),

-- Donacion 9: Carlos (1500, usado 700)
(9, (SELECT ProyectoId FROM core.Proyecto WHERE Nombre = 'Techo Seguro Ahuachapan'),
 '2024-05-05', 400.00),
(9, (SELECT ProyectoId FROM core.Proyecto WHERE Nombre = 'Rehabilitacion de Pisos Santa Ana'),
 '2024-05-10', 300.00),

-- Donacion 10: Karla (1700, usado 900)
(10, (SELECT ProyectoId FROM core.Proyecto WHERE Nombre = 'Mejora de Viviendas San Salvador'),
 '2024-05-12', 500.00),
(10, (SELECT ProyectoId FROM core.Proyecto WHERE Nombre = 'Agua Segura Chalatenango'),
 '2024-05-18', 400.00),

-- Donacion 11: Distribuidora San Miguel (3600, usado 2000)
(11, (SELECT ProyectoId FROM core.Proyecto WHERE Nombre = 'Mejoramiento Integral San Miguel'),
 '2024-05-22', 1200.00),
(11, (SELECT ProyectoId FROM core.Proyecto WHERE Nombre = 'Proyecto Costero La Union'),
 '2024-05-30', 800.00),

-- Donacion 12: Farmacia San Jose (3000, usado 1800)
(12, (SELECT ProyectoId FROM core.Proyecto WHERE Nombre = 'Techo y Piso Cabanas'),
 '2024-06-05', 900.00),
(12, (SELECT ProyectoId FROM core.Proyecto WHERE Nombre = 'Viviendas Dignas Usulutan'),
 '2024-06-12', 900.00);
GO

------------------------------------------------------------
-- DONACIONES DE JUNIO A DICIEMBRE 2024
------------------------------------------------------------

-- JUNIO 2024
INSERT INTO core.Donacion (Fecha, Monto, Usado, DonanteId, MetodoDonacionId, VoluntarioRegistroId)
VALUES
('2024-06-10', 3800.00, 2000.00,
 (SELECT DonanteId FROM core.Donante WHERE Nombre = 'Super Selectos S.A. de C.V.'),
 (SELECT MetodoId FROM cat.MetodoDonacion WHERE Nombre = 'Transferencia bancaria'),
 (SELECT VoluntarioId FROM core.Voluntario WHERE Nombre = 'Daniela Campos')),

('2024-06-25', 2400.00, 1200.00,
 (SELECT DonanteId FROM core.Donante WHERE Nombre = 'Fundacion Manos Unidas SV'),
 (SELECT MetodoId FROM cat.MetodoDonacion WHERE Nombre = 'Efectivo'),
 (SELECT VoluntarioId FROM core.Voluntario WHERE Nombre = 'Alejandra Rivera'));

-- JULIO 2024
INSERT INTO core.Donacion (Fecha, Monto, Usado, DonanteId, MetodoDonacionId, VoluntarioRegistroId)
VALUES
('2024-07-05', 4200.00, 2500.00,
 (SELECT DonanteId FROM core.Donante WHERE Nombre = 'Tigo El Salvador'),
 (SELECT MetodoId FROM cat.MetodoDonacion WHERE Nombre = 'Transferencia bancaria'),
 (SELECT VoluntarioId FROM core.Voluntario WHERE Nombre = 'Mario Molina')),

('2024-07-22', 3000.00, 1500.00,
 (SELECT DonanteId FROM core.Donante WHERE Nombre = 'Farmacia San Jose S.A. de C.V.'),
 (SELECT MetodoId FROM cat.MetodoDonacion WHERE Nombre = 'Cheque'),
 (SELECT VoluntarioId FROM core.Voluntario WHERE Nombre = 'Karla Martinez'));

-- AGOSTO 2024
INSERT INTO core.Donacion (Fecha, Monto, Usado, DonanteId, MetodoDonacionId, VoluntarioRegistroId)
VALUES
('2024-08-03', 3500.00, 1800.00,
 (SELECT DonanteId FROM core.Donante WHERE Nombre = 'Fundacion Luz y Esperanza'),
 (SELECT MetodoId FROM cat.MetodoDonacion WHERE Nombre = 'Transferencia bancaria'),
 (SELECT VoluntarioId FROM core.Voluntario WHERE Nombre = 'Oscar Rivera')),

('2024-08-19', 2500.00, 1200.00,
 (SELECT DonanteId FROM core.Donante WHERE Nombre = 'Ferreteria El Volcan'),
 (SELECT MetodoId FROM cat.MetodoDonacion WHERE Nombre = 'Efectivo'),
 (SELECT VoluntarioId FROM core.Voluntario WHERE Nombre = 'Luis Hernandez'));

-- SEPTIEMBRE 2024
INSERT INTO core.Donacion (Fecha, Monto, Usado, DonanteId, MetodoDonacionId, VoluntarioRegistroId)
VALUES
('2024-09-07', 3800.00, 2200.00,
 (SELECT DonanteId FROM core.Donante WHERE Nombre = 'Fundacion Techo Digno'),
 (SELECT MetodoId FROM cat.MetodoDonacion WHERE Nombre = 'Transferencia bancaria'),
 (SELECT VoluntarioId FROM core.Voluntario WHERE Nombre = 'Miguel Escobar')),

('2024-09-26', 2900.00, 1400.00,
 (SELECT DonanteId FROM core.Donante WHERE Nombre = 'Panaderia La Bendicion'),
 (SELECT MetodoId FROM cat.MetodoDonacion WHERE Nombre = 'Efectivo'),
 (SELECT VoluntarioId FROM core.Voluntario WHERE Nombre = 'Juan Sanchez'));

-- OCTUBRE 2024
INSERT INTO core.Donacion (Fecha, Monto, Usado, DonanteId, MetodoDonacionId, VoluntarioRegistroId)
VALUES
('2024-10-02', 4100.00, 2300.00,
 (SELECT DonanteId FROM core.Donante WHERE Nombre = 'Distribuidora San Miguel S.A. de C.V.'),
 (SELECT MetodoId FROM cat.MetodoDonacion WHERE Nombre = 'Cheque'),
 (SELECT VoluntarioId FROM core.Voluntario WHERE Nombre = 'Claudia Torres')),

('2024-10-21', 3300.00, 1500.00,
 (SELECT DonanteId FROM core.Donante WHERE Nombre = 'La Constancia S.A. de C.V.'),
 (SELECT MetodoId FROM cat.MetodoDonacion WHERE Nombre = 'Transferencia bancaria'),
 (SELECT VoluntarioId FROM core.Voluntario WHERE Nombre = 'Daniela Campos'));

-- NOVIEMBRE 2024
INSERT INTO core.Donacion (Fecha, Monto, Usado, DonanteId, MetodoDonacionId, VoluntarioRegistroId)
VALUES
('2024-11-06', 3600.00, 1800.00,
 (SELECT DonanteId FROM core.Donante WHERE Nombre = 'Karla Hernandez'),
 (SELECT MetodoId FROM cat.MetodoDonacion WHERE Nombre = 'Tarjeta de Credito'),
 (SELECT VoluntarioId FROM core.Voluntario WHERE Nombre = 'Jose Antonio Chavez')),

('2024-11-25', 2800.00, 1200.00,
 (SELECT DonanteId FROM core.Donante WHERE Nombre = 'Carlos Mejia'),
 (SELECT MetodoId FROM cat.MetodoDonacion WHERE Nombre = 'Tarjeta de Credito'),
 (SELECT VoluntarioId FROM core.Voluntario WHERE Nombre = 'Alejandra Rivera'));

-- DICIEMBRE 2024
INSERT INTO core.Donacion (Fecha, Monto, Usado, DonanteId, MetodoDonacionId, VoluntarioRegistroId)
VALUES
('2024-12-04', 4200.00, 2100.00,
 (SELECT DonanteId FROM core.Donante WHERE Nombre = 'Fundacion Manos Unidas SV'),
 (SELECT MetodoId FROM cat.MetodoDonacion WHERE Nombre = 'Transferencia bancaria'),
 (SELECT VoluntarioId FROM core.Voluntario WHERE Nombre = 'Mario Molina')),

('2024-12-20', 3100.00, 1500.00,
 (SELECT DonanteId FROM core.Donante WHERE Nombre = 'Fundacion Luz y Esperanza'),
 (SELECT MetodoId FROM cat.MetodoDonacion WHERE Nombre = 'Cheque'),
 (SELECT VoluntarioId FROM core.Voluntario WHERE Nombre = 'Karla Martinez'));
GO


------------------------------------------------------------
-- 6. Logins (en master)
------------------------------------------------------------
USE master;
GO

CREATE LOGIN login_admin_techosv
WITH PASSWORD = 'AdminFuerte#2025',
     CHECK_POLICY = OFF;

CREATE LOGIN login_coordinador
WITH PASSWORD = 'CoordFuerte#2025',
     CHECK_POLICY = OFF;

CREATE LOGIN login_registro
WITH PASSWORD = 'RegistroFuerte#2025',
     CHECK_POLICY = OFF;

CREATE LOGIN login_campo
WITH PASSWORD = 'CampoFuerte#2025',
     CHECK_POLICY = OFF;

CREATE LOGIN login_reportes
WITH PASSWORD = 'ReporteFuerte#2025',
     CHECK_POLICY = OFF;

CREATE LOGIN login_powerbi
WITH PASSWORD = 'PowerBI#2025',
     CHECK_POLICY = OFF;
GO
------------------------------------------------------------
-- 7. Usuarios en TECHOSV
------------------------------------------------------------
USE TECHOSV;
GO

CREATE USER usuario_admin_techosv
FOR LOGIN login_admin_techosv;

CREATE USER usuario_coordinador
FOR LOGIN login_coordinador;

CREATE USER usuario_registro
FOR LOGIN login_registro;

CREATE USER usuario_campo
FOR LOGIN login_campo;

CREATE USER usuario_powerbi 
FOR LOGIN login_powerbi;
GO


------------------------------------------------------------
-- 8. Roles
------------------------------------------------------------
CREATE ROLE rol_admin_techosv;
CREATE ROLE rol_coordinador_proyecto;
CREATE ROLE rol_registro_donacion;
CREATE ROLE rol_trabajo_campo;
CREATE ROLE rol_powerbi;

GO


------------------------------------------------------------
-- 9. Permisos por rol
------------------------------------------------------------

-- ADMIN (control total sobre cat y core)
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::cat  TO rol_admin_techosv;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::core TO rol_admin_techosv;



-- COORDINADOR DE PROYECTO

-- Lectura amplia
GRANT SELECT ON cat.Departamento         TO rol_coordinador_proyecto;
GRANT SELECT ON cat.Municipio            TO rol_coordinador_proyecto;
GRANT SELECT ON cat.Comunidad            TO rol_coordinador_proyecto;
GRANT SELECT ON cat.TipoDonante          TO rol_coordinador_proyecto;
GRANT SELECT ON cat.MetodoDonacion       TO rol_coordinador_proyecto;
GRANT SELECT ON cat.EstadoProyecto       TO rol_coordinador_proyecto;
GRANT SELECT ON core.Donante             TO rol_coordinador_proyecto;
GRANT SELECT ON core.Voluntario          TO rol_coordinador_proyecto;
GRANT SELECT ON core.Beneficiario        TO rol_coordinador_proyecto;
GRANT SELECT ON core.Proyecto            TO rol_coordinador_proyecto;
GRANT SELECT ON core.Donacion            TO rol_coordinador_proyecto;
GRANT SELECT ON core.BeneficiarioProyecto TO rol_coordinador_proyecto;
GRANT SELECT ON core.Financiamiento      TO rol_coordinador_proyecto;

-- Gestionar proyectos y asignaciones
GRANT INSERT, UPDATE ON core.Proyecto             TO rol_coordinador_proyecto;
GRANT INSERT, DELETE ON core.BeneficiarioProyecto TO rol_coordinador_proyecto;
GRANT INSERT, UPDATE, DELETE ON core.Financiamiento TO rol_coordinador_proyecto;



-- REGISTRO DE DONACIONES

-- Lectura de catálogos y contexto
GRANT SELECT ON cat.Departamento         TO rol_registro_donacion;
GRANT SELECT ON cat.Municipio            TO rol_registro_donacion;
GRANT SELECT ON cat.Comunidad            TO rol_registro_donacion;
GRANT SELECT ON cat.TipoDonante          TO rol_registro_donacion;
GRANT SELECT ON cat.MetodoDonacion       TO rol_registro_donacion;
GRANT SELECT ON cat.EstadoProyecto       TO rol_registro_donacion;
GRANT SELECT ON core.Proyecto            TO rol_registro_donacion;
GRANT SELECT ON core.Voluntario          TO rol_registro_donacion;
GRANT SELECT ON core.Financiamiento      TO rol_registro_donacion;
GRANT SELECT ON core.Beneficiario        TO rol_registro_donacion;
GRANT SELECT ON core.BeneficiarioProyecto TO rol_registro_donacion;

-- Puede editar donantes y donaciones
GRANT SELECT, INSERT, UPDATE ON core.Donante  TO rol_registro_donacion;
GRANT SELECT, INSERT, UPDATE ON core.Donacion TO rol_registro_donacion;  -- corregido nombre del rol



-- TRABAJO DE CAMPO

-- Necesitan contexto geográfico y proyectos
GRANT SELECT ON cat.Departamento TO rol_trabajo_campo;
GRANT SELECT ON cat.Municipio    TO rol_trabajo_campo;
GRANT SELECT ON cat.Comunidad    TO rol_trabajo_campo;
GRANT SELECT ON core.Proyecto    TO rol_trabajo_campo;

-- Registrar beneficiarios y asignarlos a proyectos
GRANT SELECT, INSERT, UPDATE ON core.Beneficiario        TO rol_trabajo_campo;
GRANT SELECT, INSERT ON core.BeneficiarioProyecto TO rol_trabajo_campo;



-- SOLO CONSULTA / REPORTES
GRANT SELECT ON cat.Departamento         TO rol_powerbi;
GRANT SELECT ON cat.Municipio            TO rol_powerbi;
GRANT SELECT ON cat.Comunidad            TO rol_powerbi;
GRANT SELECT ON cat.TipoDonante          TO rol_powerbi;
GRANT SELECT ON cat.MetodoDonacion       TO rol_powerbi;
GRANT SELECT ON cat.EstadoProyecto       TO rol_powerbi;
GRANT SELECT ON core.Donante              TO rol_powerbi;
GRANT SELECT ON core.Voluntario           TO rol_powerbi;
GRANT SELECT ON core.Beneficiario         TO rol_powerbi;
GRANT SELECT ON core.Proyecto             TO rol_powerbi;
GRANT SELECT ON core.Donacion             TO rol_powerbi;
GRANT SELECT ON core.BeneficiarioProyecto TO rol_powerbi;
GRANT SELECT ON core.Financiamiento       TO rol_powerbi;

------------------------------------------------------------
-- 10. Asignar usuarios a roles
------------------------------------------------------------

ALTER ROLE rol_admin_techosv
ADD MEMBER usuario_admin_techosv;

ALTER ROLE rol_coordinador_proyecto
ADD MEMBER usuario_coordinador;

ALTER ROLE rol_registro_donacion
ADD MEMBER usuario_registro;

ALTER ROLE rol_trabajo_campo
ADD MEMBER usuario_campo;

ALTER ROLE rol_powerbi 
ADD MEMBER usuario_powerbi;
GO

------------------------------------------------------------
-- TABLA GENERAL DE AUDITORÍA
------------------------------------------------------------
USE TECHOSV;
GO

CREATE TABLE seg.AuditoriaCambios (
    AuditoriaId INT IDENTITY(1,1) PRIMARY KEY,
    Tabla NVARCHAR(128) NOT NULL,        -- Nombre de la tabla auditada
    Operacion CHAR(1) NOT NULL,          -- I = Insert, U = Update, D = Delete
    ClavePrincipal NVARCHAR(200) NOT NULL, -- PK del registro afectado (en texto)
    ValoresAnteriores NVARCHAR(MAX) NULL, -- Estado antes del cambio
    ValoresNuevos NVARCHAR(MAX) NULL,     -- Estado después del cambio
    UsuarioSQL NVARCHAR(128) NOT NULL DEFAULT SUSER_SNAME(),
    Fecha DATETIME NOT NULL DEFAULT GETDATE(),
    Host NVARCHAR(128) NULL DEFAULT HOST_NAME()
);
GO

------------------------------------------------------------
-- TRIGGER DE AUDITORÍA: core.Donacion
------------------------------------------------------------

CREATE OR ALTER TRIGGER core.trg_Audit_Donacion   -- ? esquema core, no seg
ON core.Donacion
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO seg.AuditoriaCambios
        (Tabla, Operacion, ClavePrincipal, ValoresAnteriores, ValoresNuevos)
    SELECT
        'core.Donacion' AS Tabla,

        CASE 
            WHEN i.DonacionId IS NOT NULL AND d.DonacionId IS NULL THEN 'I'
            WHEN i.DonacionId IS NOT NULL AND d.DonacionId IS NOT NULL THEN 'U'
            WHEN i.DonacionId IS NULL AND d.DonacionId IS NOT NULL THEN 'D'
        END AS Operacion,

        CONVERT(NVARCHAR(200), COALESCE(i.DonacionId, d.DonacionId)) AS ClavePrincipal,

        -- JSON con valores ANTERIORES
        (
            SELECT 
                d.DonacionId,
                d.Fecha,
                d.Monto,
                d.Usado,
                d.Disponible,
                d.DonanteId,
                d.MetodoDonacionId,
                d.VoluntarioRegistroId
            WHERE d.DonacionId IS NOT NULL
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ) AS ValoresAnteriores,

        -- JSON con valores NUEVOS
        (
            SELECT 
                i.DonacionId,
                i.Fecha,
                i.Monto,
                i.Usado,
                i.Disponible,
                i.DonanteId,
                i.MetodoDonacionId,
                i.VoluntarioRegistroId
            WHERE i.DonacionId IS NOT NULL
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ) AS ValoresNuevos

    FROM inserted i
    FULL JOIN deleted d
        ON i.DonacionId = d.DonacionId;
END;
GO

------------------------------------------------------------
-- TRIGGER DE AUDITORÍA: core.Financiamiento
------------------------------------------------------------
CREATE OR ALTER TRIGGER core.trg_Audit_Financiamiento
ON core.Financiamiento
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO seg.AuditoriaCambios
        (Tabla, Operacion, ClavePrincipal, ValoresAnteriores, ValoresNuevos)
    SELECT
        'core.Financiamiento' AS Tabla,
        CASE 
            WHEN i.DonacionId IS NOT NULL AND d.DonacionId IS NULL THEN 'I'
            WHEN i.DonacionId IS NOT NULL AND d.DonacionId IS NOT NULL THEN 'U'
            WHEN i.DonacionId IS NULL AND d.DonacionId IS NOT NULL THEN 'D'
        END AS Operacion,

        CONCAT('DonacionId=', COALESCE(i.DonacionId, d.DonacionId),
               ';ProyectoId=', COALESCE(i.ProyectoId, d.ProyectoId)) AS ClavePrincipal,

        (
            SELECT 
                d.DonacionId,
                d.ProyectoId,
                d.Fecha,
                d.Desembolso
            WHERE d.DonacionId IS NOT NULL
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ) AS ValoresAnteriores,

        (
            SELECT 
                i.DonacionId,
                i.ProyectoId,
                i.Fecha,
                i.Desembolso
            WHERE i.DonacionId IS NOT NULL
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ) AS ValoresNuevos

    FROM inserted i
    FULL JOIN deleted d
        ON  i.DonacionId = d.DonacionId
        AND i.ProyectoId = d.ProyectoId;
END;
GO

------------------------------------------------------------
-- TRIGGER DE AUDITORÍA: core.Proyecto
------------------------------------------------------------
CREATE OR ALTER TRIGGER core.trg_Audit_Proyecto
ON core.Proyecto
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO seg.AuditoriaCambios
        (Tabla, Operacion, ClavePrincipal, ValoresAnteriores, ValoresNuevos)
    SELECT
        'core.Proyecto' AS Tabla,
        CASE 
            WHEN i.ProyectoId IS NOT NULL AND d.ProyectoId IS NULL THEN 'I'
            WHEN i.ProyectoId IS NOT NULL AND d.ProyectoId IS NOT NULL THEN 'U'
            WHEN i.ProyectoId IS NULL AND d.ProyectoId IS NOT NULL THEN 'D'
        END AS Operacion,

        CONVERT(NVARCHAR(200), COALESCE(i.ProyectoId, d.ProyectoId)) AS ClavePrincipal,

        (
            SELECT 
                d.ProyectoId,
                d.Nombre,
                d.FechaInicio,
                d.FechaFin,
                d.Descripcion,
                d.presupuesto,
                d.EstadoId,
                d.LiderVoluntarioId
            WHERE d.ProyectoId IS NOT NULL
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ) AS ValoresAnteriores,

        (
            SELECT 
                i.ProyectoId,
                i.Nombre,
                i.FechaInicio,
                i.FechaFin,
                i.Descripcion,
                i.presupuesto,
                i.EstadoId,
                i.LiderVoluntarioId
            WHERE i.ProyectoId IS NOT NULL
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ) AS ValoresNuevos

    FROM inserted i
    FULL JOIN deleted d
        ON i.ProyectoId = d.ProyectoId;
END;
GO

-- Historial de cambios de una donación específica
SELECT *
FROM seg.AuditoriaCambios
WHERE Tabla = 'core.Donacion'
  AND ClavePrincipal = '1'
ORDER BY Fecha DESC;
GO

-- Historial de cambios de un proyecto
SELECT *
FROM seg.AuditoriaCambios
WHERE Tabla = 'core.Proyecto'
  AND ClavePrincipal = '2'
ORDER BY Fecha DESC;
GO

-- Últimos 20 cambios en toda la BD
SELECT TOP 20 *
FROM seg.AuditoriaCambios
ORDER BY Fecha DESC;
GO

/*UPDATE core.Donacion
SET Usado = Usado + 50
WHERE DonacionId = 1;
SELECT * FROM core.Donante
SELECT * FROM cat.TipoDonante*/

UPDATE core.Donacion
SET Usado = 3000
WHERE DonacionId = 1;

------------------------------------------------------------
-- PLAN DE BACKUP
------------------------------------------------------------

ALTER DATABASE TECHOSV SET RECOVERY FULL;
GO

USE msdb;
GO
------------------------------------------------------------
-- BACKUP FULL
------------------------------------------------------------
-- 1. Crear Job
EXEC sp_add_job 
    @job_name = 'Backup_Full_TECHOSV';
GO

-- 2. Crear Step
EXEC sp_add_jobstep
    @job_name = 'Backup_Full_TECHOSV',
    @step_name = 'STEP_Backup_Full',
    @subsystem = 'TSQL',
    @command = '
        BACKUP DATABASE TECHOSV
        TO DISK = ''C:\Backups\TECHOSV_Full.bak''
        WITH INIT, COMPRESSION;',
    @retry_attempts = 3,
    @retry_interval = 5;
GO

-- 3. Crear Schedule
EXEC sp_add_schedule
    @schedule_name = 'SCH_Backup_Full_Semanal',
    @freq_type = 8,                 -- semanal
    @freq_interval = 1,             -- domingo
    @freq_recurrence_factor = 1,    -- cada 1 semana
    @active_start_time = 020000;    -- 02:00 AM
GO

-- 4. Adjuntar schedule al job
EXEC sp_attach_schedule
    @job_name = 'Backup_Full_TECHOSV',
    @schedule_name = 'SCH_Backup_Full_Semanal';
GO

-- 5. Asignar al SQL Agent
EXEC sp_add_jobserver
    @job_name = 'Backup_Full_TECHOSV';
GO

------------------------------------------------------------
-- BACKUP DIFERENCIAL
------------------------------------------------------------

-- 1. Crear job para backup diferencial
EXEC sp_add_job 
    @job_name = 'Backup_Diferencial_TECHOSV';
GO

-- 2. Crear step del job diferencial
EXEC sp_add_jobstep
    @job_name = 'Backup_Diferencial_TECHOSV',
    @step_name = 'STEP_Backup_Diferencial',
    @subsystem = 'TSQL',
    @command = '
        BACKUP DATABASE TECHOSV
        TO DISK = ''C:\Backups\TECHOSV_Diferencial.bak''
        WITH DIFFERENTIAL, COMPRESSION;',
    @retry_attempts = 3,
    @retry_interval = 5;
GO
-- 3. Crear Schedule
EXEC sp_add_schedule
    @schedule_name = 'Backup_Diario',
    @freq_type = 4,               -- diario
    @freq_interval = 1,           -- cada 1 día (todos los días)
    @active_start_time = 020000;  -- 02:00 AM
GO

-- (4) Asociar el schedule al job
EXEC sp_attach_schedule
    @job_name = 'Backup_Diferencial_TECHOSV',
    @schedule_name = 'Backup_Diario';
GO

-- (5) Asignar el job al servidor (SQL Agent)
EXEC sp_add_jobserver
    @job_name = 'Backup_Diferencial_TECHOSV';
GO

------------------------------------------------------------
-- BACKUP LOG cada hora
------------------------------------------------------------

-- (1) Crear el job
EXEC sp_add_job 
    @job_name = 'Backup_Log_TECHOSV';
GO

-- (2) Crear el step del job
EXEC sp_add_jobstep
    @job_name = 'Backup_Log_TECHOSV',
    @step_name = 'STEP_Backup_Log',
    @subsystem = 'TSQL',
    @command = '
        BACKUP LOG TECHOSV
        TO DISK = ''C:\Backups\TECHOSV_Log.trn''
        WITH COMPRESSION;',
    @retry_attempts = 3,
    @retry_interval = 5;
GO

-- (3) Crear el schedule (DIARIO, cada 1 hora)

EXEC sp_add_schedule
    @schedule_name = 'Backup_Log_Horario',
    @freq_type = 4,                 -- diario
    @freq_interval = 1,             -- todos los días
    @freq_subday_type = 8,          -- cada X horas
    @freq_subday_interval = 1,      -- cada 1 hora
    @active_start_time = 000000;    -- 00:00
GO

-- (4) Asociar el schedule al job
EXEC sp_attach_schedule
    @job_name = 'Backup_Log_TECHOSV',
    @schedule_name = 'Backup_Log_Horario';
GO
	
-- (5) Asignar el job al servidor (SQL Agent)
EXEC sp_add_jobserver
    @job_name = 'Backup_Log_TECHOSV';
GO



------------------------------------------------------------
-- Rendimiento (consultas avanzadas + funciones ventana + índices)
------------------------------------------------------------

--Indices
USE TECHOSV;
GO

------------------------------------------------------------
-- ÍNDICES SOBRE CLAVES FORÁNEAS Y CAMPOS DE CONSULTA
------------------------------------------------------------

-- Donación: búsquedas por Donante, Método y fecha
CREATE INDEX IX_Donacion_DonanteId
ON core.Donacion (DonanteId);

CREATE INDEX IX_Donacion_MetodoDonacionId
ON core.Donacion (MetodoDonacionId);

CREATE INDEX IX_Donacion_Fecha
ON core.Donacion (Fecha);

-- Financiamiento: usado para sumar por proyecto y por fecha
CREATE INDEX IX_Financiamiento_ProyectoId
ON core.Financiamiento (ProyectoId);

CREATE INDEX IX_Financiamiento_Fecha
ON core.Financiamiento (Fecha);

-- Proyecto: por estado (Planificado / En ejecucion / Finalizado)
CREATE INDEX IX_Proyecto_EstadoId
ON core.Proyecto (EstadoId);

-- BeneficiarioProyecto: búsquedas por proyecto
CREATE INDEX IX_BeneficiarioProyecto_ProyectoId
ON core.BeneficiarioProyecto (ProyectoId);

-- Beneficiario: búsquedas por comunidad (reportes territoriales)
CREATE INDEX IX_Beneficiario_Comunidad
ON core.Beneficiario (FK_Comunidad);
GO

--Consultas avanzadas:
--1.
WITH CTE_ProyectoFinanciamiento AS (
    SELECT 
        p.ProyectoId,
        p.Nombre,
        p.presupuesto,
        SUM(f.Desembolso) AS TotalDesembolsado
    FROM core.Proyecto p
    LEFT JOIN core.Financiamiento f
        ON p.ProyectoId = f.ProyectoId
    GROUP BY p.ProyectoId, p.Nombre, p.presupuesto
)
SELECT
    ProyectoId,
    Nombre,
    presupuesto AS Presupuesto,
    TotalDesembolsado,
    (TotalDesembolsado / NULLIF(presupuesto,0)) * 100 AS PorcentajeEjecucion,
    RANK() OVER (ORDER BY TotalDesembolsado DESC) AS RankingPorEjecucion
FROM CTE_ProyectoFinanciamiento
ORDER BY RankingPorEjecucion;

--2.
WITH CTE_Donaciones AS (
    SELECT
        d.DonanteId,
        dn.Nombre AS NombreDonante,
        d.DonacionId,
        d.Fecha,
        d.Monto,
        SUM(d.Monto) OVER (
            PARTITION BY d.DonanteId
            ORDER BY d.Fecha
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS MontoAcumulado,
        SUM(d.Monto) OVER (
            PARTITION BY d.DonanteId
        ) AS TotalPorDonante
    FROM core.Donacion d
    JOIN core.Donante dn
        ON dn.DonanteId = d.DonanteId
)
SELECT
    DonanteId,
    NombreDonante,
    DonacionId,
    Fecha,
    Monto,
    MontoAcumulado,
    TotalPorDonante,
    DENSE_RANK() OVER (ORDER BY TotalPorDonante DESC) AS RankingDonante
FROM CTE_Donaciones
ORDER BY DonanteId, Fecha;

--3.
WITH CTE_FondosDepartamento AS (
    SELECT
        dpto.nombre AS Departamento,
        SUM(f.Desembolso) AS TotalDepartamento
    FROM core.Financiamiento f
    JOIN core.Proyecto p
        ON f.ProyectoId = p.ProyectoId
    JOIN core.BeneficiarioProyecto bp
        ON p.ProyectoId = bp.ProyectoId
    JOIN core.Beneficiario b
        ON bp.BeneficiarioId = b.BeneficiarioId
    JOIN cat.Comunidad c
        ON b.FK_Comunidad = c.comunidadId
    JOIN cat.Municipio mun
        ON c.FK_municipio = mun.municipioId
    JOIN cat.Departamento dpto
        ON mun.FK_departamento = dpto.departamentoId
    GROUP BY dpto.nombre
)
SELECT
    Departamento,
    TotalDepartamento,
    SUM(TotalDepartamento) OVER () AS TotalGlobal,
    (TotalDepartamento / NULLIF(SUM(TotalDepartamento) OVER (),0)) * 100 
        AS PorcentajeSobreTotal
FROM CTE_FondosDepartamento
ORDER BY PorcentajeSobreTotal DESC;



USE TECHOSV;
GO

ALTER TABLE core.Proyecto
ADD FK_Comunidad INT NULL;
GO

--------------------------------------------------------
-- ASIGNAR PROYECTOS A COMUNIDADES REALES
--------------------------------------------------------

-- Proyectos del SQL original
UPDATE core.Proyecto SET FK_Comunidad = 2 WHERE Nombre = 'SCALL';   -- Usa Tepecoyo
UPDATE core.Proyecto SET FK_Comunidad = 3 WHERE Nombre = 'Vivienda permanente';
UPDATE core.Proyecto SET FK_Comunidad = 4 WHERE Nombre = 'Levantamiento de perfiles';
UPDATE core.Proyecto SET FK_Comunidad = 5 WHERE Nombre = 'Vivienda de riesgo';

UPDATE core.Proyecto SET FK_Comunidad = 1 WHERE Nombre = 'Techo Seguro Ahuachapan';
UPDATE core.Proyecto SET FK_Comunidad = 2 WHERE Nombre = 'Agua Segura Chalatenango';
UPDATE core.Proyecto SET FK_Comunidad = 3 WHERE Nombre = 'Viviendas Transitorias Sonsonate';
UPDATE core.Proyecto SET FK_Comunidad = 4 WHERE Nombre = 'Rehabilitacion de Pisos Santa Ana';
UPDATE core.Proyecto SET FK_Comunidad = 5 WHERE Nombre = 'Proyecto Costero La Union';
UPDATE core.Proyecto SET FK_Comunidad = 3 WHERE Nombre = 'Proyecto Morazan Solidario';
UPDATE core.Proyecto SET FK_Comunidad = 1 WHERE Nombre = 'Mejora de Viviendas San Salvador';
UPDATE core.Proyecto SET FK_Comunidad = 4 WHERE Nombre = 'Viviendas Dignas Usulutan';
UPDATE core.Proyecto SET FK_Comunidad = 2 WHERE Nombre = 'Techo y Piso Cabanas';
UPDATE core.Proyecto SET FK_Comunidad = 5 WHERE Nombre = 'Mejoramiento Integral San Miguel';

--------------------------------------------------------
-- Verifica que TODOS los proyectos quedaron asignados
--------------------------------------------------------
SELECT ProyectoId, Nombre, FK_Comunidad
FROM core.Proyecto;

ALTER TABLE core.Proyecto
ADD CONSTRAINT FK_Proyecto_Comunidad
    FOREIGN KEY (FK_Comunidad)
    REFERENCES cat.Comunidad(comunidadId);
GO


SELECT ProyectoId, Nombre, FK_Comunidad
FROM core.Proyecto;

SELECT EstadoId, COUNT(*) AS Cantidad
FROM core.Proyecto
GROUP BY EstadoId;

------------------------------------------------------------
--  FINANCIAMIENTOS COMPLETOS PARA TODAS LAS DONACIONES
--  (DonacionId 13 AL 26)
------------------------------------------------------------

-----------------------------
--  JUNIO 2024
-----------------------------

-- Donación 13 (Usado = 2000)
INSERT INTO core.Financiamiento (DonacionId, ProyectoId, Fecha, Desembolso)
VALUES
(13, 1, '2024-06-12', 1200),
(13, 3, '2024-06-22', 800);

-- Donación 14 (Usado = 1200)
INSERT INTO core.Financiamiento (DonacionId, ProyectoId, Fecha, Desembolso)
VALUES
(14, 2, '2024-06-18', 600),
(14, 4, '2024-06-27', 600);


-----------------------------
--  JULIO 2024
-----------------------------

-- Donación 15 (Usado = 2500)
INSERT INTO core.Financiamiento (DonacionId, ProyectoId, Fecha, Desembolso)
VALUES
(15, 2, '2024-07-08', 1500),
(15, 4, '2024-07-20', 1000);


-----------------------------
--  AGOSTO 2024
-----------------------------

-- Donación 16 (Usado = 1500)
INSERT INTO core.Financiamiento (DonacionId, ProyectoId, Fecha, Desembolso)
VALUES
(16, 1, '2024-08-05', 800),
(16, 3, '2024-08-21', 700);


-----------------------------
--  SEPTIEMBRE 2024
-----------------------------

-- Donación 17 (Usado = 1800)
INSERT INTO core.Financiamiento (DonacionId, ProyectoId, Fecha, Desembolso)
VALUES
(17, 5, '2024-09-10', 1000),
(17, 2, '2024-09-25', 800);


-----------------------------
--  OCTUBRE 2024
-----------------------------

-- Donación 18 (Usado = 1200)
INSERT INTO core.Financiamiento (DonacionId, ProyectoId, Fecha, Desembolso)
VALUES
(18, 3, '2024-10-07', 600),
(18, 1, '2024-10-19', 600);


-----------------------------
--  MAYO 2024 (Caso especial)
-----------------------------

-- Donación 19 (Usado = 2200)
INSERT INTO core.Financiamiento (DonacionId, ProyectoId, Fecha, Desembolso)
VALUES
(19, 4, '2024-05-12', 1200),
(19, 5, '2024-05-26', 1000);


-----------------------------
--  ABRIL 2024
-----------------------------

-- Donación 20 (Usado = 1400)
INSERT INTO core.Financiamiento (DonacionId, ProyectoId, Fecha, Desembolso)
VALUES
(20, 2, '2024-04-08', 700),
(20, 3, '2024-04-22', 700);


-----------------------------
--  MARZO 2024
-----------------------------

-- Donación 21 (Usado = 2300)
INSERT INTO core.Financiamiento (DonacionId, ProyectoId, Fecha, Desembolso)
VALUES
(21, 1, '2024-03-14', 1200),
(21, 4, '2024-03-28', 1100);


-----------------------------
--  FEBRERO 2024
-----------------------------

-- Donación 22 (Usado = 1500)
INSERT INTO core.Financiamiento (DonacionId, ProyectoId, Fecha, Desembolso)
VALUES
(22, 5, '2024-02-11', 800),
(22, 2, '2024-02-24', 700);


-----------------------------
--  NOVIEMBRE 2024
-----------------------------

-- Donación 23 (Usado = 1800)
INSERT INTO core.Financiamiento (DonacionId, ProyectoId, Fecha, Desembolso)
VALUES
(23, 5, '2024-11-09', 1000),
(23, 7, '2024-11-20', 800);

-- Donación 24 (Usado = 1200)
INSERT INTO core.Financiamiento (DonacionId, ProyectoId, Fecha, Desembolso)
VALUES
(24, 1, '2024-11-14', 600),
(24, 3, '2024-11-28', 600);


-----------------------------
--  DICIEMBRE 2024
-----------------------------

-- Donación 25 (Usado = 2100)
INSERT INTO core.Financiamiento (DonacionId, ProyectoId, Fecha, Desembolso)
VALUES
(25, 4, '2024-12-06', 1100),
(25, 2, '2024-12-19', 1000);

-- Donación 26 (Usado = 1500)
INSERT INTO core.Financiamiento (DonacionId, ProyectoId, Fecha, Desembolso)
VALUES
(26, 3, '2024-12-10', 800),
(26, 5, '2024-12-22', 700);

SELECT d.DonacionId,
       d.Monto,
       d.Usado,
       SUM(f.Desembolso) AS TotalDesembolsado
FROM core.Donacion d
LEFT JOIN core.Financiamiento f ON d.DonacionId = f.DonacionId
GROUP BY d.DonacionId, d.Monto, d.Usado
ORDER BY d.DonacionId;

------------------------------------------------------------
--  VERIFICACIÓN FINAL
------------------------------------------------------------

SELECT d.DonacionId,
       d.Monto,
       d.Usado,
       SUM(f.Desembolso) AS TotalDesembolsado
FROM core.Donacion d
LEFT JOIN core.Financiamiento f ON d.DonacionId = f.DonacionId
GROUP BY d.DonacionId, d.Monto, d.Usado
ORDER BY d.DonacionId;