REM Purges statement_id 96902 from local SQLT repository. Just execute "@sqlt_s96902_purge.sql" from sqlplus.
SPO sqlt_s96902_purge.log;
SET SERVEROUT ON;
EXEC SQLTXADMIN.sqlt$a.purge_repository(96902, 96902);
SET SERVEROUT OFF;
SPO OFF;
