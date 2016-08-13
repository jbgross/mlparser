-- file to build database in sqlite3 for parsing of SIGCSE-MEMBERS mailing list
-- author: joshua gross (gross.joshua.b@gmail.com)
drop table if exists candidateinstitution;
drop table if exists candidatecontact;
drop table if exists message;

-- these are POSSIBLE names; there might be many for a given domain
create table candidateinstitution (
candidateinstitutionid integer primary key,
domain text not null,
name text,
unique (domain, name) on conflict ignore
);

-- these are POSSIBLE names; there might be many for a given domain
create table candidatecontact (
candidatecontactid integer primary key,
address text not null,
firstname text not null,
lastname text not null,
unique (address, firstname, lastname) on conflict ignore
);

create table message (
messageid integer primary key,
candidatecontactid integer not null,
candidateinstitutionid integer not null,
subject text not null,
year integer not null,
month integer not null,
body text not null,
constraint fkmessagecandidatecontactid foreign key (candidatecontactid) references candidatecontact (candidatecontactid),
constraint fkmessagecandidateinstitutionid foreign key (candidateinstitutionid) references candidateinstitution (candidateinstitutionid)
);

/*
create table institution (
domain text not null primary key, -- not going to worry about schools with multiple domains (damn you, uw.edu/washington.edu)
formalnameid integer foreign key institutionname.uniqueid,
commonnameid integer foreign key institutionname.uniqueid
);

create table contact (
contactid integer primary key,
address text not null,
firstname text not null,
lastname text not null,
position text,
unique (address, firstname, lastname) on conflict ignore
);

*/
