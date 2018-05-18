alter session set nls_date_format = 'yyyy-mm-dd/hh24:mi:ss'

/


INSERT INTO casemgr.search_results (case_id, target_date, drafter_target_date, drafter_target_days, case_number,case_year, case_ref, cases_count, total, number_string
    , oe_list, forename, surname, am_forename, am_surname, pm_forename, pm_surname, stage_id, template_name,  td_id, case_status_desc, case_officer, external_loader_count, sent_to_minister_flag
    ,   contribution_details, text_relevance_score, free_text_snippet, free_text_section, free_text_match_count, text_relevance_score_doc, free_text_snippet_doc, free_text_category,
 free_text_match_count_doc, free_text_file_id)
WITH
 case_privs AS (
  --
  -- Case ids that exist and this user can see
  --
  SELECT
       xcd.cd_id
  FROM
       casemgr.xview_case_details xcd
  JOIN casemgr.vw_case_access vc ON vc.case_id = xcd.case_id AND vc.wua_id = 42 AND vc.system_area = xcd.system_area AND casemgr.ca_access.check_priv(vc.access_level, 'SEARCH') = 'true'
  WHERE
       xcd.status_control  = 'C'
  AND  xcd.case_status    != 'DRAFT'
  AND  xcd.system_area     = 'BIS_CU'
)
,
 t1 AS (
  --
  -- Main search filter
  --
  SELECT DISTINCT
    xcd.case_id
  , ct.target_date
  , ct.drafter_target_date
  , NVL2(ct.drafter_days_text, ct.drafter_days_text || ' (Paused)', NULL) drafter_target_days
  , ct.drafter_target_when_known drafter_target_disp
  , st.to_number_safe(substr(c.case_number,0, INSTR(c.case_number,'/')-1)) case_year
  , NULL text_relevance_score
  , NULL snippet
  , NULL section
  , NULL matched_count
  , NULL text_relevance_score_doc
  , NULL snippet_doc
  , NULL document_category
  , NULL matched_count_doc
  , NULL fox_file_id
  FROM case_privs                     cp
  JOIN casemgr.xview_case_details     xcd ON xcd.cd_id   = cp.cd_id
  JOIN casemgr.case_type_attributes   cta ON cta.case_type = xcd.case_type AND cta.system_area = xcd.system_area
  JOIN casemgr.cases                  c   ON xcd.case_id = c.id
  JOIN casemgr.case_timeliness        ct ON ct.case_uref = c.uref_value
  JOIN casemgr.case_stage_tip_initial_reopen cstio ON cstio.cd_id = xcd.cd_id AND cstio.status_control = 'C'
  LEFT OUTER JOIN casemgr.foi_case_details fcd ON fcd.cd_id = xcd.cd_id
  LEFT JOIN casemgr.xview_case_contacts xcc ON xcc.cd_id = xcd.cd_id
  WHERE xcd.status_control = 'C'
  AND xcd.case_status               = 'OPEN'
)
,
 t2 AS (
  SELECT
    t1.case_id
  , t1.target_date
  , t1.drafter_target_disp
  , t1.drafter_target_days
  , t1.text_relevance_score
  , t1.snippet
  , t1.section
  , t1.matched_count
  , t1.text_relevance_score_doc
  , t1.snippet_doc
  , t1.document_category
  , t1.matched_count_doc
  , t1.fox_file_id
  , c.case_number
  , t1.case_year
  , c.case_ref
  , xcd.create_method
  , count(1) OVER (PARTITION BY 1) cases_count
  FROM t1
  JOIN casemgr.cases c ON c.id = t1.case_id
  JOIN casemgr.xview_case_details xcd ON xcd.case_id = c.id
  WHERE (xcd.status_control = 'C'
  AND t1.target_date >= '2018-03-01/00:00:00'
  AND t1.target_date <= '2018-03-31/23:59:59'
  )
  ORDER BY t1.case_year DESC NULLS LAST, c.case_number DESC
)
,
 t3 AS (
  SELECT
    t2.case_id
  , t2.target_date
  , t2.drafter_target_disp
  , t2.drafter_target_days
  , t2.case_number
  , t2.case_year
  , t2.case_ref
  , t2.cases_count
  , t2.text_relevance_score
  , t2.snippet
  , t2.section
  , t2.matched_count
  , t2.text_relevance_score_doc
  , t2.snippet_doc
  , t2.document_category
  , t2.matched_count_doc
  , t2.fox_file_id
  , NULL external_loader_count
  FROM t2
  WHERE rownum <= 2500
)
SELECT
  search_matches.case_id
, search_matches.target_date
, search_matches.drafter_target_disp
, search_matches.drafter_target_days
, search_matches.case_number
, search_matches.case_year
, search_matches.case_ref
, search_matches.cases_count
, nvl(rc.total, 0)
, rc.number_string
, rc.oe_list
, rm.forename
, rm.surname
, rm2.forename am_forename
, rm2.surname am_surname
, rm3.forename pm_forename
, rm3.surname pm_surname
, cstio.stage_id
, xtd.template_name
, xtd.td_id
, casemgr.ca_utils.get_status_description(search_matches.case_id) case_status_desc
, casemgr.ca_utils.get_case_officer(search_matches.case_id) case_officer
, search_matches.external_loader_count
, CASE WHEN xcd.sent_to_minister_flag = 'true' OR xcd.sent_to_second_minister_flag = 'true' THEN 'true' ELSE 'false' END sent_to_minister_flag
, rc.contribution_details
, search_matches.text_relevance_score
, search_matches.snippet
, search_matches.section
, search_matches.matched_count
, search_matches.text_relevance_score_doc
, search_matches.snippet_doc
, search_matches.document_category
, search_matches.matched_count_doc
, search_matches.fox_file_id
FROM t3                                        search_matches
JOIN casemgr.xview_case_details                xcd ON search_matches.case_id = xcd.case_id
JOIN casemgr.case_stage_tip_initial_reopen cstio ON cstio.cd_id = xcd.cd_id AND cstio.status_control = 'C'
LEFT JOIN casemgr.xview_template_documents     xtd ON xcd.campaign_id        = xtd.td_id                     AND xtd.status_control = 'C'
LEFT JOIN decmgr.xview_resource_people_history rm  ON rm.rp_id               = xcd.responding_minister_rp_id AND rm.status_control  = 'C'
LEFT JOIN decmgr.xview_resource_people_history rm2 ON rm2.rp_id              = xcd.addressee_minister_rp_id AND rm2.status_control = 'C'
LEFT JOIN decmgr.xview_resource_people_history rm3 ON rm3.rp_id              = xcd.policy_minister_rp_id AND rm3.status_control = 'C'
LEFT JOIN (
        SELECT
          t.case_id
        , t.total
        , CASE WHEN t.open_count > 0 THEN '(' || open_count || ' Open)' END number_string
        , t.oe_list
        , NULL contribution_details
        FROM casemgr.referral_counts t
        WHERE t.referral_type = 'CONTRIBUTION'
        AND t.case_id IN ( SELECT case_id FROM t3)
      )
                                               rc  ON xcd.case_id            = rc.case_id
WHERE xcd.status_control = 'C'
UNION ALL
SELECT
NULL case_id
, NULL target_date
, NULL drafter_target_date
, NULL
, NULL case_number
, NULL case_year
, 'EXTERNAL_LOADER_DUMMY_ROW' case_ref
, NULL cases_count
, NULL
, NULL
, NULL
, NULL
, NULL
, NULL
, NULL
, NULL
, NULL external_loader_count
, NULL
, NULL
, NULL
, NULL
, NULL
, NULL
, NULL
, NULL
, NULL
, NULL
, NULL
, NULL
, NULL
, NULL
, NULL
, NULL
, NULL
FROM dual;

