----------------------------------------------------------------------------------------
-- Courses and Prerequisites
-- by Alan G. Labouseur
-- Tested on Postgres 9.3.2
----------------------------------------------------------------------------------------

-- 
-- Drop tables
-- 

drop table if exists prerequisites;
drop table if exists courses;

--
-- The table of courses.
--
create table Courses (
    num      integer not null,
    name     text    not null,
    credits  integer not null,
  primary key (num)
);


insert into Courses(num, name, credits)
values (499, 'CS/ITS Capping', 3 );

insert into Courses(num, name, credits)
values (308, 'Database Systems', 4 );

insert into Courses(num, name, credits)
values (221, 'Software Development Two', 4 );

insert into Courses(num, name, credits)
values (220, 'Software Development One', 4 );

insert into Courses(num, name, credits)
values (120, 'Introduction to Programming', 4);

select * 
from courses
order by num ASC;


--
-- Courses and their prerequisites
--
create table Prerequisites (
    courseNum integer not null references Courses(num),
    preReqNum integer not null references Courses(num),
  primary key (courseNum, preReqNum)
);

insert into Prerequisites(courseNum, preReqNum)
values (499, 308);

insert into Prerequisites(courseNum, preReqNum)
values (499, 221);

insert into Prerequisites(courseNum, preReqNum)
values (308, 120);

insert into Prerequisites(courseNum, preReqNum)
values (221, 220);

insert into Prerequisites(courseNum, preReqNum)
values (220, 120);

select *
from Prerequisites
order by courseNum DESC;


--
-- An example stored procedure ("function")
--
create or replace function get_courses_by_credits(int, REFCURSOR) returns refcursor as 
$$
declare
   num_credits int       := $1;
   resultset   REFCURSOR := $2;
begin
   open resultset for 
      select num, name, credits
      from   courses
       where  credits >= num_credits;
   return resultset;
end;
$$ 
language plpgsql;

select get_courses_by_credits(0, 'results');
Fetch all from results;

-- ---------------------------------------------------------------------------------------------------
-- Brian Henderson
-- November 30 2016
-- Lab 10: Stored Procedures
-- ---------------------------------------------------------------------------------------------------

-- 
-- 1: function PreReqsFor(courseNum) : Returns the immediate prerequisites for the passed-in 
--    course number.
-- 

create or replace function PreReqsFor(int, REFCURSOR) returns refcursor as
$$
declare
   course_num  int       := $1;
   preReqs     REFCURSOR := $2;
begin
   open preReqs for 
      select preReqNum
      from Prerequisites
      where  courseNum = course_num;
   return preReqs;
end;
$$ 
language plpgsql;

-- 
-- 2: functon IsPreReqFor(courseNum) : Returns the courses for which the passed-in course number is an 
--    immediate pre-requisite.
-- 

create or replace function IsPreReqFor(int, REFCURSOR) returns refcursor as
$$
declare
    course_num    int       := $1;
    courses       REFCURSOR := $2;
begin
    open courses for
       select preReqNum
       from Prerequisites
       where preReqNum = course_num;
    return courses;
end;
$$
language plpgsql;

-- 
-- Demonstrate Jedi-level skills and write a third, recursive, function that takes a passed-in course 
-- number and generates all of its prerequisites. Uses the Sirst two functions you wrote and recursion.
-- 

create or replace function AllPreReqsFor (int, REFCURSOR) returns refcursor as
$$
declare
    course_num   int       := 1;
    course_count REFCURSOR := 2;
    all_preReqs  REFCURSOR := 3;
    res          REFCURSOR := 4;
begin
    open course_count for
        select PreReqsFor(course_num, 'res');
        Fetch all from res;
      for i in select courseNum from course_count ;
      Loop
        all_preReqs UNION DISTINCT course_num;
        return allPreqsFor(i);
      End Loop;
end;
$$
language plpgsql;

-- I have not yet reached Jedi status :( But one day!
`


select get_courses_by_credits(0, 'results0');
Fetch all from results0;

select PreReqsFor(220, 'results1');
Fetch all from results1;

select IsPreReqFor(120, 'results2');
Fetch all from results2;

AllPreReqFor(499, 'results3')
Fetch all from results3;
