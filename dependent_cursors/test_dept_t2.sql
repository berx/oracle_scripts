set serveroutput on
alter session set nls_date_format='YYYY-MM-DD HH24:MI:SS';
alter session set events '10046 trace name context forever, level 12'; 

declare 
  dt varchar2(100);
  cursor c1 is select * from table(bla.get_date() );
  cursor c2 is select t.*  from table(bla.get_date() ) t;
begin
  open c1;
  fetch c1 into dt;
  dbms_output.put_line('c1 - ' || dt);

  fetch c1 into dt;
  dbms_output.put_line('c1 - ' || dt);

  open c2 ;

  fetch c2 into dt;
  dbms_output.put_line('c2 - ' || dt);

  fetch c1 into dt;
  dbms_output.put_line('c1 - ' || dt);

  close c1; 
  close c2;  

end; 
/
alter session set events '10046 trace name context forever, level 0'; 

quit
