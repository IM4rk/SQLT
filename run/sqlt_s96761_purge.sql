REM Purges statement_id 96761 from local SQLT repository. Just execute "@sqlt_s96761_purge.sql" from sqlplus.
SPO sqlt_s96761_purge.log;
SET SERVEROUT ON;
EXEC SQLTXADMIN.sqlt$a.purge_repository(96761, 96761);
SET SERVEROUT OFF;
SPO OFF;
