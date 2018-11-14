# The MoonStack v1.1

又一个即将改变世界的开源大数据分析引擎

[MoonStack 官网] http://www.moonstack.org (还在建设中)

[MoonStack 官方Blog] http://blog.moonstack.org 

# 系统组成

MoonStack v1.1 运行在 Ubuntu 18.04.x LTS 操作系统上, 基于以下环境:

[docker](https://www.docker.com/), [docker-compose](https://docs.docker.com/compose/)

并包括以下蜜罐程序的Docker版本:
* [ciscoasa](https://github.com/Cymmetria/ciscoasa_honeypot),
* [conpot](http://conpot.org/),
* [cowrie](http://www.micheloosterhof.com/cowrie/),
* [dionaea](https://github.com/DinoTools/dionaea),
* [elasticpot](https://github.com/schmalle/ElasticPot),
* [glastopf](http://mushmush.org/),
* [glutton](https://github.com/mushorg/glutton),
* [heralding](https://github.com/johnnykv/heralding),
* [honeytrap](https://github.com/armedpot/honeytrap/),
* [mailoney](https://github.com/awhitehatter/mailoney),
* [rdpy](https://github.com/citronneur/rdpy),
* [snare](http://mushmush.org/),
* [tanner](http://mushmush.org/),
* [vnclowpot](https://github.com/magisterquis/vnclowpot)

除此之外, 还用到了以下工具:

* [Cockpit](https://cockpit-project.org/running) 它是轻量级的Docker WebUI, 还提供了实时性能监控和网络终端
* [Cyberchef](https://gchq.github.io/CyberChef/) 一个提供了加密、编码、压缩和数据分析功能的Web应用程序
* [ELK stack](https://www.elastic.co/videos) MoonStack的事件可视化由它来实现.
* [Elasticsearch Head](https://mobz.github.io/elasticsearch-head/) 这是Elasticsearch的Web前端, 用于数据浏览和与ElasticSearch集群交互
* [Spiderfoot](https://github.com/smicallef/spiderfoot) 一个开源的智能自动化工具
* [Suricata](http://suricata-ids.org/) 一个网络安全监控引擎, 在其协议允许的范围内, 我们对其做出了些许调整和优化

# 运行需求

1. MoonStack安装需要至少6-8GB RAM和128 GB的空闲磁盘空间以及Internet连接.
2. 从[GITHUB]下载(https://github.com/moonstack/moon) 或使用 [中国镜像] (https://gitee.com/stackw0rm/moon) 或 [自己创建].
3. 将系统安装在[VM]（虚拟化环境）或 [物理硬件]（物理主机）中 并以各种方式接入[网络] (Lan 或 Internet).
4. 煮上一壶茶或者咖啡, 来享受MoonStack为你带来的强大的功能.
