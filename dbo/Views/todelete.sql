CREATE VIEW todelete
AS
	select top 1000 * from T
	where dt > '2020-09-30'
	order by i
