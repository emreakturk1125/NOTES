
-- AKTİF ÇALIŞAN SQL SERVER VERSİON BİLGİSİ ÖĞRENME
SELECT @@VERSION
--veya
EXEC xp_msver

--- SERVERDA BULUNAN DATABASE LERİ ÖĞRENMEK İÇİN
EXEC sp_databases;
GO
SELECT name FROM master.sys.databases;
GO
SELECT name FROM master.dbo.sysdatabases;

--- TABLODAKİ VAR OLAN İNDEXLERİ GÖR

sp_helpindex 'dbo.FirstTable'


--- TRANSACTION VAR MI KONTROLÜ
select @@TRANCOUNT

--- BULUNDUĞU SESSION DAKİ AÇIK OLAN TRANSACTION'I GÖRMEK İÇİN
DBCC OPENTRAN

--- TÜM SESSIONLARDAKİ AÇIK TRANSACTION'I GÖRMEK İÇİN
'? araştır'


--- ISOLATION LEVEL ÖĞRENME
SELECT
CASE transaction_isolation_level
WHEN 0 THEN 'Unspecified'
WHEN 1 THEN 'ReadUncommitted'
WHEN 2 THEN 'ReadCommitted'
WHEN 3 THEN 'Repeatable'
WHEN 4 THEN 'Serializable'
WHEN 5 THEN 'Snapshot'
END AS TRANSACTION_ISOLATION_LEVEL
FROM sys.dm_exec_sessions
where session_id = @@SPID

--- ISOLATION LEVEL TANIMLARI
--* Read Uncommitted
(Okuma Yapılmamış): Bu izolasyon seviyesinde, başka bir işlem tarafından yapılmış ancak henüz tamamlanmamış değişiklikleri okumak mümkündür. Bu, diğer işlemler tarafından yapılan değişiklikleri görmek için izin verir, ancak bu değişikliklerin tamamlanmama riski vardır.

--* Read Committed
(Okuma Yapılmış): Bu izolasyon seviyesinde, başka bir işlem tarafından yapılmış ancak tamamlanmış değişiklikleri okumak mümkündür. Bu, tamamlanmış değişiklikleri görmek için izin verir, ancak henüz tamamlanmamış değişiklikleri görme riski vardır.

--* Repeatable Read
(Tekrarlanabilir Okuma): Bu izolasyon seviyesinde, bir işlem bir satırı okurken, diğer işlemler tarafından değiştirilmesine veya silinmesine izin verilmez. Ancak, bir işlem aynı sorguyu tekrar çalıştırdığında, sonuçlar arasında tutarlılık sağlanır.

--* Serializable 
(Serileştirilebilir): Bu izolasyon seviyesinde, aynı anda aynı verilere erişen birden fazla işlem arasında tam bir izolasyon sağlanır. Bu, işlemlerin paralel olarak çalışmasını engeller ve tüm işlemlerin sıralı olarak gerçekleşmesini sağlar.

--* Snapshot: 
Bu izolasyon seviyesinde, her işlem belirli bir anlık görünümü görür. Diğer işlemler tarafından yapılan değişikliklerin bu anlık görünümü etkilemesine izin verilmez. Bu, işlemlerin birbirinden izole olduğu ve aynı anda çalışabildiği bir izolasyon seviyesidir.


--- BULUNDUĞUN SESSION HAKKINDA BİLGİ ÖĞRENMEK İÇİN
sp_who2 77


--- BLOKE EDİLMİŞ REQUESTLERİ GÖRMEK İÇİN
SELECT -- use * to explore
session_id AS spid,
blocking_session_id,
command,
sql_handle,
database_id,
wait_type,
wait_time,
wait_resource
FROM sys.dm_exec_requests
WHERE blocking_session_id > 0;

--- BLOKLAYAN SESSION ID'Yİ DURDURMA KOMUTU
KILL 56

--- SORGU İÇİN ZAMAN AŞIMI SÜRESİ EKLEME, SÜRE AŞILSIĞI ZAMAN (Lock request time out period exceeded.)  HATASI ALINIR
SET LOCK_TIMEOUT 5000;
SELECT productid, unitprice
FROM Production.Products -- WITH (READCOMMITTEDLOCK)
WHERE productid = 2;


--- TEMPTABLE OLUŞTURMA
# ile temptable oluşturulursa bulunduğun sessiona özel temptable dır
## ile temptable oluşturulursa global temptable dır. her sessionda kullanılabilir


--- VERİTABANI İSTATİSTİKLERİNİ GÜNCELLEME (CustomersJoin tablosunun istatistiklerini günceller)  
use [TSQLDATA]
GO
UPDATE STATISTICS  [Ali].[CustomersJoin]
WITH FULLSCAN
go

--- DATABASE İÇİNDEKİ TÜM İSTATİSTİKLERİ GÜNCELLER
sp_updatestats

-- New Query İçerisinde Bir tablo seçili iken "Alt + F1" o tablo hakkında bilgiler verir 
'Alt + F1'

---  TABLONUN İLİŞKLİ OLDUĞU TABLOLARI GÖR
SELECT
    fk.name 'FK Name',
    tp.name 'Parent table',
    cp.name, cp.column_id,
    tr.name 'Refrenced table',
    cr.name, cr.column_id
FROM 
    sys.foreign_keys fk
INNER JOIN 
    sys.tables tp ON fk.parent_object_id = tp.object_id
INNER JOIN 
    sys.tables tr ON fk.referenced_object_id = tr.object_id
INNER JOIN 
    sys.foreign_key_columns fkc ON fkc.constraint_object_id = fk.object_id
INNER JOIN 
    sys.columns cp ON fkc.parent_column_id = cp.column_id AND fkc.parent_object_id = cp.object_id
INNER JOIN 
    sys.columns cr ON fkc.referenced_column_id = cr.column_id AND fkc.referenced_object_id = cr.object_id
	where tp.name = 'ControlDevice'
ORDER BY
    tp.name, cp.column_id 


--- KOLONUN BULUNDUĞU TABLOYU GÖRMEK İÇİN
 SELECT
  sys.columns.name AS ColumnName,
  tables.name AS TableName
FROM
  sys.columns
JOIN sys.tables ON
  sys.columns.object_id = tables.object_id
WHERE
  sys.columns.name = 'totalArea'


--- TEXT' GÖRE STORED PROCEDURE BULMA
SELECT name
FROM sys.objects
WHERE type_desc = 'SQL_STORED_PROCEDURE'
  AND OBJECT_DEFINITION(object_id) LIKE '%Müşteri sözleşmesi bulunamadı%';

-- Veri Tabanı Sahiplerini Bulma

SELECT	name AS 'Database', suser_sname(owner_sid) AS 'Database Owner'
FROM sys.databases;

-- Veri Tabanı Dosya Bilgilerini Alma

SELECT
    DB.name AS 'Database',
    MF.Name AS 'Logical File Name',
    MF.physical_name AS 'Physical File',
    MF.state_desc AS 'Status',
    CAST((MF.size*8)/1024 AS VARCHAR(26)) + ' MB' AS 'File Size (MB)',
    CAST(MF.size*8 AS VARCHAR(32)) + ' Bytes' as 'File Size (Bytes)'
FROM 
    sys.master_files MF
    INNER JOIN sys.databases DB ON DB.database_id = MF.database_id
ORDER BY
    DB.name;

-- Kullanıcı Stored Procedurleri ve Fonksiyonları Bul

EXECUTE [dbo].[sp_stored_procedures] @sp_owner ='dbo';

-- Stored Procedure ve Fonksiyon Bilgilerini Alma
-- sp bilgileri
SELECT * FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_TYPE = N'PROCEDURE' and ROUTINE_SCHEMA = N'dbo' ;

--fonksiyon bilgileri
SELECT * FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_TYPE = N'FUNCTION' and ROUTINE_SCHEMA = N'dbo' ;

-- Tablo Listesini Alma
SELECT * FROM INFORMATION_SCHEMA.TABLES ORDER BY TABLE_NAME;

-- Veri Tabanı Boş Alanı Bulma
EXEC sp_spaceused;

-- Tablo Bilgilerini Bulma
Use TSQLDATA;
Go

EXEC sp_spaceused 'HR.Employees'


-- Veri Tabanı Bilgileri
-- Veri Tabanı Compatibility Level Öğrenme
SELECT name, compatibility_level 
	,version_name = 
	CASE compatibility_level
		WHEN 65  THEN 'SQL Server 6.5'
		WHEN 70  THEN 'SQL Server 7.0'
		WHEN 80  THEN 'SQL Server 2000'
		WHEN 90  THEN 'SQL Server 2005'
		WHEN 100 THEN 'SQL Server 2008/R2'
		WHEN 110 THEN 'SQL Server 2012'
		WHEN 120 THEN 'SQL Server 2014'
		WHEN 130 THEN 'SQL Server 2016'
		WHEN 140 THEN 'SQL Server 2017'
		WHEN 150 THEN 'SQL Server 2019'
		WHEN 160 THEN 'SQL Server 2022'
	END
FROM sys.databases

--- ROW_NUMBER() Over
Use AdventureWorks2022
Go
Select *
From
		(
			Select *,
				   ROW_NUMBER() Over(Order By SalesOrderDetailID ASC) as TopRow,
				   ROW_NUMBER() Over(Order By SalesOrderDetailID DESC) as BottomRow
			From Sales.SalesOrderDetail
		) as a
Where TopRow = 1 or BottomRow = 1;

-- CPU time = 1438 ms,  elapsed time = 666 ms
-- Neden CPU time Elapsed time'dan buyuk
-- Sebebi Parallelism
-- Execution Plan detaylarına bakalım bunu goruruz
  
-- Kullanılacak MAXDOP sayısını kodumuzda belirtebiliriz

Select *
From
		(
			Select *,
				   ROW_NUMBER() Over(Order By SalesOrderDetailID ASC) as TopRow,
				   ROW_NUMBER() Over(Order By SalesOrderDetailID DESC) as BottomRow
			From Sales.SalesOrderDetail
		) as a
Where TopRow = 1 or BottomRow = 1
Option (MAXDOP 1);
-- Yukarıdaki Option (MAXDOP 1) ile parallelism meydana gelmez
-- Yukarıdaki Option (MAXDOP 2) ile parallelism meydana gelir
-- MAXDOP ile o sorgunun kaç tane thread ile çalışmasını istiosan sorgu bazında, performans yönünden farkederse raporlard vs. kullanılabilir
-- Default olarak (MAXDOP 0) ise sistemdeki maximum threadi kullanır



SELECT
		 c.usecounts
		,c.objtype
		,t.text
		,q.query_plan
		,size_in_bytes
		,cacheobjtype
		,plan_handle
FROM sys.dm_exec_cached_plans AS c
CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS t
CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS q
WHERE	t.text LIKE '%select% *%' AND
		q.dbid = (select database_id from sys.databases where name ='AdventureWorks2019')
ORDER BY c.usecounts DESC










