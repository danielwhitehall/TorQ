\l ../code/handlers/permissions.q

.pm.addrole[`systemuser;"communicates between processes]
.pm.grantFunction[`exit;`systemuser;{1b}]
.pm.grantFunction[`reload;`systemuser;{1b}]
.pm.grantFunction[`..register;`systemuser;{1b}]
.pm.grantFunction[`getservices;`systemuser;{1b}]
.pm.grantFunction[`.servers.getdetails;`systemuser;{1b}]
.pm.grantFunction[`.servers.autodiscovery;`systemuser;{1b}]
.pm.grantFunction[`.servers.procupdate;`systemuser;{1b}]
.pm.grantFunction[`.gw.addservererror;`systemuser;{1b}]
.pm.grantFunction[`.gw.addserverresult;`systemuser;{1b}]
.pm.grantFunction[`.u.end;`systemuser;{1b}]
.pm.grantFunction[`.getservices;`systemuser;{1b}]
.pm.grantFunction[`upd;`systemuser;{1b}]

.pm.addgroup[`systemuser;"full access to data"]
.pm.grantaccess[`trade;`systemuser;`read]
.pm.grantaccess[`trade;`systemuser;`write]
.pm.grantaccess[`quote;`systemuser;`read]
.pm.grantaccess[`quote;`systemuser;`write]
.pm.grantaccess[`logmsg;`systemuser;`read]
.pm.grantaccess[`logmsg;`systemuser;`write]
.pm.grantaccess[`heartbeat;`systemuser;`read]
.pm.grantaccess[`heartbeat;`systemuser;`write]

