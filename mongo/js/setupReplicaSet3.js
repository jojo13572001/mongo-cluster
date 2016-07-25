rs.add(':');
rs.add(':');
cfg = rs.conf();
cfg.members[0].host = ':';
rs.reconfig(cfg,{force:true});
