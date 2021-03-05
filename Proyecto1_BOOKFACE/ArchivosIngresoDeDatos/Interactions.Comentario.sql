USE BOOKFACE;
GO

insert into Interactions.Comentario (ID_Comentario, ID_Publicacion, Estado, NumeroCola, Fecha, ID_Amigo) Values (1, 1, 'Activo', 1, getdate(), 2)
go
insert into Interactions.Comentario (ID_Comentario, ID_Publicacion, Estado, NumeroCola, Fecha, ID_Amigo) Values (2, 1, 'Activo', 1, getdate(), 3)
go
insert into Interactions.Comentario (ID_Comentario, ID_Publicacion, Estado, NumeroCola, Fecha, ID_Amigo) Values (3, 1, 'Activo', 1, getdate(), 4)
go
insert into Interactions.Comentario (ID_Comentario, ID_Publicacion, Estado, NumeroCola, Fecha, ID_Amigo) Values (4, 1, 'Activo', 1, getdate(), 5)
go
insert into Interactions.Comentario (ID_Comentario, ID_Publicacion, Estado, NumeroCola, Fecha, ID_Amigo) Values (5, 1, 'Activo', 1, getdate(), 6)
go
 -- select *from Interactions.Comentario
insert into Interactions.Comentario (ID_Comentario, ID_Publicacion, Estado, NumeroCola, Fecha, ID_Amigo) Values (6, 2, 'Activo', 1, getdate(), 3)
go
insert into Interactions.Comentario (ID_Comentario, ID_Publicacion, Estado, NumeroCola, Fecha, ID_Amigo) Values (7, 2, 'Activo', 1, getdate(), 4)
go

insert into Interactions.Comentario (ID_Comentario, ID_Publicacion, Estado, NumeroCola, Fecha, ID_Amigo) Values (8, 2, 'Activo', 1, getdate(), 5)
go

insert into Interactions.Comentario (ID_Comentario, ID_Publicacion, Estado, NumeroCola, Fecha, ID_Amigo) Values (9, 2, 'Activo', 1, getdate(), 7)
go



insert into Interactions.Comentario (ID_Comentario, ID_Publicacion, Estado, NumeroCola, Fecha, ID_Amigo) Values (14, 4, 'Activo', 1, getdate(), 1)
go
insert into Interactions.Comentario (ID_Comentario, ID_Publicacion, Estado, NumeroCola, Fecha, ID_Amigo) Values (15, 4, 'Activo', 1, getdate(), 2)
go
insert into Interactions.Comentario (ID_Comentario, ID_Publicacion, Estado, NumeroCola, Fecha, ID_Amigo) Values (16, 4, 'Activo', 1, getdate(), 3)
go
insert into Interactions.Comentario (ID_Comentario, ID_Publicacion, Estado, NumeroCola, Fecha, ID_Amigo) Values (17, 4, 'Activo', 1, getdate(), 7)
go
insert into Interactions.Comentario (ID_Comentario, ID_Publicacion, Estado, NumeroCola, Fecha, ID_Amigo) Values (18, 5, 'Activo', 1, getdate(), 10)
go

insert into Interactions.Comentario (ID_Comentario, ID_Publicacion, Estado, NumeroCola, Fecha, ID_Amigo) Values (19, 5, 'Activo', 1, getdate(), 11)
go
insert into Interactions.Comentario (ID_Comentario, ID_Publicacion, Estado, NumeroCola, Fecha, ID_Amigo) Values (20, 5, 'Activo', 1, getdate(), 15)
go


insert into Interactions.Comentario (ID_Comentario, ID_Publicacion, Estado, NumeroCola, Fecha, ID_Amigo) Values (21, 5, 'Activo', 1, getdate(), 16)
go

select *
from Interactions.Comentario where ID_Publicacion = 1


--delete Interactions.Comentario where ID_Publicacion = 1 and ID_Amigo = 4

--DELETE  Interactions.Comentario
