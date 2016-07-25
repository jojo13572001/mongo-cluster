rs.add('${mongod1r2}:${mongod1r2Port}');
rs.add('${mongod1r3}:${mongod1r3Port}');
cfg = rs.conf();
cfg.members[0].host = '${mongod1r1}:${mongod1r1Port}';
rs.reconfig(cfg,{force:true});
