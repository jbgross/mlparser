-- file to build database in sqlite3 for parsing of SIGCSE-MEMBERS mailing list
-- author: joshua gross (gross.joshua.b@gmail.com)
drop view if exists jobkeywordsum;
drop view if exists jobkeyword;
drop view if exists messageinfo;
drop view if exists jobmessageinfo;
drop table if exists candidateinstitution;
drop table if exists candidatecontact;
drop table if exists message;
drop table if exists jobmessage;

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
filename text not null,
candidatecontactid integer not null,
candidateinstitutionid integer not null,
subject text not null,
year integer not null,
month integer not null,
academicyear integer not null,
isjob integer not null,
body text not null,
constraint fkmessagecandidatecontactid foreign key (candidatecontactid) references candidatecontact (candidatecontactid),
constraint fkmessagecandidateinstitutionid foreign key (candidateinstitutionid) references candidateinstitution (candidateinstitutionid)
);

-- each of the integer columns other than messageid is a boolean, a 1 if the term is present
-- and a 0 if the term is not present; therefore there may be jobmessages that say both
-- tenuretrack and non-tenure-track (should catch all spelling variants)
create table jobmessage (
messageid integer not null primary key,
sure integer not null,
matchcount integer not null,
matchpercent real not null,
wordcount integer not null,
ratio real not null,
badsubject integer not null,
tenured integer not null,
tenuretrack integer not null,
nontenuretrack integer not null,
instructor integer not null,
lecturer integer not null,
assistantprofessor integer not null,
associateprofessor integer not null,
teachingprofessor integer not null,
professorofpractice integer not null,
phd integer not null,
earneddoctorate not null,
masters integer not null,
securityofemployment integer not null,
temporaryfixed integer not null,
visiting integer not null,
multiple integer not null,
fulltime integer not null,
parttime integer not null,
rankopen integer not null,
adjunct integer not null,
constraint fkjobmessagemessageid foreign key (messageid) references message (messageid)
);

create view messageinfo as
select
	ci.name,
	ci.domain,
	cc.address,
	cc.firstname,
	cc.lastname,
	m.messageid,
	m.month,
	m.year,
	m.academicyear,
	m.isjob,
	substr(m.subject, 0, 25) as subject,
	substr(m.body, 0, 25) as body
from
	candidateinstitution ci,
	candidatecontact cc,
	message m
where
	m.candidateinstitutionid = ci.candidateinstitutionid
	AND
	m.candidatecontactid = cc.candidatecontactid;

create view jobmessageinfo as
select
	ci.name,
	ci.domain,
	cc.address,
	cc.firstname,
	cc.lastname,
	jm.sure,
	jm.matchcount,
	round(jm.matchpercent, 2) as matchpercent,
	jm.wordcount,
	round(jm.ratio, 2) as ratio,
	jm.badsubject,
	m.messageid,
	m.month,
	m.year,
	m.academicyear,
	m.isjob,
	substr(m.subject, 0, 25) as subject,
	substr(m.body, 0, 25) as body,
	jm.tenured,
	jm.tenuretrack,
	jm.nontenuretrack,
	jm.instructor,
	jm.lecturer,
	jm.assistantprofessor,
	jm.associateprofessor,
	jm.teachingprofessor,
	jm.professorofpractice,
	jm.phd,
	jm.earneddoctorate,
	jm.masters,
	jm.securityofemployment,
	jm.temporaryfixed,
	jm.visiting,
	jm.multiple,
	jm.fulltime,
	jm.parttime,
	jm.rankopen,
	jm.adjunct
from
	candidateinstitution ci,
	candidatecontact cc,
	message m,
	jobmessage jm
where
	m.candidateinstitutionid = ci.candidateinstitutionid
	AND
	m.candidatecontactid = cc.candidatecontactid
	AND
	m.messageid = jm.messageid;

/* only look at the keyword attributes */
create view jobkeyword as
select
	messageid,
	academicyear,
	isjob,
	tenured,
	tenuretrack,
	nontenuretrack,
	instructor,
	lecturer,
	assistantprofessor,
	associateprofessor,
	teachingprofessor,
	professorofpractice,
	phd,
	earneddoctorate,
	masters,
	securityofemployment,
	temporaryfixed,
	visiting,
	multiple,
	fulltime,
	parttime,
	rankopen,
	adjunct
from
	jobmessageinfo;

create view jobkeywordsum as
select
	academicyear,
	sum(isjob) as isjob,
	sum(tenured) as tenured,
	sum(tenuretrack) as tenuretrack,
	sum(nontenuretrack) as nontenuretrack,
	sum(instructor) as instructor,
	sum(lecturer) as lecturer,
	sum(assistantprofessor) as assistantprofessor,
	sum(associateprofessor) as associateprofessor,
	sum(teachingprofessor) as teachingprofessor,
	sum(professorofpractice) as professorofpractice ,
	sum(phd) as phd,
	sum(earneddoctorate) as earneddoctorate,
	sum(masters) as masters,
	sum(securityofemployment) as securityofemployment,
	sum(temporaryfixed) as temporaryfixed,
	sum(visiting) as visiting,
	sum(multiple) as multiple,
	sum(fulltime) as fulltime,
	sum(parttime) as parttime,
	sum(rankopen) as rankopen,
	sum(adjunct) as adjunct
from
	jobkeyword
group by
	academicyear;

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
