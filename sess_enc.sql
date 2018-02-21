-- sess_enc.sql 
--
-- identify for all processes if they are using encryption & checksum
-- as it's based on LIKE - it's somehow weak & must be tested with new versions
-- 
-- 2018-02-21 - berx - initial
--
with connect_info as (
select sci.sid, sci.authentication_type, sci.client_driver, sci.client_lobattr,
    max(case when network_service_banner like '%ncryption service adapter %' then 'YES' 
    end) as encr,
    max(case when network_service_banner like '%rypto-checksumming service adapter%' then 'YES' 
    end) as checksum
from  v$session_connect_info sci
group by sci.sid, sci.authentication_type, sci.client_driver, sci.client_lobattr
)
select ses.sid, ses.username, ses.schemaname, ses.osuser, ses.process, 
       ses.machine, ses.program, ses.module, ses.action, ses.client_info, ses.logon_time,
       ci.authentication_type, ci.client_driver, ci.client_lobattr, ci.encr, ci.checksum 
from v$session ses left outer join connect_info ci on ses.sid = ci.sid ;
