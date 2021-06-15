Pgrouting 环境搭建

#### 1.安装所需软件

- PostgreSQL(version:11.12 windows)  [下载地址](https://www.enterprisedb.com/downloads/postgres-postgresql-downloads) 
- PostGis(version:pg11/3.1.0 windows) [下载地址](http://download.osgeo.org/postgis/windows/)

#### 2.创建数据库，加载扩展

使用pgrouting功能需要以下两个扩展功能,PostGis:pg11/13 windows中已经包含pgrouting

使用navicat或者postgresql自带的pgAdmin执行以下sql语句

```sql
CREATE EXTENSION postgis;
CREATE EXTENSION pgrouting;
```

查询插件是否加载成功，执行以下sql,可以获得postgis和pgrouting版本

```sql
SELECT postgis_full_version(),pgr_version();
```



#### 3.准备数据

- 由[Geofabrik ](https://www.enterprisedb.com/downloads/postgres-postgresql-downloads)下载.osm.pbf格式数据

  当前使用的是全国的矢量数据china-latest.osm.pbf

  其他数据源，该数据源可以按城市拆分[OpenstreetMap](https://download.openstreetmap.fr/extracts/)

- 下载的源数据包括所有的图层，若抽取需要的数据

  需要使用工具osmium-tool [Github](https://github.com/osmcode/osmium-tool)

  拉取源码后，按照官方文档在linux下编译成功后执行以下语句

```shell
./osmium tags-filter /home/cq/gis/pbf/china-latest.osm.pbf  w/highway=motorway w/highway=trunk w/highway=primary w/highway=motorway_link w/highway=trunk_link w/highway=primary_link -o china-osm2pgrouting.osm.pbf
```

​	成功抽取tag为motorway，trunk,primary,motorway_link,trunk_link,primary_link的路网数据

​	关于路网(highway)tag的说明, [地址](https://wiki.openstreetmap.org/wiki/Key:highway)

- osm.pbf数据转osm（pgrouting不支持osm.pbf格式数据）

  [osmconvert](https://wiki.openstreetmap.org/wiki/Osmconvert) 当前使用的是windows支持大文件版本 [下载地址](https://disk.yandex.ru/d/Vnwc4kut3LCBFm)

  转换命令

  ```powershell
  osmconvert64-0.8.8p.exe --out-osm china-osm2pgrouting.osm.pbf>china-pgrouting.osm
  ```

- 安装osm2pgrouting [Github]( https://github.com/pgrouting/osm2pgrouting) 

  拉取源码后，按照官方文档在linux下编译成功后执行以下语句导入数据

  ```shell
  osm2pgrouting -f ./build/china-pgrouting.osm -h 192.168.2.177 -p 5432 -d china_pgrouting -U postgres -W root -c ./mapconfig.xml --clean
  
  #mapconfig.xml 在osm2pgoring目录下
  #-f osm文件路径
  #-h postgresql IP
  #-p postgresql 端口
  #-d postgresql 数据库名
  #-U postgresql 用户名
  #-W posgtresql 密码
  #-c osm2pgrouting 配置文件路径
  #--clean 删除库中原有数据
  ```

  

#### 4.常用查询

​	osm数据使用的是SRID=4326坐标系

- 查询任意坐标最近顶点位置

  ```sql
  SELECT * FROM ways_vertices_pgr
  WHERE
  	ST_DWithin (
  		the_geom,
  		'SRID=4326;POINT(116.432583 39.910729)',
  		1000
  	)
  ORDER BY
  	ST_Distance (
  		the_geom,
  		'SRID=4326;POINT(116.432583 39.910729)'
  	)
  LIMIT 1;
  ```

  

- 使用Dijkstra算法计算两个顶点之间的结果

  ```sql
  select * from pgr_dijkstra (
  		'SELECT gid AS id,source, target,cost, reverse_cost FROM ways',
  		153567,
  		927741,
  		directed := FALSE
  	)
  # directed 是否是有向图计算，由于路网数据并不完整，有向图计算往往得不到计算结果	
  ```



- 将Dijkstra计算结果以GeoJson形式展示

  ```sql
  SELECT
  	ST_AsGeoJSON (ST_UNION(b.the_geom)) AS geojson
  FROM
   select * from pgr_dijkstra (
  		'SELECT gid AS id,source, target,cost, reverse_cost FROM ways',
  		153567,
  		927741,
  		directed := FALSE
  	) A,
  	ways b
  WHERE
  	A .edge = b.gid;
  ```



- 使用A*算法

  ```sql
  SELECT * FROM pgr_astar(
      'SELECT gid as id, source, target, cost, reverse_cost, x1, y1, x2, y2 FROM ways',
       153567,
       927741,	
  	directed := FALSE);
  ```

  



