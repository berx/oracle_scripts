alter session set container=PDB1;

create user trc identified by trc; 
grant create session to trc;
grant create procedure to trc; 
grant alter session to trc; 

connect trc/trc@PDB1

create or replace package bla as 

  TYPE t_d Is Table Of varchar2(100);

  function get_date 
  RETURN t_d PIPELINED;

end bla; 
/

create or replace package body bla as

  execs number := 0;

  function get_date
    return t_d PIPELINED as
    d varchar2(100);
    s varchar2(1000);
  begin
    FOR i IN 1 .. 99 LOOP
      s := 'Select ''' || 
        to_number(execs) || ' : ' || 
        rpad(' ', execs, ' ') || to_char(sysdate, 'YYYY-MM-DD HH24:MI:SS') || ''' from Dual';
      dbms_output.put_line (s);
      Execute Immediate s INTO d;
      execs := execs + 1;
    PIPE ROW(d);
  END LOOP;
  end get_date;

end bla;
/
