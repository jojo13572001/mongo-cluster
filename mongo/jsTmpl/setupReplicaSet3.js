rs.add('${mongod3r2}:${mongod3r2Port}');
rs.add('${mongod3r3}:${mongod3r3Port}');
cfg = rs.conf();
cfg.members[0].host = '${mongod3r1}:${mongod3r1Port}';
rs.reconfig(cfg,{force:true});
