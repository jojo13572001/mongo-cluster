rs.add('172.31.13.64:20001');
rs.add('172.31.13.64:30001');
cfg = rs.conf();
cfg.members[0].host = '172.31.13.64:172.31.13.64';
rs.reconfig(cfg,{force:true});
