
\d .pm

/ constants
ALL:`$"*";  / used to indicate wildcard/superuser access to functions/data
err.:(::);
err[`func]:{"pm: user role does not permit running function [",string[x],"]"}
err[`selt]:{"pm: no read permission on [",string[x],"]"}
err[`selx]:{"pm: unsupported select statement, superuser only"}
err[`updt]:{"pm: no write permission on [",string[x],"]"}
err[`expr]:{"pm: unsupported expression, superuser only"}
err[`quer]:{"pm: free text queries not permissioned for this user"}
 


/ schema
user:([id:`symbol$()]authtype:`symbol$();hashtype:`symbol$();password:())
groupinfo:([name:`symbol$()]description:())
roleinfo:([name:`symbol$()]description:())
usergroup:([]user:`symbol$();groupname:`symbol$())
userrole:([]user:`symbol$();role:`symbol$())
functiongroup:([]function:`symbol$();fgroup:`symbol$())
access:([]object:`symbol$();entity:`symbol$();level:`symbol$())
function:([]object:`symbol$();role:`symbol$();paramcheck:())
virtualtable:([name:`symbol$()]table:`symbol$();whereclause:())

/ api
adduser:{[u;a;h;p]user,:(u;a;h;p)}
removeuser:{[u]user::.[user;();_;u]}
addgroup:{[n;d]groupinfo,:(n;d)}
removegroup:{[n]groupinfo::.[groupinfo;();_;n]}
addrole:{[n;d]roleinfo,:(n;d)}
removerole:{[n]roleinfo::.[roleinfo;();_;n]}
addtogroup:{[u;g]if[not (u;g) in usergroup;usergroup,:(u;g)];}
removefromgroup:{[u;g]if[(u;g) in usergroup;usergroup::.[usergroup;();_;usergroup?(u;g)]]}
assignrole:{[u;r]if[not (u;r) in userrole;userrole,:(u;r)];}
unassignrole:{[u;r]if[(u;r) in userrole;userrole::.[userrole;();_;userrole?(u;r)]]}
addfunction:{[f;g]if[not (f;g) in functiongroup;functiongroup,:(f;g)];}
removefunction:{[f;g]if[(f;g) in functiongroup;functiongroup::.[functiongroup;();_;functiongroup?(f;g)]]}
grantaccess:{[o;e;l]if[not (o;e;l) in access;access,:(o;e;l)]}
revokeaccess:{[o;e;l]if[(o;e;l) in access;access::.[access;();_;access?(o;e;l)]]}
grantfunction:{[o;r;p]if[not (o;r;p) in function;function,:(o;r;p)]}
revokefunction:{[o;r]if[(o;r) in t:`object`role#function;function::.[function;();_;t?(o;r)]]}
createvirtualtable:{[n;t;w]if[not n in key virtualtable;virtualtable,:(n;t;w)]}
removevirtualtable:{[n]if[n in key virtualtable;virtualtable::.[virtualtable;();_;n]]}

/ permissions check functions

pdict:{[f;a]
  d:enlist[`]!enlist[::];
  d:d,$[not count a;();f~`select;();(1=count a) and (99h=type first a);first a;get[get[f]][1]!a];
  d}

fchk:{[u;f;a]
  r:exec role from userrole where user=u;  / list of roles this user has
  o:ALL,f,exec fgroup from functiongroup where function=f; / the func and any groups that contain it
  c:exec paramcheck from function where (object in o) and (role in r);
  k:@[;pdict[f;a];::] each c;  / try param check functions matched for roles
  k:`boolean$@[k;where not -1h=type each k;:;0b];  / errors or non-boolean results treated as false
  max k} / any successful check is sufficient - e.g. superuser trumps failed paramcheck from another role

achk:{[u;t;rw]
  g:raze over (exec groupname by user from usergroup)\[u]; / groups can contain groups - chase all
  exec 0<count i from access where object=t, entity in g, level in (`read`write!(`read`write;`write))[rw]}

/ expression identification
xqu:{(first[x] in (?;!)) and (count[x]>=5)} / QUery
xdq:{first[x] in .q} / Dot Q

isq:{(first[x] in (?;!)) and (count[x]>=5)}
query:{[u;q]
  if[not fchk[u;`select;()];'err[`quer][]];  / must have 'select' access to run free form queries
  / update or delete in place
  if[((!)~q[0])and(11h=type q[1]);  
    if[not achk[u;first q[1];`write];'err[`updt][first q 1]];
    :eval q;
  ];
  / nested query
  if[isq q 1;:eval @[q;1;.z.s[u]]];
  / select on named table
  if[11h=abs type q 1;
     t:first q 1;
     / virtual select 
     if[t in key virtualtable;
       vt:virtualtable[t];
       q:@[q;1;:;vt`table];
       q:@[q;2;:;enlist first[q 2],vt`whereclause]; 
     ];
     if[not achk[u;t;`read];'err[`selt][t]];
     :eval q;
  ];
  / default - not specifally handled, require superuser
  if[not fchk[u;ALL;()];'err[`selx][]];
  :eval q}
     
dotqd:enlist[`]!enlist{[u;e]if[not fchk[u;ALL;()];'err[`expr][]];exe e};
dotqd[`lj`ij`pj`uj]:{[u;e]eval @[e;1 2;expr[u]]}
dotqd[`aj`ej]:{[u;e]eval @[e;2 3;expr[u]]}
dotqd[`wj`wj1]:{[u;e]eval @[e;2;expr[u]]}
dotqf:{[u;q]
  qf:.q?(q[0]);
  p:$[null p:dotqd qf;dotqd`;p];
  p[u;q]}
  

exe:{value x}
expr:{[u;e]
  / variable reference
  if[-11h=type e;
    if[not achk[u;e;`read];'err[`selt][e]];
    :eval $[e in key virtualtable;exec (?;table;enlist whereclause;0b;()) from virtualtable[e];e];
  ];
  / named function calls
  if[-11h=type f:first e;
    if[not fchk[u;f;1_ e];'err[`func][f]];
    :exe e;
  ];
  / queries - select/update/delete
  if[isq e;:query[u;e]];
  / .q keywords
  if[xdq e;:dotqf[u;e]];
  / if we get down this far we don't have specific handling for the expression - require superuser
  if[not fchk[u;ALL;()];'err[`expr][f]];
  exe e}

destringf:{$[(x:`$x)in key`.q;.q x;x~`insert;insert;x]}
requ:{[u;q]expr[u] q:$[10=type q;parse q;$[10h=type f:first q;destringf[f],1_ q;q]]};
req:{requ[.z.u;x]}   / entry point - replace .z.pg/.zps
  
/ authentication

/ methods - must have function for each authtype - e.g. local,ldap
auth.local:{[u;p]
  ud:user[u];
  r:$[`md5~ht:ud`hashtype;
    md5[p]~ud`password;
    0b];  / unknown hashtype
  r}
 
/ entry point - replace .z.pw 
login:{[u;p]
  if[not u in key user;:0b]; / todo print log to TorQ?
  ud:user[u];
  if[not ud[`authtype] in key auth;:0b];
  auth[ud`authtype][u;p]}


init:{
  .z.pg:.z.ps:req;
  .z.pw:login;
 }
  
