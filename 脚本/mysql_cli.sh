#! /bin/sh
docker run --rm --net host -it dbcliorg/mycli:mycli-1.25.0 -h 10.112.88.208  mysql -u root -p ""
