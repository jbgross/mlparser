-- file to build database in sqlite3 for parsing of SIGCSE-MEMBERS mailing list
-- author: joshua gross (gross.joshua.b@gmail.com)
drop table if exists possibleinstitutionname;
drop table if exists possiblecontactname;

-- these are POSSIBLE names; there might be many for a given domain
create table possibleinstitutionname (
nameid integer primary key,
domain text not null,
name text,
unique (domain, name) on conflict ignore
);

-- these are POSSIBLE names; there might be many for a given domain
create table possiblecontactname (
nameid integer primary key,
address text not null,
firstname text not null,
lastname text not null,
unique (address, firstname, lastname) on conflict ignore
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

create table message (
replyto text not null foreign key email.address,
subject text not null,
year integer not null,
month integer not null,
body text not null
);
*/
