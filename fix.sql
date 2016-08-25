# this will fix academic years if I don't fix converting the months to numbers in perl
begin transaction;

select distinct(month) from message;

update message set month = 1 where month = 'Jan';
update message set month = 2 where month = 'Feb';
update message set month = 3 where month = 'Mar';
update message set month = 4 where month = 'Apr';
update message set month = 5 where month = 'May';
update message set month = 6 where month = 'Jun';
update message set month = 7 where month = 'Jul';
update message set month = 8 where month = 'Aug';
update message set month = 9 where month = 'Sep';
update message set month = 10 where month = 'Oct';
update message set month = 11 where month = 'Nov';
update message set month = 12 where month = 'Dec';

select distinct(month) from message;

select academicyear, count(*) from jobmessageinfo where isjob = 1 group by academicyear;

update message set academicyear = year;
update message set academicyear = academicyear - 1 where month < 6;

select academicyear, count(*) from jobmessageinfo where isjob = 1 group by academicyear;
