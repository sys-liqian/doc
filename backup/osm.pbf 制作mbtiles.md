# osm.pbf 制作路网mbtiles



注意事项 全球数据处理保守估计需要256G可运行内存

Ubuntu20.04 i9-10980XE 128G内存



## 数据源

全量矢量数据

**OpenStreetMap**: https://planet.openstreetmap.org/pbf/planet-latest.osm.pbf

各个大洲拆分矢量数据

**Geofabrik**: https://download.geofabrik.de



## osm.pbf 抽取指定图层

**osmium-tool**

**github**: https://github.com/osmcode/osmium-tool

按照文档说明安装必要的库，注意版本

编译osmium-tool，抽取路网数据，执行以下命令

```
./osmium tags-filter /{your-path}/latest.osm.pbf w/highway -o highway.osm.pbf
```



## osm.pbf制作mbtiles

**tilemaker**

**github**: https://github.com/systemed/tilemaker

编译可执行程序，制作mbtiles执行以下命令

```
./tilemaker --output highway.mbtiles --input /{your-path}/highway.osm.pbf  --config ../resources/config-openmaptiles.json  --process ../resources/process-openmaptiles.lua 
```



## mbtiles合并

**SQLite Expert Personal5.3**

打开一个mbtiles

选择Attach Database

执行sql

```
insert or replace into tiles select * from xxTiles
```

