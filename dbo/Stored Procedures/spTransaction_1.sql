

CREATE PROCEDURE [dbo].[spTransaction_1]
as
begin
	begin tran

		update Table_A set item = 'Giorgos from Transaction 1' where id = 1

		waitfor delay '00:00:11'

		update Table_B set item = 'Manolis from Transaction 1' where id = 1
		
	commit transaction
end