<-----------------------  *********** NOTLAR *********** ------------------------>

--> ((dbo) Sorgu çekerken tabloların başında dbo olmalıdır. Performansı etkiler)
--> ((SP) Stored Procedure yazarken isimlendirme yaparken başına SP olarak koyma çünkü ilk sistem sp lerinde arama yapar)
--> (Bir kolona göre index create edilirken fill factor oranı verebilirsin. Vermez isen database seviyesinde default ayarlı oran ne ise o şekilde fill factor oranı tanımlanır)
--> (Fill Factor, Fragmantasyon) 
--> (Tarih filtreli sorgularda en performanslı sıralama olarak '20110101', '2011-01-01' şeklinde aramaktır.)
--> (Arama yaparken Year(OrderDate) ile aramak sakıncalı, perfomansı düşürürür.)
--> (Database de tarih alanı hangi formatta tutuluyor olursa olsun, arama yaparken 'yyyymmdd' şeklinde arayabilirsin en performanlı olan budur)
--> (Veritabanı İstatistiklerini Güncelleme, sorgu performansını artırır)
--> (Index Fragmantasyon oranı  %20 altı, %20 - %30 arası reorganize,  %30 üstü rebuild yapılmalıdır)
--> reorganize (yeniden düzenler) ve rebuild (sıfırdan oluşturur) işlemleri aynı zamanda istatistikleri de günceller
--> (Sorgu performansı için her zaman JOIN kullan, subquery lerden uzak dur)
--> (Veritabanının ya da  bir tablonun istatistiklerini güncellemek, performansı artırır )
--> (ÖNEMLİ : CROSS APPLY, CTEs, Derived Table)
--> BİR TABLO İLE ALAKALI TAVSİYE ALMAK İÇİN
  Sorgu seçildikten sonra  SHİFT + 10 > Analize Query in Database ...  > Start Analize 'Hocaya tekradan sor ???'
--> Indexleri detaylı görebilmek için Tablo Adına göre
   sp_helpindex 'Ali.sod1'; 
--> Not In yerine Not Exists  kullan
--> Key LookUp olanları index te include olrak ekle

--> https://statisticsparser.com/
-- Bu site ile Execution Plan sonunda gelen mesajlardaki bilgiyi, bu siteye yapistirip ve analiz edilir

--> (Derived Table)

Select * from (
 select * from Sales.Orders
) as TabloAdi

--> (CTEs : (Her zaman Derived Table Yerine CTEs kullan)')  

With TabloAdi as (
 select * from Sales.Orders
)
select * from TabloAdi

--> (CROSS APPLY)

-- CROSS APPLY, bir dış sorgunun her bir satırı için iç sorgunun çalıştırılmasını sağlar ve her satır için iç sorgunun sonucunu döndürür.
-- İşlevsel olarak, CROSS APPLY, INNER JOIN ile benzerdir, ancak CROSS APPLY, iç sorgudaki dizi işlemlerini gerçekleştirebilme yeteneği ile daha esnek bir yapıya sahiptir.

SELECT t1.*, t2.* FROM Table1 t1
CROSS APPLY (
    SELECT * FROM Table2 WHERE Table2.ID = t1.ID
) AS t2;

-- Bu sorguda, Table1 ve Table2 tabloları arasında her satır için bir eşleşme sağlanır ve Table2'deki ilgili satırlar CROSS APPLY operatörü ile getirilir. 
-- Bu, Table1'deki her bir satırın Table2'deki ilgili verilerle birleştirilmesini sağlar.



 --> (DERİVED TABLE & CTE's BENZER SORGU ÖRNEĞİ)

SELECT 
	Cur.orderyear,
	Cur.numcusts AS curnumcusts, 
	Prv.numcusts AS prvnumcusts,
	Cur.numcusts - Prv.numcusts AS growth
FROM 
(
	SELECT YEAR(orderdate) AS orderyear, COUNT(DISTINCT custid) AS numcusts FROM Sales.Orders GROUP BY YEAR(orderdate)
) AS Cur

LEFT OUTER JOIN

(SELECT YEAR(orderdate) AS orderyear, COUNT(DISTINCT custid) AS numcusts FROM Sales.Orders GROUP BY YEAR(orderdate)
) AS Prv

ON Cur.orderyear = Prv.orderyear + 1;

-- Yukarıdaki islemimizi CTEs ile yapalım


-- CTEs örnek 1
WITH YearlyCount AS
(
	SELECT YEAR(orderdate) AS orderyear,
	COUNT(DISTINCT custid) AS numcusts
	FROM Sales.Orders
	GROUP BY YEAR(orderdate)
)

SELECT Cur.orderyear,
Cur.numcusts AS curnumcusts, Prv.numcusts AS prvnumcusts,
Cur.numcusts - Prv.numcusts AS growth
FROM YearlyCount AS Cur
LEFT OUTER JOIN YearlyCount AS Prv
ON Cur.orderyear = Prv.orderyear + 1;
-- CTEs örnek 2 (Birden fazla CTEs tanımlamak)

WITH
C1 AS
(
	SELECT YEAR(orderdate) AS orderyear, custid
	FROM Sales.Orders
),
C2 AS
(
	SELECT orderyear, COUNT(DISTINCT custid) AS numcusts
	FROM C1
	GROUP BY orderyear
)
SELECT orderyear, numcusts
FROM C2
WHERE numcusts > 70;



--> (Sql Server Index Yapısı Hakkında Kaynak )

-- https://ezgigokdemir.medium.com/sql-server-i%CC%87ndeks-yap%C4%B1s%C4%B1-98337c3b1bba 

--> (Index Çalışma Yapısı)

--Sql Server’da bir tabloya index tanımlandığı zaman o tablodaki verileri B-Tree yapısına göre sıralar. B-tree yapısının en üst node’u Root level şeklinde adlandırılır.
--Root level’in bir altında ise Intermediate level’ler vardır. B-Tree yapısına göre Root level bir tane olur, Intermediate level ise tablodaki veri sayısına göre birden fazla olabilir.
--En alt kısımda ise Leaf Node’lar yani veriyi asıl tutan yapılar vardır. Aramaya en üstten başlanıp en alt level’a kadar gelinir.
--Index tipine göre leaf node’larda tutulan veri değişiklik gösterecektir. Index’ler tablodaki veriler değiştiği zaman otomatik olarak güncellenirler.

-- **(B-Tree & Binary Search İlişkisi)** 
--B-Tree yapısı, verileri sıralı bir şekilde saklar ve arama işlemlerini hızlandırmak için logaritmik zaman karmaşıklığına sahip olur.
--Binary Search ise, sıralı bir dizide hızlı arama yapmak için kullanılan bir algoritmadır ve B-Tree yapısının herhangi bir düğümünde uygulanabilir.

--> (İSTİSTİKLERİ ÖĞRENME)

Set Statistics IO ON
set statistics time on
Select *
From Sales.Customers

--Messages kısmında şu şekilde bir sonuc karşımıza gelir
-- Table 'Customers'. Scan count 1, logical reads 5, physical reads 1, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
--  Yani SQL diyor ki (logical reads 5) memory den, 5 tane 8 Kbyte lık page okudum
--Ornek olarak logical reads 20000 olsaydı => 20.000 * 8 Kbyte / 1024 = 156 Mbyte veri okumus oluyor

--> (INDEX SCAN İŞLEMLERİ)

--- scan count,       =>
--- logical reads 5,  => (MEMORY den okur)
--- physical reads 1, => (Diskten okur)

--- Table Scan   --> Performansı en kötü dür. Herhangibir index yoktur
--- Index Scan   --> primary keyine göre arama yapar 1 milyar veri varsa  ve arayacağın veri en sonda ise 1 milyar veriyi de okur 
--- Index Seek   --> ilgili verinin binary search e göre yani ikili arama yapar


--> Table Scan (Tablo Tara): 
/*
  SQL Server, bir sorgu çalıştırıldığında, veritabanındaki bir tabloya erişmek için farklı yöntemler kullanır. 
  Table Scan, SQL Serverın bir tabloyu tüm satırlarını tek tek okuyarak taramasını ifade eder. 
  Bu yöntem, tablodaki tüm verilere erişmek için kullanılır. Table Scan, genellikle küçük tablolar veya sorgulanan veri kümesi üzerinde uygun bir index olmadığında kullanılır. 
  Ancak büyük tablolar üzerinde kullanıldığında performansı düşürebilir.
*/

--> Index Scan (İndeks Tara): 
/*
  Bir SQL Server sorgusu belirli bir index olmadan bir tabloya erişmek zorunda kaldığında veya bir index sorgunun gereksinimlerini tam olarak karşılamıyorsa, Index Scan kullanılır.
  Index Scan, bir index üzerindeki tüm satırları taramak için kullanılır. Bu, index sütunlarının kullanıldığı, ancak sorgunun tam olarak örtmediği durumlarda gerçekleşir.
  Index Scan, veritabanında geniş bir aralığı taramak için etkilidir ancak tüm verilere erişmek için index kullanılmamışsa maliyetli olabilir.
*/

-->Index Seek (İndeks Arama): 
/*
  Index Seek, bir SQL Server sorgusunun belirli bir indexi kullanarak doğrudan belirli bir satır veya satırlara erişmesini ifade eder. 
  Bu, index üzerinde yapılan bir aramada kullanılan en verimli yöntemdir çünkü belirli bir satırı bulmak için direkt olarak index'e gidilir ve tüm index taraması yapılmaz. 
  Index Seek, sorgunun veritabanında belirli bir satırı veya satırları hızlı ve etkin bir şekilde bulmasını sağlar, bu da genellikle performansı artırır.
*/

-->Key Look Up 
/*
   Where şartına göre index attığın kolon dışında, select sorgusunda farklı kolonlarıda çekersen o farklı kolonları key look up yaparak arar
   Keylookup ı önlemek için index atarken <include> yaparak diğer kolonlarda eklenmelidir
*/

--> RID LOOKUP
/*
  Clustered Index (Primary Key) yoksa RID lookup yapar
*/
 --> (AD HOC QUERY & STORED PROCEDURE FARKI)
 /*
  AD HOC QUERY (Normal sorgular), her seferinde çalışma şekli bu şekildedir. =>  (1. query, 2. parse, 3. optimize, 4. compile, 5. execute, 6. result)
  STORED PROCEDURE,  sp ilk create edilirken execution planı 1 defa oluşturulur. Sp her çağrıldığında ise sadece (5. execute, 6. result)  kısımlar tekrar tekrar çalışır. Bu da performansı olumlu yönde etkiler 
 */

 -------------------- JOIN İŞLEMLERİ -------------

 --> Merge Join
 -- indexli kolonların eşleştirilmesi ile oluşan join şekli en performanslıdır.

 --> Hash Join
 -- indexsiz kolonların eşleştirilmesi ile oluşan join şekli

 --> Nested Loop
 '???'


-----------------  MESSAGE KISMINDAKİ TANIMLAMALAR ------------------ 

-->  "Table"					Tablo ismi
-->  "Scan count"				Tablo üzerinde yapılan Scan/Seek sayısı
-->  "logical reads"			Cache/Önbellekten okunan sayfa
-->  "physical reads"			Diskten okunan sayfa sayısı
-->  "read-ahead reads"		    Sorgu için önbelleğe çekilen sayfa sayısı
-->  "lob logical reads"		Cache/Önbellekten okunan text, ntext, image, varchar(max), nvarchar(max), varbinary(max)  ve columnstore index içeren sayfalar için yapılan okuma işlemi
-->  "lob physical reads"		Diskten okunan text, ntext, image, varchar(max), nvarchar(max), varbinary(max)  ve columnstore index içeren sayfalar için yapılan okuma işlemi
-->  "lob read-ahead reads"	    Sorgu için önbelleğe çekilen text, ntext, image, varchar(max), nvarchar(max), varbinary(max)  ve columnstore index içeren sayfalar için yapılan okuma işlemi

/*
Demo
Fazla page okuyacak bir sorgu yazıyorum, 
read-ahead reads ve diğer istatistik verilerini görebilmek için 
STATISTICS IO ON konumuna getiriyorum.

Ara adım : 
		Buffer cache temizlemek için kullandığımız DBCC komutunu çalıştırıyorum 
		bu sayede read-ahead reads‘ın devreye girmesini umuyorum.

Not : 
		Canlı ortamlarda çalıştırılması, 
		şirket çalışanlarının umarsızca “veritabanı yavaşladı” 
		diyerek sağa sola koşuşturmasına sebep olabilir
		:)

*/



--> Recover Crashed Query in SSMS
/*
	SSMS bir anda kapandı ve yeniden basladiginda duzgun kaydedilmeyen Query'ler karsimiza gelir
	ve bize kurtarmamız icin bir secenek olarak cikar
	Eger bu secenek gelmezse ne yapacagiz bir bakalım
	
	C:\Users\KULLANICIADI\Documents\Visual Studio 2017\Backup Files\Solution1

	C:\Users\alito\Documents\Visual Studio 2017\Backup Files\Solution1
*/

---> Kısayollar
/*
	 Tools >> Options >> Environment >> Keyboard >> Query Shorcuts >> altında gorebiliriz ve yenilerini tanımlayabiliriz
*/

--> INDEX Yapıları
/*
SQL Server Index Yapısı
Index, veri tabanı tabloları üzerinde tanımlanan ve veriye daha az işlemle daha hızlı ulaşan veri tabanı nesneleridir.
Indexler hakkında klasik bir örnek olarak telefon rehberi verilebilir. 
Telefon rehberindeki kayıtların sıralı olmaması durumunda, yani her kaydın telefon defterinde rastgele tutulması durumunda,
arayacağımız bir isim için tüm rehberi gezmemiz gerekecek. 
Ama rehberinizdeki kayıtlar sıralı olsaydı, aradığımız ismin rehberin ortasındaki isimden 
ileride mi yoksa geride mi olduğuna bakabilirdik. Bu şekilde aradığımız verileri eleyerek bir kaç adımda istediğimiz 
sonuca ulaşabilirdik. Bu örnekteki gibi verinin sıralı tutulmasını sağlayan nesnelere index denir.

A.	Index Prensibi
Yeni bir veri tabanı oluşturduğumuzda veri tabanımızın bulunduğu dosyaları belirtiriz. 
Sql Server bu dosyaları fiziksel olarak değil mantıksal olarak 8 KB’lık bloklara böler. 
Bu bloklara page denir. Bundan dolayı dosyanın ilk 8 KB’ı page0, bir sonraki 8 KB’ı page1 olur ve bu şekilde devam eder. 
Page’lerin içinde ise tablolardaki satırlara benzeyen ve adına row denilen yapılar bulunur. 
Sql Server page’ler üzerinde başka bir mantıksal gruplama daha yapar; 
art arda 8 tane page’in bir araya gelmesiyle oluşan 64 KB büyüklüğündeki veri yapısına extent denir. 
Bir extent dolduğunda; bir sonraki kayıt, kayıt boyutu büyüklüğünde yeni bir extent’e yazılır.
 
Her page içinde bulunan satır sayısı aynı değildir. 
Page’ler, veri büyüklüğüne göre değişen satırlara sahiptir ve bir satır sadece bir page içinde olabilir. 
Sql Server aslında satırları okumaz bunun yerine page’leri okuyarak verilere ulaşır.
 
 
Sql Server’da bir tabloya index tanımlandığı zaman o tablodaki verileri aşağıdaki gibi bir tree yapısına göre organize eder.
 
Bu tree yapısının en üst node’u Root level diye adlandırılır. 
Aslında buradan başlayarak rehber örneğinde olduğu gibi sağa veya sola dallanarak kaydı bulmaya çalışır. 
Root level’in bir altında ise Intermediate level’ler vardır. Bir tane Root level olması gerekirken, 
Intermediate level’ler ise tablodaki veri sayısına göre birden fazla olabilir. 
En alt kısımda ise Leaf Node’lar yani veriyi asıl tutan yapılar vardır. 
Aramaya en üstten başlanıp en alt level’a kadar gelinir. Index tipine göre leaf node’larda tutulan 
veri değişiklik gösterecektir.
 
Yukarıdaki resimde görüldüğü gibi aradığımız veriyi üç adımda bulabiliriz. 
Ama index kullanılmasaydı, yani veriler yukarıdaki gibi tree yapısında organize edilmeseydi tüm kayıtlar 
gezilerek veriye ulaşabilirdi. 
Veriye ulaşmak için her zaman leaf level’a kadar inmek gerekir.

a.	Heap Table
Sql Server’da heap table adında bir kavram yok. Bir tabloya heap denilmesi aslında onun üzerinde bir index tanımlı olup olmamasına bağlıdır. Sql Server bir veriyi indexsiz bir tabloya eklerken sıralı olarak diskte tutmaz ve veriler rastgele data page’lere yazılır. Bu şekilde olan tablolar heap diye adlandırılır. Yani üzerinde clustered index olmayan tablolar heap table’dır diyebiliriz. Heap table üzerinde bir veri arandığında Sql Server tablonun kayıtlarına sırayla erişir ve aradığımız kayıtla eşleştirir. Kayıt bulunsa bile eşleşebilecek başka kayıt var mı diye tüm kayıtlarda karşılaştırma işlemi yapar. Sql Server’ın yaptığı bu işleme Table Scan denir. Bu işlem tablodaki kayıt sayısına göre çok uzun zaman alacaktır. Clustered Index tanımlı olan tablolara göre avantajları da vardır. Bu tablolarda ekstra index bakım maliyeti ve clustered index tree yapısı için ekstra alana ihtiyaç yoktur.
 
b.	Clustered Table
Üzerinde clustered index tanımlı tablolara denir. Sorgu index tanımlanmış kolonları kullanırsa, veriye çok hızlı erişim sağlanır. Data page’ler veriye hızlı erişim için birbirine bağlıdır. Heap table’lara göre INSERT, UPDATE ve DELETE işlemlerinde ekstra index bakım maliyeti vardır.

c.	Index Çeşitleri
Sql Server’da indexler temelde clustered ve non-clustered index olmak üzere ikiye ayrılır. Leaf node’larda tutulan verinin kendisi ise clustered, verinin hangi pagede tutulduğunu gösteren pointer ise non-clustered index diye adlandırılır.

d.	Clustered Index
Yukarıda da bahsettiğimiz gibi, clustered index’ler tablodaki veriyi fiziksel olarak sıralar. 
Bir tablo fiziksel olarak sıralandığından tablo üzerinde sadece bir tane clustered index tanımlanabilir. 
Clustered index için seçilecek kolon veya kolonlar sorgulardaki en fazla kullanılan kolonlar olmalıdır. 
Veriler, bu kolonlara göre fiziksel olarak sıralanacağından çok hızlı erişilir. 
Ayrıca seçilen kolonun çok değiştirilmeyen bir alan olması gerekir. 
Çünkü index’e ait kolonun değişmesi demek tüm index’in yeniden organize olması yani fiziksel olarak yeniden 
sıralanması anlamına gelir. Sql server index ihtiyacını aslında kendisi belirler. 
Bizim tanımlayacağımız index’leri kullanıp kullanmamaya kendisi karar verir.

CREATE CLUSTERED INDEX IX_IndexName ON TableName (Column1);

e.	Non-Clustered Index
Non-Clustered Index veriyi fiziksel değil mantıksal olarak sıralar. 
Bu index’lerin leaf node’larında verinin kendisi değil nerede olduğu bilgisi tutulur. 
Tablo üzerinde en fazla 999 tane non-clustered index tanımlanabilir. 
Non-clustered index’ler veriye doğrudan erişemez. Heap üzerinden ya da bir clustered index üzerinden erişebilir. 
Bu index’i oluştururken sorgumuzun koşul kısmında sık kullandığımız kolonlardan oluşturulması gerekir.

CREATE NONCLUSTERED INDEX IX_IndexName ON TableName (Column1);

Bir tabloda en fazla bir tane clustered index, 999 tane de non-clustered olabilir demiştik. 
Sql Server’da bir index en fazla 16 kolon içerebilir ve toplam boyutu 900 byte’ı aşmaması gerekir. 
Ayrıca büyük boyutlu alanlar yani varchar(max), nvarchar(max), xml, text ve image türüne 
sahip kolonlar üzerinde herhangi bir index tanımlaması yapılamaz. 
Hep index’in avantajlarından bahsettik ama maliyetleri de çok fazladır. 
Her index oluşturduğunuzda veri tabanınızdan bir alan işgal edilir. 
Index’lerin insert, update ve delete işlemlerinde tekrardan organize olması gerekir ve 
bu durum tablo performansını olumsuz etkiler. 
Bir tabloda index oluşturulmaya başlandığında Sql Server tabloyu kitler ve erişimi engeller. 
Index oluşturma işlemi tablodaki veri sayısına göre kısa veya uzun sürebilir. 
Dolayısıyla index seçiminde çok düşünüp dikkatli karar vermeliyiz.

f.	Unique Index
Verinin tekilliğini sağlamak için kullanılır. 
Veri tekrarını engeller ve tanımladığımız kolona göre veri çekmeyi hızlandırır. 
Tablomuza bir primary key veya unique constraint tanımladığımız zaman otomatik unique index tanımlanır. 
Bu index’i birden fazla kolona tanımladığımız zaman tekillik tek kolon üzerinden değil de tanımlandığı 
kolonlar üzerinden oluşuyor. Tanımlandığı kolona sadece bir kere null değeri eklenebilir. 
Hem clustered hem de non-clustered index’ler unique olarak tanımlanabilir.

CREATE UNIQUE INDEX AK_IndexName ON TableName (Column1);

g.	Filtered Index
Bu index türünde ise tüm tabloya index tanımlamak yerine, belirlenen koşula uyan veriye index tanımlanır. Hem performansı arttırır hem de index bakım maliyeti düşük olur. Normal bir non-clustered index’e göre daha az yer kaplar.

CREATE NONCLUSTERED INDEX IX_IndexName ON IndexName (Column1, Column2) WHERE …

Create index NIXYasFiltered On Ali.Kisiler(Yas) Where yas >= 60

h.	Composite Index
Tablo üzerinde tanımlanan index tek kolon üzerinden değil de birden fazla kolon üzerinden tanımlandıysa bu index türüne composite index denir. Index kısıtlamalarında bahsettiğimiz gibi, bir tabloda en fazla 16 kolona kadar composite index tanımlanır ve 900 byte sınırını geçmemelidir. Hem clustered hem de non-clustered index’ler composite olarak tanımlanabilir. Bu index tanımında kolonların hangi sırada yazıldığı da çok önemlidir. Index performansının artması için çeşitliliği fazla olan kolon başa yazılmalıdır. Yani tablodaki verilere göre tekil veri sayısı fazla olan kolon başa yazılır.
CREATE NONCLUSTERED INDEX IX_IndexName ON IndexName (Column1, Column2)

i.	Covered Index

Öncelikle bu index türüne neden ihtiyaç duyduğumuzu açıklayalım. Normalde bir sorguda erişmek istediğimiz alanlar index tanımında mevcut ise bu index ile birlikte veriye direkt olarak leaf node’lardan ulaşabiliriz. 
Ama index tanımından farklı bir kolon veya kolonları çekmek istediğimiz zaman, öncelikle index koşuluna uyan veriler çekilir ve key değeri belirlenir. 
Daha sonra bu key değeri üzerinden index’te tanımlı olmayan kolonların değerlerine erişilir. Bu işleme key lookup denir.
Sql Server veriye erişmek için fazladan bir key lookup işlemi yapar ve bu da I/O performansını olumsuz etkiler. Neden composite index tanımlamıyoruz diye sorabilirsiniz. 
Composite index’te 16 kolon ve 900 byte sınırı olduğundan istediğimiz kadar kolon ekleyemeyiz.
Kısıt olmasa dahi, index tanımımızda fazla kolon olması index boyutunu o kadar arttıracaktır ve yapılacak update, insert gibi işlemlerde index yeniden organize olacağından performans kaybına yol açacaktır.
Bu problemin çözümü için covered index’ler kullanabiliriz.

CREATE NONCLUSTERED INDEX IX_IndexName ON TableName (Column1) INCLUDE (Column2, Column3);

Index tanımında belirtilen INCLUDE seçeneği ile index dışında kalan ve sorgumuzda bulunan kolonları ekleyebiliriz. Sql Server bu veriye erişirken ekstradan bir key lookup işlemi yapmaz ve doğrudan erişir. INCLUDE seçeneği ayrıca bazı kısıtlamaları da ortadan kaldırır. Hatırlarsanız büyük boyutlu veri tutan varchar(max), nvarchar(max), xml, text ve image gibi alanları index tanımına ekleyemiyorduk. INCLUDE seçeneği ile eklenebilir. Ayrıca 16 kolon ve 900 byte kısıtı da ortadan kalkmış oluyor. INCLUDE seçeneği sadece non-clustered indexlerle tanımlanabilir.
Mümkün olduğunca sorgularımızda az sütun seçmeye özen göstermeli ve select * ifadesinden kaçmalıyız. Index’lerin include kısmını sütunlarla doldurmadan önce maliyeti hesaplayıp buna göre index tanımlamalıyız. Aksi taktirde sorgularımızın performansı daha düşebilir.

j.	Column Store Index
Şimdiye kadar açıkladığımız index türlerinde index’ler satır bazlı tutulur.
Bu index türünde ise kolon bazlı indexleme yapılır. 
Diğer index’lere göre depolama maliyeti düşüktür. 
Genelde verinin daha az yazılıp daha çok okunduğu sistemlerde ve karmaşık filtreleme ve 
gruplama işlemlerinin yapıldığı veri ambarı gibi büyük veri içeren uygulamalarda kullanılır. 
Non-clustered index’e göre 15 kata varan daha fazla sıkıştırma yapar ve 
sorgularda 10 kata kadar performans artışı sağlar.

CREATE COLUMNSTORE INDEX IX_IndexName_ColumnStore ON TableName (Column1, Column2);

k.	Full-text Index
Sql Server’da metin tabanlı aramalarda, 
like operatörünün performansı özellikle metin boyutu büyüdükçe düşmektedir. 
Bunun dışında index kısıtlamalarında bahsettiğimiz gibi 900 byte sınırı da index oluşturmamızı kısıtlar. 
Özellikle büyük boyutlu veri içeren alanlarda (varchar(max), nvarchar(max), xml, text) 
hızlı arama yapabilmek için bu index türünü kullanabiliriz. 
Aslında bu Sql Server’ın sunduğu bir servistir. 

B.	Index Tasarımı
Bu bölüme kadar index çeşitlerinde nasıl tanımlama yapılması gerektiğine değindik. 
Bunları özet olarak toplarsak;
•	Yoğun şekilde veri güncelleme işlemi olan tablolarda, index tanımında mümkün olduğunca az kolon seçmeliyiz.
•	Veri güncellemenin az olduğu tablolarda daha çok index tanımlayabiliriz.
•	Clustered index’i mümkün olduğunca az kolona tanımlamalıyız. 
	İdeal tanımlanma biçiminde clustered index’imiz unique olan kolonda tanımlanmalı ve null değeri içermemeli.
•	Index tanımladığımız kolonda ne kadar tekrarlı veri varsa index performansımız düşük olacaktır.
•	Composite index’lerde kolonların sırasına dikkat etmeliyiz.
•	Computed kolonlara da gereksinimleri karşıladıkça index tanımlanabilir. 
	Yani compute edilen değerin deterministik olması gerekir.
•	Depolama ve sıralama etkileri nedeniyle index tanımlarında kolonlar dikkatli seçilmelidir.
•	Index tanımında kolon sayısı, yapılacak insert, update ve delete işlemlerinde performansı direkt olarak etkileyecektir.

*/

--> İSTATİSTİKLER
/*
	İstatistiklere geri dönecek olursak,

	Bir index oluşturduğumuzda o index’e ait istatistik de oluşur.
	Ama index birden fazla kolon içeriyorsa sadece ilk kolon için istatistik oluşturulur. 
	Index’i rebuild ettiğimizde istatistik te güncellenir.

	Veritabanı bazında istatistiklerle ilgili birkaç ayar vardır.

	Veritabanı üzerinde sağ tıklayarak properties,
	ardından Options sekmesine geçtiğimizde gelen ekranda
	Ornek: TSQLDATA >> Properties >> Options >>
	Buradakileri inceleyelim


	Auto Create Statistics:
		Eğer true olarak set ederseniz sql server’a gelen sorguların 
		where kısmındaki kolonda istatistik yoksa otomatik olarak oluşacaktır.
		Default olarak True’dur. Bu şekilde bırakmanızı tavsiye ederim.

	Auto Update Statistics:
		Eğer true olarak set ederseniz tablodaki satır değişikliği
		%20’yi geçtiğinde istatistik otomatik olarak güncellenir
		Değişiklik %20’yi geçtiğinde gelen ilk sorgu istatistiğin update olmasını bekler.
		Otomatik değeri True’dur. Sisteminizde performans sıkıntısı yoksa True kalabilir.
		Ama False yaparsanız ve istatistikleri update eden bir job’ınız yoksa,
		istatistikler zamanla bozulacağı için sisteminizin performansı giderek azalacaktır.

	Auto Update Statistics Asynchronously:
		Auto Update Statistics özelliği ile beraber kullanılır.
		True olarak set ederseniz İstatistik güncelleme işleminin
		gelen sorguyu bekletmemesi için asenkron olarak çalışmasını sağlamış olursunuz.

	Auto Create Incremental Statistics:
		SQL Server 2014 ile gelen bir özelliktir.
		Eğer veritabanınızda partition varsa çok işinize yarayabilir.
		İstatistiklerinizi partition seviyesinde güncelleyebilirsiniz.
		

İstatistikleri güncellemenin iki yöntemi var.

		Sp_updatestats:
			Veritabanındaki bütün istatistikleri günceller. FULLSCAN yapmaz.

		UPDATE STATISTICS:
			İstatistik, tablo ya da veritabanı bazında istatistiklerinizi 
			UPDATE STATISTICS komutuyla güncelleyebilirsiniz. 

	İstatistiklerle ilgili bilmeniz gereken en önemli şey güncel kalmaları gerektiğidir.
	Güncel kalmalarını sağlamak için yukarda bahsettiğim ayarların dışında istatistikleri
	güncelleyen bir job’ınız olması gerekir. 
	Ben aşağıdaki script’i düzenli çalışan bir job haline getirdim.
	Genelde haftada bir çalışacak şekilde oluşturdum ama bazı sistemlerde 
	istatistik daha hızlı bozuluyor ve güncelledikten birkaç saat sonra 
	istatistik bozulduğu için performans azalmaya başlayabiliyor. 
	O yüzden bir sistemde performans sorunu varsa ilk yapacağımız şeyin 
	istatistikleri güncellemek olması gerekir. Günlük hayattan bir önrek verecek
	olursam çok yoğun kullanılan bir sistemde istatistikleri güncelleyen job’ım 
	saatte bir çalışıyor. Tabi siz ilk olarak haftada bir çalışacak şekilde
	set edip ihtiyaç halinde bu süreyi azaltarak istatistiklerinizi 
	daha sık güncelleyebilirsiniz.

	Instance üzerindeki tüm veritabanlarındaki tüm istatistikleri güncelleyen ve 
	haftada bir çalışacak şekilde job olarak oluşturmanız gereken script’i
	aşağıda paylaşıyorum. Eğer instance üzerinde restoring, 
	read only ya da offline mode’da bir veritabanı varsa script hata verecektir.

-- Tum istatisticleri guncelleyelim
-- indexleri Rebuild veya Reorganize etmek tabiki cozumdur
-- Ancak her zaman yapılmaz ve Execution Plan istatistiklere direk bakar
-- istatistikleri guncellemek ise sistemi yormaz ve 
-- her zaman yapılabilir ve yapılması gereklidir

--> İSTAİSTİK GÜNCELLEME SORGUSU

DECLARE @SQL NVARCHAR(1000) 
DECLARE @DB sysname 

DECLARE curDB CURSOR FORWARD_ONLY STATIC FOR 
   SELECT [name] 
   FROM master..sysdatabases
   -- WHERE [name] NOT IN ('model', 'tempdb','master','msdb')
   WHERE [name] IN ('TSQLDATA')
   ORDER BY [name]
OPEN curDB 
FETCH NEXT FROM curDB INTO @DB 
WHILE @@FETCH_STATUS = 0 
   BEGIN 
   IF DATABASEPROPERTYEX(@DB,'Updateability') = 'READ_WRITE'
   BEGIN
       SELECT @SQL = 'USE [' + @DB +']' + CHAR(13) + 'EXEC sp_updatestats' + CHAR(13) 
       exec sp_executesql @SQL 
END
       FETCH NEXT FROM curDB INTO @DB 
   END 
CLOSE curDB 
DEALLOCATE curDB

*/


---> JOIN TÜRLERİ

/*
	SQL Server’da TSQL sorgusu yazarken kullandığımız JOIN türlerinin
	(yani mantıksal join INNER,LEFT,RIGHT,FULL,CROSS)
	arka planda fiziksel olarak hangi join’e dönüştüğünü ve 
	arka planda dönüştüğü join işleminin performansını 
	nasıl etkilediğini ve nasıl çözeceğimizi inceleyeceğiz 


	SQL Server, bizim TSQL ile yazdığımız JOIN ifadelerini
	arka planda aşağıdaki join türlerine dönüştürür. 
	Bu dönüştürme işlemi yapılırken aşağıdakilerden hangisi 
	daha performanslı çalışacaksa sorguyu o şekilde çalıştırır
	 
	NESTED LOOPS JOIN
	MERGE JOIN
	HASH JOIN
 
	Önce yukardaki kavramları açıklayalım.
	Daha sonrada sorguları kullanarak arka planda hangi join türlerine 
	dönüştüklerini görebileceğimiz örnekler yapacağız.
	Ve sorgunun daha performanslı çalışması için bazı kolonlara
	index ekleyeceğiz. Index ekledikten sonra arka planda 
	yapılan join işleminin(nested loop, merge, hash) nasıl değiştiğini göreceğiz.

	NESTED LOOPS JOIN: 
		Tablolardan birini iç(inner) diğerini ise dış(outer) olarak işaretler ve 
		outer olarak işaretlenen tablodaki her satır için inner olarak
		işaretlenen tablodaki her satırı okur.

		Eğer tablolardan biri küçük ve diğeri büyükse ve 
		büyük tablonun join kolonunda index varsa bu join türü 
		çok performanslı çalışacaktır. 
						   			 		   
	MERGE JOIN: 
		Eğer join olacak iki tabloda küçük değilse 
		fakat 2 tabloda join’e girecek kolonlarına göre
		sıralıysa(join’e girecek kolonlarda index varsa) 
		merge join en performanslı seçenek olacaktır.
		
		Bir örnek üzerinden ilerleyelim,
		
		Aşağıdaki gibi bir join’in yapıldığını düşünün.

		Select * 
		From tablo1
		INNER JOIN tablo2 ON tablo1.a=tablo2.b
 
		Birinci tablodaki a kolonunda bir index var ve sıralı bir yapıda,
		İkinci tablodaki b kolonunda da bir index var ve sıralı bir yapıda,
		
		Böyle bir join sonucunda join’e girecek kolonların ikiside 
		sıralı yapıda olduğu için merge join çok performanslı çalışacaktır.

		Merge Join sıralı olan bu iki kolon ile yapılan bir join işleminde 
		iki kolonu karşılaştırır ve eşitse sonuç olarak döndürür.
		
	HASH JOIN: 
	  En sevmediğimiz join türüdür. 
	  Execution planda görmek istemeyiz.
	  Büyük, sırasız ve index olmayan tablolar join işlemine girerse 
	  SQL Server bu iki tabloyu birleştirebilmek için HASH JOIN yöntemini 
	  kullanmak zorunda kalır.
	  
	  İki tablodan küçük olan belleğe alınarak bir hash table oluşturulur.
	  Daha sonra büyük tablo taranır ve
	  büyük tablodaki hash değeri ile bellekteki hash table’daki
	  hash değeri karşılaştırılarak eşit olanlar sonuç listesine eklenir.
	  
	  
	Peki bu join yöntemlerinden hangisi daha performanslıdır?
	Hangi join türünü hangi join türüne dönüştürmeye çalışmalıyız?

	Hash join’in performanssız bir şekilde çalıştığına hash join’i anlatırken değindik. 
	Peki hash join’i nasıl diğer join türlerine dönüştüreceğiz bir örnek yaparak anlatalım.

	Örneğin INNER JOIN yapmak için kullandığımız sorguyu new query diyerek 
	yeni bir query sayfası açalım ve yapıştıralım.

*/