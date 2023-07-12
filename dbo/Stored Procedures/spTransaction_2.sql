

CREATE PROCEDURE [dbo].[spTransaction_2]
as
begin
	begin tran

		update Table_B set item = 'Manolis from Transaction 2' where id = 1

		waitfor delay '00:00:10'

		update Table_A set item = 'Giorgos from Transaction 2' where id = 1
		
	commit transaction
end