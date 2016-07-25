rs.add('${mongod2r2}:${mongod2r2Port}');
rs.add('${mongod2r3}:${mongod2r3Port}');
cfg = rs.conf();
cfg.members[0].host = '${mongod2r1}:${mongod2r1Port}';
rs.reconfig(cfg,{force:true});
