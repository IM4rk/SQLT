REM Purges statement_id 58733 from local SQLT repository. Just execute "@sqlt_s58733_purge.sql" from sqlplus.
SPO sqlt_s58733_purge.log;
SET SERVEROUT ON;
EXEC SQLTXADMIN.sqlt$a.purge_repository(58733, 58733);
SET SERVEROUT OFF;
SPO OFF;
