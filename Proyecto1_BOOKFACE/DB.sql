 --DROP DATABASE  IF exists BOOKFACE

CREATE DATABASE BOOKFACE
GO

use BOOKFACE
GO

CREATE SCHEMA Person
GO

CREATE SCHEMA Interactions
GO

--****************************************************************TABLAS**********************************************************************

--TABLA QUE CONTENDRA LA INFORMACION DE TODOS LOS USUARIOS
--Validar que correo electronico sea unico por usuario
--Validar que como maximo solo se llamen dos personas iguales
create table Person.Usuario
(
	ID_Usuario int identity(1,1) primary key,
	Primer_Nombre nvarchar(20) not null ,
	Segundo_Nombre nvarchar(20) not null,
	Primer_Apellido nvarchar(20) not null,
	Segundo_Apellido nvarchar(20) not null,
	Correo_Electronico nvarchar(50) not null unique,
	Total_Maximo_Amigos int default 50,
	Fecha_Nacimiento date not null,
	Fecha_Creacion_Usuario datetime default getdate(),
	Fecha_Fin_Usuario datetime default null,
	CONSTRAINT my_constraint CHECK(Correo_Electronico LIKE '%___@___%'),
	CONSTRAINT FECHAS CHECK(Fecha_Fin_Usuario >= Fecha_Creacion_Usuario)
)
GO

--TABLA DONDE SE ALMACENARAN LOS AMIGOS QUE TIENE CADA USUARIO
create table Person.Amigo
(
	ID_Usuario int not null,
	ID_FR int not null,
	Fecha_Inicio_Amistad date not null,
	Fecha_Fin_Amistad date null,
	FOREIGN KEY (ID_Usuario) REFERENCES Person.Usuario(ID_Usuario)ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY (ID_FR) REFERENCES Person.Usuario(ID_Usuario),--ON DELETE CASCADE ON UPDATE CASCADE, --***********************DUDA SI LLEVA DELETE CASCADE Y UPDATE CASCADE
	CONSTRAINT CHK_Person CHECK (ID_Usuario <> ID_FR),
	CONSTRAINT PK_Amigo primary key clustered
	(
		ID_Usuario,
		ID_FR
	)
)
GO

--TABLA DE TIPO_PUBLICACION
create table Interactions.Tipo_Publicacion
(
	ID_Tipo int identity(1,1) primary key,
	Nombre nvarchar(20) unique
)

--SE INSERTAN LOS DATOS DE TIPOS DE PUBLICACION QUE PUEDEN EXISTIR
insert into Interactions.Tipo_Publicacion(Nombre)
values('Imagen')
GO
insert into Interactions.Tipo_Publicacion(Nombre)
values('Post')
GO
insert into Interactions.Tipo_Publicacion(Nombre)
values('Noticia')
GO

--TABLA DE TIPO_DISPOSITIVO
create table Interactions.Tipo_Dispositivo
(
	ID_Tipo int identity(1,1) primary key,
	Nombre nvarchar(20) unique
)

--SE INSERTAN LOS DATOS DE TIPOS DE DISPOSITIVOS QUE PUEDEN EXISTIR
insert into Interactions.Tipo_Dispositivo(Nombre)
values('PC')
GO
insert into Interactions.Tipo_Dispositivo(Nombre)
values('Smartphone')
GO
insert into Interactions.Tipo_Dispositivo(Nombre)
values('Tablet')
GO

--TABLA QUE ALMACENARÁ EL CONTENIDO DE LAS PUBLICACIONES DE CADA USUARIO
create table Interactions.Publicacion
(
	ID_Publicacion int identity(1,1) primary key,
	ID_Usuario int not null,
	Fecha datetime not null,
	IP_Address varchar(16) not null,
	Tipo_Dispositivo int not null, --varchar(20) not null,
	Tipo_Publicacion int not null,
	Contenido nvarchar(MAX) not null,
	Estado int null default 0,
	FOREIGN KEY (ID_Usuario) REFERENCES Person.Usuario(ID_Usuario) ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY (Tipo_Publicacion) REFERENCES Interactions.Tipo_Publicacion(ID_Tipo) ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY (Tipo_Dispositivo) REFERENCES Interactions.Tipo_Dispositivo(ID_Tipo) ON DELETE CASCADE ON UPDATE CASCADE
	--CONSTRAINT Dipostivos  CHECK(Tipo_Dispositivo = 'PC' or Tipo_Dispositivo = 'Tablet' or Tipo_Dispositivo = 'Telefono' ),
	--CONSTRAINT Publicaciones  CHECK(Tipo_Publicacion = 'Imagen' or Tipo_Publicacion = 'Post' or Tipo_Publicacion = 'Noticia' ) 
)
GO

--TABLA QUE ALMACENARÁ LOS COMENTARIOS DE CADA PUBLICACIÓN
create table Interactions.Comentario
(
	ID_Comentario int not null primary key,
	ID_Publicacion int not null,
	Estado varchar(8) not null,
	NumeroCola int not null,
	Fecha datetime not null,
	ID_Amigo int not null,
	FOREIGN KEY (ID_Publicacion) REFERENCES Interactions.Publicacion(ID_Publicacion) ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY (ID_Amigo) REFERENCES Person.usuario(ID_Usuario),--ON DELETE CASCADE ON UPDATE CASCADE, --***************************DUDA DEL CASCADE
	CONSTRAINT Estado  CHECK(Estado = 'Activo' or Estado = 'Inactivo') 
)
GO

--TABLA QUE ALMACENA LOS LIKES DE CADA PUBLICACION
create table Interactions.Likes
(
	ID_Publicacion int not null,
	Tipo_Like nvarchar(10) not null,
	fecha datetime not null,
	ID_Amigo int not null,
	FOREIGN KEY (ID_Publicacion) REFERENCES Interactions.Publicacion(ID_Publicacion) ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY (ID_Amigo) REFERENCES Person.Usuario(ID_Usuario),--ON DELETE CASCADE ON UPDATE CASCADE, --******************************************DUDA DEL CASCADE
	CONSTRAINT TipoLike CHECK(Tipo_Like = 'Like' or Tipo_Like = 'Dislike')
)
GO

--*****************************************************PROCEDIMIENTOS**********************************************************************

--PROCEDIMIENTO QUE LLENA EL NUMERO DE AMIGOS MAXIMO QUE PUEDE TENER CADA USUARIO
create or alter procedure Person.usp_MaxAmigos
			@fecha datetime
as
begin

	declare @totalAmigos int,
			@id_pub int, 
			@n_likes int,
			@id_usuario int,
			@fechaActual datetime,
			@anio int,
			@mes int,
			@dia int,
			@hora int,
			@minuto int

	set @fechaActual = GETDATE()
	set	@anio = year(@fechaActual)
	set @mes = MONTH(@fechaActual)
	set @dia = DAY(@fechaActual)
	set @hora = DATEPART(HOUR, @fechaActual)
	set @minuto = DATEPART(MINUTE, @fechaActual)

	if(@anio = year(@fecha) and @mes = month(@fecha) and @dia = day(@fecha) and @hora = DATEPART(HOUR, @fecha) and @minuto = DATEPART(MINUTE, @fecha))
	begin
		--Se crea temporal en la que se filtra que la publicacion tenga un minimo de 15 likes, que la publicacion tengo como estado 0 que significa que esta publicacion no ha tenido un impacto en el crecimiento del maximo de amigos del usuario, ya que no tiene sentido que se actualice a cada rato una publicacion que ya se analizo previamente.
		--Y que filtre cuando solo sean likes y que sean las publicaciones de este usuario

		select p.ID_Publicacion,COUNT(l.Tipo_Like) as 'Total likes' into Person.PublicacionUsuario 
		from Interactions.Publicacion p
				inner join Interactions.Likes l 
					on (p.ID_Publicacion = l.ID_Publicacion and p.Estado = 0 and p.ID_Usuario = 1 and l.Tipo_Like = 'Like')
		group by p.ID_Publicacion, l.Tipo_Like
		having count(l.Tipo_Like) >= 15



		declare CursorActualizarAmigos cursor
		for select p.ID_Publicacion,COUNT(l.Tipo_Like) as 'Total',p.ID_Usuario from Interactions.Publicacion p inner join Interactions.Likes l on p.ID_Publicacion = l.ID_Publicacion where l.Tipo_Like = 'Like' group by p.ID_Publicacion,p.ID_Usuario
		open CursorActualizarAmigos
		fetch NEXT FROM CursorActualizarAmigos into @id_pub,@n_likes, @id_usuario
		while(@@FETCH_STATUS = 0)
		begin
			declare @estado int
			select @estado = estado from Interactions.Publicacion where ID_Publicacion = @id_pub

			if(@estado = 0)
			begin
				select	@totalAmigos = Total_Maximo_Amigos from Person.Usuario where ID_Usuario = @id_usuario
				set @totalAmigos = @totalAmigos +1
				update Person.Usuario set Total_Maximo_Amigos = @totalAmigos where ID_Usuario = @id_usuario
				update Interactions.Publicacion set Estado = 1 where ID_Publicacion = @id_pub
			end

			fetch NEXT FROM CursorActualizarAmigos into @id_pub,@n_likes, @id_usuario
		end
		close CursorActualizarAmigos
		Deallocate CursorActualizarAmigos

		drop table Person.PublicacionUsuario

	end
end
GO

--declare @fechaPredeterminada datetime
--set @fechaPredeterminada = GETDATE()

--exec Person.usp_MaxAmigos @fechaPredeterminada

--********************************************************FUNCIONES************************************************************************

--FUNCION QUE RETORNARÁ 0 SI NO ES AMIGO DEL USUARIO Y 1 SI ES AMIGO DEL USUARIO, PARA VALIDAR QUE UNICAMENTE AMIGOS DEL USUARIO PUEDAN REACCIONAR A SUS PUBLICACIONES
create or alter function Interactions.Validar_Interacciones_Amigos
			(@id_amigo int, @id_publicacion int, @tipo nvarchar(11))
returns int
as
begin

	declare @validar int,@id_usuario int

	if(@tipo = 'Comentario')
		begin
			select @id_usuario =p.ID_Usuario from Interactions.Publicacion p  where p.ID_Publicacion = @id_publicacion
			select @validar = COUNT(ID_FR) from Person.Amigo where ID_FR = @id_amigo and ID_Usuario = @id_usuario
		end

	if(@tipo = 'Like')
		begin
			select @id_usuario =p.ID_Usuario from Interactions.Publicacion p  where p.ID_Publicacion = @id_publicacion
			select @validar = COUNT(ID_FR) from Person.Amigo where ID_FR = @id_amigo and ID_Usuario = @id_usuario
		end

	return @validar
end
GO

--FUNCIONA QUE RETORNA 0 SI EL USUARIO HA LLEGADO AL MAXIMO DE AMIGOS Y NO PUEDE INSERTAR MÁS AMIGOS Y RETORNA 1 SI AUN NO HA LLEGADO AL MAXIMO Y PUEDE AGREGAR MÁS AMIGOS
create or alter function Person.Retornar_MaxAmigos
(@id_usuario int,@id_amigo int)
returns int
as 
begin

		declare @bool int,
				@total int, 
				@total2 int

		select @total = Total_Maximo_Amigos from Person.Usuario where ID_Usuario = @id_usuario
		select @total2 = COUNT(ID_Usuario) from Person.Amigo where ID_Usuario = @id_usuario

		set @total2 = @total2 +1

		if(@total >= @total2)
			begin
				set @bool = 1
			end
		else
			begin
				set @bool = 0
			end

	return @bool
end
GO

--********************************************************TRIGGERS*************************************************************************

--TRIGGER QUE VALIDA QUE NO SE PUEDA ALMACENAR A MÁS DE DOS PERSONAS CON EL MISMO NOMBRE
create or alter trigger Person.ti_MaxUsuarios on Person.Usuario 
instead of insert 
as
begin
	
	begin tran

	declare @ID_Usuario int, 
			@Primer_Nombre nvarchar(20), 
			@Segundo_Nombre nvarchar(20), 
			@Primer_Apellido nvarchar(20), 
			@Segundo_Apellido nvarchar(20), 
			@Correo_Electronico nvarchar(50), 
			@Fecha_Nacimiento date, 
			@Fecha_Creacion_Usuario datetime, 
			@Fecha_Fin_Usuario datetime, 
			@validar int 

	select 
			@ID_Usuario = ID_Usuario,
			@Primer_Nombre = Primer_Nombre,
			@Segundo_Nombre = Segundo_Nombre,
			@Primer_Apellido = Primer_Apellido,
			@Segundo_Apellido = Segundo_Apellido,
			@Correo_Electronico = Correo_Electronico,
			@Fecha_Nacimiento = Fecha_Nacimiento,
			@Fecha_Creacion_Usuario = Fecha_Creacion_Usuario,
			@Fecha_Fin_Usuario = Fecha_Fin_Usuario
	from inserted

	select @validar = COUNT(ID_Usuario) from Person.Usuario 
	where Primer_Nombre = @Primer_Nombre and 
		  Segundo_Nombre = @Segundo_Nombre and 
		  Primer_Apellido = @Primer_Apellido and 
		  Segundo_Apellido = @Segundo_Apellido 

	if(@validar < 2) 
		begin
			insert into Person.Usuario(Primer_Nombre, Segundo_Nombre, Primer_Apellido, Segundo_Apellido, Correo_Electronico, Total_Maximo_Amigos, Fecha_Nacimiento, Fecha_Creacion_Usuario, Fecha_Fin_Usuario)
			values(@Primer_Nombre, @Segundo_Nombre, @Primer_Apellido, @Segundo_Apellido, @Correo_Electronico, 50, @Fecha_Nacimiento, @Fecha_Creacion_Usuario, @Fecha_Fin_Usuario)
			commit
		end
	else 
		begin 
			print 'No puede existir más de dos personas con el mismo nombre completo' 
			rollback
		end
end
GO

--TRIGGER QUE VALIDA QUE UNA PERSONA SOLO TENGA AGREGADA UNA VEZ EN SU LISTA DE AMIGOS A UN USUARIO Y VALIDA QUE EL TOTAL DE AMIGOS PERMITIDO POR USUARIO SE RESPETE
CREATE or alter TRIGGER Person.ti_ValidarAmigo on Person.Amigo 
instead of insert 
as
begin

	begin tran

	declare @ID_Usuario int,
			@ID_FR int,
			@Fecha_Inicio_Amistad datetime,
			@Fecha_Fin_Amistad datetime,
			@funcion int,@funcion2 int

	declare @Validar int,
			@validar2 int,
			@total int

	select @ID_Usuario = ID_Usuario,
		   @ID_FR = ID_FR,
		   @Fecha_Inicio_Amistad = Fecha_Inicio_Amistad, 
		   @Fecha_Fin_Amistad = Fecha_Fin_Amistad  
		   from inserted

	--se extrae el total de amigos que tiene actualmente almacenado en la base de datos
	select @total = COUNT(ID_Usuario) 
	from Person.Amigo
	where ID_Usuario = @ID_Usuario

	--se extrae el ultimo registro de numero maximo de amigos que puede tener este usuario
	select @validar2 = Total_Maximo_Amigos
	from Person.Usuario 
	where ID_Usuario = @ID_Usuario 

	--se le suma 1 al total de amigos actuales para validar si con ese amigo que se desea insertar sea menor el total al maximo permitido
	set @total = @total + 1

	--se valida que el usuario no tenga agregado a este amigo, valor esperado 0
	SELECT @Validar = COUNT(ID_Usuario) 
	FROM Person.Amigo 
	where ID_Usuario=@ID_Usuario AND ID_FR =@ID_FR

	--Variable que almacenara la validacion de que si el usuario puede agregar amigos o no.  Usuario-Amigo
	select @funcion = Person.Retornar_MaxAmigos(@ID_Usuario,@ID_FR)

	--Variable que almacenara la validacion de que si el usuario puede agregar amigos o no.  Amigo-Usuario
	select @funcion2 = Person.Retornar_MaxAmigos(@ID_FR,@ID_Usuario)

	if(@Validar = 0 and @total <= @validar2 and @funcion = 1 and @funcion2 =1)
		begin 
			--insert de usuario 1 a 2
			insert into Person.Amigo(ID_Usuario, ID_FR, Fecha_Inicio_Amistad, Fecha_Fin_Amistad)
			values(@ID_Usuario, @ID_FR, @Fecha_Inicio_Amistad, @Fecha_Fin_Amistad)

			--insert de usuario 2 a 1
			insert into Person.Amigo(ID_Usuario, ID_FR, Fecha_Inicio_Amistad, Fecha_Fin_Amistad)
			values(@ID_FR, @ID_Usuario, @Fecha_Inicio_Amistad, @Fecha_Fin_Amistad)
			
			commit
		end
	else 
		begin 
			print 'Error: No se ha podido insertar este usuario a la lista de amigos' 
			--rollback
		end

end
GO

--TRIGGER QUE RESTRINGE QUE CADA PUBLICACIÓN NO PUEDAN EXISTIR MÁS DE 3 COMENTARIOS POR LO QUE A LOS COMENTARIOS 1, 2 Y 3 SERÁN MARCADOS COMO ACTIVOS Y EL RESTO SE CONVERTIRA EN INACTIVO
create or alter trigger Interactions.ti_Cola
on Interactions.Comentario  instead of insert as
begin
	begin tran

	declare @ID_Comentario int, @ID_Publicacion int,@Estado varchar(8),@NumeroCola int, @Fecha datetime, @ID_Amigo int

	select @ID_Comentario = ID_Comentario, @ID_Publicacion = ID_Publicacion,@Estado = Estado, @NumeroCola= NumeroCola,@Fecha = Fecha,@ID_Amigo = ID_Amigo from inserted

	declare @n int, 
			@tempo int

	--llama al metodo validar amigos, si es 1 es porque es su amigo y si es 0 es porque no lo es
	select @tempo = Interactions.Validar_Interacciones_Amigos(@ID_Amigo,@ID_Publicacion,'comentario')

	if(@tempo = 1)
		begin
			select top 1  @n= NumeroCola 
			from Interactions.comentario 
			where ID_Publicacion = @ID_Publicacion 
			order by Fecha desc

			if(@n is null) 
				begin 
					set @n = 0 
				end

			set @n = @n +1

			if(@n <= 3)
				begin
					insert into Interactions.Comentario(ID_Comentario,ID_Publicacion,Estado,NumeroCola,Fecha,ID_Amigo)
					values(@ID_Comentario,@ID_Publicacion,'activo',@n,@Fecha,@ID_Amigo)
				end
			else 
				begin
					insert into Interactions.Comentario(ID_Comentario,ID_Publicacion,Estado,NumeroCola,Fecha,ID_Amigo)
					values(@ID_Comentario,@ID_Publicacion,'inactivo',@n,@Fecha,@ID_Amigo)
				end
			commit
		end
	else
		begin 
			print 'No se ha podido realizar esta accion, ya que este usuario no pertenece a la lista de amigos.'
			rollback
		end
	end
GO

--TRIGGER QUE VALIDA QUE NO PUEDA EXISTIR DISLIKES SI NO EXISTEN LIKES. PENDIENTE, SE APLICÓ LOGICA DE BANCO.
create or alter trigger Interactions.Ti_ValidarLikes
on Interactions.Likes instead of insert as
begin

	begin tran

	declare @ID_Publicacion int,
			@Tipo_Like varchar(10),
			@fecha datetime, 
			@ID_Amigo int,
			@like int,
			@dislike int,
			@ID_Usuario int

	select @ID_Publicacion = ID_Publicacion,
			@Tipo_Like = Tipo_Like,
			@fecha = fecha, 
			@ID_Amigo = ID_Amigo 
	from inserted

	select @like= COUNT(Tipo_Like)  
	from Interactions.Likes 
	where Tipo_Like = 'Like' and ID_Publicacion = @ID_Publicacion

	select @dislike= COUNT(Tipo_Like)  
	from Interactions.Likes 
	where Tipo_Like = 'Dislike' and ID_Publicacion = @ID_Publicacion

	if(@like is null) 
		begin 
			set @like = 0 
		end
	
	if(@dislike is null)
		begin 
			set @dislike = 0  
		end 

	if(@Tipo_Like = 'Like')
		begin 
			set @like = @like +1	
		end

	if(@Tipo_Like = 'Dislike') 
		begin 
			set @dislike = @dislike +1	
		end

	declare @tempo int
	--llama al metodo validar amigos, si es 1 es porque es su amigo y si es 0 es porque no lo es
	select @tempo = Interactions.Validar_Interacciones_Amigos(@ID_Amigo,@ID_Publicacion,'Like')

	if(@tempo = 1)
		begin
			if(@like > @dislike)
				begin
					declare @validar int, @validar2 int
					--validar que solo se almacene que esa persona ha dejado un like o dislike en la publicacion y si ya existe un registro que no lo inserte, valor esperado es 0
					select @validar = count(ID_Amigo) from Interactions.Likes where ID_Publicacion = @ID_Publicacion and @ID_Amigo = ID_Amigo

					--validar que una persona pueda cambiar de like a dislike o de dislike a like, valor esperado 1
					select @validar2 = count(Tipo_Like) from Interactions.Likes where ID_Publicacion = @ID_Publicacion and @ID_Amigo = ID_Amigo and Tipo_Like <> @Tipo_Like

					if(@validar = 0)
						begin
							insert into Interactions.Likes(ID_Publicacion,Tipo_Like,fecha,ID_Amigo) 
							values(@ID_Publicacion,@Tipo_Like,@fecha,@ID_Amigo)

							select @ID_Usuario = ID_Usuario
							from Interactions.Publicacion p 
									inner join Interactions.Likes l
										on p.ID_Publicacion = l.ID_Publicacion
						end

					if(@validar2 = 1)
						begin
							update Interactions.Likes
							set Tipo_Like = @Tipo_Like, fecha = GETDATE() 
							where ID_Publicacion = @ID_Publicacion and ID_Amigo = @ID_Amigo

							select @ID_Usuario = ID_Usuario 
							from Interactions.Publicacion p 
									inner join Interactions.Likes l 
										on p.ID_Publicacion = l.ID_Publicacion
						end
					commit
				end
			else 
				begin 
					print 'No existe el numero minimo de likes para que se pueda realizar este dislike' 
					rollback
				end
		end
	else
		begin
			print 'No se ha podido realizar esta acción, ya que este usuario no pertenece a la lista de amigos.'
			rollback
		end

end
GO

--TRIGGER QUE PODRÁ ELIMINAR UN COMENTARIO ESPECÍFICO DE UNA PUBLICACIÓN, DEBERÁ VALIDAR SI EXISTEN COMENTARIOS EN COLA (Y QUE NO ESTÉN ACTIVOS) PARA QUE OCUPEN EL LUGAR QUE DEJA EL COMENTARIO ELIMINADO
create or alter trigger Interactions.td__EliminarComentarios
on Interactions.Comentario 
after delete 
as
begin
	begin tran

	declare @id_publicacion int,
			@cola int,
			@estado varchar(10),
			@numerocola int,
			@id_comentario int,
			@fecha datetime,
			@idamigo int,
			@estado1 varchar(10),
			@idc int,
			@idp int,
			@f datetime,
			@ida int,
			@validar int


	select 
		@id_publicacion = id_publicacion,
		@cola = NumeroCola, 
		@idamigo = ID_Amigo,
		@id_comentario = ID_Comentario,
		@estado1 = Estado,
		@fecha = Fecha
	from deleted

	if(@@ROWCOUNT = 1)
		begin
			declare CursorActualizarCola cursor
			for select ID_Comentario,ID_Publicacion,Estado,NumeroCola,Fecha,ID_Amigo from Interactions.Comentario where id_publicacion = @id_publicacion 
			open CursorActualizarCola
			fetch NEXT FROM CursorActualizarCola into @idc,@idp,@estado,@numerocola,@f,@ida
			while(@@FETCH_STATUS = 0)
			begin

			--caso cuando el que se elimina es el primer registro
			if(@cola < @numerocola)
			begin
			if(@numerocola -1 <= 3) begin set @estado = 'activo' end 
			else begin set @estado = 'inactivo' end
			update Interactions.Comentario set NumeroCola =  @numerocola -1, Estado = @estado where ID_Publicacion = @id_publicacion and ID_Comentario = @idc
			end

			--caso cuando no se tocan los primeros registros pero si los siguientes registros
			if(@numerocola > @cola)
			begin
			if(@numerocola -1 <= 3) begin set @estado = 'activo' end 
			else begin set @estado = 'inactivo' end
			update Interactions.Comentario set NumeroCola =  @numerocola -1, Estado = @estado where ID_Publicacion = @id_publicacion and ID_Comentario = @idc
			end

			fetch NEXT FROM CursorActualizarCola into @idc,@idp,@estado,@numerocola,@f,@ida
			end
			close CursorActualizarCola
			Deallocate CursorActualizarCola

			commit
		end
	else
		begin 
			rollback
		end

end

--****************EXTRA
/*
testeo para borrar comentarios

select *from Interactions.Comentario where ID_Publicacion = 3

delete Interactions.Comentario where ID_Publicacion = 3 and ID_Comentario = 13
--solo correr rollback si se llegase a cagar en la accion jaja es necesario poner begin tran seguido del delete para que funcione el procedimiento de borrar comentarios
rollback
*/

