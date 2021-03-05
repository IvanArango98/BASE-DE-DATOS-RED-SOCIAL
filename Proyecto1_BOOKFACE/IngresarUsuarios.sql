
--PROCEDIMIENTO PARA INSERTAR UN USUARIO INDIVIDUALMENTE
create or alter procedure Person.uspIngresarUsuario
						@PNombre nvarchar(20),
						@SNombre nvarchar(20),
						@PApellido nvarchar(20),
						@SApellido nvarchar(20),
						@Correo nvarchar(50),
						@MaxAmigos int,
						@FechaNac date,
						@Creacion date,
						@Fin date
as
begin
	begin tran

	--SE CREA UNA CONDICION PARA CADA POSIBILIDAD DE LOS DATOS QUE PUEDEN SER NULL O SE PUEDEN INSERTAR SIN NECESIDAD DE TENER UN VALOR
	if(@MaxAmigos is null and @Creacion is null and @Fin is null)
	begin
		insert into Person.Usuario(Primer_Nombre, Segundo_Nombre, Primer_Apellido, Segundo_Apellido, Correo_Electronico, Fecha_Nacimiento)
		values(@PNombre, @SNombre, @PApellido, @SApellido, @Correo, @FechaNac)
	end
	else if(@Creacion is null and @Fin is null)
	begin
		insert into Person.Usuario(Primer_Nombre, Segundo_Nombre, Primer_Apellido, Segundo_Apellido, Correo_Electronico, Total_Maximo_Amigos, Fecha_Nacimiento)
		values(@PNombre, @SNombre, @PApellido, @SApellido, @Correo, @MaxAmigos, @FechaNac)
	end
	else if(@MaxAmigos is null)
	begin
		insert into Person.Usuario(Primer_Nombre, Segundo_Nombre, Primer_Apellido, Segundo_Apellido, Correo_Electronico, Fecha_Nacimiento, Fecha_Creacion_Usuario, Fecha_Fin_Usuario)
		values(@PNombre, @SNombre, @PApellido, @SApellido, @Correo, @FechaNac, @Creacion, @Fin)
	end
	else if(@Fin is null)
	begin
		insert into Person.Usuario(Primer_Nombre, Segundo_Nombre, Primer_Apellido, Segundo_Apellido, Correo_Electronico, Total_Maximo_Amigos, Fecha_Nacimiento, Fecha_Creacion_Usuario)
		values(@PNombre, @SNombre, @PApellido, @SApellido, @Correo, @MaxAmigos, @FechaNac, @Creacion)
	end
	else
	begin
		insert into Person.Usuario(Primer_Nombre, Segundo_Nombre, Primer_Apellido, Segundo_Apellido, Correo_Electronico, Total_Maximo_Amigos, Fecha_Nacimiento, Fecha_Creacion_Usuario, Fecha_Fin_Usuario)
		values(@PNombre, @SNombre, @PApellido, @SApellido, @Correo, @MaxAmigos, @FechaNac, @Creacion, @Fin)
	end

	if(@@ERROR = 0)
		begin
			commit
		end
	else
		begin
			print 'ERROR DE PROCEDIMIENTO DE INSERCION INDIVIDUAL'
			rollback
		end

end

--PROCEDIMIENTO PARA INSERTAR CANTIDAD GRANDE DE DATOS DE USUARIOS DESDE UN ARCHIVO
create or alter procedure Person.uspIngresarUsuariosMasivo
as
begin
	begin tran

	--SE CREA LA TABLA TEMPORAL AL QUE SE CARGA LA INFORMACIÓN DE LOS USUARIO
	create table #temp_Usuarios
	(
		ID int,
		PrimerNombre nvarchar(20),
		SegundoNombre nvarchar(20),
		PrimerApellido nvarchar(20),
		SegundoApellido nvarchar(20),
		Correo nvarchar(50),
		Max_Amigos nvarchar(50),
		Nacimiento date,
		Creacion datetime,
		Final datetime
	)

	--SE REALIZA EL BULK INSERT PARA LA TABLA TEMPORAL
	bulk insert #temp_Usuarios
	from 'C:\Users\pabli\Desktop\Repositorios\Base de Datos II\Proyectos_BDII\Proyecto1_BOOKFACE\Ejemplo de Datos de Usuarios.csv'
	with
	(
		FORMAT = 'CSV'
	)

	--SE CREA UN CURSOR PARA QUE POR CADA REGISTRO DE LA TABLA TEMPORAL, SE REALICE UN INSERT EN LA TABLA DE USUARIOS
	--Y SE ACTIVEN LOS TRIGGERS DE INSERT.
	--*****************INICIO CURSOR**************
	declare @PNombre nvarchar(20),
			@SNombre nvarchar(20),
			@PApellido nvarchar(20),
			@SApellido nvarchar(20),
			@Correo nvarchar(50),
			@MaxAmigos int,
			@Fecha_Nacimiento date,
			@Creacion date,
			@Fin date

	declare Cursor_Inserts cursor for
		select PrimerNombre, SegundoNombre, PrimerApellido, SegundoApellido, Correo, Max_Amigos, Nacimiento, Creacion, Final
		from #temp_Usuarios

	open Cursor_Inserts
	fetch next from Cursor_Inserts into @PNombre, @SNombre, @PApellido, @SApellido, @Correo, @MaxAmigos, @Fecha_Nacimiento, @Creacion, @Fin
	while @@fetch_status = 0
		begin
			exec Person.uspIngresarUsuario @PNombre, @SNombre, @PApellido, @SApellido, @Correo, @MaxAmigos, @Fecha_Nacimiento, @Creacion, @Fin

			fetch next from Cursor_Inserts into @PNombre, @SNombre, @PApellido, @SApellido, @Correo, @MaxAmigos, @Fecha_Nacimiento, @Creacion, @Fin
		end

	close Cursor_Inserts
	deallocate Cursor_Inserts
	--********************FIN CURSOR**************

	--SI EXISTE ALGUN ERROR SE IMPRIME, DE LO CONTRARIO SE ENVIA UN MSJ DE USUARIOS INGRESADOS SIN ERROR
	if(@@ERROR = 0)
		begin
			--EN CASO QUE NO HAYA ERROR SE BOTA LA TABLA TEMPORAL Y SE HACE COMMIT A LA TRANSACCION
			drop table #temp_Usuarios
			print 'USUARIOS INGRESADOS'
			commit
		end
	else
		begin
			--EN CASO DE HABER ERROR SE IMPRIME UN MSJ DE ERROR Y ROLLBACK A LA TRANSACCION
			drop table #temp_Usuarios
			print 'ERROR DE PROCEDIMIENTO DE INSERCION MASIVA'
			rollback

			--SE REINICIA EL CONTADOR SEGUN LA CANTIDAD DE REGISTROS QUE YA EXISTIAN
			declare @ultimoID int
			select @ultimoID = count(1) from Person.Usuario

			dbcc checkident('Person.Usuario', reseed, @ultimoID)
		end
end

exec Person.uspIngresarUsuariosMasivo

select * from Person.Usuario

select * from Person.Amigo

delete from Person.Amigo

delete from Person.Usuario
dbcc checkident('Person.Usuario', reseed, 0)

drop procedure Person.uspIngresarUsuario
drop procedure Person.uspIngresarUsuariosMasivo

--drop table Amigo

--drop table Person.Usuario

--drop trigger ti_Amigo_Apellidos

--TRIGGER QUE CADA VEZ QUE SE REALIZA UN INSERT, VERIFICA SI EXISTE UNA PERSONA CON ALGUN APELLIDO IGUAL, Y DE SER ASÍ SE AGREGAN COMO AMIGOS
create or alter trigger ti_Amigos_Apellidos on Person.Usuario
after insert
as
begin
	--VARIABLES DEL USUARIO QUE SE INSERTÓ
	declare @ID_Usuario int,
			@PrimerApellido nvarchar(20),
			@SegundoApellido nvarchar(20)

	select @ID_Usuario = ID_Usuario,
			@PrimerApellido = Primer_Apellido,
			@SegundoApellido = Segundo_Apellido
	from inserted

	begin tran

	--SI LA CUENTA DE LOS USUARIOS CON ALGUN APELLIDO IGUAL ES MAYOR A 1 (MAYOR A UNO PORQUE SE VALIDA DESPUÉS DE INSERTAR EL NUEVO USUARIO)
	--ENTONCES SE CREA UN CURSOR PARA RECORRER CADA REGISTRO DE UN USUARIO CON ALGUN APELLIDO IGUAL Y SE AGREGAN COMO AMIGOS EN AMBAS VIAS
	if(
		(
			select count(1)
			from Person.Usuario
			where Primer_Apellido = @PrimerApellido or Segundo_Apellido = @SegundoApellido
		) > 1)
		begin
			--CURSOR QUE RECORRE CADA REGISTRO CON ALGUN APELLIDO IGUAL AL USUARIO RECIEN INSERTADO
			--*****************INICIO CURSOR**************
			declare @ID_UsuarioIgual int
			declare Cursor_IDs cursor for
				select ID_Usuario
				from Person.Usuario
				where Primer_Apellido = @PrimerApellido or Segundo_Apellido = @SegundoApellido

			open Cursor_IDs
			fetch next from Cursor_IDs into @ID_UsuarioIgual
			while @@fetch_status = 0
				begin
					if(@ID_Usuario <> @ID_UsuarioIgual)
						begin
							print 'AMIGOS CON MISMOS APELLIDOS CONECTADOS'

							insert into Amigo(ID_Usuario, ID_FR, Fecha_Inicio_Amistad, Fecha_Fin_Amistad)
							values (@ID_Usuario, @ID_UsuarioIgual, getdate(), null)

							--insert into Amigo(ID_Usuario, ID_FR, Fecha_Inicio_Amistad, Fecha_Fin_Amistad)
							--values (@ID_UsuarioIgual, @ID_Usuario, getdate(), null)
						end

						fetch next from Cursor_IDs into @ID_UsuarioIgual
				end

			close Cursor_IDs
			deallocate Cursor_IDs
			--********************FIN CURSOR**************
		end

		if(@@error = 0)
			begin
				commit
			end
		else
			begin
				print 'ERROR DE TRIGGER AMIGOS CON MISMOS APELLIDOS'
				rollback
			end
end


