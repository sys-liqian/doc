#!/bin/bash
docker run -d \
--name opencodedev \
--network host \
--restart always \
-v /data:/data \
-v /root/workspace:/root/workspace \
--cap-add SYS_ADMIN \
--privileged \
cs:latest