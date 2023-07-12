


CREATE PROCEDURE [dbo].[usp_db_documentation] 
	@table_search_keys nvarchar(1000) = null, -- e.g. '%cases%'
	@column_search_keys nvarchar(1000) = null -- e.g. , %bi%'
AS
BEGIN

	drop table if exists #tables
	drop table if exists #columns
	drop table if exists #primarykeys
	drop table if exists #defaultconstaints
	drop table if exists #foreignkeys
	drop table if exists #documentation
	drop table if exists ##RA_DB_Doc

	create table #tables
	(
		TABLE_ID int NOT NULL,
		TABLE_NAME nvarchar(100) NOT NULL,
		SCHEMA_ID int NOT NULL,
		SCHEMA_NAME	nvarchar(100) NOT NULL
	)

	declare @tblFilters table
	(
		Id int identity(1, 1),
		LikeFilter nvarchar(100) not null
	)

	insert into @tblFilters
	select TRIM(VALUE) FROM STRING_SPLIT(@table_search_keys, ',')


	declare @cnt smallint = 0
	set @cnt = (select count(*) from @tblFilters)

	
	--============ TABLES =============
	declare @i smallint = 1

	if @cnt > 0
	begin
		while @i <= @cnt
		begin
		
			declare @LF nvarchar(100)

			set @LF = (select LikeFilter from @tblFilters where Id = @i)

			INSERT INTO #tables
			(
				TABLE_ID,
				TABLE_NAME,
				SCHEMA_ID,
				SCHEMA_NAME
			)
			SELECT 
				TBL.object_id AS TABLE_ID,
				TBL.name AS TABLE_NAME,
				SCH.schema_id,
				SCH.name AS SCHEMA_NAME
			FROM
				SYS.tables TBL
				LEFT JOIN SYS.schemas SCH
					ON TBL.schema_id = SCH.schema_id
			where
				tbl.name like (@LF)

			set @i = @i + 1
		end
	end
	else
	begin
		INSERT INTO #tables
		(
			TABLE_ID,
			TABLE_NAME,
			SCHEMA_ID,
			SCHEMA_NAME
		)
		SELECT 
			TBL.object_id AS TABLE_ID,
			TBL.name AS TABLE_NAME,
			SCH.schema_id,
			SCH.name AS SCHEMA_NAME	
		FROM
			SYS.tables TBL
			LEFT JOIN SYS.schemas SCH
				ON TBL.schema_id = SCH.schema_id		
	end


	--============ TABLES & COLUMNS ===============

	;

	with cte as
	(
	select
		sch.schema_id as SCHEMA_ID,
		sch.name as SCHEMA_NAME,
		cast(col.object_id as nvarchar(20)) as TABLE_ID,
		obj.name as TABLE_NAME,		
		cast(col.column_id as nvarchar(5)) as COLUMN_ID,
		col.name as COLUMN_NAME,
		--tps.name as COLUMN_TYPE,
		tps.name + 
			case 
				when tps.name = 'decimal' then '(' + cast(col.precision as nvarchar(20)) + ', ' + cast(col.scale as nvarchar(20)) + ')' 
				when tps.name = 'nvarchar' then '(' + cast(col.max_length/2 as nvarchar(20)) + ')' 
			else ''  
		end as COLUMN_TYPE,
		cast(col.precision as nvarchar(5)) as PRECISION,
		cast(col.scale as nvarchar(5)) as SCALE,
		iif(col.is_nullable = 0 , '', 'YES') as ALLOW_NULLS,
		iif(col.is_identity = 1, 'YES', '') as IS_IDENTITY,
		iif(col.is_computed = 1, 'YES', '') as IS_COMPUTED,
		cast(col.max_length as nvarchar(10)) as MAX_BYTE_LENGTH
	from
		sys.columns col
	inner join sys.objects obj
		on col.object_id = obj.object_id
	inner join #tables tbl
		on col.object_id = tbl.TABLE_ID
	left join sys.types tps
		on col.system_type_id = tps.user_type_id
	left join sys.schemas sch
		on obj.schema_id = sch.schema_id
	where
		obj.type = 'U'
		and obj.name <> 'sysdiagrams'
	)
	select * 
	into #columns
	from
	(
		select *
		from
			cte
		where
			1 = 1
			and cte.COLUMN_NAME like @column_search_keys
			and @column_search_keys is not null

		union 

		select *
		from
			cte
		where
			1 = 1
			and @column_search_keys is null
	) as C
	order by 
		table_name, 
		cast(column_id as int)



	--================== PRIMARY KEYS =====================
	
	SELECT TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, CONSTRAINT_NAME as PRIMARY_KEY_NAME
	into #primarykeys
	FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
	WHERE OBJECTPROPERTY(OBJECT_ID(CONSTRAINT_SCHEMA + '.' + QUOTENAME(CONSTRAINT_NAME)), 'IsPrimaryKey') = 1
	

	--========== DEFAULT & CHECK CONSTRAINTS ===========

	select 
		sch.name as SCHEMA_NAME,
		con.[name] as constraint_name,
		t.[name]  as TABLE_NAME,
		col.[name] as COLUMN_NAME,
		con.[definition] AS DEFAULT_DEFINITION
	into #defaultconstaints
	from 
		sys.default_constraints con
		left outer join sys.objects t
			on con.parent_object_id = t.object_id
		left outer join sys.all_columns col
			on con.parent_column_id = col.column_id
			and con.parent_object_id = col.object_id
		left join sys.schemas sch
			on t.schema_id = sch.schema_id
	order by 
		con.name
                            

	;

	-- FOREIGN KEYS
	select 
		sch.name as SCHEMA_NAME,
		fk_tab.name as FK_TABLE,
		substring(column_names, 1, len(column_names)-1) as [FK_COLUMN],
		pk_tab.name as LOOK_UP_TABLE,
		fk.name as FK_NAME
	into #foreignkeys
	from sys.foreign_keys fk
		inner join sys.tables fk_tab
			on fk_tab.object_id = fk.parent_object_id
		inner join sys.tables pk_tab
			on pk_tab.object_id = fk.referenced_object_id
		left join sys.schemas sch
			on fk_tab.schema_id = sch.schema_id
		cross apply (select col.[name] + ', '
			from sys.foreign_key_columns fk_c
				inner join sys.columns col
					on fk_c.parent_object_id = col.object_id
					and fk_c.parent_column_id = col.column_id
			where fk_c.parent_object_id = fk_tab.object_id
				and fk_c.constraint_object_id = fk.object_id
					order by col.column_id
					for xml path ('') ) D (column_names)
	order by 
		fk_tab.name,
		schema_name(pk_tab.schema_id) + '.' + pk_tab.name
                            
	-- UPDATE THE CANDIDATE KEYS
	UPDATE #foreignkeys 
	SET FK_COLUMN = REPLACE(FK_COLUMN, N'tIMEID, ', '')
	WHERE FK_COLUMN LIKE 'tIMEID, %'

	-- UPDATE THE CANDIDATE KEYS
	UPDATE #foreignkeys 
	SET FK_COLUMN = REPLACE(FK_COLUMN, N', FROMTIMEID', '')
	WHERE FK_COLUMN LIKE 'PARENTID, FROMTIMEID%'

		

	--=============== D O C U M E N T A T I O N ===============

	select
		sch.name as SCHEMA_NAME,
		OBJECTS.name as [TABLE_NAME],
		COL.name as [COLUMN_NAME],
		properties.value as FIELD_DESCRIPTION,
		properties.major_id,
		properties.minor_id
	into #documentation
	from
		sys.extended_properties properties
		left outer join sys.all_objects objects
			on properties.major_id = objects.object_id
		left join sys.schemas sch
			on objects.schema_id = sch.schema_id
		LEFT JOIN SYS.all_columns COL
			ON COL.object_id = properties.major_id
			AND col.column_id = properties.minor_id
	order by
		OBJECTS.name,
		COL.column_id



	--=============== FINAL REPORT ===================
	SELECT 	
		*
	into ##RA_DB_Doc
	FROM
	(
		select
			DISTINCT
			#tables.schema_id as SCHEMA_ID,
			#tables.TABLE_ID,
			'0' AS COLUMN_ID,
			#tables.SCHEMA_NAME,
			#tables.TABLE_NAME,
		
			NULL as COLUMN_NAME,
			isnull(#documentation.FIELD_DESCRIPTION, '') as FIELD_DESCRIPTION,

		
			NULL as COLUMN_TYPE,
			NULL as PRECISION,
			NULL as SCALE,
			NULL as ALLOW_NULLS,
			NULL as IS_IDENTITY,
			NULL as IS_COMPUTED,

			NULL as  IS_PRIMARY_KEY,
			NULL as  DEFAULT_VALUE,
			NULL as FK_LOOKUP_TABLE
		from #tables
		left join #documentation
			on #tables.TABLE_NAME = #documentation.TABLE_NAME
			AND #tables.SCHEMA_NAME = #documentation.SCHEMA_NAME
			and minor_id = 0
		where
			@column_search_keys is null

		UNION

		select
			DISTINCT
			#columns.SCHEMA_ID,
			#columns.TABLE_ID,
			#columns.COLUMN_ID,		
			#columns.SCHEMA_NAME,
			#columns.TABLE_NAME,
			#columns.COLUMN_NAME,		
			isnull(#documentation.FIELD_DESCRIPTION, '') as FIELD_DESCRIPTION,

		
			#columns.COLUMN_TYPE,
			#columns.PRECISION,
			#columns.SCALE,
			#columns.ALLOW_NULLS,
			#columns.IS_IDENTITY,
			#columns.IS_COMPUTED,
			--#columns.MAX_BYTE_LENGTH,

			iif(#primarykeys.PRIMARY_KEY_NAME is not null, 'YES', '') as IS_PRIMARY_KEY,
			iif(#defaultconstaints.constraint_name is not null, #defaultconstaints.DEFAULT_DEFINITION, '') as DEFAULT_VALUE,
			iif(#foreignkeys.FK_COLUMN is not null, #foreignkeys.LOOK_UP_TABLE, '') as FK_LOOKUP_TABLE
		from
			#columns
			left join #primarykeys
				on #columns.TABLE_NAME = #primarykeys.TABLE_NAME
				and #columns.COLUMN_NAME = #primarykeys.COLUMN_NAME
				and #columns.SCHEMA_NAME = #primarykeys.TABLE_SCHEMA
			left join #defaultconstaints
				on #columns.TABLE_NAME = #defaultconstaints.TABLE_NAME
				and #columns.COLUMN_NAME = #defaultconstaints.COLUMN_NAME
				and #columns.SCHEMA_NAME = #defaultconstaints.SCHEMA_NAME
			left join #foreignkeys
				on #columns.TABLE_NAME = #foreignkeys.FK_TABLE
				and #columns.COLUMN_NAME = #foreignkeys.FK_COLUMN
				AND #columns.SCHEMA_NAME = #foreignkeys.SCHEMA_NAME
			left join #documentation
				on #columns.TABLE_NAME = #documentation.TABLE_NAME
				and #columns.COLUMN_NAME = #documentation.COLUMN_NAME
				AND #columns.SCHEMA_NAME = #documentation.SCHEMA_NAME
	) AS U
	order by
		table_name asc,
		cast(column_id as int)

	-- Για να φανούν οι πίνακες σε ξεχωριστό Sheet στο Excel
	update ##RA_DB_Doc
	set COLUMN_NAME = TABLE_NAME, TABLE_NAME = 'Index'
	where COLUMN_ID = 0

	select 
	*
	from 
		##RA_DB_Doc
	order by
		TABLE_NAME,
		cast(column_id as int),
		##RA_DB_Doc.COLUMN_NAME

	--select * from Tables
END
