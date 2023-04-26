set lines 140
set pages 999
col full_alias_path for a70
col sum_bytes for 999999999999999
col GB for 99999.99
col LVL for 99
alter session set NLS_DATE_FORMAT='YYYY-MM-DD HH24:MI';
ALTER SESSION SET NLS_LANGUAGE='ENGLISH';

select /* 20230426 - berx - V0.2
       */
        /*+ QB_NAME(main) */ 
       all_directories.full_alias_path
     , dir_sizes_dates.sum_bytes
     , round(dir_sizes_dates.sum_bytes/power(1024,3),2) GB
     , all_directories.lvl 
     , earliest_modify_date, latest_modify_date
from (-- all_directories
    SELECT /*+ QB_NAME(all_directories) */ 
           concat('+'||gname, sys_connect_by_path(aname, '/')) full_alias_path
         , level as lvl, rindex
    FROM (
        SELECT /*+ QB_NAME(dir_components) */ 
               g.name gname, a.parent_index pindex
             , a.name aname, a.reference_index rindex
        FROM v$asm_alias a, v$asm_diskgroup g
        WHERE a.group_number = g.group_number
          AND a.alias_directory='Y'
          AND g.name = '&&DG_name') dir_components
    START WITH (mod(pindex, power(2, 24))) = 0 
    CONNECT BY PRIOR rindex = pindex
     )all_directories,
     (
    Select /*+ QB_NAME(dir_sizes_dates) */ 
           rindex, sum(nvl(bytes_path,0)) as sum_bytes
         , to_date(min(date_path), 'YYYY-MM-DD_HH24:MI') earliest_modify_date
         , to_date(max(date_path), 'YYYY-MM-DD_HH24:MI') latest_modify_date
--         , rindex_path
    from (
        SELECT /*+ QB_NAME(byte_to_every_dir) */ 
              sys_connect_by_path(bytes,' ') bytes_path, pindex, rindex 
--            , level
            , sys_connect_by_path(mod_date, ' ') date_path
--            , sys_connect_by_path(rindex, ' ') as rindex_path
--            , bytes
        FROM (	
    	    SELECT /** qb_name (all_aliases) */ 
                   g.name gname, a.parent_index pindex, a.name aname
                 , a.reference_index rindex 
--------------
                 , f.bytes
                 , to_char(f.modification_date, 'YYYY-MM-DD_HH24:MI') mod_date
------------  switch to lines below IF you are interesed in "older 90 days" only
/*
                 , case when f.modification_date < sysdate-90 
                        then f.bytes else NULL end as bytes
                 , case when f.modification_date < sysdate-90 
                        then to_char(f.modification_date,  'YYYY-MM-DD_HH24:MI') 
                        else NULL end as mod_date
--*/                        
--------------                 
            FROM v$asm_alias a, v$asm_diskgroup g, v$asm_file f
            WHERE a.group_number = g.group_number
              AND a.file_number = f.file_number(+)
              AND a.group_number = f.group_number (+) 
              AND g.name = '&&DG_name') all_aliases
        START WITH nvl(bytes,0)>0
        CONNECT BY PRIOR pindex = rindex
         ) byte_to_every_dir
    group by rindex
  ) dir_sizes_dates
where dir_sizes_dates.rindex (+) = all_directories.rindex 
--  and lvl = 1  -- <-- for high level overview - if required
order by 1;
undefine DG_name
