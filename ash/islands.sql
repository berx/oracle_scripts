------------------------------------------------------------------------------
--
-- File name:   islands.sql
-- Purpose:     Based on ASH, it gives islands of activity in an ocean of idle
--              the primary concept comes from 
--              https://method-r.com/2014/02/17/connection-pool-response-times-with-method-r-tools-oceans-islands-and-rivers/
--              or 
--              https://de.slideshare.net/carymillsap/oceans-islands-rivers-etckey
--              
--              Some constants can be "set" at the beginning of the query the
--              CONST CTE.
--              Reasonable FILTERS can be applied in the FILTER_FIRST CTE.
--
--              have a look at http://berxblog.blogspot.com/2020/06/oceans-islands-and-rivers-in-ash.html
--              
--              It can be easily adapted, e.g. for DBA_HIST_ACTIVE_SESS_HISTORY
--
-- Version:     1
-- Author:      Martin Berger (martin.a.berger@gmail.com)
-- Copyright:   (c) 2020 Martin Berger - http://berxblog.blogspot.com - All rights reserved.
--              Licensed under the Apache License, Version 2.0. See LICENSE.txt for terms & conditions.
--
-- Disclaimer:  This script is provided "as is", so no warranties or 
--              guarantees are made about its correctness, reliability 
--              and safety. Use it at your own risk!
--
-- Thanks to:   Cary Millsap for the idea
--              Markus Wienand and Kim Berg Hansen for their help 
--               with MATCH_RECOGNIZE 
--               https://modern-sql.com/de/feature/match_recognize
--
--------------------------------------------------------------------------------

WITH CONST as (
SELECT /*+ qb_name(QB_CONST) */
    100 as GANTT_LENGTH -- unit: characters
  , 1   as RIVER_WIDTH  -- unit: sample_periode of ASH. --everything else IDLE is an OCEAN
FROM DUAL  
) ,FILTER_FIRST as (
SELECT /*+ qb_name(QB_FILTER_FIRST) */  ash.* 
FROM gv$active_session_history ash
WHERE 1=1 
--  AND USER_ID=123
--  AND ....
--  AND SAMPLE_ID < 487871
), ISLANDS as (
SELECT /*+ qb_Name(QB_ISLANDS) */
      min(BEGIN_SAMPLE_ID) OVER () total_min_sample_ID
   ,  max(END_SAMPLE_ID) OVER () total_max_sample_ID      
   ,   BEGIN_SAMPLE_ID
   ,  END_SAMPLE_ID
   ,  END_SAMPLE_ID - BEGIN_SAMPLE_ID +1  as ISLAND_LENGTH
   ,  ACTIVE_COUNT
   ,  inst_id
   ,  session_id
   ,  session_serial#
FROM FILTER_FIRST ff
       MATCH_RECOGNIZE(
         PARTITION BY inst_id, session_id, session_serial#
         ORDER BY SAMPLE_ID 
         MEASURES 
           first(SAMPLE_ID) as BEGIN_SAMPLE_ID,
           LAST(sample_id)  as END_SAMPLE_ID,
           COUNT(sample_id) as ACTIVE_COUNT
         ONE ROW PER MATCH
         PATTERN( frst cont*)
         DEFINE cont as SAMPLE_ID - prev(SAMPLE_ID) <= (SELECT RIVER_WIDTH FROM CONST) 
       )  
)
SELECT /*+ qb_name(QB_MAIN)*/ isl.begin_sample_id
     , isl.end_sample_id
     , isl.island_length
     , isl.active_count
     , isl.inst_id
     , isl.session_id
     , isl.session_serial#
FROM ISLANDS isl
Order by isl.begin_sample_id
        , isl.inst_id
        , isl.session_id
/