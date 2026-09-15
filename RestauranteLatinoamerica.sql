CREATE DATABASE RestauranteLatinoamericaReservas;
GO


USE RestauranteLatinoamericaReservas;
GO

CREATE TABLE dbo.EstadoReserva (
    EstadoReservaId  TINYINT       NOT NULL PRIMARY KEY,
    Nombre           VARCHAR(20)   NOT NULL UNIQUE,
    EsActiva         BIT           NOT NULL,
    Descripcion      VARCHAR(150)  NULL
);
GO

CREATE TABLE dbo.Rol (
    RolId   TINYINT     NOT NULL PRIMARY KEY,
    Nombre  VARCHAR(30) NOT NULL UNIQUE
);
GO

CREATE TABLE dbo.ParametroSistema (
    Clave        VARCHAR(50)    NOT NULL PRIMARY KEY,
    Valor        VARCHAR(100)   NOT NULL,
    Descripcion  VARCHAR(200)   NULL
);
GO

CREATE TABLE dbo.Usuario (
    UsuarioId      INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    NombreCompleto VARCHAR(120)      NOT NULL,
    NombreUsuario  VARCHAR(50)       NOT NULL UNIQUE,
    HashContrasena VARBINARY(256)    NOT NULL,
    RolId          TINYINT           NOT NULL,
    Activo         BIT               NOT NULL CONSTRAINT DF_Usuario_Activo DEFAULT (1),
    FechaCreacion  DATETIME2(0)      NOT NULL CONSTRAINT DF_Usuario_Fecha  DEFAULT (SYSDATETIME()),
    CONSTRAINT FK_Usuario_Rol FOREIGN KEY (RolId) REFERENCES dbo.Rol(RolId)
);
GO

CREATE TABLE dbo.Cliente (
    ClienteId       INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Nombre          VARCHAR(80)       NOT NULL,
    Apellido        VARCHAR(80)       NULL,
    Telefono        VARCHAR(20)       NULL,
    Email           VARCHAR(120)      NULL,
    Documento       VARCHAR(20)       NULL,
    Notas           VARCHAR(300)      NULL,
    Activo          BIT               NOT NULL CONSTRAINT DF_Cliente_Activo DEFAULT (1),
    FechaRegistro   DATETIME2(0)      NOT NULL CONSTRAINT DF_Cliente_Fecha  DEFAULT (SYSDATETIME()),
    CONSTRAINT CK_Cliente_Contacto CHECK (Telefono IS NOT NULL OR Email IS NOT NULL),
    CONSTRAINT CK_Cliente_Nombre   CHECK (LEN(LTRIM(RTRIM(Nombre))) > 0)
);
GO

CREATE TABLE dbo.Mesa (
    MesaId       INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    NumeroMesa   VARCHAR(10)       NOT NULL UNIQUE,
    Capacidad    TINYINT           NOT NULL,
    Ubicacion    VARCHAR(40)       NULL,
    Activa       BIT               NOT NULL CONSTRAINT DF_Mesa_Activa DEFAULT (1),
    CONSTRAINT CK_Mesa_Capacidad CHECK (Capacidad BETWEEN 1 AND 30)
);
GO

CREATE TABLE dbo.Reserva (
    ReservaId          INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    CodigoReserva      AS ('R-' + RIGHT('000000' + CAST(ReservaId AS VARCHAR(6)), 6)) PERSISTED,
    ClienteId          INT           NOT NULL,
    FechaReserva       DATE          NOT NULL,
    HoraInicio         TIME(0)       NOT NULL,
    DuracionMinutos    SMALLINT      NOT NULL CONSTRAINT DF_Reserva_Duracion DEFAULT (90),
    HoraFin            AS (DATEADD(MINUTE, DuracionMinutos, HoraInicio)) PERSISTED,
    CantidadPersonas   TINYINT       NOT NULL,
    EstadoReservaId    TINYINT       NOT NULL CONSTRAINT DF_Reserva_Estado DEFAULT (1),
    Observaciones      VARCHAR(300)  NULL,
    CreadaPorUsuario   INT           NULL,
    FechaCreacion      DATETIME2(0)  NOT NULL CONSTRAINT DF_Reserva_FCrea DEFAULT (SYSDATETIME()),
    FechaActualizacion DATETIME2(0)  NULL,
    CONSTRAINT FK_Reserva_Cliente FOREIGN KEY (ClienteId)        REFERENCES dbo.Cliente(ClienteId),
    CONSTRAINT FK_Reserva_Estado  FOREIGN KEY (EstadoReservaId)  REFERENCES dbo.EstadoReserva(EstadoReservaId),
    CONSTRAINT FK_Reserva_Usuario FOREIGN KEY (CreadaPorUsuario) REFERENCES dbo.Usuario(UsuarioId),
    CONSTRAINT CK_Reserva_Personas CHECK (CantidadPersonas BETWEEN 1 AND 30),
    CONSTRAINT CK_Reserva_Duracion CHECK (DuracionMinutos BETWEEN 30 AND 300)
);
GO

CREATE TABLE dbo.ReservaMesa (
    ReservaId       INT          NOT NULL,
    MesaId          INT          NOT NULL,
    FechaAsignacion DATETIME2(0) NOT NULL CONSTRAINT DF_ReservaMesa_Fecha DEFAULT (SYSDATETIME()),
    CONSTRAINT PK_ReservaMesa PRIMARY KEY (ReservaId, MesaId),
    CONSTRAINT FK_ReservaMesa_Reserva FOREIGN KEY (ReservaId) REFERENCES dbo.Reserva(ReservaId) ON DELETE CASCADE,
    CONSTRAINT FK_ReservaMesa_Mesa    FOREIGN KEY (MesaId)    REFERENCES dbo.Mesa(MesaId)
);
GO

CREATE TABLE dbo.ReservaHistorial (
    HistorialId     INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ReservaId       INT          NOT NULL,
    EstadoAnterior  TINYINT      NULL,
    EstadoNuevo     TINYINT      NOT NULL,
    UsuarioId       INT          NULL,
    Motivo          VARCHAR(200) NULL,
    FechaCambio     DATETIME2(0) NOT NULL CONSTRAINT DF_Hist_Fecha DEFAULT (SYSDATETIME()),
    CONSTRAINT FK_Hist_Reserva FOREIGN KEY (ReservaId) REFERENCES dbo.Reserva(ReservaId) ON DELETE CASCADE,
    CONSTRAINT FK_Hist_Usuario FOREIGN KEY (UsuarioId) REFERENCES dbo.Usuario(UsuarioId)
);
GO

CREATE TABLE dbo.Recargo (
    RecargoId       INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ReservaId       INT           NOT NULL,
    ClienteId       INT           NOT NULL,
    Monto           DECIMAL(12,2) NOT NULL,
    Motivo          VARCHAR(100)  NOT NULL CONSTRAINT DF_Recargo_Motivo DEFAULT ('Inasistencia a la reserva'),
    Estado          VARCHAR(15)   NOT NULL CONSTRAINT DF_Recargo_Estado DEFAULT ('Pendiente'),
    FechaGeneracion DATETIME2(0)  NOT NULL CONSTRAINT DF_Recargo_Fecha  DEFAULT (SYSDATETIME()),
    CONSTRAINT FK_Recargo_Reserva FOREIGN KEY (ReservaId) REFERENCES dbo.Reserva(ReservaId),
    CONSTRAINT FK_Recargo_Cliente FOREIGN KEY (ClienteId) REFERENCES dbo.Cliente(ClienteId),
    CONSTRAINT UQ_Recargo_Reserva UNIQUE (ReservaId),
    CONSTRAINT CK_Recargo_Monto   CHECK (Monto >= 0),
    CONSTRAINT CK_Recargo_Estado  CHECK (Estado IN ('Pendiente','Condonado'))
);
GO

CREATE UNIQUE INDEX UX_Cliente_Telefono  ON dbo.Cliente(Telefono)  WHERE Telefono  IS NOT NULL;
CREATE UNIQUE INDEX UX_Cliente_Documento ON dbo.Cliente(Documento) WHERE Documento IS NOT NULL;
CREATE INDEX IX_Cliente_Nombre ON dbo.Cliente(Nombre, Apellido);
CREATE INDEX IX_Mesa_Capacidad ON dbo.Mesa(Capacidad, Activa);

CREATE INDEX IX_Reserva_FechaHora ON dbo.Reserva(FechaReserva, HoraInicio) INCLUDE (EstadoReservaId, ClienteId);
CREATE INDEX IX_Reserva_Cliente   ON dbo.Reserva(ClienteId, FechaReserva DESC);
CREATE INDEX IX_Reserva_Estado    ON dbo.Reserva(EstadoReservaId, FechaReserva);

CREATE INDEX IX_ReservaMesa_Mesa ON dbo.ReservaMesa(MesaId, ReservaId);
CREATE INDEX IX_Hist_Reserva     ON dbo.ReservaHistorial(ReservaId, FechaCambio DESC);
CREATE INDEX IX_Recargo_Cliente  ON dbo.Recargo(ClienteId, FechaGeneracion DESC);
GO


INSERT INTO dbo.EstadoReserva (EstadoReservaId, Nombre, EsActiva, Descripcion) VALUES
    (1, 'Pendiente',  1, 'Creada, aún sin confirmar'),
    (2, 'Confirmada', 1, 'Confirmada por el cliente o la recepcionista'),
    (3, 'Cumplida',   0, 'El cliente asistió'),
    (4, 'Cancelada',  0, 'Cancelada antes de la hora'),
    (5, 'NoAsistio',  0, 'El cliente no se presentó: genera recargo');
GO

INSERT INTO dbo.Rol (RolId, Nombre) VALUES
    (1, 'Administrador'),
    (2, 'Recepcionista'),
    (3, 'Cliente');
GO

INSERT INTO dbo.ParametroSistema (Clave, Valor, Descripcion) VALUES
    ('RECARGO_INASISTENCIA',  '50000', 'CF-27: recargo automático por no asistir'),
    ('DURACION_RESERVA_MIN',  '90',    'Duración estándar de una reserva en minutos'),
    ('HORA_APERTURA',         '11:00', 'Hora de apertura del restaurante'),
    ('HORA_CIERRE',           '23:00', 'Hora de cierre del restaurante'),
    ('MIN_RESERVAS_FRECUENTE','3',     'CF-33: reservas cumplidas para ser cliente frecuente');
GO

INSERT INTO dbo.Usuario (NombreCompleto, NombreUsuario, HashContrasena, RolId) VALUES
    ('Admin General',   'admin',   HASHBYTES('SHA2_256', 'Admin123*'), 1),
    ('Laura Gómez',     'lgomez',  HASHBYTES('SHA2_256', 'Recep123*'), 2),
    ('Andrés Castaño',  'acastano',HASHBYTES('SHA2_256', 'Recep456*'), 2);
GO

INSERT INTO dbo.Mesa (NumeroMesa, Capacidad, Ubicacion, Activa) VALUES
    ('M-01', 2,  'Salón',   1),
    ('M-02', 2,  'Salón',   1),
    ('M-03', 4,  'Salón',   1),
    ('M-04', 4,  'Terraza', 1),
    ('M-05', 4,  'Terraza', 1),
    ('M-06', 6,  'Terraza', 1),
    ('M-07', 8,  'Privado', 1),
    ('M-08', 10, 'Privado', 1),
    ('M-09', 4,  'Salón',   1);   
GO

INSERT INTO dbo.Cliente (Nombre, Apellido, Telefono, Email, Documento, Activo) VALUES
    ('Juan',   'Pérez',   '3001112233', 'juan@mail.com',  '1017234567', 1),  -- 1
    ('Ana',    'Torres',  '3004445566', 'ana@mail.com',   '1020987654', 1),  -- 2
    ('Carlos', 'Ramírez', '3007778899', NULL,             NULL,         1),  -- 3
    ('Lucía',  'Mendoza', NULL,         'lucia@mail.com', NULL,         1),  -- 4
    ('Pedro',  'Gómez',   '3001234500', 'pedro@mail.com', NULL,         1),  -- 5
    ('Sofía',  'Vargas',  '3009876500', 'sofia@mail.com', NULL,         0);  -- 6 inactivo
GO

INSERT INTO dbo.Reserva (ClienteId, FechaReserva, HoraInicio, DuracionMinutos,
                         CantidadPersonas, EstadoReservaId, CreadaPorUsuario, Observaciones) VALUES
    -- 1: mañana 19:00-20:30, confirmada
    (1, DATEADD(DAY, 1, CAST(GETDATE() AS DATE)), '19:00', 90, 4, 2, 2, 'Cumpleaños'),
    -- 2: mañana 20:00-21:30, confirmada
    (2, DATEADD(DAY, 1, CAST(GETDATE() AS DATE)), '20:00', 90, 6, 2, 2, NULL),
    -- 3: pasado mañana 13:00-14:30, pendiente
    (3, DATEADD(DAY, 2, CAST(GETDATE() AS DATE)), '13:00', 90, 2, 1, NULL, NULL),
    -- 4 a 7: historial cumplido de Ana (cliente frecuente, CF-33)
    (2, DATEADD(DAY,  -7, CAST(GETDATE() AS DATE)), '19:30', 90, 2, 3, 2, NULL),
    (2, DATEADD(DAY, -14, CAST(GETDATE() AS DATE)), '19:30', 90, 2, 3, 2, NULL),
    (2, DATEADD(DAY, -21, CAST(GETDATE() AS DATE)), '20:00', 90, 4, 3, 3, NULL),
    (2, DATEADD(DAY, -28, CAST(GETDATE() AS DATE)), '12:30', 90, 2, 3, 3, NULL),
    -- 8 y 9: inasistencias de Pedro (CF-26, CF-27)
    (5, DATEADD(DAY, -10, CAST(GETDATE() AS DATE)), '20:00', 90, 4, 5, 2, NULL),
    (5, DATEADD(DAY, -20, CAST(GETDATE() AS DATE)), '21:00', 90, 4, 5, 3, NULL),
    -- 10: cancelada (no bloquea la mesa)
    (1, DATEADD(DAY,  -5, CAST(GETDATE() AS DATE)), '19:00', 90, 2, 4, 2, 'Cliente canceló');
GO

INSERT INTO dbo.ReservaMesa (ReservaId, MesaId) VALUES
    (1, 3),
    (2, 6),
    (3, 1),
    (4, 1),
    (5, 1),
    (6, 3),
    (7, 2),
    (8, 4),
    (9, 4),
    (10, 2);

INSERT INTO dbo.Recargo (ReservaId, ClienteId, Monto, Motivo, Estado) VALUES
    (8, 5, 50000, 'Inasistencia a la reserva', 'Pendiente'),
    (9, 5, 50000, 'Inasistencia a la reserva', 'Pendiente');
GO

INSERT INTO dbo.ReservaHistorial (ReservaId, EstadoAnterior, EstadoNuevo, UsuarioId, Motivo) VALUES
    (1,  NULL, 2, 2, 'Creación de la reserva'),
    (2,  NULL, 2, 2, 'Creación de la reserva'),
    (3,  NULL, 1, NULL, 'Creada por el cliente'),
    (8,  2,    5, 2, 'El cliente no se presentó'),
    (9,  2,    5, 3, 'El cliente no se presentó'),
    (10, 2,    4, 2, 'Cancelación solicitada por el cliente');
GO
/* ----------  Funciones ---------- */
/* ----------  CF-12: mesas disponibles por fecha, hora y cantidad ---------- */

CREATE OR ALTER FUNCTION dbo.fn_MesasDisponibles
(
    @Fecha            DATE,
    @HoraInicio       TIME(0),
    @CantidadPersonas TINYINT,
    @DuracionMinutos  SMALLINT,
    @ReservaIdExcluir INT = NULL
)
RETURNS TABLE
AS
RETURN
(
    SELECT m.MesaId, m.NumeroMesa, m.Capacidad, m.Ubicacion
    FROM dbo.Mesa m
    WHERE m.Activa = 1
      AND m.Capacidad >= @CantidadPersonas
      AND NOT EXISTS (
            SELECT 1
            FROM dbo.ReservaMesa rm
            INNER JOIN dbo.Reserva r       ON r.ReservaId = rm.ReservaId
            INNER JOIN dbo.EstadoReserva e ON e.EstadoReservaId = r.EstadoReservaId
            WHERE rm.MesaId = m.MesaId
              AND r.FechaReserva = @Fecha
              AND e.EsActiva = 1
              AND (@ReservaIdExcluir IS NULL OR r.ReservaId <> @ReservaIdExcluir)
              AND r.HoraInicio < DATEADD(MINUTE, @DuracionMinutos, @HoraInicio)
              AND @HoraInicio  < r.HoraFin
      )
);
GO

/* ---------- 3.2 Validar si una mesa específica está libre ---------- */

CREATE OR ALTER FUNCTION dbo.fn_MesaEstaDisponible
(
    @MesaId           INT,
    @Fecha            DATE,
    @HoraInicio       TIME(0),
    @DuracionMinutos  SMALLINT,
    @ReservaIdExcluir INT = NULL
)
RETURNS BIT
AS
BEGIN
    DECLARE @Disponible BIT = 1;

    IF NOT EXISTS (SELECT 1 FROM dbo.Mesa WHERE MesaId = @MesaId AND Activa = 1)
        RETURN 0;

    IF EXISTS (
        SELECT 1
        FROM dbo.ReservaMesa rm
        INNER JOIN dbo.Reserva r       ON r.ReservaId = rm.ReservaId
        INNER JOIN dbo.EstadoReserva e ON e.EstadoReservaId = r.EstadoReservaId
        WHERE rm.MesaId = @MesaId
          AND r.FechaReserva = @Fecha
          AND e.EsActiva = 1
          AND (@ReservaIdExcluir IS NULL OR r.ReservaId <> @ReservaIdExcluir)
          AND r.HoraInicio < DATEADD(MINUTE, @DuracionMinutos, @HoraInicio)
          AND @HoraInicio  < r.HoraFin
    )
        SET @Disponible = 0;

    RETURN @Disponible;
END;
GO

/* ---------- Procedimientos almacenados ---------- */

/* ---------- 4.1 CF-7, CF-8, CF-30: registrar cliente ---------- */

CREATE OR ALTER PROCEDURE dbo.sp_RegistrarCliente
    @Nombre    VARCHAR(80),
    @Apellido  VARCHAR(80)  = NULL,
    @Telefono  VARCHAR(20)  = NULL,
    @Email     VARCHAR(120) = NULL,
    @Documento VARCHAR(20)  = NULL,
    @ClienteId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF @Telefono IS NULL AND @Email IS NULL
        THROW 50001, 'Debe registrar al menos un medio de contacto (teléfono o email).', 1;

    SELECT @ClienteId = ClienteId
    FROM dbo.Cliente
    WHERE (@Telefono  IS NOT NULL AND Telefono  = @Telefono)
       OR (@Documento IS NOT NULL AND Documento = @Documento);

    IF @ClienteId IS NULL
    BEGIN
        INSERT INTO dbo.Cliente (Nombre, Apellido, Telefono, Email, Documento)
        VALUES (@Nombre, @Apellido, @Telefono, @Email, @Documento);

        SET @ClienteId = SCOPE_IDENTITY();
    END

    SELECT * FROM dbo.Cliente WHERE ClienteId = @ClienteId;
END;
GO

/* ---------- 4.2 CF-11 + CF-13 + CF-16 + CF-19: crear reserva ---------- */
CREATE OR ALTER PROCEDURE dbo.sp_CrearReserva
    @ClienteId        INT,
    @Fecha            DATE,
    @HoraInicio       TIME(0),
    @CantidadPersonas TINYINT,
    @MesaId           INT = NULL,       -- NULL = el sistema asigna la mejor mesa
    @DuracionMinutos  SMALLINT = NULL,
    @UsuarioId        INT = NULL,
    @Observaciones    VARCHAR(300) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @DuracionMinutos IS NULL
        SELECT @DuracionMinutos = CAST(Valor AS SMALLINT)
        FROM dbo.ParametroSistema WHERE Clave = 'DURACION_RESERVA_MIN';

    DECLARE @Apertura TIME(0), @Cierre TIME(0);
    SELECT @Apertura = CAST(Valor AS TIME(0)) FROM dbo.ParametroSistema WHERE Clave = 'HORA_APERTURA';
    SELECT @Cierre   = CAST(Valor AS TIME(0)) FROM dbo.ParametroSistema WHERE Clave = 'HORA_CIERRE';

    /* Validaciones automáticas (CF-13) */
    IF NOT EXISTS (SELECT 1 FROM dbo.Cliente WHERE ClienteId = @ClienteId AND Activo = 1)
        THROW 50010, 'El cliente no existe o está inactivo.', 1;

    IF @CantidadPersonas < 1
        THROW 50011, 'La cantidad de personas debe ser mayor a cero.', 1;

    IF @Fecha < CAST(SYSDATETIME() AS DATE)
        THROW 50012, 'No se pueden crear reservas en fechas pasadas.', 1;

    IF @HoraInicio < @Apertura OR DATEADD(MINUTE, @DuracionMinutos, @HoraInicio) > @Cierre
        THROW 50013, 'El horario solicitado está fuera del horario de atención.', 1;

    IF EXISTS (
        SELECT 1 FROM dbo.Reserva r
        INNER JOIN dbo.EstadoReserva e ON e.EstadoReservaId = r.EstadoReservaId
        WHERE r.ClienteId = @ClienteId
          AND r.FechaReserva = @Fecha
          AND e.EsActiva = 1
          AND r.HoraInicio < DATEADD(MINUTE, @DuracionMinutos, @HoraInicio)
          AND @HoraInicio  < r.HoraFin)
        THROW 50014, 'El cliente ya tiene una reserva activa en ese horario.', 1;

    BEGIN TRANSACTION;

        /* Selección o validación de mesa (CF-19) */
        IF @MesaId IS NULL
        BEGIN
            SELECT TOP (1) @MesaId = MesaId
            FROM dbo.fn_MesasDisponibles(@Fecha, @HoraInicio, @CantidadPersonas, @DuracionMinutos, NULL)
            ORDER BY Capacidad ASC, MesaId ASC;

            IF @MesaId IS NULL
                THROW 50015, 'No hay mesas disponibles para esa fecha, hora y cantidad de personas.', 1;
        END
        ELSE
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM dbo.Mesa WHERE MesaId = @MesaId AND Activa = 1)
                THROW 50016, 'La mesa indicada no existe o está inactiva.', 1;

            IF (SELECT Capacidad FROM dbo.Mesa WHERE MesaId = @MesaId) < @CantidadPersonas
                THROW 50017, 'La capacidad de la mesa es menor a la cantidad de personas.', 1;

            IF dbo.fn_MesaEstaDisponible(@MesaId, @Fecha, @HoraInicio, @DuracionMinutos, NULL) = 0
                THROW 50018, 'La mesa ya está reservada en ese horario.', 1;
        END

        INSERT INTO dbo.Reserva (ClienteId, FechaReserva, HoraInicio, DuracionMinutos,
                                 CantidadPersonas, EstadoReservaId, Observaciones, CreadaPorUsuario)
        VALUES (@ClienteId, @Fecha, @HoraInicio, @DuracionMinutos,
                @CantidadPersonas, 2, @Observaciones, @UsuarioId);

        DECLARE @ReservaId INT = SCOPE_IDENTITY();

        INSERT INTO dbo.ReservaMesa (ReservaId, MesaId) VALUES (@ReservaId, @MesaId);

        INSERT INTO dbo.ReservaHistorial (ReservaId, EstadoAnterior, EstadoNuevo, UsuarioId, Motivo)
        VALUES (@ReservaId, NULL, 2, @UsuarioId, 'Creación de la reserva');

    COMMIT TRANSACTION;

    /* Confirmación (CF-16, CF-24, CF-25) */
    SELECT r.ReservaId,
           r.CodigoReserva,
           c.Nombre + ISNULL(' ' + c.Apellido, '') AS Cliente,
           c.Telefono,
           r.FechaReserva,
           r.HoraInicio,
           r.HoraFin,
           r.CantidadPersonas,
           m.NumeroMesa,
           m.Ubicacion,
           e.Nombre AS Estado,
           'Reserva confirmada correctamente.' AS Mensaje
    FROM dbo.Reserva r
    INNER JOIN dbo.Cliente c       ON c.ClienteId = r.ClienteId
    INNER JOIN dbo.EstadoReserva e ON e.EstadoReservaId = r.EstadoReservaId
    INNER JOIN dbo.ReservaMesa rm  ON rm.ReservaId = r.ReservaId
    INNER JOIN dbo.Mesa m          ON m.MesaId = rm.MesaId
    WHERE r.ReservaId = @ReservaId;
END;
GO

/* ---------- 4.3 CF-19: asignar o reasignar mesa ---------- */

CREATE OR ALTER PROCEDURE dbo.sp_AsignarMesa
    @ReservaId  INT,
    @MesaId     INT,
    @Reemplazar BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Fecha DATE, @Hora TIME(0), @Dur SMALLINT, @Personas TINYINT;

    SELECT @Fecha = FechaReserva, @Hora = HoraInicio,
           @Dur = DuracionMinutos, @Personas = CantidadPersonas
    FROM dbo.Reserva WHERE ReservaId = @ReservaId;

    IF @Fecha IS NULL THROW 50020, 'La reserva no existe.', 1;

    IF NOT EXISTS (SELECT 1 FROM dbo.Mesa WHERE MesaId = @MesaId AND Activa = 1)
        THROW 50022, 'La mesa no existe o está inactiva.', 1;

    IF (SELECT Capacidad FROM dbo.Mesa WHERE MesaId = @MesaId) < @Personas
        THROW 50023, 'La capacidad de la mesa es menor a la cantidad de personas.', 1;

    IF dbo.fn_MesaEstaDisponible(@MesaId, @Fecha, @Hora, @Dur, @ReservaId) = 0
        THROW 50021, 'La mesa no está disponible en ese horario.', 1;

    BEGIN TRANSACTION;
        IF @Reemplazar = 1
            DELETE FROM dbo.ReservaMesa WHERE ReservaId = @ReservaId;

        IF NOT EXISTS (SELECT 1 FROM dbo.ReservaMesa WHERE ReservaId = @ReservaId AND MesaId = @MesaId)
            INSERT INTO dbo.ReservaMesa (ReservaId, MesaId) VALUES (@ReservaId, @MesaId);
    COMMIT TRANSACTION;
END;
GO

/* ---------- 4.4 CF-23, CF-26, CF-27, CF-32: actualizar estado ---------- */

CREATE OR ALTER PROCEDURE dbo.sp_ActualizarEstadoReserva
    @ReservaId   INT,
    @NuevoEstado TINYINT,
    @UsuarioId   INT = NULL,
    @Motivo      VARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @EstadoActual TINYINT, @ClienteId INT;

    SELECT @EstadoActual = EstadoReservaId, @ClienteId = ClienteId
    FROM dbo.Reserva WHERE ReservaId = @ReservaId;

    IF @EstadoActual IS NULL THROW 50030, 'La reserva no existe.', 1;

    IF NOT EXISTS (SELECT 1 FROM dbo.EstadoReserva WHERE EstadoReservaId = @NuevoEstado)
        THROW 50031, 'Estado no válido.', 1;

    IF @EstadoActual IN (3, 4, 5)
        THROW 50032, 'La reserva ya está cerrada y no admite cambios de estado.', 1;

    BEGIN TRANSACTION;

        UPDATE dbo.Reserva
        SET EstadoReservaId = @NuevoEstado,
            FechaActualizacion = SYSDATETIME()
        WHERE ReservaId = @ReservaId;

        INSERT INTO dbo.ReservaHistorial (ReservaId, EstadoAnterior, EstadoNuevo, UsuarioId, Motivo)
        VALUES (@ReservaId, @EstadoActual, @NuevoEstado, @UsuarioId, @Motivo);

        -- CF-26 / CF-27: "No asistió" genera recargo automático
        IF @NuevoEstado = 5 AND NOT EXISTS (SELECT 1 FROM dbo.Recargo WHERE ReservaId = @ReservaId)
        BEGIN
            DECLARE @Monto DECIMAL(12,2);
            SELECT @Monto = CAST(Valor AS DECIMAL(12,2))
            FROM dbo.ParametroSistema WHERE Clave = 'RECARGO_INASISTENCIA';

            INSERT INTO dbo.Recargo (ReservaId, ClienteId, Monto)
            VALUES (@ReservaId, @ClienteId, @Monto);
        END

    COMMIT TRANSACTION;

    SELECT r.ReservaId, r.CodigoReserva, e.Nombre AS Estado,
           (SELECT Monto FROM dbo.Recargo WHERE ReservaId = r.ReservaId) AS RecargoGenerado
    FROM dbo.Reserva r
    INNER JOIN dbo.EstadoReserva e ON e.EstadoReservaId = r.EstadoReservaId
    WHERE r.ReservaId = @ReservaId;
END;
GO

/* ---------- 4.5 CF-21, CF-22: listar y buscar reservas ---------- */

CREATE OR ALTER PROCEDURE dbo.sp_BuscarReservas
    @FechaDesde DATE        = NULL,
    @FechaHasta DATE        = NULL,
    @Hora       TIME(0)     = NULL,
    @Cliente    VARCHAR(80) = NULL,
    @Estado     TINYINT     = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT r.ReservaId,
           r.CodigoReserva,
           c.ClienteId,
           c.Nombre + ISNULL(' ' + c.Apellido,'') AS Cliente,
           c.Telefono,
           r.FechaReserva,
           r.HoraInicio,
           r.HoraFin,
           r.CantidadPersonas,
           STRING_AGG(m.NumeroMesa, ', ') AS Mesas,
           e.Nombre AS Estado
    FROM dbo.Reserva r
    INNER JOIN dbo.Cliente c       ON c.ClienteId = r.ClienteId
    INNER JOIN dbo.EstadoReserva e ON e.EstadoReservaId = r.EstadoReservaId
    LEFT  JOIN dbo.ReservaMesa rm  ON rm.ReservaId = r.ReservaId
    LEFT  JOIN dbo.Mesa m          ON m.MesaId = rm.MesaId
    WHERE (@FechaDesde IS NULL OR r.FechaReserva >= @FechaDesde)
      AND (@FechaHasta IS NULL OR r.FechaReserva <= @FechaHasta)
      AND (@Hora       IS NULL OR @Hora BETWEEN r.HoraInicio AND r.HoraFin)
      AND (@Estado     IS NULL OR r.EstadoReservaId = @Estado)
      AND (@Cliente    IS NULL OR c.Nombre   LIKE '%' + @Cliente + '%'
                               OR c.Apellido LIKE '%' + @Cliente + '%'
                               OR c.Telefono LIKE '%' + @Cliente + '%')
    GROUP BY r.ReservaId, r.CodigoReserva, c.ClienteId, c.Nombre, c.Apellido,
             c.Telefono, r.FechaReserva, r.HoraInicio, r.HoraFin,
             r.CantidadPersonas, e.Nombre
    ORDER BY r.FechaReserva, r.HoraInicio;
END;
GO


SELECT * FROM dbo.fn_MesasDisponibles(DATEADD(DAY,1,CAST(GETDATE() AS DATE)), '19:00', 4, 90, NULL);

SELECT g.RecargoId, c.Nombre, r.CodigoReserva, g.Monto, g.Estado
FROM dbo.Recargo g
INNER JOIN dbo.Cliente c ON c.ClienteId = g.ClienteId
INNER JOIN dbo.Reserva r ON r.ReservaId = g.ReservaId;