insert into student 
(id,first_name) values (3,'Вася');

--select SUBSTR('абвгде',floor(random()*6+1)::int,1);

insert INTO student(id, last_name)
    select word, string_agg(simvol,'') 
        FROM (select SUBSTR('абвгде',floor(random()*6+1)::int,1) as simvol , floor(random()*6) as word 
        from generate_series(1,16) 
        ) name 
    GROUP by word
    order by word;
UPDATE student Set first_name = (select string_agg(char,'') 
    FROM  (
        SELECT SUBSTR('абвгде', floor(random()*6)::int +1,1) AS char, 
            floor(random()*60) as word
    FROM generate_series(1,160)
    ) x
WHERE word = student.id-3 GROUP BY word
) WHERE first_name = 'Родион'; 

--\df floor \\узнать тип функции]

SELECT LENGTH(last_name) from (select last_name from student) last_name;
SELECT LENGTH(last_name) from student;

select COUNT(*), LENGTH(last_name) from student GROUP by LENGTH(last_name) order by LENGTH;

-- генерим дату рождения (самостоятельно)
select (timestamp '2014-01-10 20:00:00' +
       random() * (NOW() -
                   timestamp '2014-01-10 10:00:00'))::date FROM generate_series(1,10);
select ( date '2015-12-12' + (random()*(timestamp'2014-12-12'-timestamp '2014-11-11' ))  )::date;
--почему-то приведенеи типо отдельно к рандому не работает

--airports name psql -d demo
SELECT  COUNT(*), LENGTH(airport_name) from airports GROUP by LENGTH(airport_name) order by LENGTH limit 100;
-- пробел-люблй символ-любое количество символов- конец строки
SELECT regexp_replace (passenger_name, ' .*$','') FROM tickets limit 10;

SELECT COUNT(*), LENGTH(name) from 
    (SELECT regexp_replace (passenger_name, ' .*$','') name FROM tickets limit 10) x
GROUP BY LENGTH(airport_name) order by LENGTH limit 10;

SELECT count(*), name from (SELECT regexp_replace (passenger_name, ' .*$','') name FROM tickets) sp GROUP by name; 
SELECT count(*), name from (SELECT regexp_replace (passenger_name, ' .*$','') name FROM tickets) sp 
    GROUP by name order by count (*) DESC; 

--найдет сколько наталий (^ означает начало )
SELECT count(*) FROM tickets WHERE passenger_name ~ '^NATALIYA';

select min(scheduled_departure) from flights;

SELECT * from WHERE shedule = (select min )

SELECT da.airport_name,
aa.airport_name
from flights
 join airports da ON departure_airport = da.airport_code
 join airports aa ON arrival_airport = aa.airport_code
where scheduled_departure = (SELECT min(scheduled_departure) FROM flights);

SELECT count(*) FROM ticket_flights;

SELECT flight_id, count(*) FROM ticket_flights GROUP by flight_id order by count DESC;
--having применяется после group

SELECT flight_id, count(*) FROM ticket_flights GROUP by flight_id HAVING count(*)= 374 order by count;

SELECT da.airport_name,
aa.airport_name
from
 flights
 join airports da ON departure_airport = da.airport_code
 join airports aa ON arrival_airport = aa.airport_code
WHERE flight_id = ( 
    SELECT flight_id from (
        SELECT flight_id, count(*) FROM ticket_flights GROUP BY flight_id
    HAVING count(*)=(
        SELECT count(*)
        FROM ticket_flights
        GROUP BY flight_id order by count DESC LIMIT 1
    )
) x );

----------------------- ******************************************************** 
--25 03 2024 pgSphere
-- выбираем самый популярный рейс
select count(*),route from
    (SELECT concat('',departure_airport,arrival_airport) route from flights) x 
GROUP by route order by count(*) DESC limit 1;

SELECT concat('',departure_airport,arrival_airport) route, departure_airport, arrival_airport from flights 
GROUP by route order by count(*) DESC limit 1;

with
    tick as (select count(*) N_ticket ,flight_id from (select flight_id from ticket_flights) x GROUP BY flight_id order by N_ticket DESC) 

select departure_airport, arrival_airport, N_ticket  
GROUP by line order by count(*) DESC;
count(*) from flights join tick ON flights.flight_id = tick.flight_id limit 10 GROUP BY
;

--СTE ЦТЕ обшие табличные выражения 
--
WITH x AS (запрос), AS y (..) SELECT ..,
запрос как таблица с именем х, правее можно уже использовать Х
-- условные опертор  CASE  (тринарный оператор)
SELECT  WHEN a=1 THEN 'good' ELSE 'bad' END
CASE WHEN a<b THEN a ELSE b END 

-- в английсаом строки сравниваются без учета русского языка  strcmo(a,b) по байтам astrcoll по табилцам сравнения

SELECT * FROM airq


--попытка найти самый попцлярный маршрут 
SELECT count(*), flights.departure_airport, flights.arrival_airport from flights, ticket_flights
WHERE fli

-- вот тут добавляем в таблицу колво билетов для каждого полета. НЕВЕРНО тк он сумирует по ОДИНАКОВЫХ количествам пассажирам
SELECT sum(res.tick_count), res.departure_airport, res.arrival_airport, count(*) FROM
    (SELECT * -- подсчитаем сколько пассажиров в каждом рейсе
        FROM flights JOIN 
            (SELECT count(*) tick_count, flight_id tmpflight_id  FROM ticket_flights GROUP by flight_id) tf
        ON flights.flight_id = tf.tmpflight_id) res
GROUP by res.departure_airport, res.arrival_airport
ORDER by sum DESC limit 4;

------ САМый оптимальныц запрос  для поиска самого популярного 
SELECT count(*), departure_airport, arrival_airport
FROM ticket_flights 
    JOIN flights ON ticket_flights.flight_id=flights.flight_id
    GROUP by departure_airport, arrival_airport
ORDER by count(*)
DESC limit 4;

--а вот это дает другой ответ почему? а потому что он суммирует одинаковые значения 
select sum(tick_count) from  (select tmpflight_id,tick_count,departure_airport,arrival_airport from 
    (SELECT * -- подсчитаем сколько пассажиров в каждом рейсе
        FROM flights JOIN 
            (SELECT count(*) tick_count, flight_id tmpflight_id  FROM ticket_flights GROUP by flight_id) tf
        ON flights.flight_id = tf.tmpflight_id) res
wHere ROW(res.departure_airport, res.arrival_airport)=('SVO','LED')) x;

SELECT * FROM 
(SELECT *
        FROM flights JOIN 
            (SELECT count(*) tick_count, flight_id tmpflight_id  FROM ticket_flights GROUP by flight_id) tf
        ON flights.flight_id = tf.tmpflight_id) res
WHERE ROW(res.departure_airport, res.arrival_airport) = ('ARH','PEE'); --448 сумма должна получиться 
--ищем сколько рейсов в одну сторону было сделанно 
 SELECT count(*) FROM flights
 GROUP by ROW(flights.departure_airport, flights.arrival_airport);
  SELECT count(*) FROM flights
 GROUP by ROW(flights.departure_airport, flights.arrival_airport);
---------------------------------------------------------------------------------------- не работает ПОЧЕМУ?
SELECT * FROM flights 
JOIN 
    SELECT count(*) FROM ticket_flights WHERE flight_id = flights.flight_id
ON flights.flight_id = ticket_flights.flight_id;

-- какой самолет летает больше всего 
SELECT * FROM  ( SELECT count(*) c, aircraft_code
    FROM ticket_flights                                                                                     
    JOIN flights ON ticket_flights.flight_id=flights.flight_id                                      
    GROUP by flights.aircraft_code) x
JOIN aircrafts ac
ON x.aircraft_code = ac.aircraft_code;


WITH 
---координаты кадого аэропортаа
    cord as (SElECT ll_to_earth(coordinates[0], coordinates[1]), * FROM airports ORDER by airport_code),
--расстояние между парама
    dist as (SELECT * FROM (SELECT earth_distance (cord.ll_to_earth, cord2.ll_to_earth) dist, cord.airport_name, 
            cord2.airport_name, cord.airport_code aircode1,cord2.airport_code aircode2
        FROM cord, cord as cord2 ) x
        WHERE dist > 0),
--сколько пассажирова между каждым аэропоротом перевезено
    pass_route_table as (SELECT count(*) pass_route, aircraft_code, departure_airport, arrival_airport
        FROM ticket_flights                                                                                     
        JOIN flights ON ticket_flights.flight_id=flights.flight_id                                      
        GROUP by flights.aircraft_code, flights.departure_airport, flights.arrival_airport)
SELECT  *, sum_dist/count_flight as average_distance, count_passenger::float/count_flight as aver_passenger,
    sum_dist::float/count_passenger as dist_fo_one
FROM (SELECT sum(pass_route * dist) as sum_dist, aircraft_code from pass_route_table
        LEFT JOIN dist ON pass_route_table.departure_airport=dist.aircode1 AND pass_route_table.arrival_airport=dist.aircode2
        GROUP by aircraft_code) result -- просумируем дистанцию*кол-во пассажиров для каджого борта. 
JOIN aircrafts as info USING (aircraft_code)
JOIN (SELECT count(*) as count_flight, aircraft_code FROM flights GROUP by aircraft_code) cf USING (aircraft_code) --сколько полетов сделал каждый борт
JOIN (SELECT count(*) as count_passenger, aircraft_code FROM --посчитаем сколько пассажиров перевез каждый тип борта 
    ticket_flights JOIN  flights USING(flight_id)   
    GROUP by aircraft_code) cp USING (aircraft_code)
ORDER BY sum_dist;
------------------ а как объеденить чтобы не возникало одинаковых столбцев????????? DISTINCT


SELECT count(*), departure_airport, arrival_airport
FROM ticket_flights 
    JOIN flights ON ticket_flights.flight_id=flights.flight_id
    GROUP by departure_airport, arrival_airport
ORDER by count(*)
DESC limit 4;

----
----
----------------------- для посчета расстояния 
CREATE EXTENSION earthdistance


---- Рекурсия
--- CTE comand table extension
WITH
    T1 AS (),
    T2 AS () 
SELECT t1,t1 
---recurs
--- состамим дерево 
CREATE node (
    id int PRIMARY KEY,
    name text,
    parent int REFERENCES node (id),
    pos int
),
--старт и шаг
WITH RECURISVE 
tree AS (
    SELECT * FROM node WHERE parent is null -- старт рекурсии, начало деревво
    UNOIN --шаг, делаетмя до тех пор пока шаг будет добавлять узлы
    tree level + 1 AS level
    SELECT( node.* FROM 
        node join tree ON node parent=tree.id)
    WHERE level <10
)
SELECT * FROM tree;


----
ARRAY[departure_airport::text,arrival_airport::text]
path || ARRAY(arrival_airport)
x = ANY (PATH) -- поле Х встречается в массиве 
------
CREATE table ... as 
    SELECT ... ; 

select coordinates[1] FROM airports limit 1 offset 1; --выберем2 строку 
select ll_to_earth(coordinates[0], coordinates[1]) FROM airports;

WITH 
    cord as (SElECT ll_to_earth(coordinates[0], coordinates[1]), * FROM airports)
SELECT earth_distance (earth1, earth2) FROM  -- то есть скорее x.earth1
    (SELECT cord.ll_to_earth as earth1 FROM cord where airport_code='YKS') x
    JOIN
    (SELECT cord.ll_to_earth as earth2 FROM cord where airport_code='LED') xx
    ON TRUE
;

-- проверка работоспособности
WITH 
    cord as (SElECT ll_to_earth(coordinates[0], coordinates[1]), * FROM airports ORDER by airport_code),
    corddesc as (select *  FROM cord order by airport_code DESC)
SELECT earth_distance (cord.ll_to_earth, corddesc.ll_to_earth) FROM cord,corddesc;--декартовое произведение ??????  почему

--цикл 
FOR variable IN start_value..end_value 
LOOP 
-- Statements to execute in each iteration 
END LOOP; 
-------- ном ожно обойтись и без этого 


--ищем самый дальний аэропорт
WITH 
    cord as (SElECT ll_to_earth(coordinates[0], coordinates[1]), * FROM airports ORDER by airport_code)
SELECT earth_distance (cord.ll_to_earth, cord2.ll_to_earth), cord.airport_name, cord2.airport_name 
    FROM cord, cord as cord2 order by earth_distance DESC;

--from a,b эквивалентвно "a join on on TRUE"

WITH 
    cord as (SElECT ll_to_earth(coordinates[0], coordinates[1]), * FROM airports ORDER by airport_code)
SELECT * FROM (SELECT earth_distance (cord.ll_to_earth, cord2.ll_to_earth) dist, cord.airport_name, 
cord2.airport_name, cord.airport_code aircode1,cord2.airport_code aircode2
    FROM cord, cord as cord2 ) x
WHERE dist > 0
order by dist limit 5;





ЗВЕЗДЫ 

download
cope file frim filecreate tale textglise (str text) 
найти расстояния 
substr (str col длина)
replace (,'','')
where


----
нужно положить файл а tmp 
 DELETE FROM text_gliese WHERE str ~ 'Result'
Coordinate system: Equatorial
|name     |ra        |dec      |app_mag|spect_type|result_parallax|result_parallax_error|
 |NN 3958  |16 54 09.5|-87 24 37| 14.58 |DA6       | 41.0          | 8.0                 |
 |Gl 385   |10 07 38.1|-85 07 12| 10.22 |          | 56.6          |15.3                 |
 |Gl 606.1B|16 10 27.3|-84 13 53| 11.03 |k-m       | 39.0          | 6.0                 |
 SELECT substr(str, 52,5) from text_gliese;
 --отбираем поле с цифрами 
WITH
 parallax as (SELECT * from (SELECT REPLACE(substr(str, 52,5),' ','') r from text_gliese where substr(str, 52,5) ~'\d') r where r.r >0)
 SELECT 1/parallax[] FROM parallax;

COPY (
WITH
 parallax as (  SELECT r.r p, 1/r.r r from 
            (SELECT REPLACE(substr(str, 52,5),' ','')::float r 
            from text_gliese 
            where substr(str, 52,5) ~'\d') r 
        where r.r >0), --таблица с расстояниями

raspred as (SELECT r, count (*) OVER (ORDER by r) N FROM parallax Order by r)
SELECT * from raspred) to '/tmp/raspred.txt';
 

row_number() over as id; --способ пронумировать таблицу  с помощью оконной функции, потом для них нужно создать индекс
----

-- explain  покажет какой алгоритм использовался 
-- надо использовать либо индекс скан либо по хешу
CREATE table gliece_vel (
    --garbf text,
    name  text,
    RAB1950 text,
    DEB1950 text,
    pm text,
    pmPA text,
    RV text,
    Sp text,
    Vmag text,
    B_V text,
    plx text,
    uvel text,
    vvel text,
    wvel  text,
    _RAicrs text,
    _DEicrs  text
    --garb text
);
drop table gliece_vel;
--проверим что пробелов не т ~'\s' ~vматч регулярного <> неравное 
COPY gliece_vel(garbf,name, ra ,dec,app_mag,spect_type,result_parallax,result_parallax_error,uvel,vvel,wvel,garb)
FROM '/tmp/BrowseTargets-1501-1713768516.txt' delimiter '|' csv header;
garbf,n
COPY gliece_vel
FROM '/tmp/asu.tsv' delimiter E'\t' csv header;


WITH 
    vel as (select gl.uvel::int uv, gl.vvel::int vv, gl.wvel::int wv, gl.id from 
            (select  REPLACE(gll.uvel,' ', '') uvel, REPLACE(gll.vvel,' ', '') vvel, REPLACE(gll.wvel,' ', '') wvel, 
                row_number() over() as id FROM gliece_vel gll) gl
        WHERE gl.uvel <>''  and gl.vvel <>'\s'and gl.vvel <>'\s'),
    vel_point as (select point(uv,vv) uv, id FROM vel) 
    vdist as (SELECT i.id, i.uv, j.id, j.uv, i.uv <-> j.uv vdist from vel_point i, vel_point j 
    WHERE i.id=(
        SELECT id from vel_point k where k.id <> j.id
        Order by k.uv <-> j.uv
        limit 1
    ) and i.id< j.id
order by vdist,i.id) 
SELECT
;

---сощдадим таблицу классетар 
CREATE TABLE IF NOT EXISTS clusters AS (
    WITH 
   vel as (select gl.uvel::int uv, gl.vvel::int vv, gl.wvel::int wv, gl.id from 
            (select  REPLACE(gll.uvel,' ', '') uvel, REPLACE(gll.vvel,' ', '') vvel, REPLACE(gll.wvel,' ', '') wvel, 
                row_number() over() as id FROM gliece_vel gll) gl
        WHERE gl.uvel <>''  and gl.vvel <>'\s'and gl.vvel <>'\s'),
    vel_point as (select point(uv,vv) uv, id FROM vel) 
    SELECT ARRAY[id] AS ids,
        uv p, 1 AS m
  FROM vel_point
);
ALTER TABLE clusters ADD PRIMARY KEY (ids);
CREATE INDEX ON clusters USING gist(p);

ALTER TABLE ALTER ids TYPE int [];
CREATE FUNCION/.. language sql
-- конец 
-- теперь надо каждую точку сделать как кластер и объеденять по очереди 
WITH 
    pairs1 as (SELECT i.ids ids1, i.p p2, j.ids ids2, j.p p2, i.p <-> j.p vdist from clusters i, clusters j 
    WHERE i.ids=(
        SELECT ids from clusters k where k.ids <> j.ids
        Order by k.p <-> j.p
        limit 1
    ) and i.ids< j.ids
order by i.ids,vdist) 
    clusters1 AS (
        SELECT uniq(sort ()) where dist<3
        объеденим все пары в один кластер где dist <3

        в итоге получится куча класеров
    )

SELECT * from vdist;


ALTER TABLE clusters ADD PRIMARY KEY (ids);
CREATE INDEX ON clusters USING gist(p);

SELECT i.id, i.uv,j.uv from vel_point i, vel_point j 
    WHERE i.id=(
        SELECT id from vel_point k where k.id <> i.id
        Order by k.uv <-> i.uv
        limit 1
    );-- AND i.id <j.id ;

--это декларативное програмирование
-- || cоеденяет два массива 
-- uniq(sort())
-- point(x,y) *point(p,0) = point(px,py) маразменое умножение или деление 
UNIUN когда приписывает другие строки, исключает повторяющие строки
UNION ALL  (оставляет повторяюще строки)
|агломерация  (замена агрегатной функции)
UNION ALL 
| оставляетм это 





------CUBE
CREATE EXTENSION CUBE
-- задает по дионогали куба (ближний нижний и дальней верхний угол)
SELECT cube (ARRAY[1,2,3])

CREATE or REPLACE FUNCTION vcenter (
    ids int[]
) RETURNS cube 
language sql AS $$
    --sql запрос. Динамический скл на лету подставляет имена таблицы и перемены
    SELECT cube(ARRAY[avg(u),avg(v),avg(w)]) FROM vel
    --SELECT cube(ARRAY[sum(u)::float,count(*),sum(u)::float/count(*)]) FROM vel
    where vel.id =ANY (ids)
$$;
select vcenter( array_agg(id) ) from vel ;




(37,2,18.5)
---------------
 (-18, 1, -18)
 (-19, 1, -19)
  u  |  v  | w  | id  
-----+-----+----+-----
 -19 | -14 | -7 | 380
 -18 | -12 | -8 | 475

-- gli  
id = ANY (ids)
 ALTER TABLE gliece_vel  ADD id int;


 SELECT row_number() over () from (SELECT name from gliece_vel order by name) x ;

 WITH o AS (SELECT name, row_number() over (order by name) from gliece_vel)
 UPDATE gliece_vel set id=(SELECT row_number from o where o.name=gliece_vel.name)
 ;
 ALTER TABLE gliece_vel ADD u int;

--создадим таблицу из подзапроса 
CREATE TABLE vel as (select gl.uvel::int u, gl.vvel::int v, gl.wvel::int w, gl.id from 
            (select  REPLACE(gll.uvel,' ', '') uvel, REPLACE(gll.vvel,' ', '') vvel, REPLACE(gll.wvel,' ', '') wvel, 
                row_number()::int over() as id FROM gliece_vel gll) gl
        WHERE gl.uvel <>''  and gl.vvel <>'\s'and gl.vvel <>'\s');
EXISTS (SELECT...) --==true если не пустой 

select vcenter( array_agg(id) ) from vel ;
ALTER TABLE vel ALTER id TYPE int; -- поменяем тип чтобы не ругалась на бигинт

cube_ll_colrd(vel,1) --индекс начинается с 1



                                                                                                                                --кластерный  анализ

(WITH 
clust0 as (SELECT ARRAY[id] ids, cube(ARRAY[u,v,w]) V from vel
),
pairs0 AS (--нашли ближайшее соседей для каджой звезды
    SELECT i.ids id1, j.ids id2, i.V V1, j.V V2, i.V<->j.V dist from (select V ,ids from clust0) i, (select  V, ids from clust0) j
        where j.ids = ( SELECT ids from (select   V, ids from clust0) k
            where not ( (i.ids @> k.ids) and (i.ids <@ k.ids) ) --i.ids != k.ids --and k.ids > i.ids--условие проверяет что все уникальные элементы входят в оба массива т е 
            --те это аналогичено структуре set = set
        ORDER BY i.V<->k.V limit 1
        )
    order by id1
 ),
clust1 AS ( --объеденим близкие пары
    select id1||id2 ids, vcenter(id1||id2) V from pairs0
        where dist <4
    UNION 
    select id1 ids, V1 V from pairs0 where dist >4
    UNION 
    select id2 ids, V2 V from pairs0 where dist >4
),
pairs1 AS (--нашли ближайшее соседей для каджой звезды
    SELECT i.ids id1, j.ids id2, i.V V1, j.V V2, i.V<->j.V dist from (select V ,ids from clust1) i, (select  V, ids from clust1) j
        where j.ids = ( SELECT ids from (select   V, ids from clust1) k
            where not ( (i.ids @> k.ids) and (i.ids <@ k.ids) ) --and k.ids > i.ids
        ORDER BY i.V<->k.V limit 1
        )
    order by id1
 ),
clust2 AS ( --некотрые пары включают одинаковые звезды, избавляемся от них 
    select ARRAY( SELECT DISTINCT ids FROM unnest(id1||id2) ids) ids, vcenter(ARRAY( SELECT DISTINCT ids FROM unnest(id1||id2) ids)) V from pairs1
        where dist <5
    UNION 
    select id1 ids, V1 V from pairs1 where dist >5
    UNION 
    select id2 ids, V2 V from pairs1 where dist >5
),
pairs2 AS (--нашли ближайшее соседей для каджой звезды
    SELECT i.ids id1, j.ids id2, i.V V1, j.V V2, i.V<->j.V dist from (select V ,ids from clust2) i, (select  V, ids from clust2) j
        where j.ids = ( SELECT ids from (select   V, ids from clust2) k
            where not ( (i.ids @> k.ids) and (i.ids <@ k.ids) ) --and k.ids > i.ids
        ORDER BY i.V<->k.V limit 1
        )
    order by id1
 ),
clust3 AS ( --некотрые пары включают одинаковые звезды, избавляемся от них 
    select ARRAY( SELECT DISTINCT ids FROM unnest(id1||id2) ids) ids, vcenter(ARRAY( SELECT DISTINCT ids FROM unnest(id1||id2) ids)) V from pairs2
        where dist <6
    UNION 
    select id1 ids, V1 V from pairs2 where dist >6
    UNION 
    select id2 ids, V2 V from pairs2 where dist >6
),
pairs3 AS (--нашли ближайшее соседей для каджой звезды
    SELECT i.ids id1, j.ids id2, i.V V1, j.V V2, i.V<->j.V dist from (select V ,ids from clust3) i, (select  V, ids from clust3) j
        where j.ids = ( SELECT ids from (select   V, ids from clust3) k
            where not ( (i.ids @> k.ids) and (i.ids <@ k.ids) ) --and k.ids > i.ids
        ORDER BY i.V<->k.V limit 1
        )
    order by id1
 ),
clust4 AS ( --некотрые пары включают одинаковые звезды, избавляемся от них 
    select ARRAY( SELECT DISTINCT ids FROM unnest(id1||id2) ids) ids, vcenter(ARRAY( SELECT DISTINCT ids FROM unnest(id1||id2) ids)) V from pairs3
        where dist <7
    UNION 
    select id1 ids, V1 V from pairs3 where dist >7
    UNION 
    select id2 ids, V2 V from pairs3 where dist >7
)q
SELECT  cardinality(ids) mass,V,ids from clust4 order by V DESC);

select x.[1] from (Select v from clust) ; 
select * from clust where v->1 < -30 and v->2 < -20 and v->3 < -14; 

                                                                                                                                    --рекурсивыный
 --N! или разложить число на множители

 WITH RECURISVE -- требует чтобы AS состояла из двух частей обхеденыену uniin
    fact AS (
        старт 
        UNION ALL
        шаг рекурсии -- тут можно использовать fact (но нельзя использовать сегрегатные функции, но можно оконныные )
        --продолжается пока не добовляется новые строчки

    ),
    другая таблица как обынчый with
SELECT,,

WITH recursive
    fact (n::int, f::bigint) AS (
        SELECT 1::int,1::bigint
    UNION ALL -- если тут сделать union то повторяющие строчки схлоповаются 
        SELECT n+1,f*(n+1) from fact
    WHERE n <=7
    )
SELECT * FROM fact where n =4;

WITH recursive
    prost (number, flag, N) as (
        SELECT 2,-1,37909979
        UNION ALL
        --if number>1 THEN
            SELECT CASE WHEN flag = 0 THEN number ELSE number+1 END as number ,
                N%(number) flag, 
                CASE WHEN N%(number) = 0 THEN N/(number) ELSE N  END as N 
            from prost 

            where number <= N
    ) -- раскладывает на множители 
SELECT count(*), number from prost where flag =0 GROUP by number order by number;
SELECT * FROM prost where flag=5;
SELECT * FROM prost;

EXPLAIN
WITH recursive
    prost1 (flag, number, N) as (
        SELECT -1, 2, 28 --0 простое, стартуем с простого числа 2, требуемое простое число (37909979, 83475347) 3487532
        UNION ALL
            SELECT N%(number),
            CASE WHEN  N%(number)=0 THEN number ELSE number+1 END as number ,   
            CASE WHEN N%(number)=0 THEN N/(number) ELSE N  END as N 
            from prost1
            where number * number <=N -- проверяем все делители до корня из N с учетом их кратности 
    ),
    prost as (
        SELECT * from prost1
        union all -- добавляем оставшийся остаток (он гарантировано простой) -- c АЛЛ строк по порядку
            SELECT 0 flag, min(N) number, min (N)/min(N) N from prost1
    )
    SELECT count(*), number from prost where flag =0 GROUP by number order by number;
SELECT * FROM prost;
    SELECT * FROM prost;

COPY (SELECT * from clust) TO '/tmp/clust.csv' (format csv, delimiter '|')


    --------------------------------- 13.05 
    --снова авио перевозки 
    --1) маршрут от до и диапазон мин макс билета
    --2)по каким дням недели летают чаще
--Моргунов 300стр про транзакции
ticket_flights: ticket_no   | flight_id | fare_conditions |  amount

 flights: flight_id | flight_no |  scheduled_departure   |   scheduled_arrival    | departure_airport | arrival_airport |  status   | aircraft_code | actual_departure | actual_arrival 

SELECT  departure_airport,arrival_airport, min(amount), max(amount) FROM (
    SELECT f.flight_id, departure_airport,arrival_airport,amount from flights  f
    JOIN ticket_flights tf 
    ON f.flight_id=tf.flight_id
) x
GROUP by departure_airport,arrival_airport
limit 4;

select count(*), dow, sum(Npas) from (
    SELECT * FROM 
    (select EXTRACT(DOW FROM scheduled_departure) as dow, * from flights
    GROUP BY flight_id, dow) f --избежим повторне билетов
    JOIN (SELECT count(*) Npas,flight_id from ticket_flights
            GROUP by flight_id ) pas
        ON pas.flight_id=f.flight_id
) ans  
GROUP by dow
order by dow;

select count(*), dow from (
    SELECT * FROM 
    (select EXTRACT(DOW FROM scheduled_departure) as dow, * from flights
    GROUP BY flight_id, dow) f --избежим повторне билетов
) ans  
GROUP by dow
order by dow;

select * from date_part('dow', '2024-05-13'::date); --воскресенье это 0 день

--создадим свою агрегатную функцию 
SUM, min, avg --сколярные
ARRAY_AGG 
create aggregate --она должна возращать одно значение 
--делает гистограмму дискретной величины
{-значние -> сколько раз}


            ---уровни изоляции
1 READ UNCOMMITED (
    это и так по дефолту синтаксис
)
2 READ COMMITTED (тут может быть как фонтомные чтение)
3 REPATABLE READ (выстраивает порядок транзакуий, реальзов не полностью)
4 SERIALIZABLE

 create table ... as select * from ...; --не копируется индексы и ограничения
---- Фантомное чтенеи
BEGIN
SELECT  * from aircrafts_tmp where range>6000
    --во втором терминал добавили
    SELECT  * from airports_tmp where range<6000; --будет уже другой результат"

во второй сесии
 update aircrafts_tmp set range=5700 where aircraft_code ='320';

---select 
select
    for UPDATE --блокирует только выделеные поля, другие не блокирует

BEGIN ISOLATION level REPEATABLE READ; --явно устанвливает уровень изоляции транзакции 
--версии строк xmin(когда сощдан ) xmax (Null) (нет конца)
А320  5700          1           56--номер транзакии типо время
--полсе абдейт      
А320  5700          57           inf



----------------------                                        ----------- теория про SELECT
SELECT FROM ..T.E.. WHERE
таблица join, ljoin 
(select ) x
Фунеция Возращаяю таблицу ФРТ 
values (1,2),(3,4)
select 1,2 union all select 3,4

a JOIN usiallu it is INNER JOIN b.x=a.y
a cross join b (декартовое произведенеи )
a left [onter] join on b.x=a.y
a full outer join (добовляет строки из обоих таблиц)
a join lateral b(a.y) (когда b функции, вычисляюще из а) on true ()
---------------

WITH 
    nov_mos as (
        SELECT * from flights where departure_airport='OVB' and arrival_airport in ('VKO','SVO','DME','ZIA')
    ),
    mos_san as  (SELECT * FROM nov_mos join lateral 
        (select  arrival_airport, flights.scheduled_departure mdep, flights.scheduled_arrival lenarr , flights.scheduled_departure-nov_mos.scheduled_arrival tdist  from flights
        where 
        nov_mos.arrival_airport=flights.departure_airport and
        flights.arrival_airport in ('LED') and
        nov_mos.scheduled_arrival < flights.scheduled_departure
        order by tdist limit 1
        ) x on TRUE
    )
    select * from mos_san;
или 
select *.*
(
    select nov_mos.*,(select flight_id, from .. where)-
    -- или select nov_mos.*,(select row_to_json(flights), from .. where)-
    from ... ovb
) join flit where id=id


WITH 
    fromNOV as (select arrival_airport midl_air, scheduled_arrival midl_time, scheduled_departure time_nov from flights
        where  departure_airport='OVB'
    ),
    toLED as (select midl_time,to_arr,to_arr_time,midl_air from fromNOV inner join (
        select departure_airport to_dep, arrival_airport to_arr, scheduled_arrival to_arr_time, scheduled_departure to_time from  flights
        where departure_airport='LED') x
    on x.to_arr = fromNOV.midl_air and
    midl_time<to_arr_time
    )
select DISTINCT toLED.midl_air from toLED ;
WITH RECURISVE
    list_airport as (select DISTINCT departure_airport from flights)

----
unnest перврращает массив в набор строк -- цикл по элементам -- обратно array_agg
selet * unnest (1,2,3)  получим три строчки 

подъязыки DML DQL DDL D*L 
UPDATE ... RETURNINIG
INSERT .. RETURN id
--управление доступом ДБ
GRAND/REVOKE дает и отбирает права 

--- полнотекстовый поиск 
найди все тексты где есть слова 
TEXT like "%Вася%" подстрока 
~'\bВая\b' \b граница слова 
tsvector() &&
tsquery()

to_tsvetor('ваш текст')
to_tsquery('ваш подзабпрос') --тк поиск может ускоряться с помощью индекса 
ts_rank --