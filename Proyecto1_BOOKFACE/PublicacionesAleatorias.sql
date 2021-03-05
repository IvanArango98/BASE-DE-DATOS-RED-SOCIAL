
--PROCEDIMIENTO PARA GENERAR PUBLICACIONES ALEATORIAS
--RECIBE COMO PARAMETROS LA CANTIDAD DE USUARIOS M A LOS QUE SE QUIEREN GENERAR UNA CANTIDAD DE PUBLICACIONES N
create or alter procedure Interactions.uspPublicacionesAleatorias
						@usuarios int,
						@publicaciones int
as
begin

	declare @contador int,
			@id int,
			@ip nvarchar(20),
			@tipoDisp nvarchar(20),
			@tipoPub int,
			@cantTipoDispExisten int,
			@cantTipoPubExisten int

	set @ip = '198.162.15.'

	--SE DECLARA EL NIVEL DE AISLAMIENTO
	set transaction isolation level read committed
	begin tran

	--SI SE LLEGA A INGRESAR UN VALOR NULO O MENOR O IGUAL A 0 SE LE ASIGNA UN VALOR ALEATORIO ENTRE 1 Y LA CANTIDAD DE USUARIOS MAXIMA QUE EXISTE
	if(@usuarios is null or @usuarios <= 0)
	begin
		declare @cantidadUsuariosExisten int
		select @cantidadUsuariosExisten = count(1) from Person.Usuario

		set @usuarios = FLOOR(RAND()*(@cantidadUsuariosExisten-1+1)+1)
	end
	else --SE VALIDA QUE LA CANTIDAD DE USUARIOS INGRESADOS SEA MENOR O IGUA A LA CANTIDAD DE USUARIOS QUE EXISTEN 
	begin
		--SI LA CANTIDAD DE USUARIOS INGRESADOS ES MAYOR A LA CANTIDAD DE USUARIOS QUE EXISTEN ACTUALMENTE, ENTONCES SE IGUALA A LA CANTIDAD EXISTENTE
		if(@usuarios > (select count(1) from Person.Usuario))
		begin
			select @usuarios = count(1) from Person.Usuario
		end
	end

	--SI SE INGRESA UN VALOR DE PUBLICACIONES NULO O MENOR O IGUAL A 0 SE LE ASIGNAR UN VALOR ALEATORIO ENTRE 1 Y 500
	if(@publicaciones is null or @publicaciones  <= 0)
	begin
		declare @cantidadPublicaciones int

		set @cantidadPublicaciones = FLOOR(RAND()*(500-1+1)+1)
	end

	--LUEGO DE HABER REALIZADO TODAS LAS VALIDACIONES POSIBLES, SE CONTINÚA CON LA CREACION DE PUBLICACIONES
	set @contador = @usuarios
	select @cantTipoDispExisten = count(1) from Interactions.Tipo_Dispositivo
	select @cantTipoPubExisten = count(1) from Interactions.Tipo_Publicacion

	while (@contador > 0)
	begin
		set @id = FLOOR(RAND()*(@usuarios-1+1)+1)

		if exists(select * from Person.Usuario where ID_Usuario = @id)
		begin
			--select ID_Usuario from Person.Usuario where ID_Usuario = @id
			
			set @tipoDisp = FLOOR(RAND()*(@cantTipoDispExisten-1+1)+1)
			set @tipoPub = FLOOR(RAND()*(@cantTipoPubExisten-1+1)+1)

			insert into Interactions.Publicacion(ID_Usuario, Fecha, IP_Address, Tipo_Dispositivo, Tipo_Publicacion, Contenido, Estado)
			values(@id, GETDATE(), @ip + CONVERT(nvarchar(10), @id), @tipoDisp, @tipoPub, 'x', 0)

			set @contador -= 1
		end
	end

	if(@@ERROR = 0)
	begin
		print 'PUBLICACIONES REALIZADAS'
		commit
	end
	else
	begin
		print 'ERROR DE PROCEDIMIENTO PARA GENERAR PUBLICACIONES ALEATORIAS'
		rollback
	end

end

exec Interactions.uspPublicacionesAleatorias 5, 10