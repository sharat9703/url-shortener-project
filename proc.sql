PROMPT CREATE OR REPLACE PROCEDURE mfx_tf_fetch_data
CREATE OR REPLACE procedure mfx_tf_fetch_data(a_trans_ref_no varchar2,trans_type varchar2,a_branch_code varchar2,
a_user_id VARCHAR2,a_funding_req varchar2,v_err_code OUT VARCHAR2,v_err_msg OUT  clob)
IS
v_trans_ref_no  VARCHAR2(35);
v_cust_id VARCHAR2(35);
v_trans_curr VARCHAR2(3);
v_trans_amt  NUMBER(17,6);
v_eefc_trans_curr_amt NUMBER(24,6);
v_eefc_conv_amt NUMBER(24,6);
v_oth_curr  VARCHAR2(3);
v_ready_amt  NUMBER(17,6);
v_nego_start_date VARCHAR2(10);
v_start_date    VARCHAR2(10);
v_end_date VARCHAR2(20);
v_maturity_date VARCHAR2(10);
v_current_status VARCHAR2(60);
v_nego_disc VARCHAR2(3);
v_trans_nostroid VARCHAR2(35);
v_oth_nostroid VARCHAR2(35);
v_corr_ref VARCHAR2(35);
v_rate NUMBER(14,6);
v_rate1 NUMBER(14,6);
v_rate2 NUMBER(14,6);
v_ready_rupee_eqvt NUMBER(24,6);
v_mtrans_no VARCHAR2(30);
cnt_tf_data NUMBER;
v_contract_type   VARCHAR2(30);
v_record_type  VARCHAR2(35);
v_delivery_trans_no VARCHAR2(30);
v_rebooking VARCHAR2(30);
v_margin_rupee NUMBER(14,6);
v_mode_disbursal NUMBER(14,6);
v_swap_charges NUMBER(20);
------------
v_bill_refno  VARCHAR2(35);
v_pcfc_trans_curr_amt NUMBER(35,4);
 v_pcfc_conv_amt  NUMBER(35,4);
v_branch_code VARCHAR2(15);
v_value_date VARCHAR2(10);
v_nostro_date  VARCHAR2(10);
v_nostro_real_date  VARCHAR2(10);
v_trans_date_tf VARCHAR2(10);
v_buy_sell VARCHAR2(20);
v_tenor NUMBER(35);
v_excess_short VARCHAR2(20);
v_amt_realised VARCHAR2(20);
v_rate_breakup VARCHAR2(30);
v_spread      VARCHAR2(10);
v_base_rate    NUMBER(14,6);
v_gross_rate NUMBER(24,6);
v_cancel_rate  NUMBER(16,6);
v_cancel_charges NUMBER(16,6);
v_bal_amt   NUMBER(17,3);
 err_num NUMBER ;             -- For storing the error number
 err_msg VARCHAR2(5000);       -- for storing the error message
v_sq1 VARCHAR2(32765);
v_chk VARCHAR2(32765);
V_Out3  VARCHAR2(500);
v_cmt   VARCHAR2(500);
V_ID    VARCHAR2(32765);
v_IF_ID VARCHAR2(32765);
v_chk_cnt    number;
tmp_err_code VARCHAR2(200);
tmp_err_msg VARCHAR2(4800);
v_conv_curr VARCHAR2(20);
v_conv_corr VARCHAR2(20);
v_disbursal_mfx_no VARCHAR2(30);
v_forex_txn_no  VARCHAR2(30);
v_BILL_REMITTANCE_NUMBER VARCHAR2(30);
v_BILL_REMITTANCE_MFX_NO VARCHAR2(30);
v_chk_BRANCH_USER_ID VARCHAR2(30);
v_chk_TRANS_TYPE_CODE  VARCHAR2(30);
v_interest_fcy NUMBER(16,6);
v_err_code_mm_conv VARCHAR2(200);
v_err_msg_mm_conv VARCHAR2(4900);
v_err_code_lcy VARCHAR2(200);
v_err_msg_lcy  VARCHAR2(4900);
v_mode_disbusal VARCHAR2(200);
v_MFX_TRANS_NO VARCHAR2(200);
v_cust_charges_acc_no  VARCHAR2(200);
v_exp_bill_type  VARCHAR2(200);
v_nature_of_bill   VARCHAR2(200);
v_premium_upto_date VARCHAR2(10);
v_interest_amt NUMBER(17,3);
v_fb_charges_amt NUMBER(27,3);
v_refund_intr_amt NUMBER(27,3);
v_outstanding_nego_amt NUMBER(27,3);
v_cust_cif_no VARCHAR2(35); --to store the TF CIF manoj 25-apr-08

-- Jitesh : 17.01.2012 : v4.0.0.116 : Forward Cancellation Gain changes.
v_customer_liability_type VARCHAR2(10);
v_rollover VARCHAR2(10);
-- Office : 20.09.2012 : v4.0.0.147 : DE15
v_doc_submit_date VARCHAR2(10);
-- Office : 29.10.2012 : v4.0.0.151 : Send MTM and PFE account number from exim to murex
v_mtm_account VARCHAR2(20);
v_pfe_account VARCHAR2(20);
v_delv_type VARCHAR2(20);
---vasudeo Buyers Credit start -----
v_Paymt_Amt_FCY VARCHAR2(100);
v_paymt_flag VARCHAR2(10);
v_othr_charges VARCHAR2(100);
v_mig_bank VARCHAR2(255);
---vasudeo Buyers Credit End -----

--fwd cashflow params
v_cashflow_urn VARCHAR2(100);
v_cashflow_ccy VARCHAR2(100);
v_cashflow_expected_end_date DATE;
v_cashflow_expected_amt NUMBER;
v_simplified_hedge VARCHAR2(100);

--odi params
v_odi_trn_no VARCHAR2(100);
v_odi_uin VARCHAR2(100);
v_odi_flag VARCHAR2(1):='0';

--flc params
v_conversion_flag VARCHAR2(10);
v_other_ccy_credit VARCHAR2(10);

v_poc_cnt NUMBER; --poc
CURSOR cr_fetch IS  SELECT  SQL_STMT,VALID_CHK,mst.COMMENTS FROM mfx_tf_trans_sql_map mp ,mfx_tf_sql_master mst WHERE mp.MFX_TF_SQL_ID=mst.MFX_TF_SQL_ID
 and trans_type_code=trans_type AND SEND_RECV='R'  ORDER BY  SEQ;
BEGIN
Dbms_Output.put_line('one ');
v_err_code:='00';
v_err_msg :='';
v_IF_ID:='';
v_mig_bank:='';
Dbms_Output.put_line('start 1 :  ');
SELECT mfx_get_bank(a_branch_code) INTO v_mig_bank FROM dual;
Dbms_Output.put_line('end 1 :  '||v_mig_bank);


SELECT Count(*) INTO cnt_tf_data FROM mfx_IF_transaction_Master WHERE ref_number=a_trans_ref_no AND Nvl(sent_back,'N')!='Y' ;
print_out('Entries available IN mfx_IF_transaction_Master==> '||cnt_tf_data);
IF(cnt_tf_data=0) THEN
SELECT mfx_tf_data_id.NEXTVAL INTO V_ID FROM dual;
EXECUTE IMMEDIATE 'alter session set nls_date_format =''dd-mm-yyyy''';
v_trans_ref_no  :=a_trans_ref_no;
Dbms_Output.put_line(v_trans_ref_no||' * ');
Dbms_Output.put_line(trans_type||' * ');
SELECT buy_sell INTO v_buy_sell FROM trans_type_master WHERE trans_type_code=trans_type;
Dbms_Output.put_line('  * 3 * ');
CASE
WHEN trans_type='BN' Then  Dbms_Output.put_line('Called  Export Bill negotiation, discounting');
Dbms_Output.put_line('start 2 :  2');
 IF v_mig_bank='SBH' THEN
 Dbms_Output.put_line('SBH');
  --mercury_exim_sbh.FETCH_EXPNEGODISC(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,v_ready_amt,v_nego_start_date,
  --v_maturity_date,v_current_status,v_nego_disc,v_trans_nostroid,v_oth_nostroid,v_branch_code,v_exp_bill_type,v_nature_of_bill,v_premium_upto_date);
  ELSIF v_mig_bank='SBBJ' THEN
  Dbms_Output.put_line('SBBJ');
  --mercury_exim_sbbj.FETCH_EXPNEGODISC(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,v_ready_amt,v_nego_start_date,
  --v_maturity_date,v_current_status,v_nego_disc,v_trans_nostroid,v_oth_nostroid,v_branch_code,v_exp_bill_type,v_nature_of_bill,v_premium_upto_date);
  ELSIF v_mig_bank='SBT' THEN
  Dbms_Output.put_line('SBT');
  --mercury_exim_sbt.FETCH_EXPNEGODISC(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,v_ready_amt,v_nego_start_date,
  --v_maturity_date,v_current_status,v_nego_disc,v_trans_nostroid,v_oth_nostroid,v_branch_code,v_exp_bill_type,v_nature_of_bill,v_premium_upto_date);
  ELSIF v_mig_bank='SBP' THEN
  Dbms_Output.put_line('SBP');
  --mercury_exim_sbp.FETCH_EXPNEGODISC(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,v_ready_amt,v_nego_start_date,
  --v_maturity_date,v_current_status,v_nego_disc,v_trans_nostroid,v_oth_nostroid,v_branch_code,v_exp_bill_type,v_nature_of_bill,v_premium_upto_date);
  ELSIF v_mig_bank='SBM' THEN
  Dbms_Output.put_line('SBM');
  --mercury_exim_sbm.FETCH_EXPNEGODISC(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,v_ready_amt,v_nego_start_date,
  --v_maturity_date,v_current_status,v_nego_disc,v_trans_nostroid,v_oth_nostroid,v_branch_code,v_exp_bill_type,v_nature_of_bill,v_premium_upto_date);
  ELSE
  Dbms_Output.put_line('SBI');
  --mercury_exim_fetch_EXPNEGODISC(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,v_ready_amt,v_nego_start_date,
  --v_maturity_date,v_current_status,v_nego_disc,v_trans_nostroid,v_oth_nostroid,v_branch_code,v_exp_bill_type,v_nature_of_bill,v_premium_upto_date);
  END IF ;
 Dbms_Output.put_line('end 2 :  2');
 -- Jitesh : 19.03.2012 : Log to maintain data received from Trade Finance.
  --insert into mfx_tf_raw_data(trans_ref_no,trans_type_code,fetch_time,cust_id,trans_curr,trans_amt,eefc_trans_curr_amt,eefc_conv_amt,oth_curr,ready_amt,
  --nego_start_date,maturity_date,current_status,nego_disc,trans_nostroid,oth_nostroid,branch_code,exp_bill_type,nature_of_bill,premium_upto_date)
  --values (v_trans_ref_no,trans_type,sysdate,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,v_ready_amt,
  --v_nego_start_date,v_maturity_date,v_current_status,v_nego_disc,v_trans_nostroid,v_oth_nostroid,v_branch_code,v_exp_bill_type,v_nature_of_bill,v_premium_upto_date);

SELECT
    TRANS_REF_NO,cust_id,trans_curr,trans_amt,eefc_trans_curr_amt,eefc_conv_amt,oth_curr,ready_amt,
    nego_start_date,maturity_date,current_status,nego_disc,trans_nostroid,oth_nostroid,branch_code,exp_bill_type,nature_of_bill,premium_upto_date
  INTO
    v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,v_ready_amt,
    v_nego_start_date,v_maturity_date,v_current_status,v_nego_disc,v_trans_nostroid,v_oth_nostroid,v_branch_code,v_exp_bill_type,v_nature_of_bill,v_premium_upto_date
FROM  MFX_TF_RAW_DATA
WHERE TRANS_REF_NO=v_trans_ref_no AND trans_type_code='BN';


  Dbms_Output.put_line(v_cust_id||' * ');
  Dbms_Output.put_line('v_trans_amt:'||v_trans_amt);
  v_cust_cif_no:=v_cust_id;
    mfx_tf_if_fetch_validation(v_trans_ref_no,trans_type,v_trans_nostroid,v_trans_curr,v_oth_nostroid,v_oth_curr,v_start_date,v_value_date,v_maturity_date,v_cust_id,
    v_current_status , v_excess_short ,v_nego_disc ,v_mode_disbusal ,v_record_type ,v_contract_type ,v_trans_amt ,
    v_ready_amt ,v_eefc_trans_curr_amt ,v_eefc_conv_amt ,v_pcfc_trans_curr_amt ,v_pcfc_conv_amt ,v_bal_amt,v_bal_amt,v_branch_code ,
    a_branch_code ,v_base_rate,v_spread,v_gross_rate,
    a_user_id  ,v_cust_charges_acc_no ,v_exp_bill_type ,v_nature_of_bill  , v_premium_upto_date,v_rate ,v_conv_curr ,v_conv_corr ,v_interest_fcy,v_amt_realised,v_outstanding_nego_amt,
    tmp_err_code,tmp_err_msg);
Dbms_Output.put_line('tmp_err_code ==>'||tmp_err_code||tmp_err_msg);
IF(tmp_err_code='00') THEN
  mfx_tf_conv_curr_corr(trans_type,v_trans_curr,v_oth_curr,v_trans_nostroid,v_oth_nostroid,v_conv_curr,v_conv_corr);
  insert into mfx_tf_data (TF_ID,trans_ref_no,trans_type_code,fetch_time,cust_id,trans_curr,trans_amt,eefc_trans_curr_amt,eefc_conv_amt,oth_curr,ready_amt,
  nego_start_date,maturity_date,current_status,nego_disc,trans_nostroid,oth_nostroid,branch_code,INR_nostroid,buy_sell,branch_user_id,conv_curr,conv_corr,value_date,
  premium_upto_date,start_date)
   values ( V_ID,v_trans_ref_no,trans_type,sysdate,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,v_ready_amt,
  v_nego_start_date,v_maturity_date,v_current_status,v_nego_disc,v_trans_nostroid,v_oth_nostroid,v_branch_code,'OVRAC',v_buy_sell,a_user_id,v_conv_curr,v_conv_corr,v_value_date,
  v_premium_upto_date,v_premium_upto_date);
END IF;
WHEN trans_type='BCR' Then  Dbms_Output.put_line('Called  Export Bill Crystallization');
Dbms_Output.put_line('start 3');
IF v_mig_bank='SBH' THEN
Dbms_Output.put_line('SBH');
--mercury_exim_sbh.FETCH_EXPCRYSTAL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_nego_start_date,v_maturity_date,v_current_status,v_branch_code,v_exp_bill_type,v_nature_of_bill,v_premium_upto_date,v_rate,v_fb_charges_amt);
ELSIF v_mig_bank='SBBJ' THEN
Dbms_Output.put_line('SBBJ');
--mercury_exim_sbbj.FETCH_EXPCRYSTAL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_nego_start_date,v_maturity_date,v_current_status,v_branch_code,v_exp_bill_type,v_nature_of_bill,v_premium_upto_date,v_rate,v_fb_charges_amt);
ELSIF v_mig_bank='SBT' THEN
Dbms_Output.put_line('SBT');
--mercury_exim_sbt.FETCH_EXPCRYSTAL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_nego_start_date,v_maturity_date,v_current_status,v_branch_code,v_exp_bill_type,v_nature_of_bill,v_premium_upto_date,v_rate,v_fb_charges_amt);
ELSIF v_mig_bank='SBP' THEN
Dbms_Output.put_line('SBP');
--mercury_exim_sbp.FETCH_EXPCRYSTAL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_nego_start_date,v_maturity_date,v_current_status,v_branch_code,v_exp_bill_type,v_nature_of_bill,v_premium_upto_date,v_rate,v_fb_charges_amt);
ELSIF v_mig_bank='SBM' THEN
Dbms_Output.put_line('SBM');
--mercury_exim_sbm.FETCH_EXPCRYSTAL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_nego_start_date,v_maturity_date,v_current_status,v_branch_code,v_exp_bill_type,v_nature_of_bill,v_premium_upto_date,v_rate,v_fb_charges_amt);
ELSE
Dbms_Output.put_line('SBI');
--mercury_exim_fetch_EXPCRYSTAL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_nego_start_date,v_maturity_date,v_current_status,v_branch_code,v_exp_bill_type,v_nature_of_bill,v_premium_upto_date,v_rate,v_fb_charges_amt);
END IF;
Dbms_Output.put_line('end 3');
--  Dbms_Output.Put_Line(v_trans_ref_no||':'||v_cust_id||':'||v_trans_curr||':'||v_trans_amt||':'||v_nego_start_date||':'||v_maturity_date||':'||v_current_status||':'||v_branch_code||':'||v_exp_bill_type||':'||v_nature_of_bill||':'||v_premium_upto_date||':'||v_rate||':'||v_fb_charges_amt);

--poc
add_bcr_dataforpoc(v_trans_ref_no);


  --Jitesh : 19.03.2012 : Log to maintain data received from Trade Finance.
--  insert into mfx_tf_raw_data(trans_ref_no,trans_type_code,fetch_time,cust_id,trans_curr,trans_amt,nego_start_date,maturity_date,current_status,branch_code,exp_bill_type,nature_of_bill,premium_upto_date,rate,FB_CHARGES_AMT)
--  values (v_trans_ref_no,trans_type,sysdate,v_cust_id,v_trans_curr,v_trans_amt,v_nego_start_date,v_maturity_date,
--  v_current_status,v_branch_code,v_exp_bill_type,v_nature_of_bill,v_premium_upto_date,v_rate,v_fb_charges_amt);


SELECT
    trans_ref_no,cust_id,trans_curr,trans_amt,nego_start_date,maturity_date,current_status,branch_code,exp_bill_type,nature_of_bill,premium_upto_date,rate,FB_CHARGES_AMT
  INTO
    v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_nego_start_date,v_maturity_date,v_current_status,v_branch_code,v_exp_bill_type,v_nature_of_bill,v_premium_upto_date,v_rate,v_fb_charges_amt
FROM  MFX_TF_RAW_DATA
WHERE TRANS_REF_NO=v_trans_ref_no AND trans_type_code='BCR';


  v_cust_cif_no:=v_cust_id;

  mfx_tf_if_fetch_validation(v_trans_ref_no,trans_type,v_trans_nostroid,v_trans_curr,v_oth_nostroid,v_oth_curr,v_start_date,v_value_date ,v_maturity_date,v_cust_id,
  v_current_status , v_excess_short ,v_nego_disc ,v_mode_disbusal ,v_record_type ,v_contract_type ,v_trans_amt ,
  v_ready_amt ,v_eefc_trans_curr_amt ,v_eefc_conv_amt ,v_pcfc_trans_curr_amt ,v_pcfc_conv_amt ,v_bal_amt,v_bal_amt,v_branch_code ,
  a_branch_code ,v_base_rate,v_spread,v_gross_rate,a_user_id  ,v_cust_charges_acc_no ,v_exp_bill_type ,v_nature_of_bill  ,
  v_premium_upto_date,v_rate ,v_conv_curr ,v_conv_corr ,v_interest_fcy,v_amt_realised,v_outstanding_nego_amt,tmp_err_code,tmp_err_msg);
IF(tmp_err_code='00') THEN
  Dbms_Output.Put_Line('v_trans_nostroid Before: '||v_trans_nostroid);
  mfx_tf_conv_curr_corr(trans_type,v_trans_curr,v_oth_curr,v_trans_nostroid,v_oth_nostroid,v_conv_curr,v_conv_corr);
  Dbms_Output.Put_Line('v_trans_nostroid After: '||v_trans_nostroid);
 /* Changes for ver1.7 */
 insert into mfx_tf_data (TF_ID,trans_ref_no,trans_type_code,fetch_time,cust_id,trans_curr,trans_amt,ready_amt,nego_start_date,maturity_date,current_status,branch_code,buy_sell,trans_nostroid,oth_nostroid,
  INR_nostroid,branch_user_id,conv_curr,conv_corr,value_date,exp_bill_type,nature_of_bill,start_date,premium_upto_date,rate,FB_CHARGES_AMT)
  values ( V_ID,v_trans_ref_no,trans_type,sysdate,v_cust_id,v_trans_curr,v_trans_amt,v_trans_amt,v_nego_start_date,v_maturity_date,
  v_current_status,v_branch_code,v_buy_sell,v_trans_nostroid,v_oth_nostroid,'OVRAC',a_user_id,v_conv_curr,v_conv_corr,v_value_date,
  v_exp_bill_type,v_nature_of_bill,v_start_date,v_premium_upto_date,v_rate,v_fb_charges_amt);
 /*Changes for ver1.7 */
END IF;

WHEN trans_type='BP' Then  Dbms_Output.put_line('Called  Export Bill Payment after Crystallization');
Dbms_Output.put_line('start 4');
IF  v_mig_bank='SBH' THEN
Dbms_Output.put_line('SBH');
--mercury_exim_sbh.FETCH_EXPAFTRCRYSTAL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,v_ready_amt,
--v_nego_start_date,v_maturity_date,v_current_status,v_trans_nostroid,v_oth_nostroid,v_branch_code,v_exp_bill_type,v_nature_of_bill);
ELSIF v_mig_bank='SBBJ' THEN
Dbms_Output.put_line('SBBJ');                                         
--mercury_exim_sbbj.FETCH_EXPAFTRCRYSTAL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,v_ready_amt,
--v_nego_start_date,v_maturity_date,v_current_status,v_trans_nostroid,v_oth_nostroid,v_branch_code,v_exp_bill_type,v_nature_of_bill);
ELSIF v_mig_bank='SBT' THEN
Dbms_Output.put_line('SBT');
--mercury_exim_sbt.FETCH_EXPAFTRCRYSTAL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,v_ready_amt,
--v_nego_start_date,v_maturity_date,v_current_status,v_trans_nostroid,v_oth_nostroid,v_branch_code,v_exp_bill_type,v_nature_of_bill);
ELSIF v_mig_bank='SBP' THEN
Dbms_Output.put_line('SBP');
--mercury_exim_sbp.FETCH_EXPAFTRCRYSTAL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,v_ready_amt,
--v_nego_start_date,v_maturity_date,v_current_status,v_trans_nostroid,v_oth_nostroid,v_branch_code,v_exp_bill_type,v_nature_of_bill);
ELSIF v_mig_bank='SBM' THEN
Dbms_Output.put_line('SBM');
--mercury_exim_sbm.FETCH_EXPAFTRCRYSTAL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,v_ready_amt,
--v_nego_start_date,v_maturity_date,v_current_status,v_trans_nostroid,v_oth_nostroid,v_branch_code,v_exp_bill_type,v_nature_of_bill);
ELSE
Dbms_Output.put_line('SBI');
mer_exim_fetch_EXPAFTRCRYSTAL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,v_ready_amt,
v_nego_start_date,v_maturity_date,v_current_status,v_trans_nostroid,v_oth_nostroid,v_branch_code,v_exp_bill_type,v_nature_of_bill);
END IF;
Dbms_Output.put_line('end  4');

v_cust_cif_no:=v_cust_id;
   mfx_tf_if_fetch_validation(v_trans_ref_no,trans_type,v_trans_nostroid,v_trans_curr,v_oth_nostroid,v_oth_curr,v_start_date,v_value_date,
   v_maturity_date,v_cust_id,v_current_status , v_excess_short ,v_nego_disc ,v_mode_disbusal ,v_record_type ,v_contract_type ,v_trans_amt ,
   v_ready_amt ,v_eefc_trans_curr_amt ,v_eefc_conv_amt ,v_pcfc_trans_curr_amt ,v_pcfc_conv_amt ,v_bal_amt,v_bal_amt,v_branch_code ,
   a_branch_code ,v_base_rate,v_spread,v_gross_rate,a_user_id  ,v_cust_charges_acc_no ,v_exp_bill_type ,v_nature_of_bill  ,
    v_premium_upto_date,v_rate ,v_conv_curr ,v_conv_corr ,v_interest_fcy,v_amt_realised,v_outstanding_nego_amt,tmp_err_code,tmp_err_msg);
IF(tmp_err_code='00') THEN
mfx_tf_conv_curr_corr(trans_type,v_trans_curr,v_oth_curr,v_trans_nostroid,v_oth_nostroid,v_conv_curr,v_conv_corr);
  INSERT INTO mfx_tf_data(TF_ID,trans_ref_no,trans_type_code,fetch_time,cust_id,trans_curr,trans_amt,eefc_trans_curr_amt,eefc_conv_amt,oth_curr,ready_amt,nego_start_date,maturity_date,nego_disc,trans_nostroid,oth_nostroid,branch_code,buy_sell,INR_nostroid,branch_user_id,conv_curr,conv_corr,value_date,exp_bill_type,nature_of_bill)
  values(V_ID,v_trans_ref_no,trans_type,sysdate,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,v_ready_amt,v_nego_start_date,v_maturity_date,v_nego_disc,v_trans_nostroid,v_oth_nostroid,v_branch_code,v_buy_sell,'OVRAC',a_user_id,v_conv_curr,v_conv_corr,v_value_date,v_exp_bill_type,v_nature_of_bill);
END IF;


WHEN trans_type='EPC' Then  Dbms_Output.put_line('Called  EBR Bill Payment after Crystallization');
Dbms_Output.put_line('start 5');
IF v_mig_bank='SBH' THEN
Dbms_Output.put_line('SBH');
--mercury_exim_sbh.fetch_EBRAFTRCRYSTAL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,v_ready_amt,
--v_value_date,v_current_status,v_trans_nostroid,v_oth_nostroid,v_nostro_real_date,v_branch_code,v_exp_bill_type,v_nature_of_bill);
ELSIF v_mig_bank='SBBJ' THEN
Dbms_Output.put_line('SBBJ');
--mercury_exim_sbbj.fetch_EBRAFTRCRYSTAL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,v_ready_amt,
--v_value_date,v_current_status,v_trans_nostroid,v_oth_nostroid,v_nostro_real_date,v_branch_code,v_exp_bill_type,v_nature_of_bill);
ELSIF v_mig_bank='SBT' THEN
Dbms_Output.put_line('SBT');
--mercury_exim_sbt.fetch_EBRAFTRCRYSTAL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,v_ready_amt,
--v_value_date,v_current_status,v_trans_nostroid,v_oth_nostroid,v_nostro_real_date,v_branch_code,v_exp_bill_type,v_nature_of_bill);
ELSIF v_mig_bank='SBP' THEN
Dbms_Output.put_line('SBP');
--mercury_exim_sbp.fetch_EBRAFTRCRYSTAL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,v_ready_amt,
--v_value_date,v_current_status,v_trans_nostroid,v_oth_nostroid,v_nostro_real_date,v_branch_code,v_exp_bill_type,v_nature_of_bill);
ELSIF v_mig_bank='SBM' THEN
Dbms_Output.put_line('SBM');
--mercury_exim_sbm.fetch_EBRAFTRCRYSTAL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,v_ready_amt,
--v_value_date,v_current_status,v_trans_nostroid,v_oth_nostroid,v_nostro_real_date,v_branch_code,v_exp_bill_type,v_nature_of_bill);
ELSE
Dbms_Output.put_line('SBI');
mer_exim_fetch_EBRAFTRCRYSTAL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,v_ready_amt,
v_value_date,v_current_status,v_trans_nostroid,v_oth_nostroid,v_nostro_real_date,v_branch_code,v_exp_bill_type,v_nature_of_bill);
END IF;

Dbms_Output.put_line('end  5');

  --Jitesh : 13.04.2012 : Log to maintain data received from Trade Finance.
  INSERT INTO MFX_TF_RAW_DATA(trans_ref_no,trans_type_code,fetch_time,cust_id,trans_curr,trans_amt,eefc_trans_curr_amt,eefc_conv_amt,
  oth_curr,ready_amt,value_date,current_status,trans_nostroid,oth_nostroid,nostro_real_date,branch_code,exp_bill_type,nature_of_bill)
  VALUES(v_trans_ref_no,trans_type,sysdate,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,
  v_ready_amt,v_value_date,v_current_status,v_trans_nostroid,v_oth_nostroid,v_nostro_real_date,v_branch_code,v_exp_bill_type,v_nature_of_bill);

v_cust_cif_no:=v_cust_id;
  mfx_tf_if_fetch_validation(v_trans_ref_no,trans_type,v_trans_nostroid,v_trans_curr,v_oth_nostroid,v_oth_curr,v_start_date,v_value_date,
  v_maturity_date,v_cust_id,v_current_status , v_excess_short ,v_nego_disc ,v_mode_disbusal ,v_record_type ,v_contract_type ,v_trans_amt ,
  v_ready_amt ,v_eefc_trans_curr_amt ,v_eefc_conv_amt ,v_pcfc_trans_curr_amt ,v_pcfc_conv_amt ,v_bal_amt,v_bal_amt,v_branch_code ,
  a_branch_code ,v_base_rate,v_spread,v_gross_rate,a_user_id  ,v_cust_charges_acc_no ,v_exp_bill_type ,v_nature_of_bill  ,
  v_premium_upto_date,v_rate ,v_conv_curr ,v_conv_corr ,v_interest_fcy,v_amt_realised,v_outstanding_nego_amt,tmp_err_code,tmp_err_msg);
IF(tmp_err_code='00') THEN
mfx_tf_conv_curr_corr(trans_type,v_trans_curr,v_oth_curr,v_trans_nostroid,v_oth_nostroid,v_conv_curr,v_conv_corr);
  INSERT INTO mfx_tf_data(TF_ID,trans_ref_no,trans_type_code,fetch_time,cust_id,trans_curr,trans_amt,eefc_trans_curr_amt,eefc_conv_amt,
  oth_curr,ready_amt,value_date,current_status,trans_nostroid,oth_nostroid,nostro_real_date,branch_code,buy_sell,INR_nostroid,branch_user_id,
  conv_curr,conv_corr,exp_bill_type,nature_of_bill)
  VALUES(V_ID,v_trans_ref_no,trans_type,sysdate,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,
  v_ready_amt,v_value_date,v_current_status,v_trans_nostroid,v_oth_nostroid,v_nostro_real_date,v_branch_code,v_buy_sell,'OVRAC',a_user_id,
  v_conv_curr,v_conv_corr,v_exp_bill_type,v_nature_of_bill);
END IF;

WHEN trans_type='CC' Then  Dbms_Output.put_line('Called  Export Bill Collection Payment');



Dbms_Output.put_line('start 6');
IF v_mig_bank='SBH' THEN
Dbms_Output.put_line('SBH');
--mercury_exim_sbh.FETCH_EXPCOLLPYMT(v_trans_ref_no,v_bill_refno,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,
--v_pcfc_trans_curr_amt, v_pcfc_conv_amt,v_oth_curr,v_ready_amt,v_maturity_date,v_nostro_real_date,v_trans_nostroid,v_oth_nostroid,v_branch_code);
ELSIF v_mig_bank='SBBJ' THEN
Dbms_Output.put_line('SBBJ');
--mercury_exim_sbbj.FETCH_EXPCOLLPYMT(v_trans_ref_no,v_bill_refno,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,
--v_pcfc_trans_curr_amt, v_pcfc_conv_amt,v_oth_curr,v_ready_amt,v_maturity_date,v_nostro_real_date,v_trans_nostroid,v_oth_nostroid,v_branch_code);
ELSIF v_mig_bank='SBT' THEN
Dbms_Output.put_line('SBT');
--mercury_exim_sbt.FETCH_EXPCOLLPYMT(v_trans_ref_no,v_bill_refno,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,
--v_pcfc_trans_curr_amt, v_pcfc_conv_amt,v_oth_curr,v_ready_amt,v_maturity_date,v_nostro_real_date,v_trans_nostroid,v_oth_nostroid,v_branch_code);
ELSIF v_mig_bank='SBP' THEN
Dbms_Output.put_line('SBP');
--mercury_exim_sbp.FETCH_EXPCOLLPYMT(v_trans_ref_no,v_bill_refno,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,
--v_pcfc_trans_curr_amt, v_pcfc_conv_amt,v_oth_curr,v_ready_amt,v_maturity_date,v_nostro_real_date,v_trans_nostroid,v_oth_nostroid,v_branch_code);
ELSIF v_mig_bank='SBM' THEN
Dbms_Output.put_line('SBM');
--mercury_exim_sbm.FETCH_EXPCOLLPYMT(v_trans_ref_no,v_bill_refno,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,
--v_pcfc_trans_curr_amt, v_pcfc_conv_amt,v_oth_curr,v_ready_amt,v_maturity_date,v_nostro_real_date,v_trans_nostroid,v_oth_nostroid,v_branch_code);
ELSE
Dbms_Output.put_line('SBI');
mercury_exim_fetch_EXPCOLLPYMT(v_trans_ref_no,v_bill_refno,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,
v_pcfc_trans_curr_amt, v_pcfc_conv_amt,v_oth_curr,v_ready_amt,v_maturity_date,v_nostro_real_date,v_trans_nostroid,v_oth_nostroid,v_branch_code);
END IF ;
Dbms_Output.put_line('end  6');


v_cust_cif_no:=v_cust_id;
  mfx_tf_if_fetch_validation(v_trans_ref_no,trans_type,v_trans_nostroid,v_trans_curr,v_oth_nostroid,v_oth_curr,v_start_date,v_value_date ,v_maturity_date,v_cust_id,
  v_current_status , v_excess_short ,v_nego_disc ,v_mode_disbusal ,v_record_type ,v_contract_type ,v_trans_amt ,
  v_ready_amt ,v_eefc_trans_curr_amt ,v_eefc_conv_amt ,v_pcfc_trans_curr_amt ,v_pcfc_conv_amt ,v_bal_amt,v_bal_amt,v_branch_code ,
  a_branch_code ,v_base_rate,v_spread,v_gross_rate,a_user_id  ,v_cust_charges_acc_no ,v_exp_bill_type ,v_nature_of_bill  , v_premium_upto_date,v_rate ,v_conv_curr ,
  v_conv_corr ,v_interest_fcy,v_amt_realised,v_outstanding_nego_amt,tmp_err_code,tmp_err_msg);
IF(tmp_err_code='00') THEN
mfx_tf_conv_curr_corr(trans_type,v_trans_curr,v_oth_curr,v_trans_nostroid,v_oth_nostroid,v_conv_curr,v_conv_corr);
  insert into mfx_tf_data (TF_ID,trans_ref_no,trans_type_code,fetch_time,cust_id,trans_curr,trans_amt,eefc_trans_curr_amt,eefc_conv_amt,
  pcfc_trans_curr_amt, pcfc_conv_amt,oth_curr,ready_amt,maturity_date,nostro_real_date,trans_nostroid,oth_nostroid,branch_code,INR_nostroid,buy_sell,branch_user_id,conv_curr,conv_corr,value_date)
   values ( V_ID,v_trans_ref_no,trans_type,sysdate,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,
  v_eefc_conv_amt,v_pcfc_trans_curr_amt, v_pcfc_conv_amt,v_oth_curr,v_ready_amt,v_maturity_date,v_nostro_real_date,v_trans_nostroid,
  v_oth_nostroid,v_branch_code,'OVRAC',v_buy_sell,a_user_id,v_conv_curr,v_conv_corr,v_value_date);
END IF;

WHEN trans_type='IL' Then  Dbms_Output.put_line('Called Import LC Bill Payment ');
Dbms_Output.put_line('start 7');
IF v_mig_bank='SBH' THEN
Dbms_Output.put_line('SBH');
--mercury_exim_sbh.FETCH_ILCBILLPYMT(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,
--v_pcfc_trans_curr_amt, v_pcfc_conv_amt,v_oth_curr,v_ready_amt,v_value_date,v_trans_nostroid,v_oth_nostroid,v_nostro_date,v_branch_code);
ELSIF v_mig_bank='SBBJ' THEN
Dbms_Output.put_line('SBBJ');
--mercury_exim_sbbj.FETCH_ILCBILLPYMT(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,
--v_pcfc_trans_curr_amt, v_pcfc_conv_amt,v_oth_curr,v_ready_amt,v_value_date,v_trans_nostroid,v_oth_nostroid,v_nostro_date,v_branch_code);
ELSIF v_mig_bank='SBT' THEN
Dbms_Output.put_line('SBT');
--mercury_exim_sbt.FETCH_ILCBILLPYMT(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,
--v_pcfc_trans_curr_amt, v_pcfc_conv_amt,v_oth_curr,v_ready_amt,v_value_date,v_trans_nostroid,v_oth_nostroid,v_nostro_date,v_branch_code);
ELSIF v_mig_bank='SBP' THEN
Dbms_Output.put_line('SBP');
--mercury_exim_sbp.FETCH_ILCBILLPYMT(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,
--v_pcfc_trans_curr_amt, v_pcfc_conv_amt,v_oth_curr,v_ready_amt,v_value_date,v_trans_nostroid,v_oth_nostroid,v_nostro_date,v_branch_code);
ELSIF v_mig_bank='SBM' THEN
Dbms_Output.put_line('SBM');
--mercury_exim_sbm.FETCH_ILCBILLPYMT(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,
--v_pcfc_trans_curr_amt, v_pcfc_conv_amt,v_oth_curr,v_ready_amt,v_value_date,v_trans_nostroid,v_oth_nostroid,v_nostro_date,v_branch_code);
ELSE
Dbms_Output.put_line('SBI');
mercury_exim_fetch_ILCBILLPYMT(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,
v_pcfc_trans_curr_amt, v_pcfc_conv_amt,v_oth_curr,v_ready_amt,v_value_date,v_trans_nostroid,v_oth_nostroid,v_nostro_date,v_branch_code,v_conversion_flag,v_other_ccy_credit);
END IF;

Dbms_Output.put_line('END  7');
v_cust_cif_no:=v_cust_id;
  Dbms_Output.Put_Line(v_branch_code || '-----------------------' || a_branch_code);
  mfx_tf_if_fetch_validation(v_trans_ref_no,trans_type,v_trans_nostroid,v_trans_curr,v_oth_nostroid,v_oth_curr,v_start_date,v_value_date ,v_maturity_date,v_cust_id,
  v_current_status , v_excess_short ,v_nego_disc ,v_mode_disbusal ,v_record_type ,v_contract_type ,v_trans_amt ,v_ready_amt ,
  v_eefc_trans_curr_amt ,v_eefc_conv_amt ,v_pcfc_trans_curr_amt ,v_pcfc_conv_amt ,v_bal_amt,v_bal_amt,v_branch_code ,a_branch_code ,v_base_rate,v_spread,v_gross_rate,
  a_user_id  ,v_cust_charges_acc_no ,v_exp_bill_type ,v_nature_of_bill  , v_premium_upto_date,v_rate ,v_conv_curr ,v_conv_corr ,v_interest_fcy,v_amt_realised,
  v_outstanding_nego_amt,tmp_err_code,tmp_err_msg);
IF(tmp_err_code='00') THEN
mfx_tf_conv_curr_corr(trans_type,v_trans_curr,v_oth_curr,v_trans_nostroid,v_oth_nostroid,v_conv_curr,v_conv_corr);
  insert into mfx_tf_data(TF_ID,trans_ref_no,trans_type_code,fetch_time,cust_id,trans_curr,trans_amt,eefc_trans_curr_amt,eefc_conv_amt,
  pcfc_trans_curr_amt, pcfc_conv_amt,oth_curr,ready_amt,value_date,maturity_date,
  trans_nostroid,oth_nostroid,nostro_date,branch_code,buy_sell,INR_nostroid,branch_user_id,conv_curr,conv_corr)
  VALUES(V_ID,v_trans_ref_no,trans_type,sysdate,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,
  v_pcfc_trans_curr_amt, v_pcfc_conv_amt,v_oth_curr,v_ready_amt,v_value_date,v_value_date,
  v_trans_nostroid,v_oth_nostroid,v_nostro_date,v_branch_code,v_buy_sell,'OVRAC',a_user_id,v_conv_curr,v_conv_corr);
  --FLC Data
  INSERT INTO mfx_tf_flc_data (if_id, trans_ref_no, conversion_flag, other_ccy_credit)
  VALUES (V_ID, v_trans_ref_no, v_conversion_flag , v_other_ccy_credit);
END IF;
---added by vasudeo Buyers credit trans type start
WHEN trans_type='BCP' Then  Dbms_Output.put_line('Called Buyers Credit Principal Payment ');

Dbms_Output.put_line('START 8 ');
IF v_mig_bank='SBH' THEN
Dbms_Output.put_line('SBH');
--mercury_exim_sbh.FETCH_BCPrincipal(v_trans_ref_no,v_cust_id,v_trans_curr,v_paymt_flag,v_eefc_trans_curr_amt,v_eefc_conv_amt,
--v_oth_curr,v_Paymt_Amt_FCY,v_othr_charges,v_trans_amt, v_ready_amt,v_value_date,v_Maturity_date,v_trans_nostroid,v_oth_nostroid,v_nostro_date,v_branch_code);
ELSIF v_mig_bank='SBBJ' THEN
Dbms_Output.put_line('SBBJ');
--mercury_exim_sbbj.FETCH_BCPrincipal(v_trans_ref_no,v_cust_id,v_trans_curr,v_paymt_flag,v_eefc_trans_curr_amt,v_eefc_conv_amt,
--v_oth_curr,v_Paymt_Amt_FCY,v_othr_charges,v_trans_amt, v_ready_amt,v_value_date,v_Maturity_date,v_trans_nostroid,v_oth_nostroid,v_nostro_date,v_branch_code);
ELSIF v_mig_bank='SBT' THEN
Dbms_Output.put_line('SBT');
--mercury_exim_sbt.FETCH_BCPrincipal(v_trans_ref_no,v_cust_id,v_trans_curr,v_paymt_flag,v_eefc_trans_curr_amt,v_eefc_conv_amt,
--v_oth_curr,v_Paymt_Amt_FCY,v_othr_charges,v_trans_amt, v_ready_amt,v_value_date,v_Maturity_date,v_trans_nostroid,v_oth_nostroid,v_nostro_date,v_branch_code);
ELSIF v_mig_bank='SBP' THEN
Dbms_Output.put_line('SBP');
--mercury_exim_sbp.FETCH_BCPrincipal(v_trans_ref_no,v_cust_id,v_trans_curr,v_paymt_flag,v_eefc_trans_curr_amt,v_eefc_conv_amt,
--v_oth_curr,v_Paymt_Amt_FCY,v_othr_charges,v_trans_amt, v_ready_amt,v_value_date,v_Maturity_date,v_trans_nostroid,v_oth_nostroid,v_nostro_date,v_branch_code);
ELSIF v_mig_bank='SBM' THEN
Dbms_Output.put_line('SBM');
--mercury_exim_sbm.FETCH_BCPrincipal(v_trans_ref_no,v_cust_id,v_trans_curr,v_paymt_flag,v_eefc_trans_curr_amt,v_eefc_conv_amt,
--v_oth_curr,v_Paymt_Amt_FCY,v_othr_charges,v_trans_amt, v_ready_amt,v_value_date,v_Maturity_date,v_trans_nostroid,v_oth_nostroid,v_nostro_date,v_branch_code);
ELSE
Dbms_Output.put_line('SBI');
mercury_exim_fetch_BCPrincipal(v_trans_ref_no,v_cust_id,v_trans_curr,v_paymt_flag,v_eefc_trans_curr_amt,v_eefc_conv_amt,
v_oth_curr,v_Paymt_Amt_FCY,v_othr_charges,v_trans_amt, v_ready_amt,v_value_date,v_Maturity_date,v_trans_nostroid,v_oth_nostroid,v_nostro_date,v_branch_code);
END IF;

Dbms_Output.put_line('END  8 ');



insert into mfx_tf_raw_data(trans_ref_no,trans_type_code,fetch_time,cust_id,trans_curr,paymt_flag,eefc_trans_curr_amt,eefc_conv_amt,
oth_curr,Paymt_Amt_FCY,othr_charges,trans_amt,ready_amt,value_date,Maturity_date,trans_nostroid,oth_nostroid,nostro_date,branch_code)
  values (v_trans_ref_no,trans_type,sysdate,v_cust_id,v_trans_curr,v_paymt_flag,v_eefc_trans_curr_amt,v_eefc_conv_amt,
v_oth_curr,v_Paymt_Amt_FCY,v_othr_charges,v_trans_amt, v_ready_amt,v_value_date,v_Maturity_date,v_trans_nostroid,v_oth_nostroid,v_nostro_date,v_branch_code);

v_cust_cif_no:=v_cust_id;
  Dbms_Output.Put_Line(v_branch_code || '-----------------------' || a_branch_code);
  mfx_tf_if_fetch_validation(v_trans_ref_no,trans_type,v_trans_nostroid,v_trans_curr,v_oth_nostroid,v_oth_curr,v_start_date,v_value_date ,v_maturity_date,v_cust_id,
  v_current_status , v_excess_short ,v_nego_disc ,v_mode_disbusal ,v_record_type ,v_contract_type ,v_trans_amt ,v_ready_amt ,
  v_eefc_trans_curr_amt ,v_eefc_conv_amt ,v_pcfc_trans_curr_amt ,v_pcfc_conv_amt ,v_bal_amt,v_bal_amt,v_branch_code ,a_branch_code ,v_base_rate,v_spread,v_gross_rate,
  a_user_id  ,v_cust_charges_acc_no ,v_exp_bill_type ,v_nature_of_bill  , v_premium_upto_date,v_rate ,v_conv_curr ,v_conv_corr ,v_interest_fcy,v_amt_realised,
  v_outstanding_nego_amt,tmp_err_code,tmp_err_msg);
IF(tmp_err_code='00') THEN
mfx_tf_conv_curr_corr(trans_type,v_trans_curr,v_oth_curr,v_trans_nostroid,v_oth_nostroid,v_conv_curr,v_conv_corr);
  insert into mfx_tf_data(TF_ID,trans_ref_no,trans_type_code,fetch_time,cust_id,trans_curr,trans_amt,eefc_trans_curr_amt,eefc_conv_amt,
  pcfc_trans_curr_amt, pcfc_conv_amt,oth_curr,ready_amt,value_date,maturity_date,
  trans_nostroid,oth_nostroid,nostro_date,branch_code,buy_sell,INR_nostroid,branch_user_id,conv_curr,conv_corr,Paymt_Amt_FCY,othr_charges,paymt_flag)
  VALUES(V_ID,v_trans_ref_no,trans_type,sysdate,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,
  v_pcfc_trans_curr_amt, v_pcfc_conv_amt,v_oth_curr,v_ready_amt,v_value_date,v_maturity_date,
  v_trans_nostroid,v_oth_nostroid,v_nostro_date,v_branch_code,v_buy_sell,'OVRAC',a_user_id,v_conv_curr,v_conv_corr,v_Paymt_Amt_FCY,v_othr_charges,v_paymt_flag);
END IF;
---Start NLRF Payment--------------
WHEN trans_type='NLRF' Then  Dbms_Output.put_line('Called Non-LC Reimbursement Finance Payment');

Dbms_Output.put_line('START 8 ');
IF v_mig_bank='SBH' THEN
Dbms_Output.put_line('SBH');
--mercury_exim_sbh.FETCH_BCPrincipal(v_trans_ref_no,v_cust_id,v_trans_curr,v_paymt_flag,v_eefc_trans_curr_amt,v_eefc_conv_amt,
--v_oth_curr,v_Paymt_Amt_FCY,v_othr_charges,v_trans_amt, v_ready_amt,v_value_date,v_Maturity_date,v_trans_nostroid,v_oth_nostroid,v_nostro_date,v_branch_code);
ELSIF v_mig_bank='SBBJ' THEN
Dbms_Output.put_line('SBBJ');
--mercury_exim_sbbj.FETCH_BCPrincipal(v_trans_ref_no,v_cust_id,v_trans_curr,v_paymt_flag,v_eefc_trans_curr_amt,v_eefc_conv_amt,
--v_oth_curr,v_Paymt_Amt_FCY,v_othr_charges,v_trans_amt, v_ready_amt,v_value_date,v_Maturity_date,v_trans_nostroid,v_oth_nostroid,v_nostro_date,v_branch_code);
ELSIF v_mig_bank='SBT' THEN
Dbms_Output.put_line('SBT');
--mercury_exim_sbt.FETCH_BCPrincipal(v_trans_ref_no,v_cust_id,v_trans_curr,v_paymt_flag,v_eefc_trans_curr_amt,v_eefc_conv_amt,
--v_oth_curr,v_Paymt_Amt_FCY,v_othr_charges,v_trans_amt, v_ready_amt,v_value_date,v_Maturity_date,v_trans_nostroid,v_oth_nostroid,v_nostro_date,v_branch_code);
ELSIF v_mig_bank='SBP' THEN
Dbms_Output.put_line('SBP');
--mercury_exim_sbp.FETCH_BCPrincipal(v_trans_ref_no,v_cust_id,v_trans_curr,v_paymt_flag,v_eefc_trans_curr_amt,v_eefc_conv_amt,
--v_oth_curr,v_Paymt_Amt_FCY,v_othr_charges,v_trans_amt, v_ready_amt,v_value_date,v_Maturity_date,v_trans_nostroid,v_oth_nostroid,v_nostro_date,v_branch_code);
ELSIF v_mig_bank='SBM' THEN
Dbms_Output.put_line('SBM');
--mercury_exim_sbm.FETCH_BCPrincipal(v_trans_ref_no,v_cust_id,v_trans_curr,v_paymt_flag,v_eefc_trans_curr_amt,v_eefc_conv_amt,
--v_oth_curr,v_Paymt_Amt_FCY,v_othr_charges,v_trans_amt, v_ready_amt,v_value_date,v_Maturity_date,v_trans_nostroid,v_oth_nostroid,v_nostro_date,v_branch_code);
ELSE
Dbms_Output.put_line('SBI');
mercury_exim_fetch_nlrf_paymt(v_trans_ref_no,v_cust_id,v_trans_curr,v_paymt_flag,v_eefc_trans_curr_amt,v_eefc_conv_amt,
v_oth_curr,v_Paymt_Amt_FCY,v_othr_charges,v_trans_amt, v_ready_amt,v_value_date,v_Maturity_date,v_trans_nostroid,v_oth_nostroid,v_nostro_date,v_branch_code);
END IF;

Dbms_Output.put_line('END  8 ');



insert into mfx_tf_raw_data(trans_ref_no,trans_type_code,fetch_time,cust_id,trans_curr,paymt_flag,eefc_trans_curr_amt,eefc_conv_amt,
oth_curr,Paymt_Amt_FCY,othr_charges,trans_amt,ready_amt,value_date,Maturity_date,trans_nostroid,oth_nostroid,nostro_date,branch_code)
  values (v_trans_ref_no,trans_type,sysdate,v_cust_id,v_trans_curr,v_paymt_flag,v_eefc_trans_curr_amt,v_eefc_conv_amt,
v_oth_curr,v_Paymt_Amt_FCY,v_othr_charges,v_trans_amt, v_ready_amt,v_value_date,v_Maturity_date,v_trans_nostroid,v_oth_nostroid,v_nostro_date,v_branch_code);

v_cust_cif_no:=v_cust_id;
  Dbms_Output.Put_Line(v_branch_code || '-----------------------' || a_branch_code);
  mfx_tf_if_fetch_validation(v_trans_ref_no,trans_type,v_trans_nostroid,v_trans_curr,v_oth_nostroid,v_oth_curr,v_start_date,v_value_date ,v_maturity_date,v_cust_id,
  v_current_status , v_excess_short ,v_nego_disc ,v_mode_disbusal ,v_record_type ,v_contract_type ,v_trans_amt ,v_ready_amt ,
  v_eefc_trans_curr_amt ,v_eefc_conv_amt ,v_pcfc_trans_curr_amt ,v_pcfc_conv_amt ,v_bal_amt,v_bal_amt,v_branch_code ,a_branch_code ,v_base_rate,v_spread,v_gross_rate,
  a_user_id  ,v_cust_charges_acc_no ,v_exp_bill_type ,v_nature_of_bill  , v_premium_upto_date,v_rate ,v_conv_curr ,v_conv_corr ,v_interest_fcy,v_amt_realised,
  v_outstanding_nego_amt,tmp_err_code,tmp_err_msg);
IF(tmp_err_code='00') THEN
mfx_tf_conv_curr_corr(trans_type,v_trans_curr,v_oth_curr,v_trans_nostroid,v_oth_nostroid,v_conv_curr,v_conv_corr);
  insert into mfx_tf_data(TF_ID,trans_ref_no,trans_type_code,fetch_time,cust_id,trans_curr,trans_amt,eefc_trans_curr_amt,eefc_conv_amt,
  pcfc_trans_curr_amt, pcfc_conv_amt,oth_curr,ready_amt,value_date,maturity_date,
  trans_nostroid,oth_nostroid,nostro_date,branch_code,buy_sell,INR_nostroid,branch_user_id,conv_curr,conv_corr,Paymt_Amt_FCY,othr_charges,paymt_flag)
  VALUES(V_ID,v_trans_ref_no,trans_type,sysdate,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,
  v_pcfc_trans_curr_amt, v_pcfc_conv_amt,v_oth_curr,v_ready_amt,v_value_date,v_maturity_date,
  v_trans_nostroid,v_oth_nostroid,v_nostro_date,v_branch_code,v_buy_sell,'OVRAC',a_user_id,v_conv_curr,v_conv_corr,v_Paymt_Amt_FCY,v_othr_charges,v_paymt_flag);
END IF;
----END NLRF Payment
WHEN trans_type='BCI' Then  Dbms_Output.put_line('Called Buyers Credit Interest Payment ');
Dbms_Output.put_line('start 10 ');
IF v_mig_bank='SBH' THEN
Dbms_Output.put_line('SBH');
--mercury_exim_sbh.fetch_BCInterest(v_trans_ref_no,v_cust_id,v_trans_curr,v_eefc_trans_curr_amt,v_eefc_conv_amt,
--v_oth_curr,v_Paymt_Amt_FCY,v_othr_charges,v_trans_amt, v_ready_amt,v_value_date,v_Maturity_date,v_trans_nostroid,v_oth_nostroid,v_nostro_date,v_branch_code);
ELSIF v_mig_bank='SBBJ' THEN
Dbms_Output.put_line('SBBJ');
--mercury_exim_sbbj.fetch_BCInterest(v_trans_ref_no,v_cust_id,v_trans_curr,v_eefc_trans_curr_amt,v_eefc_conv_amt,
--v_oth_curr,v_Paymt_Amt_FCY,v_othr_charges,v_trans_amt, v_ready_amt,v_value_date,v_Maturity_date,v_trans_nostroid,v_oth_nostroid,v_nostro_date,v_branch_code);
ELSIF v_mig_bank='SBT' THEN
Dbms_Output.put_line('SBT');
--mercury_exim_sbt.fetch_BCInterest(v_trans_ref_no,v_cust_id,v_trans_curr,v_eefc_trans_curr_amt,v_eefc_conv_amt,
--v_oth_curr,v_Paymt_Amt_FCY,v_othr_charges,v_trans_amt, v_ready_amt,v_value_date,v_Maturity_date,v_trans_nostroid,v_oth_nostroid,v_nostro_date,v_branch_code);
ELSIF v_mig_bank='SBP' THEN
Dbms_Output.put_line('SBP');
--mercury_exim_sbp.fetch_BCInterest(v_trans_ref_no,v_cust_id,v_trans_curr,v_eefc_trans_curr_amt,v_eefc_conv_amt,
--v_oth_curr,v_Paymt_Amt_FCY,v_othr_charges,v_trans_amt, v_ready_amt,v_value_date,v_Maturity_date,v_trans_nostroid,v_oth_nostroid,v_nostro_date,v_branch_code);
ELSIF v_mig_bank='SBM' THEN
Dbms_Output.put_line('SBM');
--mercury_exim_sbm.fetch_BCInterest(v_trans_ref_no,v_cust_id,v_trans_curr,v_eefc_trans_curr_amt,v_eefc_conv_amt,
--v_oth_curr,v_Paymt_Amt_FCY,v_othr_charges,v_trans_amt, v_ready_amt,v_value_date,v_Maturity_date,v_trans_nostroid,v_oth_nostroid,v_nostro_date,v_branch_code);
ELSE
Dbms_Output.put_line('SBI');
mercury_exim_fetch_BCInterest(v_trans_ref_no,v_cust_id,v_trans_curr,v_eefc_trans_curr_amt,v_eefc_conv_amt,
v_oth_curr,v_Paymt_Amt_FCY,v_othr_charges,v_trans_amt, v_ready_amt,v_value_date,v_Maturity_date,v_trans_nostroid,v_oth_nostroid,v_nostro_date,v_branch_code);
END IF;

Dbms_Output.put_line('end  10 ');
insert into mfx_tf_raw_data(trans_ref_no,trans_type_code,fetch_time,cust_id,trans_curr,eefc_trans_curr_amt,eefc_conv_amt,
oth_curr,Paymt_Amt_FCY,othr_charges,trans_amt, ready_amt,value_date,Maturity_date,trans_nostroid,oth_nostroid,nostro_date,branch_code)
  values (v_trans_ref_no,trans_type,sysdate,v_cust_id,v_trans_curr,v_eefc_trans_curr_amt,v_eefc_conv_amt,
v_oth_curr,v_Paymt_Amt_FCY,v_othr_charges,v_trans_amt, v_ready_amt,v_value_date,v_Maturity_date,v_trans_nostroid,v_oth_nostroid,v_nostro_date,v_branch_code);
v_cust_cif_no:=v_cust_id;
  Dbms_Output.Put_Line(v_branch_code || '-----------------------' || a_branch_code);
  mfx_tf_if_fetch_validation(v_trans_ref_no,trans_type,v_trans_nostroid,v_trans_curr,v_oth_nostroid,v_oth_curr,v_start_date,v_value_date ,v_maturity_date,v_cust_id,
  v_current_status , v_excess_short ,v_nego_disc ,v_mode_disbusal ,v_record_type ,v_contract_type ,v_trans_amt ,v_ready_amt ,
  v_eefc_trans_curr_amt ,v_eefc_conv_amt ,v_pcfc_trans_curr_amt ,v_pcfc_conv_amt ,v_bal_amt,v_bal_amt,v_branch_code ,a_branch_code ,v_base_rate,v_spread,v_gross_rate,
  a_user_id  ,v_cust_charges_acc_no ,v_exp_bill_type ,v_nature_of_bill  , v_premium_upto_date,v_rate ,v_conv_curr ,v_conv_corr ,v_interest_fcy,v_amt_realised,
  v_outstanding_nego_amt,tmp_err_code,tmp_err_msg);
IF(tmp_err_code='00') THEN
mfx_tf_conv_curr_corr(trans_type,v_trans_curr,v_oth_curr,v_trans_nostroid,v_oth_nostroid,v_conv_curr,v_conv_corr);
  insert into mfx_tf_data(TF_ID,trans_ref_no,trans_type_code,fetch_time,cust_id,trans_curr,trans_amt,eefc_trans_curr_amt,eefc_conv_amt,
  pcfc_trans_curr_amt, pcfc_conv_amt,oth_curr,ready_amt,value_date,maturity_date,
  trans_nostroid,oth_nostroid,nostro_date,branch_code,buy_sell,INR_nostroid,branch_user_id,conv_curr,conv_corr,Paymt_Amt_FCY,othr_charges)
  VALUES(V_ID,v_trans_ref_no,trans_type,sysdate,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,
  v_pcfc_trans_curr_amt, v_pcfc_conv_amt,v_oth_curr,v_ready_amt,v_value_date,v_maturity_date,
  v_trans_nostroid,v_oth_nostroid,v_nostro_date,v_branch_code,v_buy_sell,'OVRAC',a_user_id,v_conv_curr,v_conv_corr,v_Paymt_Amt_FCY,v_othr_charges);
END IF;

---added by vasudeo Buyers credit trans type END
WHEN trans_type='IC' THEN
Dbms_Output.Put_Line('satrt 1');
IF v_mig_bank='SBH' THEN
Dbms_Output.put_line('SBH');
--mercury_exim_sbh.FETCH_IMPCOLPYMT(v_trans_ref_no,v_bill_refno,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_pcfc_trans_curr_amt,
--v_pcfc_conv_amt,v_oth_curr,v_ready_amt,v_maturity_date,v_corr_ref,v_trans_nostroid,v_oth_nostroid,v_branch_code);
ELSIF v_mig_bank='SBBJ' THEN
Dbms_Output.put_line('SBBJ');
--mercury_exim_sbbj.FETCH_IMPCOLPYMT(v_trans_ref_no,v_bill_refno,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_pcfc_trans_curr_amt,
--v_pcfc_conv_amt,v_oth_curr,v_ready_amt,v_maturity_date,v_corr_ref,v_trans_nostroid,v_oth_nostroid,v_branch_code);
ELSIF v_mig_bank='SBT' THEN
Dbms_Output.put_line('SBT');
--mercury_exim_sbt.FETCH_IMPCOLPYMT(v_trans_ref_no,v_bill_refno,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_pcfc_trans_curr_amt,
--v_pcfc_conv_amt,v_oth_curr,v_ready_amt,v_maturity_date,v_corr_ref,v_trans_nostroid,v_oth_nostroid,v_branch_code);
ELSIF v_mig_bank='SBP' THEN
Dbms_Output.put_line('SBP');
--mercury_exim_sbp.FETCH_IMPCOLPYMT(v_trans_ref_no,v_bill_refno,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_pcfc_trans_curr_amt,
--v_pcfc_conv_amt,v_oth_curr,v_ready_amt,v_maturity_date,v_corr_ref,v_trans_nostroid,v_oth_nostroid,v_branch_code);
ELSIF v_mig_bank='SBM' THEN
Dbms_Output.put_line('SBM');
--mercury_exim_sbm.FETCH_IMPCOLPYMT(v_trans_ref_no,v_bill_refno,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_pcfc_trans_curr_amt,
--v_pcfc_conv_amt,v_oth_curr,v_ready_amt,v_maturity_date,v_corr_ref,v_trans_nostroid,v_oth_nostroid,v_branch_code);
ELSE
Dbms_Output.put_line('SBI');
mercury_exim_fetch_IMPCOLPYMT(v_trans_ref_no,v_bill_refno,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_pcfc_trans_curr_amt,
v_pcfc_conv_amt,v_oth_curr,v_ready_amt,v_maturity_date,v_corr_ref,v_trans_nostroid,v_oth_nostroid,v_branch_code);
END IF;
Dbms_Output.Put_Line('end 9 ');
--dbms_output.put_line('v_trans_ref_no=' || v_trans_ref_no|| ' * '  ||v_bill_refno|| ' * '  ||v_cust_id|| ' * '  ||v_trans_curr|| ' * '  ||v_trans_amt|| ' * '  ||v_eefc_trans_curr_amt|| ' * '  ||v_eefc_conv_amt|| ' * '  ||v_pcfc_trans_curr_amt|| ' * '  || v_pcfc_conv_amt|| ' * '  ||v_oth_curr|| ' * '  ||v_ready_amt|| ' * '  ||v_value_date|| ' * '  ||v_nostro_date|| ' * '  ||v_trans_nostroid|| ' * '  ||v_oth_nostroid|| ' * '  ||v_branch_code);
Dbms_Output.Put_Line('v_cust_id:'||v_cust_id);
v_cust_cif_no:=v_cust_id;

  mfx_tf_if_fetch_validation(v_trans_ref_no,trans_type,v_trans_nostroid,v_trans_curr,v_oth_nostroid,v_oth_curr,v_start_date,v_value_date,
  v_maturity_date,v_cust_id,v_current_status , v_excess_short ,v_nego_disc ,v_mode_disbusal ,v_record_type ,v_contract_type ,v_trans_amt ,
  v_ready_amt ,v_eefc_trans_curr_amt ,v_eefc_conv_amt ,v_pcfc_trans_curr_amt ,v_pcfc_conv_amt ,v_bal_amt,v_bal_amt,v_branch_code ,a_branch_code ,v_base_rate,v_spread,v_gross_rate,
  a_user_id  ,v_cust_charges_acc_no ,v_exp_bill_type ,v_nature_of_bill  , v_premium_upto_date,v_rate ,v_conv_curr ,v_conv_corr ,v_interest_fcy,v_amt_realised,
  v_outstanding_nego_amt,tmp_err_code,tmp_err_msg);

IF(tmp_err_code='00') THEN
  mfx_tf_conv_curr_corr(trans_type,v_trans_curr,v_oth_curr,v_trans_nostroid,v_oth_nostroid,v_conv_curr,v_conv_corr);
  insert into mfx_tf_data (TF_ID,trans_ref_no,trans_type_code,fetch_time,bill_refno,cust_id,trans_curr,trans_amt,eefc_trans_curr_amt,eefc_conv_amt,
  pcfc_trans_curr_amt, pcfc_conv_amt,oth_curr,ready_amt,maturity_date,corr_ref,trans_nostroid,oth_nostroid,branch_code,INR_nostroid,buy_sell,branch_user_id,conv_curr,conv_corr,value_date)
   values ( V_ID,v_trans_ref_no,trans_type,sysdate,v_bill_refno,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,
  v_eefc_conv_amt,v_pcfc_trans_curr_amt, v_pcfc_conv_amt,v_oth_curr,v_ready_amt,v_maturity_date,v_corr_ref,v_trans_nostroid,
  v_oth_nostroid,v_branch_code,'OVRAC',v_buy_sell,a_user_id,v_conv_curr,v_conv_corr,v_value_date);
END IF;

WHEN trans_type='FG' THEN
Dbms_Output.Put_Line('Called Foreign Guarantee Charge');
IF v_mig_bank='SBH' THEN
Dbms_Output.put_line('SBH');
--mercury_exim_sbh.FETCH_IMPCOLPYMT(v_trans_ref_no,v_bill_refno,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_pcfc_trans_curr_amt,
--v_pcfc_conv_amt,v_oth_curr,v_ready_amt,v_maturity_date,v_corr_ref,v_trans_nostroid,v_oth_nostroid,v_branch_code);
ELSIF v_mig_bank='SBBJ' THEN
Dbms_Output.put_line('SBBJ');
--mercury_exim_sbbj.FETCH_IMPCOLPYMT(v_trans_ref_no,v_bill_refno,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_pcfc_trans_curr_amt,
--v_pcfc_conv_amt,v_oth_curr,v_ready_amt,v_maturity_date,v_corr_ref,v_trans_nostroid,v_oth_nostroid,v_branch_code);
ELSIF v_mig_bank='SBT' THEN
Dbms_Output.put_line('SBT');
--mercury_exim_sbt.FETCH_IMPCOLPYMT(v_trans_ref_no,v_bill_refno,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_pcfc_trans_curr_amt,
--v_pcfc_conv_amt,v_oth_curr,v_ready_amt,v_maturity_date,v_corr_ref,v_trans_nostroid,v_oth_nostroid,v_branch_code);
ELSIF v_mig_bank='SBP' THEN
Dbms_Output.put_line('SBP');
--mercury_exim_sbp.FETCH_IMPCOLPYMT(v_trans_ref_no,v_bill_refno,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_pcfc_trans_curr_amt,
--v_pcfc_conv_amt,v_oth_curr,v_ready_amt,v_maturity_date,v_corr_ref,v_trans_nostroid,v_oth_nostroid,v_branch_code);
ELSIF v_mig_bank='SBM' THEN
Dbms_Output.put_line('SBM');
--mercury_exim_sbm.FETCH_IMPCOLPYMT(v_trans_ref_no,v_bill_refno,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_pcfc_trans_curr_amt,
--v_pcfc_conv_amt,v_oth_curr,v_ready_amt,v_maturity_date,v_corr_ref,v_trans_nostroid,v_oth_nostroid,v_branch_code);
ELSE
Dbms_Output.put_line('SBI');
mercury_exim_fetch_fgpymt(v_trans_ref_no,v_bill_refno,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,
v_oth_curr,v_ready_amt,v_maturity_date,v_corr_ref,v_trans_nostroid,v_oth_nostroid,v_branch_code);
END IF;
Dbms_Output.Put_Line('end 9 ');
--dbms_output.put_line('v_trans_ref_no=' || v_trans_ref_no|| ' * '  ||v_bill_refno|| ' * '  ||v_cust_id|| ' * '  ||v_trans_curr|| ' * '  ||v_trans_amt|| ' * '  ||v_eefc_trans_curr_amt|| ' * '  ||v_eefc_conv_amt|| ' * '  ||v_pcfc_trans_curr_amt|| ' * '  || v_pcfc_conv_amt|| ' * '  ||v_oth_curr|| ' * '  ||v_ready_amt|| ' * '  ||v_value_date|| ' * '  ||v_nostro_date|| ' * '  ||v_trans_nostroid|| ' * '  ||v_oth_nostroid|| ' * '  ||v_branch_code);
Dbms_Output.Put_Line('v_cust_id:'||v_cust_id);
v_cust_cif_no:=v_cust_id;

  mfx_tf_if_fetch_validation(v_trans_ref_no,trans_type,v_trans_nostroid,v_trans_curr,v_oth_nostroid,v_oth_curr,v_start_date,v_value_date,
  v_maturity_date,v_cust_id,v_current_status , v_excess_short ,v_nego_disc ,v_mode_disbusal ,v_record_type ,v_contract_type ,v_trans_amt ,
  v_ready_amt ,v_eefc_trans_curr_amt ,v_eefc_conv_amt ,v_pcfc_trans_curr_amt ,v_pcfc_conv_amt ,v_bal_amt,v_bal_amt,v_branch_code ,a_branch_code ,v_base_rate,v_spread,v_gross_rate,
  a_user_id  ,v_cust_charges_acc_no ,v_exp_bill_type ,v_nature_of_bill  , v_premium_upto_date,v_rate ,v_conv_curr ,v_conv_corr ,v_interest_fcy,v_amt_realised,
  v_outstanding_nego_amt,tmp_err_code,tmp_err_msg);
IF(tmp_err_code='00') THEN
  mfx_tf_conv_curr_corr(trans_type,v_trans_curr,v_oth_curr,v_trans_nostroid,v_oth_nostroid,v_conv_curr,v_conv_corr);
  insert into mfx_tf_data (TF_ID,trans_ref_no,trans_type_code,fetch_time,bill_refno,cust_id,trans_curr,trans_amt,eefc_trans_curr_amt,eefc_conv_amt,
  pcfc_trans_curr_amt, pcfc_conv_amt,oth_curr,ready_amt,maturity_date,corr_ref,trans_nostroid,oth_nostroid,branch_code,INR_nostroid,buy_sell,branch_user_id,conv_curr,conv_corr,value_date)
   values ( V_ID,v_trans_ref_no,trans_type,sysdate,v_bill_refno,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,
  v_eefc_conv_amt,v_pcfc_trans_curr_amt, v_pcfc_conv_amt,v_oth_curr,v_ready_amt,v_maturity_date,v_corr_ref,v_trans_nostroid,
  v_oth_nostroid,v_branch_code,'OVRAC',v_buy_sell,a_user_id,v_conv_curr,v_conv_corr,v_value_date);
END IF;

WHEN trans_type='IA' Then  Dbms_Output.put_line('Called Import Advance Payment ');
Dbms_Output.put_line('start 10 ');
IF v_mig_bank='SBH' THEN
Dbms_Output.put_line('SBH');
--mercury_exim_sbh.FETCH_IMPADVPYMT(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_pcfc_trans_curr_amt, --v_pcfc_conv_amt,v_oth_curr,v_ready_amt,v_maturity_date,v_trans_nostroid,v_oth_nostroid,v_branch_code);
ELSIF v_mig_bank='SBBJ' THEN
Dbms_Output.put_line('SBBJ');
--mercury_exim_sbbj.FETCH_IMPADVPYMT(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_pcfc_trans_curr_amt, v_pcfc_conv_amt,v_oth_curr,v_ready_amt,v_maturity_date,v_trans_nostroid,v_oth_nostroid,v_branch_code);
ELSIF v_mig_bank='SBT' THEN
Dbms_Output.put_line('SBT');
--mercury_exim_sbt.FETCH_IMPADVPYMT(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_pcfc_trans_curr_amt, v_pcfc_conv_amt,v_oth_curr,v_ready_amt,v_maturity_date,v_trans_nostroid,v_oth_nostroid,v_branch_code);
ELSIF v_mig_bank='SBP' THEN
Dbms_Output.put_line('SBP');
--mercury_exim_sbp.FETCH_IMPADVPYMT(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_pcfc_trans_curr_amt, v_pcfc_conv_amt,v_oth_curr,v_ready_amt,v_maturity_date,v_trans_nostroid,v_oth_nostroid,v_branch_code);
ELSIF v_mig_bank='SBM' THEN
Dbms_Output.put_line('SBM');
--mercury_exim_sbm.FETCH_IMPADVPYMT(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_pcfc_trans_curr_amt, v_pcfc_conv_amt,v_oth_curr,v_ready_amt,v_maturity_date,v_trans_nostroid,v_oth_nostroid,v_branch_code);
ELSE
Dbms_Output.put_line('SBI');
mercury_exim_fetch_IMPADVPYMT(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_pcfc_trans_curr_amt, v_pcfc_conv_amt,v_oth_curr,v_ready_amt,v_maturity_date,v_trans_nostroid,v_oth_nostroid,v_branch_code,v_odi_trn_no,v_odi_uin,v_odi_flag);
END IF ;
Dbms_Output.put_line('end  10 ');
v_cust_cif_no:=v_cust_id;
  mfx_tf_if_fetch_validation(v_trans_ref_no,trans_type,v_trans_nostroid,v_trans_curr,v_oth_nostroid,v_oth_curr,v_start_date,v_value_date ,v_maturity_date,v_cust_id,
  v_current_status , v_excess_short ,v_nego_disc ,v_mode_disbusal ,v_record_type ,v_contract_type ,v_trans_amt ,
  v_ready_amt ,v_eefc_trans_curr_amt ,v_eefc_conv_amt ,v_pcfc_trans_curr_amt ,v_pcfc_conv_amt ,v_bal_amt,v_bal_amt,v_branch_code ,
  a_branch_code ,v_base_rate,v_spread,v_gross_rate,a_user_id  ,v_cust_charges_acc_no ,v_exp_bill_type ,v_nature_of_bill  ,
   v_premium_upto_date,v_rate ,v_conv_curr ,v_conv_corr ,v_interest_fcy,v_amt_realised,v_outstanding_nego_amt,tmp_err_code,tmp_err_msg);

  IF(v_odi_flag = '1' AND tmp_err_code='00') THEN
    mfx_tf_fetch_odi_validation(v_odi_uin,v_trans_curr,v_trans_amt,v_odi_trn_no,tmp_err_code,tmp_err_msg);
    Dbms_Output.Put_Line('ODI validation : '||tmp_err_code||':'||tmp_err_msg);
  END IF;

IF(tmp_err_code='00') THEN
  mfx_tf_conv_curr_corr(trans_type,v_trans_curr,v_oth_curr,v_trans_nostroid,v_oth_nostroid,v_conv_curr,v_conv_corr);
  insert into mfx_tf_data (TF_ID,trans_ref_no,trans_type_code,fetch_time,cust_id,trans_curr,trans_amt,eefc_trans_curr_amt,eefc_conv_amt,
  pcfc_trans_curr_amt, pcfc_conv_amt,oth_curr,ready_amt,maturity_date,trans_nostroid,oth_nostroid,branch_code,INR_nostroid,buy_sell,branch_user_id,conv_curr,conv_corr,value_date)
   values ( V_ID,v_trans_ref_no,trans_type,sysdate,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,
  v_eefc_conv_amt,v_pcfc_trans_curr_amt, v_pcfc_conv_amt,v_oth_curr,v_ready_amt,v_maturity_date,v_trans_nostroid,
  v_oth_nostroid,v_branch_code,'OVRAC',v_buy_sell,a_user_id,v_conv_curr,v_conv_corr,v_value_date);
END IF;

WHEN trans_type='FPD' Then  Dbms_Output.put_line('Called  Forward Purchase Delivery');
-- Office : 29.10.2012 : v4.0.0.151 : Send MTM and PFE account number from exim to murex
--mercury_exim_fetch_FCDELIVR(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_value_date,v_contract_type,v_start_date,v_maturity_date,v_record_type,v_rate,v_ready_rupee_eqvt,v_mtrans_no,v_delivery_trans_no,v_bal_amt,v_branch_code);
Dbms_Output.Put_Line('start 12');

IF v_mig_bank='SBH' THEN
Dbms_Output.put_line('SBH');
--mercury_exim_sbh.FETCH_FCDELIVR(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_value_date,v_contract_type,v_start_date,v_maturity_date,v_record_type,v_rate,v_ready_rupee_eqvt,v_mtrans_no,v_delivery_trans_no,v_bal_amt,v_branch_code,v_mtm_account,v_pfe_account);
ELSIF v_mig_bank='SBBJ' THEN
Dbms_Output.put_line('SBBJ');
--mercury_exim_sbbj.FETCH_FCDELIVR(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_value_date,v_contract_type,v_start_date,v_maturity_date,v_record_type,v_rate,v_ready_rupee_eqvt,v_mtrans_no,v_delivery_trans_no,v_bal_amt,v_branch_code,v_mtm_account,v_pfe_account);
ELSIF v_mig_bank='SBT' THEN
Dbms_Output.put_line('SBT');
--mercury_exim_sbt.FETCH_FCDELIVR(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_value_date,v_contract_type,v_start_date,v_maturity_date,v_record_type,v_rate,v_ready_rupee_eqvt,v_mtrans_no,v_delivery_trans_no,v_bal_amt,v_branch_code,v_mtm_account,v_pfe_account);
ELSIF v_mig_bank='SBP' THEN
Dbms_Output.put_line('SBP');
--mercury_exim_sbp.FETCH_FCDELIVR(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_value_date,v_contract_type,v_start_date,v_maturity_date,v_record_type,v_rate,v_ready_rupee_eqvt,v_mtrans_no,v_delivery_trans_no,v_bal_amt,v_branch_code,v_mtm_account,v_pfe_account);
ELSIF v_mig_bank='SBM' THEN
Dbms_Output.put_line('SBM');
--mercury_exim_sbm.FETCH_FCDELIVR(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_value_date,v_contract_type,v_start_date,v_maturity_date,v_record_type,v_rate,v_ready_rupee_eqvt,v_mtrans_no,v_delivery_trans_no,v_bal_amt,v_branch_code,v_mtm_account,v_pfe_account);
ELSE
Dbms_Output.put_line('SBI');
mercury_exim_fetch_FCDELIVR(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_value_date,v_contract_type,v_start_date,v_maturity_date,v_record_type,v_rate,v_ready_rupee_eqvt,v_mtrans_no,v_delivery_trans_no,v_bal_amt,v_branch_code,v_mtm_account,v_pfe_account);
END IF ;

Dbms_Output.Put_Line('end  12');

--dbms_output.put_line('v_trans_ref_no=' || v_trans_ref_no|| ' * '  ||v_cust_id|| ' * '  ||v_trans_curr|| ' * '  ||v_trans_amt|| v_value_date|| ' * '  ||v_contract_type|| ' * '  ||v_start_date|| ' * '  ||v_maturity_date|| ' * '  ||v_record_type|| ' * '  ||v_rate|| ' * '  ||v_ready_rupee_eqvt|| ' * '  ||v_mtrans_no|| ' * '  ||v_delivery_trans_no|| ' * '  ||v_branch_code||'*');
Dbms_Output.Put_Line('v_branch_code:'||v_branch_code);

--Jitesh : 19.03.2012 : Log to maintain data received from Trade Finance.
--insert into mfx_tf_raw_data(trans_ref_no,fetch_time,trans_type_code,cust_id,trans_curr,trans_amt,value_date,contract_type,start_date,maturity_date,
--record_type,rate,ready_rupee_eqvt,mtrans_no,delivery_trans_no,bal_amt,branch_code,mtm_account,pfe_account)
--values (v_trans_ref_no,SYSDATE,trans_type,v_cust_id,v_trans_curr,v_trans_amt,v_value_date,v_contract_type,v_start_date,v_maturity_date,
--v_record_type,v_rate,v_ready_rupee_eqvt,v_mtrans_no,v_delivery_trans_no,v_bal_amt,v_branch_code,v_mtm_account,v_pfe_account);

  SELECT  TRANS_REF_NO,CUST_ID,TRANS_CURR,TRANS_AMT,OTH_CURR,VALUE_DATE,CONTRACT_TYPE,START_DATE,MATURITY_DATE,RECORD_TYPE,rate,ready_rupee_eqvt,mtrans_no,
  branch_code,bal_amt,cust_charges_acc_no,customer_liability,doc_submit_date,mtm_account,pfe_account INTO
  v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_value_date,v_contract_type,
  v_start_date,v_maturity_date, v_record_type,v_rate,v_ready_rupee_eqvt,v_mtrans_no,v_branch_code,
  v_bal_amt,v_cust_charges_acc_no,v_customer_liability_type,v_doc_submit_date,v_mtm_account,v_pfe_account FROM  MFX_TF_RAW_DATA
  WHERE TRANS_REF_NO=v_trans_ref_no;

v_cust_cif_no:=v_cust_id;
  mfx_tf_if_fetch_validation(v_trans_ref_no,trans_type,v_trans_nostroid,v_trans_curr,v_oth_nostroid,v_oth_curr,v_start_date,v_value_date,v_maturity_date,v_cust_id,
  v_current_status , v_excess_short ,v_nego_disc ,v_mode_disbusal ,v_record_type ,v_contract_type ,v_trans_amt ,
  v_ready_amt ,v_eefc_trans_curr_amt ,v_eefc_conv_amt ,v_pcfc_trans_curr_amt ,v_pcfc_conv_amt ,v_bal_amt,v_bal_amt,v_branch_code ,
  a_branch_code ,v_base_rate,v_spread,v_gross_rate,a_user_id  ,v_cust_charges_acc_no ,v_exp_bill_type ,v_nature_of_bill  ,
  v_premium_upto_date,v_rate ,v_conv_curr ,v_conv_corr ,v_interest_fcy,v_amt_realised,v_outstanding_nego_amt,tmp_err_code,tmp_err_msg);
IF(tmp_err_code='00') THEN
  mfx_tf_conv_curr_corr(trans_type,v_trans_curr,v_oth_curr,v_trans_nostroid,v_oth_nostroid,v_conv_curr,v_conv_corr);
  -- Office : 29.10.2012 : v4.0.0.151 : Send MTM and PFE account number from exim to murex
  insert into mfx_tf_data (TF_ID,trans_ref_no,fetch_time,trans_type_code,cust_id,trans_curr,trans_amt,delv_amt,value_date,contract_type,start_date,maturity_date,record_type,rate,ready_rupee_eqvt,mtrans_no,delivery_trans_no,branch_code,buy_sell,INR_nostroid,branch_user_id,conv_curr,conv_corr,bal_amt,mtm_account,pfe_account) values
  (V_ID,v_trans_ref_no,SYSDATE,trans_type,v_cust_id,v_trans_curr,v_trans_amt,v_trans_amt,v_value_date,v_contract_type,v_start_date,v_maturity_date,v_record_type,v_rate,v_ready_rupee_eqvt,v_mtrans_no,v_delivery_trans_no,v_branch_code,v_buy_sell,'OVRAC',a_user_id,v_conv_curr,v_conv_corr,v_bal_amt,v_mtm_account,v_pfe_account);

END IF;
WHEN trans_type='FSD' Then  Dbms_Output.put_line('Called  Forward Purchase Delivery');
-- Office : 29.10.2012 : v4.0.0.151 : Send MTM and PFE account number from exim to murex
--mercury_exim_fetch_FCDELIVR(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_value_date,v_contract_type,v_start_date,v_maturity_date,v_record_type,v_rate,v_ready_rupee_eqvt,v_mtrans_no,v_delivery_trans_no,v_bal_amt,v_branch_code);

Dbms_Output.put_line('START 13');
IF v_mig_bank='SBH' THEN
Dbms_Output.put_line('SBH');
--mercury_exim_sbh.FETCH_FCDELIVR(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_value_date,v_contract_type,v_start_date,v_maturity_date,v_record_type,v_rate,v_ready_rupee_eqvt,v_mtrans_no,v_delivery_trans_no,v_bal_amt,v_branch_code,v_mtm_account,v_pfe_account);
ELSIF v_mig_bank='SBBJ' THEN
Dbms_Output.put_line('SBBJ');
--mercury_exim_sbbj.FETCH_FCDELIVR(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_value_date,v_contract_type,v_start_date,v_maturity_date,v_record_type,v_rate,v_ready_rupee_eqvt,v_mtrans_no,v_delivery_trans_no,v_bal_amt,v_branch_code,v_mtm_account,v_pfe_account);
ELSIF v_mig_bank='SBT' THEN
Dbms_Output.put_line('SBT');
--mercury_exim_sbt.FETCH_FCDELIVR(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_value_date,v_contract_type,v_start_date,v_maturity_date,v_record_type,v_rate,v_ready_rupee_eqvt,v_mtrans_no,v_delivery_trans_no,v_bal_amt,v_branch_code,v_mtm_account,v_pfe_account);
ELSIF v_mig_bank='SBP' THEN
Dbms_Output.put_line('SBP');
--mercury_exim_sbp.FETCH_FCDELIVR(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_value_date,v_contract_type,v_start_date,v_maturity_date,v_record_type,v_rate,v_ready_rupee_eqvt,v_mtrans_no,v_delivery_trans_no,v_bal_amt,v_branch_code,v_mtm_account,v_pfe_account);
ELSIF v_mig_bank='SBM' THEN
Dbms_Output.put_line('SBM');
--mercury_exim_sbm.FETCH_FCDELIVR(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_value_date,v_contract_type,v_start_date,v_maturity_date,v_record_type,v_rate,v_ready_rupee_eqvt,v_mtrans_no,v_delivery_trans_no,v_bal_amt,v_branch_code,v_mtm_account,v_pfe_account);
ELSE
Dbms_Output.put_line('SBI');
mercury_exim_fetch_FCDELIVR(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_value_date,v_contract_type,v_start_date,v_maturity_date,v_record_type,v_rate,v_ready_rupee_eqvt,v_mtrans_no,v_delivery_trans_no,v_bal_amt,v_branch_code,v_mtm_account,v_pfe_account);
END IF ;
Dbms_Output.put_line('END  13');
--  print_out('v_trans_ref_no=' || v_trans_ref_no|| ' * '  ||v_cust_id|| ' * '  ||v_trans_curr|| ' * '  ||v_trans_amt|| v_value_date|| ' * '  ||v_contract_type|| ' * '  ||v_start_date|| ' * '  ||v_maturity_date|| ' * '  ||v_record_type|| ' * '  ||v_rate|| ' * '  ||v_ready_rupee_eqvt|| ' * '  ||v_mtrans_no|| ' * '  ||v_delivery_trans_no|| ' * '  ||v_branch_code);

--Jitesh : 19.03.2012 : Log to maintain data received from Trade Finance.
insert into mfx_tf_raw_data(trans_ref_no,fetch_time,trans_type_code,cust_id,trans_curr,trans_amt,value_date,contract_type,start_date,maturity_date,
record_type,rate,ready_rupee_eqvt,mtrans_no,delivery_trans_no,bal_amt,branch_code,mtm_account,pfe_account)
values (v_trans_ref_no,SYSDATE,trans_type,v_cust_id,v_trans_curr,v_trans_amt,v_value_date,v_contract_type,v_start_date,v_maturity_date,
v_record_type,v_rate,v_ready_rupee_eqvt,v_mtrans_no,v_delivery_trans_no,v_bal_amt,v_branch_code,v_mtm_account,v_pfe_account);

v_cust_cif_no:=v_cust_id;
  mfx_tf_if_fetch_validation(v_trans_ref_no,trans_type,v_trans_nostroid,v_trans_curr,v_oth_nostroid,v_oth_curr,v_start_date,v_value_date ,
  v_maturity_date,v_cust_id,v_current_status , v_excess_short ,v_nego_disc ,v_mode_disbusal ,v_record_type ,v_contract_type ,v_trans_amt ,
  v_ready_amt ,v_eefc_trans_curr_amt ,v_eefc_conv_amt ,v_pcfc_trans_curr_amt ,v_pcfc_conv_amt ,v_bal_amt,v_bal_amt,v_branch_code ,
  a_branch_code ,v_base_rate,v_spread,v_gross_rate,a_user_id  ,v_cust_charges_acc_no ,v_exp_bill_type ,v_nature_of_bill  , v_premium_upto_date,v_rate ,v_conv_curr ,v_conv_corr ,v_interest_fcy,v_amt_realised,
  v_outstanding_nego_amt,tmp_err_code,tmp_err_msg);
IF(tmp_err_code='00') THEN
  mfx_tf_conv_curr_corr(trans_type,v_trans_curr,v_oth_curr,v_trans_nostroid,v_oth_nostroid,v_conv_curr,v_conv_corr);
  -- Office : 29.10.2012 : v4.0.0.151 : Send MTM and PFE account number from exim to murex
  insert into mfx_tf_data (TF_ID,trans_ref_no,fetch_time,trans_type_code,cust_id,trans_curr,trans_amt,delv_amt,value_date,contract_type,start_date,maturity_date,record_type,rate,ready_rupee_eqvt,mtrans_no,delivery_trans_no,branch_code,buy_sell,INR_nostroid,branch_user_id,conv_curr,conv_corr,bal_amt,mtm_account,pfe_account) values
  (V_ID,v_trans_ref_no,SYSDATE,trans_type,v_cust_id,v_trans_curr,v_trans_amt,v_trans_amt,v_value_date,v_contract_type,v_start_date,v_maturity_date,v_record_type,v_rate,v_ready_rupee_eqvt,v_mtrans_no,v_delivery_trans_no,v_branch_code,v_buy_sell,'OVRAC',a_user_id,v_conv_curr,v_conv_corr,v_bal_amt,v_mtm_account,v_pfe_account);
END IF;

WHEN trans_type='XPD' Then  Dbms_Output.put_line('Called Cross Currency Forward Purchase Delivery');
-- Office : 29.10.2012 : v4.0.0.151 : Send MTM and PFE account number from exim to murex
--   mercury_exim_fetch_CCYDELIVER(v_trans_ref_no,v_cust_id,v_trans_curr,v_oth_curr,v_bal_amt,v_value_date,v_contract_type,
--   v_start_date,v_maturity_date,v_record_type,v_rate,v_delivery_trans_no,v_branch_code,v_mtrans_no);
Dbms_Output.put_line('START 14');
IF v_mig_bank='SBH' THEN
Dbms_Output.put_line('SBH');
--mercury_exim_sbh.fetch_CCYDELIVER(v_trans_ref_no,v_cust_id,v_trans_curr,v_oth_curr,v_bal_amt,v_value_date,v_contract_type,
--v_start_date,v_maturity_date,v_record_type,v_rate,v_delivery_trans_no,v_branch_code,v_mtrans_no,v_mtm_account,v_pfe_account);
ELSIF v_mig_bank='SBBJ' THEN
Dbms_Output.put_line('SBBJ');
--mercury_exim_sbbj.fetch_CCYDELIVER(v_trans_ref_no,v_cust_id,v_trans_curr,v_oth_curr,v_bal_amt,v_value_date,v_contract_type,
--v_start_date,v_maturity_date,v_record_type,v_rate,v_delivery_trans_no,v_branch_code,v_mtrans_no,v_mtm_account,v_pfe_account);
ELSIF v_mig_bank='SBT' THEN
Dbms_Output.put_line('SBT');
--mercury_exim_sbt.fetch_CCYDELIVER(v_trans_ref_no,v_cust_id,v_trans_curr,v_oth_curr,v_bal_amt,v_value_date,v_contract_type,
--v_start_date,v_maturity_date,v_record_type,v_rate,v_delivery_trans_no,v_branch_code,v_mtrans_no,v_mtm_account,v_pfe_account);
ELSIF v_mig_bank='SBP' THEN
Dbms_Output.put_line('SBP');
--mercury_exim_sbp.fetch_CCYDELIVER(v_trans_ref_no,v_cust_id,v_trans_curr,v_oth_curr,v_bal_amt,v_value_date,v_contract_type,
--v_start_date,v_maturity_date,v_record_type,v_rate,v_delivery_trans_no,v_branch_code,v_mtrans_no,v_mtm_account,v_pfe_account);
ELSIF v_mig_bank='SBM' THEN
Dbms_Output.put_line('SBM');
--mercury_exim_sbm.fetch_CCYDELIVER(v_trans_ref_no,v_cust_id,v_trans_curr,v_oth_curr,v_bal_amt,v_value_date,v_contract_type,
--v_start_date,v_maturity_date,v_record_type,v_rate,v_delivery_trans_no,v_branch_code,v_mtrans_no,v_mtm_account,v_pfe_account);
ELSE
Dbms_Output.put_line('SBI');
mercury_exim_fetch_CCYDELIVER(v_trans_ref_no,v_cust_id,v_trans_curr,v_oth_curr,v_bal_amt,v_value_date,v_contract_type,
v_start_date,v_maturity_date,v_record_type,v_rate,v_delivery_trans_no,v_branch_code,v_mtrans_no,v_mtm_account,v_pfe_account);
END IF;
Dbms_Output.put_line('END 14');

--Jitesh : 19.03.2012 : Log to maintain data received from Trade Finance.
insert into mfx_tf_raw_data(trans_ref_no,fetch_time,trans_type_code,cust_id,trans_curr,oth_curr,bal_amt,value_date,contract_type,start_date,maturity_date,record_type,rate,delivery_trans_no,branch_code,mtrans_no,mtm_account,pfe_account)
values (v_trans_ref_no,SYSDATE,trans_type,v_cust_id,v_trans_curr,v_oth_curr,v_bal_amt,v_value_date,v_contract_type,v_start_date,v_maturity_date,v_record_type,v_rate,v_delivery_trans_no,v_branch_code,v_mtrans_no,v_mtm_account,v_pfe_account);

v_cust_cif_no:=v_cust_id;
    mfx_tf_if_fetch_validation(v_trans_ref_no,trans_type,v_trans_nostroid,v_trans_curr,v_oth_nostroid,v_oth_curr,v_start_date,v_value_date ,v_maturity_date,v_cust_id,
  v_current_status , v_excess_short ,v_nego_disc ,v_mode_disbusal ,v_record_type ,v_contract_type ,v_trans_amt ,
  v_ready_amt ,v_eefc_trans_curr_amt ,v_eefc_conv_amt ,v_pcfc_trans_curr_amt ,v_pcfc_conv_amt ,v_bal_amt,v_bal_amt,v_branch_code ,
  a_branch_code ,v_base_rate,v_spread,v_gross_rate,      a_user_id  ,v_cust_charges_acc_no ,v_exp_bill_type ,v_nature_of_bill  ,
   v_premium_upto_date,v_rate ,v_conv_curr ,v_conv_corr ,v_interest_fcy,v_amt_realised,v_outstanding_nego_amt,tmp_err_code,tmp_err_msg);
IF(tmp_err_code='00') THEN
  mfx_tf_conv_curr_corr(trans_type,v_trans_curr,v_oth_curr,v_trans_nostroid,v_oth_nostroid,v_conv_curr,v_conv_corr);
  -- Office : 29.10.2012 : v4.0.0.151 : Send MTM and PFE account number from exim to murex
  insert into mfx_tf_data (TF_ID,trans_ref_no,fetch_time,trans_type_code,cust_id,trans_curr,trans_amt,oth_curr,value_date,contract_type,start_date,maturity_date,record_type,rate,mtrans_no,branch_code,buy_sell,INR_nostroid,branch_user_id,conv_curr,conv_corr,bal_amt,delivery_trans_no,mtm_account,pfe_account)
  values ( V_ID,v_trans_ref_no,SYSDATE,trans_type,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_value_date,v_contract_type,v_start_date,v_maturity_date,v_record_type,v_rate,v_mtrans_no,v_branch_code,v_buy_sell,'OVRAC',a_user_id,v_conv_curr,v_conv_corr,v_bal_amt,v_delivery_trans_no,v_mtm_account,v_pfe_account);
END IF;

WHEN trans_type='XSD' Then  Dbms_Output.put_line('Called Cross Currency Forward Sale Delivery');
-- Office : 29.10.2012 : v4.0.0.151 : Send MTM and PFE account number from exim to murex
-- mercury_exim_fetch_CCYDELIVER(v_trans_ref_no,v_cust_id,v_trans_curr,v_oth_curr,v_bal_amt,v_value_date,v_contract_type,
--   v_start_date,v_maturity_date,v_record_type,v_rate,v_delivery_trans_no,v_branch_code,v_mtrans_no);
Dbms_Output.put_line('START 14');
IF v_mig_bank='SBH' THEN
Dbms_Output.put_line('SBH');
--mercury_exim_sbh.fetch_CCYDELIVER(v_trans_ref_no,v_cust_id,v_trans_curr,v_oth_curr,v_bal_amt,v_value_date,v_contract_type,
  --v_start_date,v_maturity_date,v_record_type,v_rate,v_delivery_trans_no,v_branch_code,v_mtrans_no,v_mtm_account,v_pfe_account);
ELSIF v_mig_bank='SBBJ' THEN
Dbms_Output.put_line('SBBJ');
--mercury_exim_sbbj.fetch_CCYDELIVER(v_trans_ref_no,v_cust_id,v_trans_curr,v_oth_curr,v_bal_amt,v_value_date,v_contract_type,
  --v_start_date,v_maturity_date,v_record_type,v_rate,v_delivery_trans_no,v_branch_code,v_mtrans_no,v_mtm_account,v_pfe_account);
ELSIF v_mig_bank='SBT' THEN
Dbms_Output.put_line('SBT');
--mercury_exim_sbt.fetch_CCYDELIVER(v_trans_ref_no,v_cust_id,v_trans_curr,v_oth_curr,v_bal_amt,v_value_date,v_contract_type,
  --v_start_date,v_maturity_date,v_record_type,v_rate,v_delivery_trans_no,v_branch_code,v_mtrans_no,v_mtm_account,v_pfe_account);
ELSIF v_mig_bank='SBP' THEN
Dbms_Output.put_line('SBP');
--mercury_exim_sbp.fetch_CCYDELIVER(v_trans_ref_no,v_cust_id,v_trans_curr,v_oth_curr,v_bal_amt,v_value_date,v_contract_type,
--v_start_date,v_maturity_date,v_record_type,v_rate,v_delivery_trans_no,v_branch_code,v_mtrans_no,v_mtm_account,v_pfe_account);
ELSIF v_mig_bank='SBM' THEN
Dbms_Output.put_line('SBM');
--mercury_exim_sbm.fetch_CCYDELIVER(v_trans_ref_no,v_cust_id,v_trans_curr,v_oth_curr,v_bal_amt,v_value_date,v_contract_type,
  --v_start_date,v_maturity_date,v_record_type,v_rate,v_delivery_trans_no,v_branch_code,v_mtrans_no,v_mtm_account,v_pfe_account);
ELSE
Dbms_Output.put_line('SBI');
mercury_exim_fetch_CCYDELIVER(v_trans_ref_no,v_cust_id,v_trans_curr,v_oth_curr,v_bal_amt,v_value_date,v_contract_type,
  v_start_date,v_maturity_date,v_record_type,v_rate,v_delivery_trans_no,v_branch_code,v_mtrans_no,v_mtm_account,v_pfe_account);
END IF;

Dbms_Output.put_line('END  14');
--Jitesh : 19.03.2012 : Log to maintain data received from Trade Finance.
insert into mfx_tf_raw_data(trans_ref_no,fetch_time,trans_type_code,cust_id,trans_curr,oth_curr,bal_amt,value_date,contract_type,start_date,maturity_date,record_type,rate,delivery_trans_no,branch_code,mtrans_no,mtm_account,pfe_account)
values (v_trans_ref_no,SYSDATE,trans_type,v_cust_id,v_trans_curr,v_oth_curr,v_bal_amt,v_value_date,v_contract_type,v_start_date,v_maturity_date,v_record_type,v_rate,v_delivery_trans_no,v_branch_code,v_mtrans_no,v_mtm_account,v_pfe_account);

v_cust_cif_no:=v_cust_id;
    mfx_tf_if_fetch_validation(v_trans_ref_no,trans_type,v_trans_nostroid,v_trans_curr,v_oth_nostroid,v_oth_curr,v_start_date,v_value_date ,v_maturity_date,v_cust_id,
  v_current_status , v_excess_short ,v_nego_disc ,v_mode_disbusal ,v_record_type ,v_contract_type ,v_trans_amt ,
  v_ready_amt ,v_eefc_trans_curr_amt ,v_eefc_conv_amt ,v_pcfc_trans_curr_amt ,v_pcfc_conv_amt ,v_bal_amt,v_bal_amt,v_branch_code ,
  a_branch_code ,v_base_rate,v_spread,v_gross_rate,      a_user_id  ,v_cust_charges_acc_no ,v_exp_bill_type ,v_nature_of_bill  ,
   v_premium_upto_date,v_rate ,v_conv_curr ,v_conv_corr ,v_interest_fcy,v_amt_realised,v_outstanding_nego_amt,tmp_err_code,tmp_err_msg);
IF(tmp_err_code='00') THEN
  mfx_tf_conv_curr_corr(trans_type,v_trans_curr,v_oth_curr,v_trans_nostroid,v_oth_nostroid,v_conv_curr,v_conv_corr);
  -- Office : 29.10.2012 : v4.0.0.151 : Send MTM and PFE account number from exim to murex
  insert into mfx_tf_data (TF_ID,trans_ref_no,fetch_time,trans_type_code,cust_id,trans_curr,trans_amt,oth_curr,value_date,contract_type,start_date,maturity_date,record_type,rate,mtrans_no,branch_code,buy_sell,INR_nostroid,branch_user_id,conv_curr,conv_corr,bal_amt,delivery_trans_no,mtm_account,pfe_account)
  values ( V_ID,v_trans_ref_no,SYSDATE,trans_type,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_value_date,v_contract_type,v_start_date,v_maturity_date,v_record_type,v_rate,v_mtrans_no,v_branch_code,v_buy_sell,'OVRAC',a_user_id,v_conv_curr,v_conv_corr,v_bal_amt,v_delivery_trans_no,v_mtm_account,v_pfe_account);
END IF;

WHEN trans_type='ILC' Then  Dbms_Output.put_line('Called  Import Bill LC Charges * ');
IF v_mig_bank='SBH' THEN
Dbms_Output.put_line('SBH');
--mercury_exim_sbh.fetch_IMPLCCHRGS(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_value_date,v_trans_nostroid,v_nostro_date,v_branch_code);
ELSIF v_mig_bank='SBBJ' THEN
Dbms_Output.put_line('SBBJ');
--mercury_exim_sbbj.fetch_IMPLCCHRGS(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_value_date,v_trans_nostroid,v_nostro_date,v_branch_code);
ELSIF v_mig_bank='SBT' THEN
Dbms_Output.put_line('SBT');
--mercury_exim_sbt.fetch_IMPLCCHRGS(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_value_date,v_trans_nostroid,v_nostro_date,v_branch_code);
ELSIF v_mig_bank='SBP' THEN
Dbms_Output.put_line('SBP');
--mercury_exim_sbp.fetch_IMPLCCHRGS(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_value_date,v_trans_nostroid,v_nostro_date,v_branch_code);
ELSIF v_mig_bank='SBM' THEN
Dbms_Output.put_line('SBM');
--mercury_exim_sbm.fetch_IMPLCCHRGS(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_value_date,v_trans_nostroid,v_nostro_date,v_branch_code);
ELSE
Dbms_Output.put_line('SBI');
mercury_exim_fetch_IMPLCCHRGS(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_value_date,v_trans_nostroid,v_nostro_date,v_branch_code);
END IF;

v_cust_cif_no:=v_cust_id;
  mfx_tf_if_fetch_validation(v_trans_ref_no,trans_type,v_trans_nostroid,v_trans_curr,v_oth_nostroid,v_oth_curr,v_start_date,v_value_date ,v_maturity_date,v_cust_id,
  v_current_status , v_excess_short ,v_nego_disc ,v_mode_disbusal ,v_record_type ,v_contract_type ,v_trans_amt ,
  v_ready_amt ,v_eefc_trans_curr_amt ,v_eefc_conv_amt ,v_pcfc_trans_curr_amt ,v_pcfc_conv_amt ,v_bal_amt,v_bal_amt,v_branch_code ,
  a_branch_code ,v_base_rate,v_spread,v_gross_rate,a_user_id  ,v_cust_charges_acc_no ,v_exp_bill_type ,v_nature_of_bill  ,
  v_premium_upto_date,v_rate ,v_conv_curr ,v_conv_corr ,v_interest_fcy,v_amt_realised,v_outstanding_nego_amt,tmp_err_code,tmp_err_msg);
IF(tmp_err_code='00') THEN
   mfx_tf_conv_curr_corr(trans_type,v_trans_curr,v_oth_curr,v_trans_nostroid,v_oth_nostroid,v_conv_curr,v_conv_corr);
  INSERT INTO mfx_tf_data (TF_ID,trans_ref_no,trans_type_code,fetch_time,cust_id,trans_curr,trans_amt,value_date,trans_nostroid,nostro_date,branch_code,buy_sell,INR_nostroid,branch_user_id,conv_curr,conv_corr)
  values ( V_ID,v_trans_ref_no,trans_type,sysdate,v_cust_id,v_trans_curr,v_trans_amt,v_value_date,v_trans_nostroid,v_nostro_date,v_branch_code,v_buy_sell,'OVRAC',a_user_id,v_conv_curr,v_conv_corr);
END IF;

WHEN trans_type='FS' Then  Dbms_Output.put_line('Called  Forward Sale Booking');
-- Office : 29.10.2012 : v4.0.0.151 : Send MTM and PFE account number from exim to murex
--  mercury_exim_fetch_FCBOOKING(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_trans_date_tf,v_contract_type,v_start_date,v_maturity_date,v_record_type,v_branch_code);

Dbms_Output.put_line('START 15');
  IF v_mig_bank='SBH' THEN
  Dbms_Output.put_line('SBH');
  --mercury_exim_sbh.fetch_FCBOOKING(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_trans_date_tf,v_contract_type,v_start_date,v_maturity_date,v_record_type,v_branch_code,v_mtm_account,v_pfe_account,v_delv_type,v_customer_liability_type);
  ELSIF v_mig_bank='SBBJ' THEN
  Dbms_Output.put_line('SBBJ');
  --mercury_exim_sbbj.fetch_FCBOOKING(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_trans_date_tf,v_contract_type,v_start_date,v_maturity_date,v_record_type,v_branch_code,v_mtm_account,v_pfe_account,v_delv_type,v_customer_liability_type);
  ELSIF v_mig_bank='SBT' THEN
  Dbms_Output.put_line('SBT');
  --mercury_exim_sbt.fetch_FCBOOKING(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_trans_date_tf,v_contract_type,v_start_date,v_maturity_date,v_record_type,v_branch_code,v_mtm_account,v_pfe_account,v_delv_type,v_customer_liability_type);
  ELSIF v_mig_bank='SBP' THEN
  Dbms_Output.put_line('SBP');
  --mercury_exim_sbp.fetch_FCBOOKING(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_trans_date_tf,v_contract_type,v_start_date,v_maturity_date,v_record_type,v_branch_code,v_mtm_account,v_pfe_account,v_delv_type,v_customer_liability_type);
  ELSIF v_mig_bank='SBM' THEN
  Dbms_Output.put_line('SBM');
  --mercury_exim_sbm.fetch_FCBOOKING(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_trans_date_tf,v_contract_type,v_start_date,v_maturity_date,v_record_type,v_branch_code,v_mtm_account,v_pfe_account,v_delv_type,v_customer_liability_type);
  ELSE
  Dbms_Output.put_line('SBI');
  --mercury_exim_fetch_FCBOOKING(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_trans_date_tf,v_contract_type,v_start_date,v_maturity_date,v_record_type,v_branch_code,v_mtm_account,v_pfe_account,v_delv_type,v_customer_liability_type);
  mercury_exim_fetch_FCBOOKING(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_trans_date_tf,v_contract_type,v_start_date,v_maturity_date,v_record_type,v_branch_code,v_mtm_account,v_pfe_account,v_delv_type,v_customer_liability_type,v_cashflow_urn,v_cashflow_ccy,v_cashflow_expected_end_date,v_cashflow_expected_amt,v_simplified_hedge);
  END IF;

Dbms_Output.put_line('END  15');

--Jitesh : 19.03.2012 : Log to maintain data received from Trade Finance.
--INSERT INTO mfx_tf_raw_data (trans_ref_no,trans_type_code,fetch_time,cust_id,trans_curr,trans_amt,oth_curr,trans_date_tf,contract_type,start_date,maturity_date,record_type,branch_code,mtm_account,pfe_account,delv_type,customer_liability) VALUES
--(v_trans_ref_no,trans_type,SYSDATE,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_trans_date_tf,v_contract_type,v_start_date,v_maturity_date,v_record_type,v_branch_code,v_mtm_account,v_pfe_account,v_delv_type,v_customer_liability_type);
SELECT  TRANS_REF_NO,CUST_ID,TRANS_CURR,TRANS_AMT,OTH_CURR,VALUE_DATE,CONTRACT_TYPE,START_DATE,MATURITY_DATE,RECORD_TYPE,rate,ready_rupee_eqvt,mtrans_no,
branch_code,bal_amt,cust_charges_acc_no,customer_liability,doc_submit_date,mtm_account,pfe_account INTO
v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_value_date,v_contract_type,
v_start_date,v_maturity_date, v_record_type,v_rate,v_ready_rupee_eqvt,v_mtrans_no,v_branch_code,
v_bal_amt,v_cust_charges_acc_no,v_customer_liability_type,v_doc_submit_date,v_mtm_account,v_pfe_account FROM  MFX_TF_RAW_DATA
WHERE TRANS_REF_NO='0999520FS0000188';


 v_cust_cif_no:=v_cust_id;
 Dbms_Output.Put_Line('v_cust_id : '||v_cust_id);
  mfx_tf_if_fetch_validation(v_trans_ref_no,trans_type,v_trans_nostroid,v_trans_curr,v_oth_nostroid,v_oth_curr,v_start_date,v_value_date ,v_maturity_date,v_cust_id,
  v_current_status , v_excess_short ,v_nego_disc ,v_mode_disbusal ,v_record_type ,v_contract_type ,v_trans_amt ,
  v_ready_amt ,v_eefc_trans_curr_amt ,v_eefc_conv_amt ,v_pcfc_trans_curr_amt ,v_pcfc_conv_amt ,v_bal_amt,v_bal_amt,v_branch_code ,
  a_branch_code ,v_base_rate,v_spread,v_gross_rate,a_user_id  ,v_cust_charges_acc_no ,v_exp_bill_type ,v_nature_of_bill  , v_premium_upto_date,v_rate ,v_conv_curr ,v_conv_corr ,v_interest_fcy,v_amt_realised,
  v_outstanding_nego_amt,tmp_err_code,tmp_err_msg);

  IF (v_customer_liability_type = '4' OR v_customer_liability_type = '5' OR v_customer_liability_type = '6') THEN
    SELECT mfx_tf_fwd_liab_flag(v_customer_liability_type) INTO v_customer_liability_type FROM DUAL;
  ELSE
    v_customer_liability_type :='NA';
  END IF;
    IF v_customer_liability_type='NA' THEN
      tmp_err_code:='01';
      tmp_err_msg:='Customer Liability Type can be 4 (Contractual Exposure for 15 Days) or 5 (Anticipated Exposure) or 6 (Contractual Exposure) only. Please Check with Trade Finance';
    END IF;
  Dbms_Output.Put_Line('FS - tmp_err_code : '||tmp_err_code);
IF(tmp_err_code='00') THEN
  mfx_tf_conv_curr_corr(trans_type,v_trans_curr,v_oth_curr,v_trans_nostroid,v_oth_nostroid,v_conv_curr,v_conv_corr);
  -- Office : 29.10.2012 : v4.0.0.151 : Send MTM and PFE account number from exim to murex
  INSERT INTO mfx_tf_data (TF_ID,trans_ref_no,trans_type_code,fetch_time,cust_id,trans_curr,trans_amt,oth_curr,trans_date_tf,contract_type,start_date,maturity_date,record_type,branch_code,ready_amt,buy_sell,trans_nostroid,oth_nostroid,INR_nostroid,branch_user_id,conv_curr,conv_corr,value_date,mtm_account,pfe_account,delv_type,customer_liability)
  VALUES(V_ID,v_trans_ref_no,trans_type,SYSDATE,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_trans_date_tf,v_contract_type,v_start_date,v_maturity_date,v_record_type,v_branch_code,v_trans_amt,v_buy_sell,v_trans_nostroid,v_oth_nostroid,'OVRAC',a_user_id,v_conv_curr,v_conv_corr,v_value_date,v_mtm_account,v_pfe_account,v_delv_type,v_customer_liability_type);
END IF;

WHEN trans_type='FP' Then  Dbms_Output.put_line('Called  Forward Purchase Booking');
-- Office : 29.10.2012 : v4.0.0.151 : Send MTM and PFE account number from exim to murex
-- mercury_exim_fetch_FCBOOKING(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_trans_date_tf,v_contract_type,v_start_date,v_maturity_date,v_record_type,v_branch_code);

Dbms_Output.put_line('start 16');
IF v_mig_bank='SBH' THEN
Dbms_Output.put_line('SBH');
--mercury_exim_sbh.fetch_FCBOOKING(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_trans_date_tf,v_contract_type,v_start_date,v_maturity_date,v_record_type,v_branch_code,v_mtm_account,v_pfe_account,v_delv_type,v_customer_liability_type);
ELSIF v_mig_bank='SBBJ' THEN
Dbms_Output.put_line('SBBJ');
--mercury_exim_sbbj.fetch_FCBOOKING(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_trans_date_tf,v_contract_type,v_start_date,v_maturity_date,v_record_type,v_branch_code,v_mtm_account,v_pfe_account,v_delv_type,v_customer_liability_type);
ELSIF v_mig_bank='SBT' THEN
Dbms_Output.put_line('SBT');
--mercury_exim_sbt.fetch_FCBOOKING(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_trans_date_tf,v_contract_type,v_start_date,v_maturity_date,v_record_type,v_branch_code,v_mtm_account,v_pfe_account,v_delv_type,v_customer_liability_type);
ELSIF v_mig_bank='SBP' THEN
Dbms_Output.put_line('SBP');
--mercury_exim_sbp.fetch_FCBOOKING(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_trans_date_tf,v_contract_type,v_start_date,v_maturity_date,v_record_type,v_branch_code,v_mtm_account,v_pfe_account,v_delv_type,v_customer_liability_type);
ELSIF v_mig_bank='SBM' THEN
Dbms_Output.put_line('SBM');
--mercury_exim_sbm.fetch_FCBOOKING(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_trans_date_tf,v_contract_type,v_start_date,v_maturity_date,v_record_type,v_branch_code,v_mtm_account,v_pfe_account,v_delv_type,v_customer_liability_type);
ELSE
Dbms_Output.put_line('SBI');
mercury_exim_fetch_FCBOOKING(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_trans_date_tf,v_contract_type,v_start_date,v_maturity_date,v_record_type,v_branch_code,v_mtm_account,v_pfe_account,v_delv_type,v_customer_liability_type,v_cashflow_urn,v_cashflow_ccy,v_cashflow_expected_end_date,v_cashflow_expected_amt,v_simplified_hedge);
END IF ;
Dbms_Output.put_line('end 16');

Dbms_Output.Put_Line('v_trans_ref_no:'||v_trans_ref_no);
Dbms_Output.Put_Line('v_cust_id:'||v_cust_id);

--Jitesh : 19.03.2012 : Log to maintain data received from Trade Finance.
--INSERT INTO mfx_tf_raw_data (trans_ref_no,trans_type_code,fetch_time,cust_id,trans_curr,trans_amt,oth_curr,trans_date_tf,contract_type,start_date,maturity_date,record_type,branch_code,mtm_account,pfe_account,delv_type,customer_liability) VALUES
--(v_trans_ref_no,trans_type,SYSDATE,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_trans_date_tf,v_contract_type,v_start_date,v_maturity_date,v_record_type,v_branch_code,v_mtm_account,v_pfe_account,v_delv_type,v_customer_liability_type);

SELECT  TRANS_REF_NO,CUST_ID,TRANS_CURR,TRANS_AMT,OTH_CURR,VALUE_DATE,CONTRACT_TYPE,START_DATE,MATURITY_DATE,RECORD_TYPE,rate,ready_rupee_eqvt,mtrans_no,
branch_code,bal_amt,cust_charges_acc_no,customer_liability,doc_submit_date,mtm_account,pfe_account INTO
v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_value_date,v_contract_type,
v_start_date,v_maturity_date, v_record_type,v_rate,v_ready_rupee_eqvt,v_mtrans_no,v_branch_code,
v_bal_amt,v_cust_charges_acc_no,v_customer_liability_type,v_doc_submit_date,v_mtm_account,v_pfe_account FROM  MFX_TF_RAW_DATA
WHERE TRANS_REF_NO=v_trans_ref_no;

v_cust_cif_no:=v_cust_id;
  mfx_tf_if_fetch_validation(v_trans_ref_no,trans_type,v_trans_nostroid,v_trans_curr,v_oth_nostroid,v_oth_curr,v_start_date,v_value_date ,v_maturity_date,v_cust_id,
  v_current_status , v_excess_short ,v_nego_disc ,v_mode_disbusal ,v_record_type ,v_contract_type ,v_trans_amt ,
  v_ready_amt ,v_eefc_trans_curr_amt ,v_eefc_conv_amt ,v_pcfc_trans_curr_amt ,v_pcfc_conv_amt ,v_bal_amt,v_bal_amt,v_branch_code ,
  a_branch_code ,v_base_rate,v_spread,v_gross_rate,a_user_id  ,v_cust_charges_acc_no ,v_exp_bill_type ,v_nature_of_bill  , v_premium_upto_date,v_rate ,v_conv_curr ,v_conv_corr ,v_interest_fcy,v_amt_realised,
  v_outstanding_nego_amt,tmp_err_code,tmp_err_msg);

  IF (v_customer_liability_type = '4' OR v_customer_liability_type = '5' OR v_customer_liability_type = '6') THEN
    SELECT mfx_tf_fwd_liab_flag(v_customer_liability_type) INTO v_customer_liability_type FROM DUAL;
  ELSE
    v_customer_liability_type :='NA';
  END IF;
    IF v_customer_liability_type='NA' THEN
      tmp_err_code:='01';
      tmp_err_msg:='Customer Liability Type can be 4 (Contractual Exposure for 15 Days) or 5 (Anticipated Exposure) or 6 (Contractual Exposure) only. Please Check with Trade Finance';
    END IF;
  Dbms_Output.Put_Line('FP - tmp_err_code : '||tmp_err_code);
IF(tmp_err_code='00') THEN
  mfx_tf_conv_curr_corr(trans_type,v_trans_curr,v_oth_curr,v_trans_nostroid,v_oth_nostroid,v_conv_curr,v_conv_corr);
  -- Office : 29.10.2012 : v4.0.0.151 : Send MTM and PFE account number from exim to murex
  INSERT INTO mfx_tf_data (TF_ID,trans_ref_no,trans_type_code,fetch_time,cust_id,trans_curr,trans_amt,oth_curr,trans_date_tf,contract_type,start_date,maturity_date,record_type,branch_code,ready_amt,buy_sell,trans_nostroid,oth_nostroid,INR_nostroid,branch_user_id,conv_curr,conv_corr,value_date,mtm_account,pfe_account,delv_type,customer_liability) VALUES
  (V_ID,v_trans_ref_no,trans_type,SYSDATE,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_trans_date_tf,v_contract_type,v_start_date,v_maturity_date,v_record_type,v_branch_code,v_trans_amt,v_buy_sell,v_trans_nostroid,v_oth_nostroid,'OVRAC',a_user_id,v_conv_curr,v_conv_corr,v_value_date,v_mtm_account,v_pfe_account,v_delv_type,v_customer_liability_type);
END IF;

WHEN trans_type='XS' Then  Dbms_Output.put_line('Called  Forward Sale Cancellation');
-- Office : 29.10.2012 : v4.0.0.151 : Send MTM and PFE account number from exim to murex
-- mercury_exim_fetch_CCYBOOKNG(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_trans_date_tf,v_contract_type,v_start_date,v_maturity_date,v_record_type,v_branch_code);

Dbms_Output.put_line('START 17');


IF v_mig_bank='SBH' THEN
Dbms_Output.put_line('SBH');
--mercury_exim_sbh.fetch_CCYBOOKNG(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_trans_date_tf,v_contract_type,v_start_date,v_maturity_date,v_record_type,v_branch_code,v_mtm_account,v_pfe_account,v_delv_type,v_customer_liability_type);
ELSIF v_mig_bank='SBBJ' THEN
Dbms_Output.put_line('SBBJ');
--mercury_exim_sbbj.fetch_CCYBOOKNG(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_trans_date_tf,v_contract_type,v_start_date,v_maturity_date,v_record_type,v_branch_code,v_mtm_account,v_pfe_account,v_delv_type,v_customer_liability_type);
ELSIF v_mig_bank='SBT' THEN
Dbms_Output.put_line('SBT');
--mercury_exim_sbt.fetch_CCYBOOKNG(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_trans_date_tf,v_contract_type,v_start_date,v_maturity_date,v_record_type,v_branch_code,v_mtm_account,v_pfe_account,v_delv_type,v_customer_liability_type);
ELSIF v_mig_bank='SBP' THEN
Dbms_Output.put_line('SBP');
--mercury_exim_sbp.fetch_CCYBOOKNG(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_trans_date_tf,v_contract_type,v_start_date,v_maturity_date,v_record_type,v_branch_code,v_mtm_account,v_pfe_account,v_delv_type,v_customer_liability_type);
ELSIF v_mig_bank='SBM' THEN
Dbms_Output.put_line('SBM');
--mercury_exim_sbm.fetch_CCYBOOKNG(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_trans_date_tf,v_contract_type,v_start_date,v_maturity_date,v_record_type,v_branch_code,v_mtm_account,v_pfe_account,v_delv_type,v_customer_liability_type);
ELSE
Dbms_Output.put_line('SBI');
mercury_exim_fetch_CCYBOOKNG(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_trans_date_tf,v_contract_type,v_start_date,v_maturity_date,v_record_type,v_branch_code,v_mtm_account,v_pfe_account,v_delv_type,v_customer_liability_type,v_cashflow_urn,v_cashflow_ccy,v_cashflow_expected_end_date,v_cashflow_expected_amt,v_simplified_hedge);
END IF;

Dbms_Output.put_line('END 17');

--Jitesh : 19.03.2012 : Log to maintain data received from Trade Finance.
INSERT INTO mfx_tf_raw_data (trans_ref_no,trans_type_code,fetch_time,cust_id,trans_curr,trans_amt,oth_curr,trans_date_tf,contract_type,start_date,maturity_date,record_type,branch_code,mtm_account,pfe_account,delv_type,customer_liability) VALUES
(v_trans_ref_no,trans_type,SYSDATE,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_trans_date_tf,v_contract_type,v_start_date,v_maturity_date,v_record_type,v_branch_code,v_mtm_account,v_pfe_account,v_delv_type,v_customer_liability_type);

v_cust_cif_no:=v_cust_id;
  mfx_tf_if_fetch_validation(v_trans_ref_no,trans_type,v_trans_nostroid,v_trans_curr,v_oth_nostroid,v_oth_curr,v_start_date,v_value_date ,v_maturity_date,v_cust_id,
  v_current_status , v_excess_short ,v_nego_disc ,v_mode_disbusal ,v_record_type ,v_contract_type ,v_trans_amt ,
  v_ready_amt ,v_eefc_trans_curr_amt ,v_eefc_conv_amt ,v_pcfc_trans_curr_amt ,v_pcfc_conv_amt ,v_bal_amt,v_bal_amt,v_branch_code ,
  a_branch_code ,v_base_rate,v_spread,v_gross_rate,
  a_user_id  ,v_cust_charges_acc_no ,v_exp_bill_type ,v_nature_of_bill  , v_premium_upto_date,v_rate ,v_conv_curr ,v_conv_corr ,v_interest_fcy,v_amt_realised,
  v_outstanding_nego_amt,tmp_err_code,tmp_err_msg);

  IF (v_customer_liability_type = '4' OR v_customer_liability_type = '5' OR v_customer_liability_type = '6') THEN
    SELECT mfx_tf_fwd_liab_flag(v_customer_liability_type) INTO v_customer_liability_type FROM DUAL;
  ELSE
    v_customer_liability_type :='NA';
  END IF;
    IF v_customer_liability_type='NA' THEN
      tmp_err_code:='01';
      tmp_err_msg:='Customer Liability Type can be 4 (Contractual Exposure for 15 Days) or 5 (Anticipated Exposure) or 6 (Contractual Exposure) only. Please Check with Trade Finance';
    END IF;
  Dbms_Output.Put_Line('XS - tmp_err_code : '||tmp_err_code);

IF(tmp_err_code='00') THEN
  mfx_tf_conv_curr_corr(trans_type,v_trans_curr,v_oth_curr,v_trans_nostroid,v_oth_nostroid,v_conv_curr,v_conv_corr);
  -- Office : 29.10.2012 : v4.0.0.151 : Send MTM and PFE account number from exim to murex
  INSERT INTO mfx_tf_data (TF_ID,trans_ref_no,trans_type_code,fetch_time,cust_id,trans_curr,trans_amt,oth_curr,trans_date_tf,contract_type,start_date,maturity_date,record_type,branch_code,ready_amt,buy_sell,trans_nostroid,oth_nostroid,INR_nostroid,branch_user_id,conv_curr,conv_corr,value_date,mtm_account,pfe_account,delv_type,customer_liability) VALUES
  (V_ID,v_trans_ref_no,trans_type,SYSDATE,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_trans_date_tf,v_contract_type,v_start_date,v_maturity_date,v_record_type,v_branch_code,v_trans_amt,v_buy_sell,v_trans_nostroid,v_oth_nostroid,'OVRAC',a_user_id,v_conv_curr,v_conv_corr,v_value_date,v_mtm_account,v_pfe_account,v_delv_type,v_customer_liability_type);
END IF;

WHEN trans_type='XP' Then  Dbms_Output.put_line('Called  Forward Purchase Booking');
-- Office : 29.10.2012 : v4.0.0.151 : Send MTM and PFE account number from exim to murex
-- mercury_exim_fetch_CCYBOOKNG(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_trans_date_tf,v_contract_type,v_start_date,v_maturity_date,v_record_type,v_branch_code);
Dbms_Output.put_line('START 18');
IF v_mig_bank='SBH' THEN
Dbms_Output.put_line('SBH');
--mercury_exim_sbh.fetch_CCYBOOKNG(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_trans_date_tf,v_contract_type,v_start_date,v_maturity_date,v_record_type,v_branch_code,v_mtm_account,v_pfe_account,v_delv_type,v_customer_liability_type);
ELSIF v_mig_bank='SBBJ' THEN
Dbms_Output.put_line('SBBJ');
--mercury_exim_sbbj.fetch_CCYBOOKNG(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_trans_date_tf,v_contract_type,v_start_date,v_maturity_date,v_record_type,v_branch_code,v_mtm_account,v_pfe_account,v_delv_type,v_customer_liability_type);
ELSIF v_mig_bank='SBT' THEN
Dbms_Output.put_line('SBT');
--mercury_exim_sbt.fetch_CCYBOOKNG(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_trans_date_tf,v_contract_type,v_start_date,v_maturity_date,v_record_type,v_branch_code,v_mtm_account,v_pfe_account,v_delv_type,v_customer_liability_type);
ELSIF v_mig_bank='SBP' THEN
Dbms_Output.put_line('SBP');
--mercury_exim_sbp.fetch_CCYBOOKNG(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_trans_date_tf,v_contract_type,v_start_date,v_maturity_date,v_record_type,v_branch_code,v_mtm_account,v_pfe_account,v_delv_type,v_customer_liability_type);
ELSIF v_mig_bank='SBM' THEN
Dbms_Output.put_line('SBM');
--mercury_exim_sbm.fetch_CCYBOOKNG(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_trans_date_tf,v_contract_type,v_start_date,v_maturity_date,v_record_type,v_branch_code,v_mtm_account,v_pfe_account,v_delv_type,v_customer_liability_type);
ELSE
Dbms_Output.put_line('SBI');
mercury_exim_fetch_CCYBOOKNG(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_trans_date_tf,v_contract_type,v_start_date,v_maturity_date,v_record_type,v_branch_code,v_mtm_account,v_pfe_account,v_delv_type,v_customer_liability_type,v_cashflow_urn,v_cashflow_ccy,v_cashflow_expected_end_date,v_cashflow_expected_amt,v_simplified_hedge);
END IF;
Dbms_Output.put_line('END 18');
--Jitesh : 19.03.2012 : Log to maintain data received from Trade Finance.
INSERT INTO mfx_tf_raw_data (trans_ref_no,trans_type_code,fetch_time,cust_id,trans_curr,trans_amt,oth_curr,trans_date_tf,contract_type,start_date,maturity_date,record_type,branch_code,mtm_account,pfe_account,delv_type,customer_liability) VALUES
(v_trans_ref_no,trans_type,SYSDATE,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_trans_date_tf,v_contract_type,v_start_date,v_maturity_date,v_record_type,v_branch_code,v_mtm_account,v_pfe_account,v_delv_type,v_customer_liability_type);

v_cust_cif_no:=v_cust_id;
mfx_tf_if_fetch_validation(v_trans_ref_no,trans_type,v_trans_nostroid,v_trans_curr,v_oth_nostroid,v_oth_curr,v_start_date,v_value_date ,v_maturity_date,v_cust_id,
v_current_status , v_excess_short ,v_nego_disc ,v_mode_disbusal ,v_record_type ,v_contract_type ,v_trans_amt ,
     v_ready_amt ,v_eefc_trans_curr_amt ,v_eefc_conv_amt ,v_pcfc_trans_curr_amt ,v_pcfc_conv_amt ,v_bal_amt,v_bal_amt,v_branch_code,
     a_branch_code ,v_base_rate,v_spread,v_gross_rate,
     a_user_id  ,v_cust_charges_acc_no ,v_exp_bill_type ,v_nature_of_bill  , v_premium_upto_date,v_rate ,v_conv_curr ,v_conv_corr ,v_interest_fcy,v_amt_realised,
     v_outstanding_nego_amt,tmp_err_code,tmp_err_msg);

  IF (v_customer_liability_type = '4' OR v_customer_liability_type = '5' OR v_customer_liability_type = '6') THEN
    SELECT mfx_tf_fwd_liab_flag(v_customer_liability_type) INTO v_customer_liability_type FROM DUAL;
  ELSE
    v_customer_liability_type :='NA';
  END IF;
    IF v_customer_liability_type='NA' THEN
      tmp_err_code:='01';
      tmp_err_msg:='Customer Liability Type can be 4 (Contractual Exposure for 15 Days) or 5 (Anticipated Exposure) or 6 (Contractual Exposure) only. Please Check with Trade Finance';
    END IF;
  Dbms_Output.Put_Line('XP - tmp_err_code : '||tmp_err_code);

IF(tmp_err_code='00') THEN
    mfx_tf_conv_curr_corr(trans_type,v_trans_curr,v_oth_curr,v_trans_nostroid,v_oth_nostroid,v_conv_curr,v_conv_corr);
    -- Office : 29.10.2012 : v4.0.0.151 : Send MTM and PFE account number from exim to murex
  INSERT INTO mfx_tf_data (TF_ID,trans_ref_no,trans_type_code,fetch_time,cust_id,trans_curr,trans_amt,oth_curr,trans_date_tf, contract_type,start_date,maturity_date,record_type,branch_code,ready_amt,buy_sell,trans_nostroid,oth_nostroid,INR_nostroid,branch_user_id,conv_curr,conv_corr,value_date,mtm_account,pfe_account,delv_type,customer_liability) VALUES
  (V_ID,v_trans_ref_no,trans_type,sysdate,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_trans_date_tf,v_contract_type,v_start_date,v_maturity_date,v_record_type,v_branch_code,v_trans_amt,v_buy_sell,v_trans_nostroid,v_oth_nostroid,'OVRAC',a_user_id,v_conv_curr,v_conv_corr,v_value_date,v_mtm_account,v_pfe_account,v_delv_type,v_customer_liability_type);
END IF;

WHEN trans_type='PDB' Then  Dbms_Output.put_line('PCFC Disbursal ');
Dbms_Output.put_line('START 19');
IF v_mig_bank='SBH' THEN
Dbms_Output.put_line('SBH');
--mercury_exim_sbh.fetch_PCFCDISBURSAL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_value_date,v_maturity_date,v_current_status,v_trans_nostroid,v_tenor,v_branch_code,v_base_rate,v_spread,v_gross_rate);
ELSIF v_mig_bank='SBBJ' THEN
Dbms_Output.put_line('SBBJ');
--mercury_exim_sbbj.fetch_PCFCDISBURSAL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_value_date,v_maturity_date,v_current_status,v_trans_nostroid,v_tenor,v_branch_code,v_base_rate,v_spread,v_gross_rate);
ELSIF v_mig_bank='SBT' THEN
Dbms_Output.put_line('SBT');
--mercury_exim_sbt.fetch_PCFCDISBURSAL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_value_date,v_maturity_date,v_current_status,v_trans_nostroid,v_tenor,v_branch_code,v_base_rate,v_spread,v_gross_rate);
ELSIF v_mig_bank='SBP' THEN
Dbms_Output.put_line('SBP');
--mercury_exim_sbp.fetch_PCFCDISBURSAL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_value_date,v_maturity_date,v_current_status,v_trans_nostroid,v_tenor,v_branch_code,v_base_rate,v_spread,v_gross_rate);
ELSIF v_mig_bank='SBM' THEN
Dbms_Output.put_line('SBM');
--mercury_exim_sbm.fetch_PCFCDISBURSAL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_value_date,v_maturity_date,v_current_status,v_trans_nostroid,v_tenor,v_branch_code,v_base_rate,v_spread,v_gross_rate);
ELSE
Dbms_Output.put_line('SBI');
mer_exim_fetch_PCFCDISBURSAL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_value_date,v_maturity_date,v_current_status,v_trans_nostroid,v_tenor,v_branch_code,v_base_rate,v_spread,v_gross_rate);
END IF;
Dbms_Output.put_line('END 19');

v_cust_cif_no:=v_cust_id;
  mfx_tf_if_fetch_validation(v_trans_ref_no,trans_type,v_trans_nostroid,v_trans_curr,v_oth_nostroid,v_oth_curr,v_start_date,v_value_date ,v_maturity_date,v_cust_id,
  v_current_status , v_excess_short ,v_nego_disc ,v_mode_disbusal ,v_record_type ,v_contract_type ,v_trans_amt ,
  v_trans_amt ,v_eefc_trans_curr_amt ,v_eefc_conv_amt ,v_pcfc_trans_curr_amt ,v_pcfc_conv_amt ,v_bal_amt,v_bal_amt,v_branch_code,
  a_branch_code ,v_base_rate,v_spread,v_gross_rate,a_user_id  ,v_cust_charges_acc_no ,v_exp_bill_type ,v_nature_of_bill  , v_premium_upto_date,v_rate ,v_conv_curr ,v_conv_corr ,v_interest_fcy,v_amt_realised,
  v_outstanding_nego_amt,tmp_err_code,tmp_err_msg);
IF(tmp_err_code='00') THEN
  -- mfx_tf_conv_curr_corr(trans_type,v_trans_curr,v_oth_curr,v_trans_nostroid,v_oth_nostroid,v_conv_curr,v_conv_corr); MOT REQUIRED
  INSERT INTO mfx_tf_data(TF_ID,trans_ref_no,trans_type_code,fetch_time,cust_id,trans_curr,trans_amt,ready_amt,value_date,maturity_date,mode_disbursal,current_status,trans_nostroid,tenor,branch_code,buy_sell,INR_nostroid,branch_user_id,conv_curr,conv_corr,base_rate,spread,gross_rate)
  Values(V_ID,v_trans_ref_no,trans_type,SYSDATE,v_cust_id,v_trans_curr,v_trans_amt,v_trans_amt,v_value_date,v_maturity_date,v_mode_disbursal,v_current_status,v_trans_nostroid,v_tenor,v_branch_code,v_buy_sell,'OVRAC',a_user_id,v_conv_curr,v_conv_corr,v_base_rate,v_spread,v_gross_rate);
END IF ;

WHEN trans_type='PCC' Then  Dbms_Output.put_line('PCFC Disbursal - Conversion ');
Dbms_Output.put_line('START 20');
IF v_mig_bank='SBH' THEN
Dbms_Output.put_line('SBH');
--mercury_exim_sbh.fetch_pcfcconv(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_mode_disbursal,v_value_date,v_maturity_date,
--v_current_status,v_branch_code,v_trans_nostroid,v_disbursal_mfx_no,v_bal_amt);
ELSIF v_mig_bank='SBBJ' THEN
Dbms_Output.put_line('SBBJ');
--mercury_exim_sbbj.fetch_pcfcconv(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_mode_disbursal,v_value_date,v_maturity_date,
--v_current_status,v_branch_code,v_trans_nostroid,v_disbursal_mfx_no,v_bal_amt);
ELSIF v_mig_bank='SBT' THEN
Dbms_Output.put_line('SBT');
--mercury_exim_sbt.fetch_pcfcconv(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_mode_disbursal,v_value_date,v_maturity_date,
--v_current_status,v_branch_code,v_trans_nostroid,v_disbursal_mfx_no,v_bal_amt);
ELSIF v_mig_bank='SBP' THEN
Dbms_Output.put_line('SBP');
--mercury_exim_sbp.fetch_pcfcconv(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_mode_disbursal,v_value_date,v_maturity_date,
--v_current_status,v_branch_code,v_trans_nostroid,v_disbursal_mfx_no,v_bal_amt);
ELSIF v_mig_bank='SBM' THEN
Dbms_Output.put_line('SBM');
--mercury_exim_sbm.fetch_pcfcconv(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_mode_disbursal,v_value_date,v_maturity_date,
--v_current_status,v_branch_code,v_trans_nostroid,v_disbursal_mfx_no,v_bal_amt);
ELSE
Dbms_Output.put_line('SBI');
mercury_exim_fetch_pcfcconv(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_mode_disbursal,v_value_date,v_maturity_date,
v_current_status,v_branch_code,v_trans_nostroid,v_disbursal_mfx_no,v_bal_amt);
END IF;
Dbms_Output.put_line('END 20');


v_cust_cif_no:=v_cust_id;
  mfx_tf_if_fetch_validation(v_trans_ref_no,trans_type,v_trans_nostroid,v_trans_curr,v_oth_nostroid,v_oth_curr,v_start_date,v_value_date ,v_maturity_date,v_cust_id,
  v_current_status , v_excess_short ,v_nego_disc ,v_mode_disbusal ,v_record_type ,v_contract_type ,v_trans_amt ,
  v_ready_amt ,v_eefc_trans_curr_amt ,v_eefc_conv_amt ,v_pcfc_trans_curr_amt ,v_pcfc_conv_amt ,v_bal_amt,v_trans_amt,v_branch_code,
  a_branch_code ,v_base_rate,v_spread,v_gross_rate, a_user_id  ,v_cust_charges_acc_no ,v_exp_bill_type ,v_nature_of_bill  , v_premium_upto_date,v_rate ,v_conv_curr ,v_conv_corr ,v_interest_fcy,v_amt_realised,
  v_outstanding_nego_amt,tmp_err_code,tmp_err_msg);
IF(tmp_err_code='00') THEN
   mfx_tf_conv_curr_corr(trans_type,v_trans_curr,v_oth_curr,v_trans_nostroid,v_oth_nostroid,v_conv_curr,v_conv_corr);
  INSERT INTO mfx_tf_data(TF_ID,trans_ref_no,trans_type_code,fetch_time,cust_id,trans_curr,trans_amt,ready_amt,value_date,maturity_date,mode_disbursal,current_status,trans_nostroid,tenor,branch_code,buy_sell,INR_nostroid,branch_user_id,conv_curr,conv_corr,disbursal_mfx_no,bal_amt)
  Values(V_ID,v_trans_ref_no,trans_type,SYSDATE,v_cust_id,v_trans_curr,v_trans_amt,v_trans_amt,v_value_date,v_maturity_date,v_mode_disbursal,v_current_status,v_trans_nostroid,v_tenor,v_branch_code,v_buy_sell,'FCGA',a_user_id,v_conv_curr,v_conv_corr,v_disbursal_mfx_no,v_bal_amt);
END IF ;

WHEN trans_type='PCD' Then  Dbms_Output.put_line('PCFC Remittance - Import  ');
Dbms_Output.put_line('START 21');
IF v_mig_bank='SBH' THEN
Dbms_Output.put_line('SBH');
--mercury_exim_sbh.fetch_PCFCREMITIMP(v_trans_ref_no,v_cust_id,v_trans_curr,v_forex_txn_no,v_mode_disbursal,v_value_date,
--v_maturity_date,v_current_status,v_branch_code,v_trans_nostroid,v_disbursal_mfx_no,v_bal_amt);
ELSIF v_mig_bank='SBBJ' THEN
Dbms_Output.put_line('SBBJ');
--mercury_exim_sbbj.fetch_PCFCREMITIMP(v_trans_ref_no,v_cust_id,v_trans_curr,v_forex_txn_no,v_mode_disbursal,v_value_date,
--v_maturity_date,v_current_status,v_branch_code,v_trans_nostroid,v_disbursal_mfx_no,v_bal_amt);
ELSIF v_mig_bank='SBT' THEN
Dbms_Output.put_line('SBT');
--mercury_exim_sbt.fetch_PCFCREMITIMP(v_trans_ref_no,v_cust_id,v_trans_curr,v_forex_txn_no,v_mode_disbursal,v_value_date,
--v_maturity_date,v_current_status,v_branch_code,v_trans_nostroid,v_disbursal_mfx_no,v_bal_amt);
ELSIF v_mig_bank='SBP' THEN
Dbms_Output.put_line('SBP');
--mercury_exim_sbp.fetch_PCFCREMITIMP(v_trans_ref_no,v_cust_id,v_trans_curr,v_forex_txn_no,v_mode_disbursal,v_value_date,
--v_maturity_date,v_current_status,v_branch_code,v_trans_nostroid,v_disbursal_mfx_no,v_bal_amt);
ELSIF v_mig_bank='SBM' THEN
Dbms_Output.put_line('SBM');
--mercury_exim_sbm.fetch_PCFCREMITIMP(v_trans_ref_no,v_cust_id,v_trans_curr,v_forex_txn_no,v_mode_disbursal,v_value_date,
--v_maturity_date,v_current_status,v_branch_code,v_trans_nostroid,v_disbursal_mfx_no,v_bal_amt);
ELSE
Dbms_Output.put_line('SBI');
mer_exim_fetch_pcfcremitimp(v_trans_ref_no,v_cust_id,v_trans_curr,v_forex_txn_no,v_mode_disbursal,v_value_date,
v_maturity_date,v_current_status,v_branch_code,v_trans_nostroid,v_disbursal_mfx_no,v_bal_amt);
END IF;
Dbms_Output.put_line('END 21');

v_cust_cif_no:=v_cust_id;
  mfx_tf_if_fetch_validation(v_trans_ref_no,trans_type,v_trans_nostroid,v_trans_curr,v_oth_nostroid,v_oth_curr,v_start_date,v_value_date ,v_maturity_date,v_cust_id,
  v_current_status , v_excess_short ,v_nego_disc ,v_mode_disbusal ,v_record_type ,v_contract_type ,v_trans_amt ,
  v_ready_amt ,v_eefc_trans_curr_amt ,v_eefc_conv_amt ,v_pcfc_trans_curr_amt ,v_pcfc_conv_amt ,v_bal_amt,v_bal_amt,v_branch_code,
  a_branch_code ,v_base_rate,v_spread,v_gross_rate,a_user_id,v_cust_charges_acc_no ,v_exp_bill_type ,v_nature_of_bill  , v_premium_upto_date,v_rate ,v_conv_curr ,v_conv_corr ,v_interest_fcy,v_amt_realised,
  v_outstanding_nego_amt,tmp_err_code,tmp_err_msg);
IF(tmp_err_code='00') THEN
  mfx_tf_conv_curr_corr(trans_type,v_trans_curr,v_oth_curr,v_trans_nostroid,v_oth_nostroid,v_conv_curr,v_conv_corr);
  INSERT INTO mfx_tf_data(TF_ID,trans_ref_no,trans_type_code,fetch_time,cust_id,trans_curr,trans_amt,ready_amt,value_date,maturity_date,mode_disbursal,current_status,trans_nostroid,branch_code,buy_sell,INR_nostroid,branch_user_id,conv_curr,conv_corr,disbursal_mfx_no,forex_txn_no,bal_amt)
  Values(V_ID,v_trans_ref_no,trans_type,SYSDATE,v_cust_id,v_trans_curr,v_trans_amt,v_trans_amt,v_value_date,v_maturity_date,v_mode_disbursal,v_current_status,v_trans_nostroid,v_branch_code,v_buy_sell,'FCGA',a_user_id,v_conv_curr,v_conv_corr,v_disbursal_mfx_no,v_forex_txn_no,v_bal_amt);
END IF ;

WHEN trans_type='BER' Then  Dbms_Output.put_line('Export bill Excess Realization');

Dbms_Output.put_line('START 22');
IF v_mig_bank='SBH' THEN
Dbms_Output.put_line('SBH');
--mercury_exim_sbh.fetch_EXPNEGOPYMT(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,
--v_ready_amt,v_nego_start_date,v_nostro_real_date,v_maturity_date,v_current_status,v_excess_short,v_trans_nostroid,v_oth_nostroid,v_amt_realised,v_branch_code,v_exp_bill_type,v_nature_of_bill,v_premium_upto_date,v_rate,v_outstanding_nego_amt);
ELSIF v_mig_bank='SBBJ' THEN
Dbms_Output.put_line('SBBJ');
--mercury_exim_sbbj.fetch_EXPNEGOPYMT(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,
--v_ready_amt,v_nego_start_date,v_nostro_real_date,v_maturity_date,v_current_status,v_excess_short,v_trans_nostroid,v_oth_nostroid,v_amt_realised,v_branch_code,v_exp_bill_type,v_nature_of_bill,v_premium_upto_date,v_rate,v_outstanding_nego_amt);
ELSIF v_mig_bank='SBT' THEN
Dbms_Output.put_line('SBT');
--mercury_exim_sbt.fetch_EXPNEGOPYMT(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,
--v_ready_amt,v_nego_start_date,v_nostro_real_date,v_maturity_date,v_current_status,v_excess_short,v_trans_nostroid,v_oth_nostroid,v_amt_realised,v_branch_code,v_exp_bill_type,v_nature_of_bill,v_premium_upto_date,v_rate,v_outstanding_nego_amt);
ELSIF v_mig_bank='SBP' THEN
Dbms_Output.put_line('SBP');
--mercury_exim_sbp.fetch_EXPNEGOPYMT(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,
--v_ready_amt,v_nego_start_date,v_nostro_real_date,v_maturity_date,v_current_status,v_excess_short,v_trans_nostroid,v_oth_nostroid,v_amt_realised,v_branch_code,v_exp_bill_type,v_nature_of_bill,v_premium_upto_date,v_rate,v_outstanding_nego_amt);
ELSIF v_mig_bank='SBM' THEN
Dbms_Output.put_line('SBM');
--mercury_exim_sbm.fetch_EXPNEGOPYMT(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,
--v_ready_amt,v_nego_start_date,v_nostro_real_date,v_maturity_date,v_current_status,v_excess_short,v_trans_nostroid,v_oth_nostroid,v_amt_realised,v_branch_code,v_exp_bill_type,v_nature_of_bill,v_premium_upto_date,v_rate,v_outstanding_nego_amt);
ELSE
Dbms_Output.put_line('SBI');
mercury_exim_fetch_EXPNEGOPYMT(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,
v_ready_amt,v_nego_start_date,v_nostro_real_date,v_maturity_date,v_current_status,v_excess_short,v_trans_nostroid,v_oth_nostroid,v_amt_realised,v_branch_code,v_exp_bill_type,v_nature_of_bill,v_premium_upto_date,v_rate,v_outstanding_nego_amt);
END IF;
Dbms_Output.put_line('END 22');

--Jitesh : 01.02.2012 : Log to maintain data received from Trade Finance.
INSERT INTO mfx_tf_raw_data(trans_ref_no,trans_type_code,fetch_time,cust_id,trans_curr,trans_amt,eefc_trans_curr_amt,eefc_conv_amt,
oth_curr,ready_amt,nego_start_date,nostro_real_date,maturity_date,current_status,excess_short,trans_nostroid,oth_nostroid,amt_realised,branch_code,
exp_bill_type,nature_of_bill,premium_upto_date,rate,outstanding_nego_amt)
values (v_trans_ref_no,trans_type,SYSDATE,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,
v_ready_amt,v_nego_start_date,v_nostro_real_date,v_maturity_date,v_current_status,v_excess_short,v_trans_nostroid,v_oth_nostroid,v_amt_realised,v_branch_code,
v_exp_bill_type,v_nature_of_bill,v_premium_upto_date,v_rate,v_outstanding_nego_amt);

v_cust_cif_no:=v_cust_id;
  mfx_tf_if_fetch_validation(v_trans_ref_no,trans_type,v_trans_nostroid,v_trans_curr,v_oth_nostroid,v_oth_curr,v_start_date,v_value_date ,v_maturity_date,v_cust_id,
  v_current_status , v_excess_short ,v_nego_disc ,v_mode_disbusal ,v_record_type ,v_contract_type ,v_trans_amt ,
  v_ready_amt ,v_eefc_trans_curr_amt ,v_eefc_conv_amt ,v_pcfc_trans_curr_amt ,v_pcfc_conv_amt ,v_bal_amt,v_bal_amt,v_branch_code,
  a_branch_code ,v_base_rate,v_spread,v_gross_rate,a_user_id  ,v_cust_charges_acc_no ,v_exp_bill_type ,v_nature_of_bill  , v_premium_upto_date,v_rate ,v_conv_curr ,v_conv_corr ,v_interest_fcy,v_amt_realised,
  v_outstanding_nego_amt,tmp_err_code,tmp_err_msg);

IF(tmp_err_code='00') THEN
    mfx_tf_conv_curr_corr(trans_type,v_trans_curr,v_oth_curr,v_trans_nostroid,v_oth_nostroid,v_conv_curr,v_conv_corr);
    Dbms_Output.put_line('v_outstanding_nego_amt===>'||v_outstanding_nego_amt);
    INSERT INTO mfx_tf_data(TF_ID,trans_ref_no,trans_type_code,fetch_time,cust_id,trans_curr,trans_amt,eefc_trans_curr_amt,eefc_conv_amt,
    oth_curr,ready_amt,nego_start_date,nostro_real_date,maturity_date,current_status,excess_short,trans_nostroid,oth_nostroid,amt_realised,branch_code,buy_sell,INR_nostroid,branch_user_id,conv_curr,conv_corr,value_date,exp_bill_type,nature_of_bill,premium_upto_date,rate,start_date,outstanding_nego_amt)
    values ( V_ID,v_trans_ref_no,trans_type,SYSDATE,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,
    v_ready_amt,v_nego_start_date,v_nostro_real_date,v_maturity_date,v_current_status,v_excess_short,v_trans_nostroid,v_oth_nostroid,v_amt_realised,v_branch_code,v_buy_sell,'OVRAC',a_user_id,v_conv_curr,v_conv_corr,v_value_date,v_exp_bill_type,v_nature_of_bill,v_premium_upto_date,v_rate,v_start_date,v_outstanding_nego_amt);
END IF;

WHEN trans_type='BSR' Then  Dbms_Output.put_line('Export bill Short Realization');
/* Changes for ver1.7
mercury_exim_fetch_EXPNEGOPYMT(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,v_ready_amt,v_nego_start_date,v_nostro_real_date,v_maturity_date,v_current_status,
v_excess_short,v_trans_nostroid,v_oth_nostroid,v_amt_realised,v_branch_code,v_exp_bill_type,v_nature_of_bill,v_premium_upto_date,v_rate);
*/
Dbms_Output.put_line('START 23');
IF v_mig_bank='SBH' THEN
Dbms_Output.put_line('SBH');
--mercury_exim_sbh.fetch_EXPNEGOPYMT(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,v_ready_amt,v_nego_start_date,
--v_nostro_real_date,v_maturity_date,v_current_status,
--v_excess_short,v_trans_nostroid,v_oth_nostroid,v_amt_realised,v_branch_code,v_exp_bill_type,v_nature_of_bill,v_premium_upto_date,v_rate,v_outstanding_nego_amt);
ELSIF v_mig_bank='SBBJ' THEN
Dbms_Output.put_line('SBBJ');
--mercury_exim_sbbj.fetch_EXPNEGOPYMT(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,v_ready_amt,v_nego_start_date,
--v_nostro_real_date,v_maturity_date,v_current_status,
--v_excess_short,v_trans_nostroid,v_oth_nostroid,v_amt_realised,v_branch_code,v_exp_bill_type,v_nature_of_bill,v_premium_upto_date,v_rate,v_outstanding_nego_amt);
ELSIF v_mig_bank='SBT' THEN
Dbms_Output.put_line('SBT');
--mercury_exim_sbt.fetch_EXPNEGOPYMT(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,v_ready_amt,v_nego_start_date,
--v_nostro_real_date,v_maturity_date,v_current_status,
--v_excess_short,v_trans_nostroid,v_oth_nostroid,v_amt_realised,v_branch_code,v_exp_bill_type,v_nature_of_bill,v_premium_upto_date,v_rate,v_outstanding_nego_amt);
ELSIF v_mig_bank='SBP' THEN
Dbms_Output.put_line('SBP');
--mercury_exim_sbp.fetch_EXPNEGOPYMT(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,v_ready_amt,v_nego_start_date,
--v_nostro_real_date,v_maturity_date,v_current_status,
--v_excess_short,v_trans_nostroid,v_oth_nostroid,v_amt_realised,v_branch_code,v_exp_bill_type,v_nature_of_bill,v_premium_upto_date,v_rate,v_outstanding_nego_amt);
ELSIF v_mig_bank='SBM' THEN
Dbms_Output.put_line('SBM');
--mercury_exim_sbm.fetch_EXPNEGOPYMT(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,v_ready_amt,v_nego_start_date,
--v_nostro_real_date,v_maturity_date,v_current_status,
--v_excess_short,v_trans_nostroid,v_oth_nostroid,v_amt_realised,v_branch_code,v_exp_bill_type,v_nature_of_bill,v_premium_upto_date,v_rate,v_outstanding_nego_amt);
ELSE
Dbms_Output.put_line('SBI');
--mercury_exim_fetch_EXPNEGOPYMT(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,v_ready_amt,v_nego_start_date,
--v_nostro_real_date,v_maturity_date,v_current_status,
--v_excess_short,v_trans_nostroid,v_oth_nostroid,v_amt_realised,v_branch_code,v_exp_bill_type,v_nature_of_bill,v_premium_upto_date,v_rate,v_outstanding_nego_amt);
END IF;
Dbms_Output.put_line('END 23');

--poc
add_bsr_dataforpoc(v_trans_ref_no);

--Jitesh : 01.02.2012 : Log to maintain data received from Trade Finance.
--INSERT INTO mfx_tf_raw_data(trans_ref_no,trans_type_code,fetch_time,cust_id,trans_curr,trans_amt,eefc_trans_curr_amt,eefc_conv_amt,oth_curr,ready_amt,nego_start_date,
--nostro_real_date,maturity_date,current_status,excess_short,trans_nostroid,oth_nostroid,amt_realised,branch_code,
--exp_bill_type,nature_of_bill,premium_upto_date,rate,outstanding_nego_amt)
--values (v_trans_ref_no,trans_type,SYSDATE,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,v_ready_amt,v_nego_start_date,
--v_nostro_real_date,v_maturity_date,v_current_status,v_excess_short,v_trans_nostroid,v_oth_nostroid,v_amt_realised,v_branch_code,
--v_exp_bill_type,v_nature_of_bill,v_premium_upto_date,v_rate,v_outstanding_nego_amt);

SELECT
    trans_ref_no,cust_id,trans_curr,trans_amt,eefc_trans_curr_amt,eefc_conv_amt,oth_curr,ready_amt,nego_start_date,
    nostro_real_date,maturity_date,current_status,
    excess_short,trans_nostroid,oth_nostroid,amt_realised,branch_code,exp_bill_type,nature_of_bill,premium_upto_date,rate,outstanding_nego_amt
  INTO
    v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,v_ready_amt,v_nego_start_date,
    v_nostro_real_date,v_maturity_date,v_current_status,
    v_excess_short,v_trans_nostroid,v_oth_nostroid,v_amt_realised,v_branch_code,v_exp_bill_type,v_nature_of_bill,v_premium_upto_date,v_rate,v_outstanding_nego_amt
FROM  MFX_TF_RAW_DATA
WHERE TRANS_REF_NO=v_trans_ref_no AND trans_type_code='BSR';

v_cust_cif_no:=v_cust_id;
Dbms_Output.Put_Line('v_current_status :'||v_current_status);
Dbms_Output.Put_Line('v_trans_amt :'||v_trans_amt);
Dbms_Output.Put_Line('v_amt_realised :'||v_amt_realised);

  mfx_tf_if_fetch_validation(v_trans_ref_no,trans_type,v_trans_nostroid,v_trans_curr,v_oth_nostroid,v_oth_curr,v_start_date,v_value_date ,v_maturity_date,v_cust_id,
  v_current_status , v_excess_short ,v_nego_disc ,v_mode_disbusal ,v_record_type ,v_contract_type ,v_trans_amt ,
  v_ready_amt ,v_eefc_trans_curr_amt ,v_eefc_conv_amt ,v_pcfc_trans_curr_amt ,v_pcfc_conv_amt ,v_bal_amt,v_bal_amt,v_branch_code,
  a_branch_code ,v_base_rate,v_spread,v_gross_rate,a_user_id  ,v_cust_charges_acc_no ,v_exp_bill_type ,v_nature_of_bill  , v_premium_upto_date,v_rate ,v_conv_curr ,v_conv_corr ,v_interest_fcy,v_amt_realised,
  v_outstanding_nego_amt,tmp_err_code,tmp_err_msg);
IF(tmp_err_code='00') THEN
  mfx_tf_conv_curr_corr(trans_type,v_trans_curr,v_oth_curr,v_trans_nostroid,v_oth_nostroid,v_conv_curr,v_conv_corr);
  /* Changes for ver1.7
  INSERT INTO mfx_tf_data(TF_ID,trans_ref_no,trans_type_code,fetch_time,cust_id,trans_curr,trans_amt,eefc_trans_curr_amt,eefc_conv_amt,oth_curr,ready_amt,nego_start_date,nostro_real_date,maturity_date,current_status,excess_short,trans_nostroid,oth_nostroid,amt_realised,branch_code,buy_sell,INR_nostroid,branch_user_id,conv_curr,conv_corr,value_date,exp_bill_type,nature_of_bill,premium_upto_date,rate,start_date)
  values ( V_ID,v_trans_ref_no,trans_type,SYSDATE,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,v_ready_amt,v_nego_start_date,v_nostro_real_date,v_maturity_date,v_current_status,v_excess_short,v_trans_nostroid,v_oth_nostroid,v_amt_realised,v_branch_code,v_buy_sell,'OVRAC',a_user_id,v_conv_curr,v_conv_corr,v_value_date,v_exp_bill_type,v_nature_of_bill,v_premium_upto_date,v_rate,v_start_date);

  */
  INSERT INTO mfx_tf_data(TF_ID,trans_ref_no,trans_type_code,fetch_time,cust_id,trans_curr,trans_amt,eefc_trans_curr_amt,eefc_conv_amt,oth_curr,ready_amt,nego_start_date,nostro_real_date,maturity_date,current_status,excess_short,trans_nostroid,oth_nostroid,amt_realised,branch_code,buy_sell,INR_nostroid,branch_user_id,conv_curr,conv_corr,value_date,exp_bill_type,nature_of_bill,premium_upto_date,rate,start_date,outstanding_nego_amt)
  values ( V_ID,v_trans_ref_no,trans_type,SYSDATE,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,v_ready_amt,v_nego_start_date,v_nostro_real_date,v_maturity_date,v_current_status,v_excess_short,v_trans_nostroid,v_oth_nostroid,v_amt_realised,v_branch_code,v_buy_sell,'OVRAC',a_user_id,v_conv_curr,v_conv_corr,v_value_date,v_exp_bill_type,v_nature_of_bill,v_premium_upto_date,v_rate,v_start_date,v_outstanding_nego_amt);

END IF;

WHEN trans_type='EER' Then  Dbms_Output.put_line('EBR Bill Excess Realization');
/* Changes for ver1.6
mercury_exim_fetch_EBRPYMT(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,v_ready_amt,v_nego_start_date,v_nostro_real_date,v_maturity_date,v_current_status,v_excess_short,v_trans_nostroid,v_oth_nostroid,v_amt_realised,v_base_rate,v_spread,v_gross_rate,v_branch_code,v_interest_fcy,v_exp_bill_type,v_nature_of_bill);
Changes for ver1.6 */
Dbms_Output.put_line('start 24');
IF v_mig_bank='SBH' THEN
Dbms_Output.put_line('SBH');
--mercury_exim_sbh.fetch_EBRPYMT(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,v_ready_amt,v_nego_start_date,v_nostro_real_date,v_maturity_date,v_current_status,v_excess_short,v_trans_nostroid,v_oth_nostroid,v_amt_realised,v_base_rate,v_spread,v_gross_rate,v_branch_code,v_interest_fcy,v_exp_bill_type,v_nature_of_bill,v_outstanding_nego_amt);
ELSIF v_mig_bank='SBBJ' THEN
Dbms_Output.put_line('SBBJ');
--mercury_exim_sbbj.fetch_EBRPYMT(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,v_ready_amt,v_nego_start_date,v_nostro_real_date,v_maturity_date,v_current_status,v_excess_short,v_trans_nostroid,v_oth_nostroid,v_amt_realised,v_base_rate,v_spread,v_gross_rate,v_branch_code,v_interest_fcy,v_exp_bill_type,v_nature_of_bill,v_outstanding_nego_amt);
ELSIF v_mig_bank='SBT' THEN
Dbms_Output.put_line('SBT');
--mercury_exim_sbt.fetch_EBRPYMT(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,v_ready_amt,v_nego_start_date,v_nostro_real_date,v_maturity_date,v_current_status,v_excess_short,v_trans_nostroid,v_oth_nostroid,v_amt_realised,v_base_rate,v_spread,v_gross_rate,v_branch_code,v_interest_fcy,v_exp_bill_type,v_nature_of_bill,v_outstanding_nego_amt);
ELSIF v_mig_bank='SBP' THEN
Dbms_Output.put_line('SBP');
--mercury_exim_sbp.fetch_EBRPYMT(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,v_ready_amt,v_nego_start_date,v_nostro_real_date,v_maturity_date,v_current_status,v_excess_short,v_trans_nostroid,v_oth_nostroid,v_amt_realised,v_base_rate,v_spread,v_gross_rate,v_branch_code,v_interest_fcy,v_exp_bill_type,v_nature_of_bill,v_outstanding_nego_amt);
ELSIF v_mig_bank='SBM' THEN
Dbms_Output.put_line('SBM');
--mercury_exim_sbm.fetch_EBRPYMT(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,v_ready_amt,v_nego_start_date,v_nostro_real_date,v_maturity_date,v_current_status,v_excess_short,v_trans_nostroid,v_oth_nostroid,v_amt_realised,v_base_rate,v_spread,v_gross_rate,v_branch_code,v_interest_fcy,v_exp_bill_type,v_nature_of_bill,v_outstanding_nego_amt);
ELSE
Dbms_Output.put_line('SBI');
mercury_exim_fetch_EBRPYMT(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,v_ready_amt,v_nego_start_date,v_nostro_real_date,v_maturity_date,v_current_status,v_excess_short,v_trans_nostroid,v_oth_nostroid,v_amt_realised,v_base_rate,v_spread,v_gross_rate,v_branch_code,v_interest_fcy,v_exp_bill_type,v_nature_of_bill,v_outstanding_nego_amt);
END IF ;
Dbms_Output.put_line('end 24');

  --Jitesh : 13.04.2012 : Log to maintain data received from Trade Finance.
  INSERT INTO MFX_TF_RAW_DATA(trans_ref_no,trans_type_code,fetch_time,cust_id,trans_curr,trans_amt,eefc_trans_curr_amt,eefc_conv_amt,oth_curr,ready_amt,nego_start_date,nostro_real_date,
  maturity_date,current_status,excess_short,trans_nostroid,oth_nostroid,amt_realised,base_rate,spread,gross_rate,branch_code,interest_fcy,exp_bill_type,nature_of_bill,outstanding_nego_amt)
  VALUES(v_trans_ref_no,trans_type,SYSDATE,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,v_ready_amt,v_nego_start_date,v_nostro_real_date,
  v_maturity_date,v_current_status,v_excess_short,v_trans_nostroid,v_oth_nostroid,v_amt_realised,v_base_rate,v_spread,v_gross_rate,v_branch_code,v_interest_fcy,v_exp_bill_type,
  v_nature_of_bill,v_outstanding_nego_amt);

v_cust_cif_no:=v_cust_id;
  mfx_tf_if_fetch_validation(v_trans_ref_no,trans_type,v_trans_nostroid,v_trans_curr,v_oth_nostroid,v_oth_curr,v_start_date,v_value_date ,v_maturity_date,v_cust_id,
  v_current_status , v_excess_short ,v_nego_disc ,v_mode_disbusal ,v_record_type ,v_contract_type ,v_trans_amt ,
  v_ready_amt ,v_eefc_trans_curr_amt ,v_eefc_conv_amt ,v_pcfc_trans_curr_amt ,v_pcfc_conv_amt ,v_bal_amt,v_bal_amt,v_branch_code,
  a_branch_code ,v_base_rate,v_spread,v_gross_rate,a_user_id  ,v_cust_charges_acc_no ,v_exp_bill_type ,v_nature_of_bill  , v_premium_upto_date,v_rate ,v_conv_curr ,v_conv_corr ,v_interest_fcy,v_amt_realised,
  v_outstanding_nego_amt,tmp_err_code,tmp_err_msg);
IF(tmp_err_code='00') THEN
    mfx_tf_conv_curr_corr(trans_type,v_trans_curr,v_oth_curr,v_trans_nostroid,v_oth_nostroid,v_conv_curr,v_conv_corr);
    /*
    INSERT INTO mfx_tf_data(TF_ID,trans_ref_no,trans_type_code,fetch_time,cust_id,trans_curr,trans_amt,eefc_trans_curr_amt,eefc_conv_amt,oth_curr,ready_amt,nego_start_date,nostro_real_date,maturity_date,current_status,excess_short,trans_nostroid,oth_nostroid,amt_realised,base_rate,spread,gross_rate,branch_code,buy_sell,INR_nostroid,branch_user_id,conv_curr,conv_corr,interest_fcy,value_date,exp_bill_type,nature_of_bill)
    VALUES(V_ID,v_trans_ref_no,trans_type,SYSDATE,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,v_ready_amt,v_nego_start_date,v_nostro_real_date,v_maturity_date,v_current_status,v_excess_short,v_trans_nostroid,v_oth_nostroid,v_amt_realised,v_base_rate,v_spread,v_gross_rate,v_branch_code,v_buy_sell,'OVRAC',
  a_user_id,v_conv_curr,v_conv_corr,v_interest_fcy,v_value_date,v_exp_bill_type,v_nature_of_bill);
  */
  /* Changes for ver1.7 */
  INSERT INTO mfx_tf_data(TF_ID,trans_ref_no,trans_type_code,fetch_time,cust_id,trans_curr,trans_amt,eefc_trans_curr_amt,eefc_conv_amt,oth_curr,ready_amt,nego_start_date,nostro_real_date,maturity_date,current_status,excess_short,trans_nostroid,oth_nostroid,amt_realised,base_rate,spread,gross_rate,branch_code,buy_sell,INR_nostroid,branch_user_id,conv_curr,conv_corr,interest_fcy,value_date,exp_bill_type,nature_of_bill,outstanding_nego_amt)
    VALUES(V_ID,v_trans_ref_no,trans_type,SYSDATE,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,v_ready_amt,v_nego_start_date,v_nostro_real_date,v_maturity_date,v_current_status,v_excess_short,v_trans_nostroid,v_oth_nostroid,v_amt_realised,v_base_rate,v_spread,v_gross_rate,v_branch_code,v_buy_sell,'OVRAC',
    a_user_id,v_conv_curr,v_conv_corr,v_interest_fcy,v_value_date,v_exp_bill_type,v_nature_of_bill,v_outstanding_nego_amt);
  /*Changes for ver1.7 */
END IF;

WHEN trans_type='ESR' Then  Dbms_Output.put_line('EBR Bill Short Realization');
/* Changes for ver1.7
mercury_exim_fetch_EBRPYMT(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,v_ready_amt,v_nego_start_date,v_nostro_real_date,v_maturity_date,v_current_status,v_excess_short,v_trans_nostroid,v_oth_nostroid,v_amt_realised,v_base_rate,v_spread,v_gross_rate,v_branch_code,
v_interest_fcy,v_exp_bill_type,v_nature_of_bill);
Changes for ver1.7 */
Dbms_Output.put_line('start 25');
IF v_mig_bank='SBH' THEN
Dbms_Output.put_line('SBH');
--mercury_exim_sbh.fetch_EBRPYMT(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,v_ready_amt,v_nego_start_date,v_nostro_real_date,v_maturity_date,v_current_status,v_excess_short,v_trans_nostroid,v_oth_nostroid,v_amt_realised,v_base_rate,v_spread,v_gross_rate,v_branch_code,
--v_interest_fcy,v_exp_bill_type,v_nature_of_bill,v_outstanding_nego_amt);
ELSIF v_mig_bank='SBBJ' THEN
Dbms_Output.put_line('SBBJ');
--mercury_exim_sbbj.fetch_EBRPYMT(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,v_ready_amt,v_nego_start_date,v_nostro_real_date,v_maturity_date,v_current_status,v_excess_short,v_trans_nostroid,v_oth_nostroid,v_amt_realised,v_base_rate,v_spread,v_gross_rate,v_branch_code,
--v_interest_fcy,v_exp_bill_type,v_nature_of_bill,v_outstanding_nego_amt);
ELSIF v_mig_bank='SBT' THEN
Dbms_Output.put_line('SBT');
--mercury_exim_sbt.fetch_EBRPYMT(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,v_ready_amt,v_nego_start_date,v_nostro_real_date,v_maturity_date,v_current_status,v_excess_short,v_trans_nostroid,v_oth_nostroid,v_amt_realised,v_base_rate,v_spread,v_gross_rate,v_branch_code,
--v_interest_fcy,v_exp_bill_type,v_nature_of_bill,v_outstanding_nego_amt);
ELSIF v_mig_bank='SBP' THEN
Dbms_Output.put_line('SBP');
--mercury_exim_sbp.fetch_EBRPYMT(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,v_ready_amt,v_nego_start_date,v_nostro_real_date,v_maturity_date,v_current_status,v_excess_short,v_trans_nostroid,v_oth_nostroid,v_amt_realised,v_base_rate,v_spread,v_gross_rate,v_branch_code,
--v_interest_fcy,v_exp_bill_type,v_nature_of_bill,v_outstanding_nego_amt);
ELSIF v_mig_bank='SBM' THEN
Dbms_Output.put_line('SBM');
--mercury_exim_sbm.fetch_EBRPYMT(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,v_ready_amt,v_nego_start_date,v_nostro_real_date,v_maturity_date,v_current_status,v_excess_short,v_trans_nostroid,v_oth_nostroid,v_amt_realised,v_base_rate,v_spread,v_gross_rate,v_branch_code,
--v_interest_fcy,v_exp_bill_type,v_nature_of_bill,v_outstanding_nego_amt);
ELSE
Dbms_Output.put_line('SBI');
mercury_exim_fetch_EBRPYMT(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,v_ready_amt,v_nego_start_date,v_nostro_real_date,v_maturity_date,v_current_status,v_excess_short,v_trans_nostroid,v_oth_nostroid,v_amt_realised,v_base_rate,v_spread,v_gross_rate,v_branch_code,
v_interest_fcy,v_exp_bill_type,v_nature_of_bill,v_outstanding_nego_amt);
END IF;
Dbms_Output.put_line('END 24');

  --Jitesh : 13.04.2012 : Log to maintain data received from Trade Finance.
  INSERT INTO MFX_TF_RAW_DATA(trans_ref_no,trans_type_code,fetch_time,cust_id,trans_curr,trans_amt,eefc_trans_curr_amt,eefc_conv_amt,oth_curr,ready_amt,nego_start_date,nostro_real_date,
  maturity_date,current_status,excess_short,trans_nostroid,oth_nostroid,amt_realised,base_rate,spread,gross_rate,branch_code,interest_fcy,exp_bill_type,nature_of_bill,outstanding_nego_amt)
  VALUES(v_trans_ref_no,trans_type,SYSDATE,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,v_ready_amt,v_nego_start_date,v_nostro_real_date,
  v_maturity_date,v_current_status,v_excess_short,v_trans_nostroid,v_oth_nostroid,v_amt_realised,v_base_rate,v_spread,v_gross_rate,v_branch_code,v_interest_fcy,v_exp_bill_type,
  v_nature_of_bill,v_outstanding_nego_amt);


v_cust_cif_no:=v_cust_id;
  mfx_tf_if_fetch_validation(v_trans_ref_no,trans_type,v_trans_nostroid,v_trans_curr,v_oth_nostroid,v_oth_curr,v_start_date,v_value_date ,v_maturity_date,v_cust_id,
  v_current_status , v_excess_short ,v_nego_disc ,v_mode_disbusal ,v_record_type ,v_contract_type ,v_trans_amt ,
  v_ready_amt ,v_eefc_trans_curr_amt ,v_eefc_conv_amt ,v_pcfc_trans_curr_amt ,v_pcfc_conv_amt ,v_bal_amt,v_bal_amt,v_branch_code,
  a_branch_code ,v_base_rate,v_spread,v_gross_rate,a_user_id  ,v_cust_charges_acc_no ,v_exp_bill_type ,v_nature_of_bill  , v_premium_upto_date,v_rate ,v_conv_curr ,v_conv_corr ,v_interest_fcy,v_amt_realised,
  v_outstanding_nego_amt,tmp_err_code,tmp_err_msg);
IF(tmp_err_code='00') THEN

    mfx_tf_conv_curr_corr(trans_type,v_trans_curr,v_oth_curr,v_trans_nostroid,v_oth_nostroid,v_conv_curr,v_conv_corr);
    /*
    INSERT INTO mfx_tf_data(TF_ID,trans_ref_no,trans_type_code,fetch_time,cust_id,trans_curr,trans_amt,eefc_trans_curr_amt,eefc_conv_amt,oth_curr,ready_amt,nego_start_date,nostro_real_date,maturity_date,current_status,excess_short,trans_nostroid,oth_nostroid,amt_realised,base_rate,spread,gross_rate,branch_code,buy_sell,INR_nostroid,branch_user_id,conv_curr,conv_corr,interest_fcy,value_date,exp_bill_type,nature_of_bill)
    VALUES(V_ID,v_trans_ref_no,trans_type,SYSDATE,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,v_ready_amt,v_nego_start_date,v_nostro_real_date,v_maturity_date,v_current_status,v_excess_short,v_trans_nostroid,v_oth_nostroid,v_amt_realised,v_base_rate,v_spread,v_gross_rate,v_branch_code,v_buy_sell,'OVRAC',a_user_id,v_conv_curr,v_conv_corr,v_interest_fcy
    ,v_value_date,v_exp_bill_type,v_nature_of_bill);
    */

    /* Changes for ver1.7 */
      INSERT INTO mfx_tf_data(TF_ID,trans_ref_no,trans_type_code,fetch_time,cust_id,trans_curr,trans_amt,eefc_trans_curr_amt,eefc_conv_amt,oth_curr,ready_amt,nego_start_date,nostro_real_date,maturity_date,current_status,excess_short,trans_nostroid,oth_nostroid,amt_realised,base_rate,spread,gross_rate,branch_code,buy_sell,INR_nostroid,branch_user_id,conv_curr,conv_corr,interest_fcy,value_date,exp_bill_type,nature_of_bill,outstanding_nego_amt)
      VALUES(V_ID,v_trans_ref_no,trans_type,SYSDATE,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_oth_curr,v_ready_amt,v_nego_start_date,v_nostro_real_date,v_maturity_date,v_current_status,v_excess_short,v_trans_nostroid,v_oth_nostroid,v_amt_realised,v_base_rate,v_spread,v_gross_rate,v_branch_code,v_buy_sell,'OVRAC',a_user_id,v_conv_curr,v_conv_corr,v_interest_fcy
      ,v_value_date,v_exp_bill_type,v_nature_of_bill,v_outstanding_nego_amt);
    /*Changes for ver1.7 */
END IF;

WHEN trans_type='FSC' Then  Dbms_Output.put_line('Forward Sale Cancellation');
-- Jitesh : 17.01.2012 : v4.0.0.116 : Forward Cancellation Gain changes.
--mercury_exim_fetch_FCCANCEL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_value_date,v_contract_type,v_start_date,
--v_maturity_date, v_record_type,v_rate,v_ready_rupee_eqvt,v_mtrans_no,v_branch_code,v_bal_amt,v_cust_charges_acc_no);
-- Office : 20.09.2012 : v4.0.0.147 : DE15
-- Office : 29.10.2012 : v4.0.0.151 : Send MTM and PFE account number from exim to murex
Dbms_Output.put_line('start 25');
IF v_mig_bank='SBH' THEN
Dbms_Output.put_line('SBH');
--mercury_exim_sbh.fetch_FCCANCEL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_value_date,v_contract_type,v_start_date,
--v_maturity_date, v_record_type,v_rate,v_ready_rupee_eqvt,v_mtrans_no,v_branch_code,v_bal_amt,v_cust_charges_acc_no,v_customer_liability_type,v_doc_submit_date,v_mtm_account,v_pfe_account);
ELSIF v_mig_bank='SBBJ' THEN
Dbms_Output.put_line('SBBJ');
--mercury_exim_sbbj.fetch_FCCANCEL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_value_date,v_contract_type,v_start_date,
--v_maturity_date, v_record_type,v_rate,v_ready_rupee_eqvt,v_mtrans_no,v_branch_code,v_bal_amt,v_cust_charges_acc_no,v_customer_liability_type,v_doc_submit_date,v_mtm_account,v_pfe_account);
ELSIF v_mig_bank='SBT' THEN
Dbms_Output.put_line('SBT');
--mercury_exim_sbt.fetch_FCCANCEL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_value_date,v_contract_type,v_start_date,
--v_maturity_date, v_record_type,v_rate,v_ready_rupee_eqvt,v_mtrans_no,v_branch_code,v_bal_amt,v_cust_charges_acc_no,v_customer_liability_type,v_doc_submit_date,v_mtm_account,v_pfe_account);
ELSIF v_mig_bank='SBP' THEN
Dbms_Output.put_line('SBP');
--mercury_exim_sbp.fetch_FCCANCEL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_value_date,v_contract_type,v_start_date,
--v_maturity_date, v_record_type,v_rate,v_ready_rupee_eqvt,v_mtrans_no,v_branch_code,v_bal_amt,v_cust_charges_acc_no,v_customer_liability_type,v_doc_submit_date,v_mtm_account,v_pfe_account);
ELSIF v_mig_bank='SBM' THEN
Dbms_Output.put_line('SBM');
--mercury_exim_sbm.fetch_FCCANCEL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_value_date,v_contract_type,v_start_date,
--v_maturity_date, v_record_type,v_rate,v_ready_rupee_eqvt,v_mtrans_no,v_branch_code,v_bal_amt,v_cust_charges_acc_no,v_customer_liability_type,v_doc_submit_date,v_mtm_account,v_pfe_account);
ELSE
Dbms_Output.put_line('SBI');
mercury_exim_fetch_FCCANCEL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_value_date,v_contract_type,v_start_date,
v_maturity_date, v_record_type,v_rate,v_ready_rupee_eqvt,v_mtrans_no,v_branch_code,v_bal_amt,v_cust_charges_acc_no,v_customer_liability_type,v_doc_submit_date,v_mtm_account,v_pfe_account);
END IF ;
Dbms_Output.put_line('END 25');
--v_trans_type VARCHAR2(50);
--v_trans_type:=trans_type;

--SELECT  TRANS_REF_NO,CUST_ID,TRANS_CURR,TRANS_AMT,OTH_CURR,VALUE_DATE,CONTRACT_TYPE,START_DATE,MATURITY_DATE,RECORD_TYPE,rate,ready_rupee_eqvt,mtrans_no,
--branch_code,bal_amt,cust_charges_acc_no,customer_liability,doc_submit_date,mtm_account,pfe_account INTO
--v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_value_date,v_contract_type,
--v_start_date,v_maturity_date, v_record_type,v_rate,v_ready_rupee_eqvt,v_mtrans_no,v_branch_code,
--v_bal_amt,v_cust_charges_acc_no,v_customer_liability_type,v_doc_submit_date,v_mtm_account,v_pfe_account FROM  MFX_TF_RAW_DATA
--WHERE TRANS_REF_NO='1637618FS0074500';
--Jitesh : 01.02.2012 : Log to maintain data received from Trade Finance.
--INSERT INTO MFX_TF_RAW_DATA (TRANS_REF_NO,CUST_ID,TRANS_CURR,TRANS_AMT,OTH_CURR,VALUE_DATE,CONTRACT_TYPE,START_DATE,MATURITY_DATE,RECORD_TYPE,rate,ready_rupee_eqvt,mtrans_no,
--branch_code,bal_amt,cust_charges_acc_no,customer_liability,trans_type_code,fetch_time,doc_submit_date,mtm_account,pfe_account)
--VALUES (v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_value_date,v_contract_type,
--v_start_date,v_maturity_date, v_record_type,v_rate,v_ready_rupee_eqvt,v_mtrans_no,v_branch_code,
--v_bal_amt,v_cust_charges_acc_no,v_customer_liability_type,trans_type,sysdate,v_doc_submit_date,v_mtm_account,v_pfe_account);
SELECT  TRANS_REF_NO,CUST_ID,TRANS_CURR,TRANS_AMT,OTH_CURR,VALUE_DATE,CONTRACT_TYPE,START_DATE,MATURITY_DATE,RECORD_TYPE,rate,ready_rupee_eqvt,mtrans_no,
branch_code,bal_amt,cust_charges_acc_no,customer_liability,doc_submit_date,mtm_account,pfe_account INTO
v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_value_date,v_contract_type,
v_start_date,v_maturity_date, v_record_type,v_rate,v_ready_rupee_eqvt,v_mtrans_no,v_branch_code,
v_bal_amt,v_cust_charges_acc_no,v_customer_liability_type,v_doc_submit_date,v_mtm_account,v_pfe_account FROM  MFX_TF_RAW_DATA
WHERE TRANS_REF_NO='0999520FS0000188' AND trans_type_code = 'FSC';



v_cust_cif_no:=v_cust_id;
  mfx_tf_if_fetch_validation(v_trans_ref_no,trans_type,v_trans_nostroid,v_trans_curr,v_oth_nostroid,v_oth_curr,v_start_date,v_value_date,v_maturity_date,v_cust_id,
  v_current_status , v_excess_short ,v_nego_disc ,v_mode_disbusal ,v_record_type ,v_contract_type ,v_trans_amt ,
  v_ready_amt ,v_eefc_trans_curr_amt ,v_eefc_conv_amt ,v_pcfc_trans_curr_amt ,v_pcfc_conv_amt ,v_bal_amt,v_trans_amt,v_branch_code,
  a_branch_code ,v_base_rate,v_spread,v_gross_rate,a_user_id  ,v_cust_charges_acc_no ,v_exp_bill_type ,v_nature_of_bill  , v_premium_upto_date,v_rate ,v_conv_curr ,v_conv_corr ,v_interest_fcy,v_amt_realised,
  v_outstanding_nego_amt,tmp_err_code,tmp_err_msg);

  -- Jitesh : 17.01.2012 : v4.0.0.116 : Forward Cancellation Gain changes.

  v_rollover:='N';

  SELECT mfx_tf_fwd_liab_flag(v_customer_liability_type) INTO v_customer_liability_type FROM DUAL;
  IF v_customer_liability_type='NA' THEN
    tmp_err_code:='01';
    tmp_err_msg:='Customer Liability Type can be 1 (PP) or 2 (DE) or 3 (DE15) or 4 (CE15) or 5 (AE) or 6 (CE) only. Please Check with Trade Finance';
  END IF;

--  IF v_customer_liability_type=1 THEN
--      v_customer_liability_type:='PP';
--  ELSE
--    IF v_customer_liability_type=2 THEN
--      v_customer_liability_type:='DE';
--    ELSE
--      IF v_customer_liability_type=3 THEN
--      v_customer_liability_type:='DE15';
--        ELSE
--        tmp_err_code:='01';
--        tmp_err_msg:='Customer Liability Type can be 1 (Past Performance) or 2 (Dcoumentary Evidence) or 3 (Dcoumentary Evidence 15 days) only. Please Check with Trade Finance';
--      END IF;
--    END IF;
--  END IF;

IF(tmp_err_code='00') THEN
  mfx_tf_conv_curr_corr(trans_type,v_trans_curr,v_oth_curr,v_trans_nostroid,v_oth_nostroid,v_conv_curr,v_conv_corr);
  -- Jitesh : 17.01.2012 : v4.0.0.116 : Forward Cancellation Gain changes.
--  INSERT INTO mfx_tf_data(TF_ID,trans_ref_no,fetch_time,trans_type_code,cust_id,trans_curr,trans_amt,ready_amt,oth_curr,value_date,record_type,
--  start_date,maturity_date,contract_type,rate,ready_rupee_eqvt,mtrans_no,branch_code,buy_sell,trans_nostroid,oth_nostroid,INR_nostroid,branch_user_id,
--  conv_curr,conv_corr,bal_amt,cust_charges_acc_no)
--  VALUES(V_ID,v_trans_ref_no,SYSDATE,trans_type,v_cust_id,v_trans_curr,v_trans_amt,v_trans_amt,v_oth_curr,v_value_date,v_record_type,
--  v_start_date,v_maturity_date,v_contract_type,v_rate,v_ready_rupee_eqvt,v_mtrans_no,v_branch_code,v_buy_sell,v_trans_nostroid,v_oth_nostroid,'OVRAC',a_user_id,
--  v_conv_curr,v_conv_corr,v_bal_amt,v_cust_charges_acc_no);
-- Office : 20.09.2012 : v4.0.0.147 : DE15
-- Office : 29.10.2012 : v4.0.0.151 : Send MTM and PFE account number from exim to murex
 Dbms_Output.Put_Line('doc_submit_date'||v_customer_liability_type||':'||v_doc_submit_date);

  INSERT INTO mfx_tf_data(TF_ID,trans_ref_no,fetch_time,trans_type_code,cust_id,trans_curr,trans_amt,ready_amt,oth_curr,value_date,record_type,
  start_date,maturity_date,contract_type,rate,ready_rupee_eqvt,mtrans_no,branch_code,buy_sell,trans_nostroid,oth_nostroid,INR_nostroid,branch_user_id,
  conv_curr,conv_corr,bal_amt,cust_charges_acc_no,customer_liability,rollover_flag,doc_submit_date,mtm_account,pfe_account)
  VALUES(V_ID,v_trans_ref_no,SYSDATE,trans_type,v_cust_id,v_trans_curr,v_trans_amt,v_trans_amt,v_oth_curr,v_value_date,v_record_type,
  v_start_date,v_maturity_date,v_contract_type,v_rate,v_ready_rupee_eqvt,v_mtrans_no,v_branch_code,v_buy_sell,v_trans_nostroid,v_oth_nostroid,'OVRAC',a_user_id,
  v_conv_curr,v_conv_corr,v_bal_amt,v_cust_charges_acc_no,v_customer_liability_type,v_rollover,v_doc_submit_date,v_mtm_account,v_pfe_account);
END IF;

WHEN trans_type='FPC' Then  Dbms_Output.put_line('Forward Purchase Cancellation ');
-- Jitesh : 17.01.2012 : v4.0.0.116 : Forward Cancellation Gain changes.
--mercury_exim_fetch_FCCANCEL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_value_date,v_contract_type,
--v_start_date,v_maturity_date, v_record_type,v_rate,v_ready_rupee_eqvt,v_mtrans_no,v_branch_code,
--v_bal_amt,v_cust_charges_acc_no);
-- Office : 20.09.2012 : v4.0.0.147 : DE15
-- Office : 29.10.2012 : v4.0.0.151 : Send MTM and PFE account number from exim to murex
Dbms_Output.put_line('start 26');
IF v_mig_bank='SBH' THEN
Dbms_Output.put_line('SBH');
--mercury_exim_sbh.fetch_FCCANCEL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_value_date,v_contract_type,
--v_start_date,v_maturity_date, v_record_type,v_rate,v_ready_rupee_eqvt,v_mtrans_no,v_branch_code,
--v_bal_amt,v_cust_charges_acc_no,v_customer_liability_type,v_doc_submit_date,v_mtm_account,v_pfe_account);
ELSIF v_mig_bank='SBBJ' THEN
Dbms_Output.put_line('SBBJ');
--mercury_exim_sbbj.fetch_FCCANCEL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_value_date,v_contract_type,
--v_start_date,v_maturity_date, v_record_type,v_rate,v_ready_rupee_eqvt,v_mtrans_no,v_branch_code,
--v_bal_amt,v_cust_charges_acc_no,v_customer_liability_type,v_doc_submit_date,v_mtm_account,v_pfe_account);
ELSIF v_mig_bank='SBT' THEN
Dbms_Output.put_line('SBT');
--mercury_exim_sbt.fetch_FCCANCEL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_value_date,v_contract_type,
--v_start_date,v_maturity_date, v_record_type,v_rate,v_ready_rupee_eqvt,v_mtrans_no,v_branch_code,
--v_bal_amt,v_cust_charges_acc_no,v_customer_liability_type,v_doc_submit_date,v_mtm_account,v_pfe_account);
ELSIF v_mig_bank='SBP' THEN
Dbms_Output.put_line('SBP');
--mercury_exim_sbp.fetch_FCCANCEL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_value_date,v_contract_type,
--v_start_date,v_maturity_date, v_record_type,v_rate,v_ready_rupee_eqvt,v_mtrans_no,v_branch_code,
--v_bal_amt,v_cust_charges_acc_no,v_customer_liability_type,v_doc_submit_date,v_mtm_account,v_pfe_account);
ELSIF v_mig_bank='SBM' THEN
Dbms_Output.put_line('SBM');
--mercury_exim_sbm.fetch_FCCANCEL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_value_date,v_contract_type,
--v_start_date,v_maturity_date, v_record_type,v_rate,v_ready_rupee_eqvt,v_mtrans_no,v_branch_code,
--v_bal_amt,v_cust_charges_acc_no,v_customer_liability_type,v_doc_submit_date,v_mtm_account,v_pfe_account);
ELSE
Dbms_Output.put_line('SBI');
--mercury_exim_fetch_FCCANCEL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_value_date,v_contract_type,
--v_start_date,v_maturity_date, v_record_type,v_rate,v_ready_rupee_eqvt,v_mtrans_no,v_branch_code,
--v_bal_amt,v_cust_charges_acc_no,v_customer_liability_type,v_doc_submit_date,v_mtm_account,v_pfe_account);
END IF;
Dbms_Output.put_line('END 25');
--Jitesh : 01.02.2012 : Log to maintain data received from Trade Finance.
--INSERT INTO MFX_TF_RAW_DATA (TRANS_REF_NO,CUST_ID,TRANS_CURR,TRANS_AMT,OTH_CURR,VALUE_DATE,CONTRACT_TYPE,START_DATE,MATURITY_DATE,RECORD_TYPE,rate,ready_rupee_eqvt,mtrans_no,
--branch_code,bal_amt,cust_charges_acc_no,customer_liability,trans_type_code,fetch_time,doc_submit_date,mtm_account,pfe_account)
--VALUES (v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_value_date,v_contract_type,
--v_start_date,v_maturity_date, v_record_type,v_rate,v_ready_rupee_eqvt,v_mtrans_no,v_branch_code,
--v_bal_amt,v_cust_charges_acc_no,v_customer_liability_type,trans_type,sysdate,v_doc_submit_date,v_mtm_account,v_pfe_account);

SELECT TRANS_REF_NO,CUST_ID,TRANS_CURR,TRANS_AMT,OTH_CURR,VALUE_DATE,CONTRACT_TYPE,START_DATE,MATURITY_DATE,RECORD_TYPE,rate,ready_rupee_eqvt,mtrans_no,
branch_code,bal_amt,cust_charges_acc_no,customer_liability,doc_submit_date,mtm_account,pfe_account INTO
v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_value_date,v_contract_type,
v_start_date,v_maturity_date, v_record_type,v_rate,v_ready_rupee_eqvt,v_mtrans_no,v_branch_code,
v_bal_amt,v_cust_charges_acc_no,v_customer_liability_type,v_doc_submit_date,v_mtm_account,v_pfe_account FROM  MFX_TF_RAW_DATA
WHERE TRANS_REF_NO=v_trans_ref_no AND trans_type_code='FPC';

v_cust_cif_no:=v_cust_id;
  mfx_tf_if_fetch_validation(v_trans_ref_no,trans_type,v_trans_nostroid,v_trans_curr,v_oth_nostroid,v_oth_curr,v_start_date,v_value_date ,v_maturity_date,v_cust_id,
  v_current_status , v_excess_short ,v_nego_disc ,v_mode_disbusal ,v_record_type ,v_contract_type ,v_trans_amt ,
  v_trans_amt ,v_eefc_trans_curr_amt ,v_eefc_conv_amt ,v_pcfc_trans_curr_amt ,v_pcfc_conv_amt ,v_bal_amt,v_trans_amt,v_branch_code,
  a_branch_code ,v_base_rate,v_spread,v_gross_rate,a_user_id  ,v_cust_charges_acc_no ,v_exp_bill_type ,v_nature_of_bill  ,
   v_premium_upto_date,v_rate ,v_conv_curr ,v_conv_corr ,v_interest_fcy,v_amt_realised,v_outstanding_nego_amt,tmp_err_code,tmp_err_msg);

    -- Jitesh : 17.01.2012 : v4.0.0.116 : Forward Cancellation Gain changes.
  v_rollover:='N';
    Dbms_Output.Put_Line('OK : '||v_customer_liability_type||' - '||v_rollover||' : '||tmp_err_code);


    SELECT mfx_tf_fwd_liab_flag(v_customer_liability_type) INTO v_customer_liability_type FROM DUAL;
    IF v_customer_liability_type='NA' THEN
      tmp_err_code:='01';
      tmp_err_msg:='Customer Liability Type can be 1 (PP) or 2 (DE) or 3 (DE15) or 4 (CE15) or 5 (AE) or 6 (CE) only. Please Check with Trade Finance';
    END IF;

--  IF v_customer_liability_type=1 THEN
--      v_customer_liability_type:='PP';
--  ELSE
--    IF v_customer_liability_type=2 THEN
--      v_customer_liability_type:='DE';
--    ELSE
--      IF v_customer_liability_type=3 THEN
--      v_customer_liability_type:='DE15';
--        ELSE
--        tmp_err_code:='01';
--        tmp_err_msg:='Customer Liability Type can be 1 (Past Performance) or 2 (Dcoumentary Evidence) or 3 (Dcoumentary Evidence 15 days) only. Please Check with Trade Finance';
--      END IF;
--    END IF;
--  END IF;

Dbms_Output.Put_Line('FPC - tmp_err_code : '||tmp_err_code);
IF(tmp_err_code='00') THEN
    mfx_tf_conv_curr_corr(trans_type,v_trans_curr,v_oth_curr,v_trans_nostroid,v_oth_nostroid,v_conv_curr,v_conv_corr);

    -- Jitesh : 17.01.2012 : v4.0.0.116 : Forward Cancellation Gain changes.
--    INSERT INTO mfx_tf_data(TF_ID,trans_ref_no,fetch_time,trans_type_code,cust_id,trans_curr,trans_amt,ready_amt,oth_curr,value_date,record_type,
--    start_date,maturity_date,contract_type,rate,ready_rupee_eqvt,mtrans_no,branch_code,buy_sell,trans_nostroid,oth_nostroid,INR_nostroid,branch_user_id,conv_curr,conv_corr,bal_amt,cust_charges_acc_no)
--    VALUES(V_ID,v_trans_ref_no,SYSDATE,trans_type,v_cust_id,v_trans_curr,v_trans_amt,v_trans_amt,v_oth_curr,v_value_date,v_record_type,
--    v_start_date,v_maturity_date,v_contract_type,v_rate,v_ready_rupee_eqvt,v_mtrans_no,v_branch_code,v_buy_sell,v_trans_nostroid,v_oth_nostroid,'OVRAC',a_user_id,v_conv_curr,v_conv_corr,v_bal_amt,v_cust_charges_acc_no);

   Dbms_Output.Put_Line(V_ID||':'||v_trans_ref_no||':'||SYSDATE||':'||trans_type||':'||v_cust_id||':'||v_trans_curr||':'||v_trans_amt||':'||v_trans_amt||':'||v_oth_curr||':'||v_value_date||':'||v_record_type||':'||    v_start_date||':'||v_maturity_date||':'||v_contract_type||':'||v_rate||':'||v_ready_rupee_eqvt||':'||v_mtrans_no||':'||v_branch_code||':'||v_buy_sell||':'||v_trans_nostroid||':'||v_oth_nostroid||':'||'OVRAC'||':'||a_user_id||':'||v_conv_curr||':'||v_conv_corr||':'||v_bal_amt||':'||v_cust_charges_acc_no||':'||v_customer_liability_type||':'||v_rollover);
-- Office : 20.09.2012 : v4.0.0.147 : DE15
-- Office : 29.10.2012 : v4.0.0.151 : Send MTM and PFE account number from exim to murex
  Dbms_Output.Put_Line('doc_submit_date'||v_customer_liability_type||':'||v_doc_submit_date);
    INSERT INTO mfx_tf_data(TF_ID,trans_ref_no,fetch_time,trans_type_code,cust_id,trans_curr,trans_amt,ready_amt,oth_curr,value_date,record_type,
    start_date,maturity_date,contract_type,rate,ready_rupee_eqvt,mtrans_no,branch_code,buy_sell,trans_nostroid,oth_nostroid,INR_nostroid,branch_user_id,conv_curr,conv_corr,bal_amt,cust_charges_acc_no,customer_liability,rollover_flag,doc_submit_date,mtm_account,pfe_account)
    VALUES(V_ID,v_trans_ref_no,SYSDATE,trans_type,v_cust_id,v_trans_curr,v_trans_amt,v_trans_amt,v_oth_curr,v_value_date,v_record_type,
    v_start_date,v_maturity_date,v_contract_type,v_rate,v_ready_rupee_eqvt,v_mtrans_no,v_branch_code,v_buy_sell,v_trans_nostroid,v_oth_nostroid,'OVRAC',a_user_id,v_conv_curr,v_conv_corr,v_bal_amt,v_cust_charges_acc_no,v_customer_liability_type,v_rollover,v_doc_submit_date,v_mtm_account,v_pfe_account);

END IF;

WHEN trans_type='XSC' Then  Dbms_Output.put_line('CCFC Sale Cancellation');
-- Jitesh : 17.01.2012 : v4.0.0.116 : Forward Cancellation Gain changes.
--mercury_exim_fetch_CCYCANCEL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_value_date,v_contract_type,v_start_date,
--v_maturity_date,v_record_type,v_rate,v_mtrans_no,v_branch_code,v_bal_amt,v_cust_charges_acc_no);
-- Office : 20.09.2012 : v4.0.0.147 : DE15
-- Office : 29.10.2012 : v4.0.0.151 : Send MTM and PFE account number from exim to murex
Dbms_Output.put_line('start 27');
IF v_mig_bank ='SBH' THEN
Dbms_Output.put_line('SBH');
--mercury_exim_sbh.fetch_CCYCANCEL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_value_date,v_contract_type,v_start_date,
--v_maturity_date,v_record_type,v_rate,v_mtrans_no,v_branch_code,v_bal_amt,v_cust_charges_acc_no,v_customer_liability_type,v_doc_submit_date,v_mtm_account,v_pfe_account);
ELSIF v_mig_bank ='SBBJ' THEN
Dbms_Output.put_line('SBBJ');
--mercury_exim_sbbj.fetch_CCYCANCEL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_value_date,v_contract_type,v_start_date,
--v_maturity_date,v_record_type,v_rate,v_mtrans_no,v_branch_code,v_bal_amt,v_cust_charges_acc_no,v_customer_liability_type,v_doc_submit_date,v_mtm_account,v_pfe_account);
ELSIF v_mig_bank ='SBT' THEN
Dbms_Output.put_line('SBT');
--mercury_exim_sbt.fetch_CCYCANCEL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_value_date,v_contract_type,v_start_date,
--v_maturity_date,v_record_type,v_rate,v_mtrans_no,v_branch_code,v_bal_amt,v_cust_charges_acc_no,v_customer_liability_type,v_doc_submit_date,v_mtm_account,v_pfe_account);
ELSIF v_mig_bank ='SBP' THEN
Dbms_Output.put_line('SBP');
--mercury_exim_sbp.fetch_CCYCANCEL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_value_date,v_contract_type,v_start_date,
--v_maturity_date,v_record_type,v_rate,v_mtrans_no,v_branch_code,v_bal_amt,v_cust_charges_acc_no,v_customer_liability_type,v_doc_submit_date,v_mtm_account,v_pfe_account);
ELSIF v_mig_bank ='SBM' THEN
Dbms_Output.put_line('SBM');
--mercury_exim_sbm.fetch_CCYCANCEL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_value_date,v_contract_type,v_start_date,
--v_maturity_date,v_record_type,v_rate,v_mtrans_no,v_branch_code,v_bal_amt,v_cust_charges_acc_no,v_customer_liability_type,v_doc_submit_date,v_mtm_account,v_pfe_account);
ELSE
Dbms_Output.put_line('SBI');
mercury_exim_fetch_CCYCANCEL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_value_date,v_contract_type,v_start_date,
v_maturity_date,v_record_type,v_rate,v_mtrans_no,v_branch_code,v_bal_amt,v_cust_charges_acc_no,v_customer_liability_type,v_doc_submit_date,v_mtm_account,v_pfe_account);
END IF;
Dbms_Output.put_line('end 27');

--Jitesh : 01.02.2012 : Log to maintain data received from Trade Finance.
INSERT INTO MFX_TF_RAW_DATA (TRANS_REF_NO,CUST_ID,TRANS_CURR,TRANS_AMT,OTH_CURR,VALUE_DATE,CONTRACT_TYPE,START_DATE,MATURITY_DATE,RECORD_TYPE,rate,mtrans_no,
branch_code,bal_amt,cust_charges_acc_no,customer_liability,trans_type_code,fetch_time,doc_submit_date,mtm_account,pfe_account)
VALUES (v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_value_date,v_contract_type,
v_start_date,v_maturity_date, v_record_type,v_rate,v_mtrans_no,v_branch_code,
v_bal_amt,v_cust_charges_acc_no,v_customer_liability_type,trans_type,sysdate,v_doc_submit_date,v_mtm_account,v_pfe_account);

v_cust_cif_no:=v_cust_id;
  mfx_tf_if_fetch_validation(v_trans_ref_no,trans_type,v_trans_nostroid,v_trans_curr,v_oth_nostroid,v_oth_curr,v_start_date,v_value_date,
  v_maturity_date,v_cust_id,v_current_status , v_excess_short ,v_nego_disc ,v_mode_disbusal ,v_record_type ,v_contract_type ,v_trans_amt ,
  v_trans_amt,v_eefc_trans_curr_amt ,v_eefc_conv_amt ,v_pcfc_trans_curr_amt ,v_pcfc_conv_amt ,v_bal_amt,v_trans_amt,v_branch_code,
  a_branch_code ,v_base_rate,v_spread,v_gross_rate,a_user_id  ,v_cust_charges_acc_no ,v_exp_bill_type ,v_nature_of_bill  , v_premium_upto_date,v_rate ,v_conv_curr ,v_conv_corr ,v_interest_fcy,
  v_amt_realised,v_outstanding_nego_amt,tmp_err_code,tmp_err_msg);

  -- Jitesh : 17.01.2012 : v4.0.0.116 : Forward Cancellation Gain changes.

  v_rollover:='N';

  SELECT mfx_tf_fwd_liab_flag(v_customer_liability_type) INTO v_customer_liability_type FROM DUAL;
  IF v_customer_liability_type='NA' THEN

    -- Jitesh : 30.03.2012 : On request of client(Amitesh), marked this fowards as DE, becoz flag received from TF is invalid i.e. 0
--    IF v_trans_ref_no='0999507KS0077523' OR v_trans_ref_no='0999507KS0077524' OR v_trans_ref_no='0999507KS0077525' THEN
--      v_customer_liability_type:='DE';
--    ELSE
      tmp_err_code:='01';
      tmp_err_msg:='Customer Liability Type can be 1 (PP) or 2 (DE) or 3 (DE15) or 4 (CE15) or 5 (AE) or 6 (CE) only. Please Check with Trade Finance';
--    END IF;

  END IF;


--  IF v_customer_liability_type=1 THEN
--      v_customer_liability_type:='PP';
--  ELSE
--    IF v_customer_liability_type=2 THEN
--      v_customer_liability_type:='DE';
--    ELSE
--      IF v_customer_liability_type=3 THEN
--      v_customer_liability_type:='DE15';
--        ELSE
--        tmp_err_code:='01';
--        tmp_err_msg:='Customer Liability Type can be 1 (Past Performance) or 2 (Dcoumentary Evidence) or 3 (Dcoumentary Evidence 15 days) only. Please Check with Trade Finance';
--      END IF;
--    END IF;
--  END IF;

IF(tmp_err_code='00') THEN
     mfx_tf_conv_curr_corr(trans_type,v_trans_curr,v_oth_curr,v_trans_nostroid,v_oth_nostroid,v_conv_curr,v_conv_corr);
     -- Jitesh : 17.01.2012 : v4.0.0.116 : Forward Cancellation Gain changes.
--    INSERT INTO mfx_tf_data(TF_ID,trans_ref_no,fetch_time,trans_type_code,cust_id,trans_curr,trans_amt,ready_amt,oth_curr,value_date,
--    contract_type,start_date,maturity_date,record_type,rate,mtrans_no,branch_code,buy_sell,trans_nostroid,oth_nostroid,INR_nostroid,branch_user_id,
--    conv_curr,conv_corr,cust_charges_acc_no)
--    VALUES(V_ID,v_trans_ref_no,SYSDATE,trans_type,v_cust_id,v_trans_curr,v_trans_amt,v_trans_amt,v_oth_curr,v_value_date,
--    v_contract_type,v_start_date,v_maturity_date,v_record_type,v_rate,v_mtrans_no,v_branch_code,v_buy_sell,v_trans_nostroid,v_oth_nostroid,'OVRAC',a_user_id,
--    v_conv_curr,v_conv_corr,v_cust_charges_acc_no);
-- Office : 20.09.2012 : v4.0.0.147 : DE15
-- Office : 29.10.2012 : v4.0.0.151 : Send MTM and PFE account number from exim to murex
    INSERT INTO mfx_tf_data(TF_ID,trans_ref_no,fetch_time,trans_type_code,cust_id,trans_curr,trans_amt,ready_amt,oth_curr,value_date,
    contract_type,start_date,maturity_date,record_type,rate,mtrans_no,branch_code,buy_sell,trans_nostroid,oth_nostroid,INR_nostroid,branch_user_id,
    conv_curr,conv_corr,cust_charges_acc_no,customer_liability,rollover_flag,doc_submit_date,mtm_account,pfe_account)
    VALUES(V_ID,v_trans_ref_no,SYSDATE,trans_type,v_cust_id,v_trans_curr,v_trans_amt,v_trans_amt,v_oth_curr,v_value_date,
    v_contract_type,v_start_date,v_maturity_date,v_record_type,v_rate,v_mtrans_no,v_branch_code,v_buy_sell,v_trans_nostroid,v_oth_nostroid,'OVRAC',a_user_id,
    v_conv_curr,v_conv_corr,v_cust_charges_acc_no,v_customer_liability_type,v_rollover,v_doc_submit_date,v_mtm_account,v_pfe_account);
END IF;

WHEN trans_type='XPC' Then  Dbms_Output.put_line('CCFC Purchase Cancellation');

-- Jitesh : 17.01.2012 : v4.0.0.116 : Forward Cancellation Gain changes.
--mercury_exim_fetch_CCYCANCEL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_value_date,v_contract_type,v_start_date,
--v_maturity_date,v_record_type,v_rate,v_mtrans_no,v_branch_code,v_bal_amt,v_cust_charges_acc_no);
-- Office : 20.09.2012 : v4.0.0.147 : DE15
-- Office : 29.10.2012 : v4.0.0.151 : Send MTM and PFE account number from exim to murex
Dbms_Output.put_line('start 28');
IF v_mig_bank='SBH' THEN
Dbms_Output.put_line('SBH');
--mercury_exim_sbh.fetch_CCYCANCEL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_value_date,v_contract_type,v_start_date,
--v_maturity_date,v_record_type,v_rate,v_mtrans_no,v_branch_code,v_bal_amt,v_cust_charges_acc_no,v_customer_liability_type,v_doc_submit_date,v_mtm_account,v_pfe_account);
ELSIF v_mig_bank='SBBJ' THEN
Dbms_Output.put_line('SBBJ');
--mercury_exim_sbbj.fetch_CCYCANCEL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_value_date,v_contract_type,v_start_date,
--v_maturity_date,v_record_type,v_rate,v_mtrans_no,v_branch_code,v_bal_amt,v_cust_charges_acc_no,v_customer_liability_type,v_doc_submit_date,v_mtm_account,v_pfe_account);
ELSIF v_mig_bank='SBT' THEN
Dbms_Output.put_line('SBT');
--mercury_exim_sbt.fetch_CCYCANCEL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_value_date,v_contract_type,v_start_date,
--v_maturity_date,v_record_type,v_rate,v_mtrans_no,v_branch_code,v_bal_amt,v_cust_charges_acc_no,v_customer_liability_type,v_doc_submit_date,v_mtm_account,v_pfe_account);
ELSIF v_mig_bank='SBP' THEN
Dbms_Output.put_line('SBP');
--mercury_exim_sbp.fetch_CCYCANCEL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_value_date,v_contract_type,v_start_date,
--v_maturity_date,v_record_type,v_rate,v_mtrans_no,v_branch_code,v_bal_amt,v_cust_charges_acc_no,v_customer_liability_type,v_doc_submit_date,v_mtm_account,v_pfe_account);
ELSIF v_mig_bank='SBM' THEN
Dbms_Output.put_line('SBM');
--mercury_exim_sbm.fetch_CCYCANCEL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_value_date,v_contract_type,v_start_date,
--v_maturity_date,v_record_type,v_rate,v_mtrans_no,v_branch_code,v_bal_amt,v_cust_charges_acc_no,v_customer_liability_type,v_doc_submit_date,v_mtm_account,v_pfe_account);
ELSE
Dbms_Output.put_line('SBI');
mercury_exim_fetch_CCYCANCEL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_value_date,v_contract_type,v_start_date,
v_maturity_date,v_record_type,v_rate,v_mtrans_no,v_branch_code,v_bal_amt,v_cust_charges_acc_no,v_customer_liability_type,v_doc_submit_date,v_mtm_account,v_pfe_account);
END IF ;
Dbms_Output.put_line('start 28');
--Jitesh : 01.02.2012 : Log to maintain data received from Trade Finance.
INSERT INTO MFX_TF_RAW_DATA (TRANS_REF_NO,CUST_ID,TRANS_CURR,TRANS_AMT,OTH_CURR,VALUE_DATE,CONTRACT_TYPE,START_DATE,MATURITY_DATE,RECORD_TYPE,rate,mtrans_no,
branch_code,bal_amt,cust_charges_acc_no,customer_liability,trans_type_code,fetch_time,doc_submit_date,mtm_account,pfe_account)
VALUES (v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_oth_curr,v_value_date,v_contract_type,
v_start_date,v_maturity_date, v_record_type,v_rate,v_mtrans_no,v_branch_code,
v_bal_amt,v_cust_charges_acc_no,v_customer_liability_type,trans_type,sysdate,v_doc_submit_date,v_mtm_account,v_pfe_account);

v_cust_cif_no:=v_cust_id;
  mfx_tf_if_fetch_validation(v_trans_ref_no,trans_type,v_trans_nostroid,v_trans_curr,v_oth_nostroid,v_oth_curr,v_start_date,v_value_date,
  v_maturity_date,v_cust_id,v_current_status , v_excess_short ,v_nego_disc ,v_mode_disbusal ,v_record_type ,v_contract_type ,v_trans_amt ,
  v_trans_amt ,v_eefc_trans_curr_amt ,v_eefc_conv_amt ,v_pcfc_trans_curr_amt ,v_pcfc_conv_amt ,v_bal_amt,v_trans_amt,v_branch_code,
  a_branch_code ,v_base_rate,v_spread,v_gross_rate,a_user_id  ,v_cust_charges_acc_no ,v_exp_bill_type ,v_nature_of_bill  ,
   v_premium_upto_date,v_rate ,v_conv_curr ,v_conv_corr ,v_interest_fcy,v_amt_realised,
  v_outstanding_nego_amt,tmp_err_code,tmp_err_msg);

  -- Jitesh : 17.01.2012 : v4.0.0.116 : Forward Cancellation Gain changes.
  v_rollover:='N';

  SELECT mfx_tf_fwd_liab_flag(v_customer_liability_type) INTO v_customer_liability_type FROM DUAL;

  IF v_customer_liability_type='NA' THEN
    tmp_err_code:='01';
    tmp_err_msg:='Customer Liability Type can be 1 (PP) or 2 (DE) or 3 (DE15) or 4 (CE15) or 5 (AE) or 6 (CE) only. Please Check with Trade Finance';
  END IF;

--  IF v_customer_liability_type=1 THEN
--      v_customer_liability_type:='PP';
--  ELSE
--    IF v_customer_liability_type=2 THEN
--      v_customer_liability_type:='DE';
--    ELSE
--      IF v_customer_liability_type=3 THEN
--      v_customer_liability_type:='DE15';
--        ELSE
--        tmp_err_code:='01';
--        tmp_err_msg:='Customer Liability Type can be 1 (Past Performance) or 2 (Dcoumentary Evidence) or 3 (Dcoumentary Evidence 15 days) only. Please Check with Trade Finance';
--      END IF;
--    END IF;
--  END IF;

IF(tmp_err_code='00') THEN
     mfx_tf_conv_curr_corr(trans_type,v_trans_curr,v_oth_curr,v_trans_nostroid,v_oth_nostroid,v_conv_curr,v_conv_corr);

     -- Jitesh : 17.01.2012 : v4.0.0.116 : Forward Cancellation Gain changes.
--    INSERT INTO mfx_tf_data(TF_ID,trans_ref_no,fetch_time,trans_type_code,cust_id,trans_curr,trans_amt,ready_amt,oth_curr,value_date,
--    contract_type,start_date,maturity_date,record_type,rate,mtrans_no,branch_code,buy_sell,trans_nostroid,oth_nostroid,INR_nostroid,branch_user_id,
--    conv_curr,conv_corr,cust_charges_acc_no)
--    VALUES(V_ID,v_trans_ref_no,SYSDATE,trans_type,v_cust_id,v_trans_curr,v_trans_amt,v_trans_amt,v_oth_curr,v_value_date,
--    v_contract_type,v_start_date,v_maturity_date,v_record_type,v_rate,v_mtrans_no,v_branch_code,v_buy_sell,v_trans_nostroid,v_oth_nostroid,'OVRAC',a_user_id,
--    v_conv_curr,v_conv_corr,v_cust_charges_acc_no);
-- Office : 20.09.2012 : v4.0.0.147 : DE15
-- Office : 29.10.2012 : v4.0.0.151 : Send MTM and PFE account number from exim to murex
      INSERT INTO mfx_tf_data(TF_ID,trans_ref_no,fetch_time,trans_type_code,cust_id,trans_curr,trans_amt,ready_amt,oth_curr,value_date,
    contract_type,start_date,maturity_date,record_type,rate,mtrans_no,branch_code,buy_sell,trans_nostroid,oth_nostroid,INR_nostroid,branch_user_id,
    conv_curr,conv_corr,cust_charges_acc_no,customer_liability,rollover_flag,doc_submit_date,mtm_account,pfe_account)
    VALUES(V_ID,v_trans_ref_no,SYSDATE,trans_type,v_cust_id,v_trans_curr,v_trans_amt,v_trans_amt,v_oth_curr,v_value_date,
    v_contract_type,v_start_date,v_maturity_date,v_record_type,v_rate,v_mtrans_no,v_branch_code,v_buy_sell,v_trans_nostroid,v_oth_nostroid,'OVRAC',a_user_id,
    v_conv_curr,v_conv_corr,v_cust_charges_acc_no,v_customer_liability_type,v_rollover,v_doc_submit_date,v_mtm_account,v_pfe_account);
END IF;

WHEN trans_type='CP' Then  Dbms_Output.put_line('Export Bill Collection Payment');
Dbms_Output.put_line('start 29');
IF v_mig_bank='SBH' THEN
Dbms_Output.put_line('SBH');
--mercury_exim_sbh.fetch_EXPCOLLPYMT(v_trans_ref_no,v_bill_refno,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,
--v_pcfc_trans_curr_amt, v_pcfc_conv_amt,v_oth_curr,v_ready_amt,v_value_date,v_nostro_real_date,v_trans_nostroid,v_oth_nostroid,v_branch_code);
ELSIF v_mig_bank='SBBJ' THEN
Dbms_Output.put_line('SBBJ');
--mercury_exim_sbbj.fetch_EXPCOLLPYMT(v_trans_ref_no,v_bill_refno,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,
--v_pcfc_trans_curr_amt, v_pcfc_conv_amt,v_oth_curr,v_ready_amt,v_value_date,v_nostro_real_date,v_trans_nostroid,v_oth_nostroid,v_branch_code);
ELSIF v_mig_bank='SBT' THEN
Dbms_Output.put_line('SBT');
--mercury_exim_sbt.fetch_EXPCOLLPYMT(v_trans_ref_no,v_bill_refno,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,
--v_pcfc_trans_curr_amt, v_pcfc_conv_amt,v_oth_curr,v_ready_amt,v_value_date,v_nostro_real_date,v_trans_nostroid,v_oth_nostroid,v_branch_code);
ELSIF v_mig_bank='SBP' THEN
Dbms_Output.put_line('SBP');
--mercury_exim_sbp.fetch_EXPCOLLPYMT(v_trans_ref_no,v_bill_refno,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,
--v_pcfc_trans_curr_amt, v_pcfc_conv_amt,v_oth_curr,v_ready_amt,v_value_date,v_nostro_real_date,v_trans_nostroid,v_oth_nostroid,v_branch_code);
ELSIF v_mig_bank='SBM' THEN
Dbms_Output.put_line('SBM');
--mercury_exim_sbm.fetch_EXPCOLLPYMT(v_trans_ref_no,v_bill_refno,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,
--v_pcfc_trans_curr_amt, v_pcfc_conv_amt,v_oth_curr,v_ready_amt,v_value_date,v_nostro_real_date,v_trans_nostroid,v_oth_nostroid,v_branch_code);
ELSE
Dbms_Output.put_line('SBI');
mercury_exim_fetch_EXPCOLLPYMT(v_trans_ref_no,v_bill_refno,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,
v_pcfc_trans_curr_amt, v_pcfc_conv_amt,v_oth_curr,v_ready_amt,v_value_date,v_nostro_real_date,v_trans_nostroid,v_oth_nostroid,v_branch_code);
END IF;
Dbms_Output.put_line('start 29');
/*v_trans_ref_no:='0411409CP8800357';v_cust_id:='00000085010245233';v_trans_curr:='USD';v_trans_amt:=18152;v_value_date:=sysdate;
v_start_date:=SYSDATE+11;v_maturity_date:=SYSDATE+11;v_rate:=46.41;v_ready_amt:=18152;v_branch_code:='04114';v_nostro_real_date:=sysdate-1;
v_bal_amt:=1000000;v_ready_rupee_eqvt:=500000; */

v_cust_cif_no:=v_cust_id;
  mfx_tf_if_fetch_validation(v_trans_ref_no,trans_type,v_trans_nostroid,v_trans_curr,v_oth_nostroid,v_oth_curr,v_start_date,v_value_date,v_maturity_date,v_cust_id,
  v_current_status , v_excess_short ,v_nego_disc ,v_mode_disbusal ,v_record_type ,v_contract_type ,v_trans_amt ,
  v_ready_amt ,v_eefc_trans_curr_amt ,v_eefc_conv_amt ,v_pcfc_trans_curr_amt ,v_pcfc_conv_amt ,v_bal_amt,v_bal_amt,v_branch_code,
  a_branch_code ,v_base_rate,v_spread,v_gross_rate,a_user_id  ,v_cust_charges_acc_no ,v_exp_bill_type ,v_nature_of_bill  , v_premium_upto_date,v_rate ,v_conv_curr ,v_conv_corr ,v_interest_fcy,v_amt_realised,
  v_outstanding_nego_amt,tmp_err_code,tmp_err_msg);
IF(tmp_err_code='00') THEN
     mfx_tf_conv_curr_corr(trans_type,v_trans_curr,v_oth_curr,v_trans_nostroid,v_oth_nostroid,v_conv_curr,v_conv_corr);
    insert into mfx_tf_data (TF_ID,trans_ref_no,trans_type_code,bill_refno,cust_id,fetch_time,trans_curr,trans_amt,eefc_trans_curr_amt,eefc_conv_amt,pcfc_trans_curr_amt, pcfc_conv_amt,oth_curr,ready_amt,value_date,nostro_real_date,trans_nostroid,oth_nostroid,branch_code,buy_sell,INR_nostroid,branch_user_id,conv_curr,conv_corr)
     values ( V_ID,v_trans_ref_no,trans_type,v_bill_refno,v_cust_id,SYSDATE,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_pcfc_trans_curr_amt, v_pcfc_conv_amt,v_oth_curr,v_ready_amt,v_value_date,v_nostro_real_date,v_trans_nostroid,v_oth_nostroid,v_branch_code,v_buy_sell,'OVRAC',a_user_id,v_conv_curr,v_conv_corr);
END IF;

WHEN trans_type='PER' Then  Dbms_Output.put_line('PCFC Repayment from balance in EEFC');
mercury_exim_fetch_PCFCEEFC(v_trans_ref_no,v_bill_refno,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,
v_pcfc_trans_curr_amt, v_pcfc_conv_amt,v_oth_curr,v_ready_amt,v_value_date,v_nostro_real_date,v_trans_nostroid,v_oth_nostroid,v_branch_code);

v_cust_cif_no:=v_cust_id;
  mfx_tf_if_fetch_validation(v_trans_ref_no,trans_type,v_trans_nostroid,v_trans_curr,v_oth_nostroid,v_oth_curr,v_start_date,v_value_date,v_maturity_date,v_cust_id,
  v_current_status , v_excess_short ,v_nego_disc ,v_mode_disbusal ,v_record_type ,v_contract_type ,v_trans_amt ,
  v_ready_amt ,v_eefc_trans_curr_amt ,v_eefc_conv_amt ,v_pcfc_trans_curr_amt ,v_pcfc_conv_amt ,v_bal_amt,v_bal_amt,v_branch_code,
  a_branch_code ,v_base_rate,v_spread,v_gross_rate,a_user_id  ,v_cust_charges_acc_no ,v_exp_bill_type ,v_nature_of_bill  , v_premium_upto_date,v_rate ,v_conv_curr ,v_conv_corr ,v_interest_fcy,v_amt_realised,
  v_outstanding_nego_amt,tmp_err_code,tmp_err_msg);
IF(tmp_err_code='00') THEN
     mfx_tf_conv_curr_corr(trans_type,v_trans_curr,v_oth_curr,v_trans_nostroid,v_oth_nostroid,v_conv_curr,v_conv_corr);
    insert into mfx_tf_data (TF_ID,trans_ref_no,trans_type_code,bill_refno,cust_id,fetch_time,trans_curr,trans_amt,eefc_trans_curr_amt,eefc_conv_amt,pcfc_trans_curr_amt, pcfc_conv_amt,oth_curr,ready_amt,value_date,nostro_real_date,trans_nostroid,oth_nostroid,branch_code,buy_sell,INR_nostroid,branch_user_id,conv_curr,conv_corr)
     values ( V_ID,v_trans_ref_no,trans_type,v_bill_refno,v_cust_id,SYSDATE,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_pcfc_trans_curr_amt, v_pcfc_conv_amt,v_oth_curr,v_ready_amt,v_value_date,v_nostro_real_date,v_trans_nostroid,v_oth_nostroid,v_branch_code,v_buy_sell,'OVRAC',a_user_id,v_conv_curr,v_conv_corr);
END IF;

WHEN trans_type='EN' Then  Dbms_Output.put_line('EBR Bill Negotiation');

Dbms_Output.put_line('start 30');
IF v_mig_bank='SBH' THEN
Dbms_Output.put_line('SBH');
--mercury_exim_sbh.fetch_EBRNEGO(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_pcfc_trans_curr_amt,
--v_pcfc_conv_amt,v_oth_curr,v_interest_amt,v_ready_amt,v_value_date,v_maturity_date,v_current_status,v_nego_disc,v_trans_nostroid,v_oth_nostroid,
--v_branch_code,v_base_rate,v_spread,v_gross_rate,v_exp_bill_type,v_nature_of_bill);
ELSIF v_mig_bank='SBBJ' THEN
Dbms_Output.put_line('SBBJ');
--mercury_exim_sbbj.fetch_EBRNEGO(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_pcfc_trans_curr_amt,
--v_pcfc_conv_amt,v_oth_curr,v_interest_amt,v_ready_amt,v_value_date,v_maturity_date,v_current_status,v_nego_disc,v_trans_nostroid,v_oth_nostroid,
--v_branch_code,v_base_rate,v_spread,v_gross_rate,v_exp_bill_type,v_nature_of_bill);
ELSIF v_mig_bank='SBT' THEN
Dbms_Output.put_line('SBT');
--mercury_exim_sbt.fetch_EBRNEGO(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_pcfc_trans_curr_amt,
--v_pcfc_conv_amt,v_oth_curr,v_interest_amt,v_ready_amt,v_value_date,v_maturity_date,v_current_status,v_nego_disc,v_trans_nostroid,v_oth_nostroid,
--v_branch_code,v_base_rate,v_spread,v_gross_rate,v_exp_bill_type,v_nature_of_bill);
ELSIF v_mig_bank='SBP' THEN
Dbms_Output.put_line('SBP');
--mercury_exim_sbp.fetch_EBRNEGO(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_pcfc_trans_curr_amt,
--v_pcfc_conv_amt,v_oth_curr,v_interest_amt,v_ready_amt,v_value_date,v_maturity_date,v_current_status,v_nego_disc,v_trans_nostroid,v_oth_nostroid,
--v_branch_code,v_base_rate,v_spread,v_gross_rate,v_exp_bill_type,v_nature_of_bill);
ELSIF v_mig_bank='SBM' THEN
Dbms_Output.put_line('SBM');
--mercury_exim_sbm.fetch_EBRNEGO(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_pcfc_trans_curr_amt,
--v_pcfc_conv_amt,v_oth_curr,v_interest_amt,v_ready_amt,v_value_date,v_maturity_date,v_current_status,v_nego_disc,v_trans_nostroid,v_oth_nostroid,
--v_branch_code,v_base_rate,v_spread,v_gross_rate,v_exp_bill_type,v_nature_of_bill);
ELSE
Dbms_Output.put_line('SBI');
mercury_exim_fetch_EBRNEGO(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,v_pcfc_trans_curr_amt,
v_pcfc_conv_amt,v_oth_curr,v_interest_amt,v_ready_amt,v_value_date,v_maturity_date,v_current_status,v_nego_disc,v_trans_nostroid,v_oth_nostroid,
v_branch_code,v_base_rate,v_spread,v_gross_rate,v_exp_bill_type,v_nature_of_bill);
END IF ;
Dbms_Output.put_line('start 30');

v_cust_cif_no:=v_cust_id;
  mfx_tf_if_fetch_validation(v_trans_ref_no,trans_type,v_trans_nostroid,v_trans_curr,v_oth_nostroid,v_oth_curr,v_start_date,v_value_date ,v_maturity_date,v_cust_id,
  v_current_status , v_excess_short ,v_nego_disc ,v_mode_disbusal ,v_record_type ,v_contract_type ,v_trans_amt ,
  v_ready_amt ,v_eefc_trans_curr_amt ,v_eefc_conv_amt ,v_pcfc_trans_curr_amt ,v_pcfc_conv_amt ,v_bal_amt,v_bal_amt,v_branch_code,
  a_branch_code ,v_base_rate,v_spread,v_gross_rate,a_user_id  ,v_cust_charges_acc_no ,v_exp_bill_type ,v_nature_of_bill  , v_premium_upto_date,v_rate ,v_conv_curr ,v_conv_corr ,v_interest_amt,
  v_amt_realised,v_outstanding_nego_amt,tmp_err_code,tmp_err_msg);
IF(tmp_err_code='00') THEN
    mfx_tf_conv_curr_corr(trans_type,v_trans_curr,v_oth_curr,v_trans_nostroid,v_oth_nostroid,v_conv_curr,v_conv_corr);
    insert into mfx_tf_data (TF_ID,trans_ref_no,trans_type_code,cust_id,trans_curr,fetch_time,trans_amt,eefc_trans_curr_amt,eefc_conv_amt,
    pcfc_trans_curr_amt,pcfc_conv_amt,oth_curr,ready_amt,value_date,maturity_date,current_status,nego_disc,trans_nostroid,
    oth_nostroid,branch_code,buy_sell,INR_nostroid,branch_user_id,conv_curr,conv_corr,base_rate,spread,gross_rate,exp_bill_type,nature_of_bill,interest_amt)
    values ( V_ID,v_trans_ref_no,trans_type,v_cust_id,v_trans_curr,SYSDATE,v_trans_amt,v_eefc_trans_curr_amt,v_eefc_conv_amt,
    v_pcfc_trans_curr_amt,v_pcfc_conv_amt,Decode(v_oth_curr,' ','INR','','INR',v_oth_curr),v_ready_amt,v_value_date,v_maturity_date,
    v_current_status,v_nego_disc,v_trans_nostroid,v_oth_nostroid,v_branch_code,v_buy_sell,'OVRAC',a_user_id,v_conv_curr,v_conv_corr,v_base_rate,v_spread,v_gross_rate,
    v_exp_bill_type,v_nature_of_bill,v_interest_amt);
END IF;

WHEN trans_type='EC' Then  Dbms_Output.put_line('EBR Crystallization');
  Dbms_Output.put_line('start 31');
  IF v_mig_bank='SBH' THEN
  Dbms_Output.put_line('SBH');
  --mercury_exim_sbh.fetch_EBRCRYSTAL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_ready_amt,v_nego_start_date,v_maturity_date,
  --v_current_status,v_trans_nostroid,v_base_rate,v_spread,v_gross_rate,v_branch_code,v_interest_fcy,v_exp_bill_type,v_nature_of_bill,
  --v_fb_charges_amt,v_REFUND_INTR_AMT);
  ELSIF v_mig_bank='SBBJ' THEN
  Dbms_Output.put_line('SBBJ');
  --mercury_exim_sbbj.fetch_EBRCRYSTAL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_ready_amt,v_nego_start_date,v_maturity_date,
  --v_current_status,v_trans_nostroid,v_base_rate,v_spread,v_gross_rate,v_branch_code,v_interest_fcy,v_exp_bill_type,v_nature_of_bill,
  --v_fb_charges_amt,v_REFUND_INTR_AMT);
  ELSIF v_mig_bank='SBT' THEN
  Dbms_Output.put_line('SBT');
  --mercury_exim_sbt.fetch_EBRCRYSTAL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_ready_amt,v_nego_start_date,v_maturity_date,
  --v_current_status,v_trans_nostroid,v_base_rate,v_spread,v_gross_rate,v_branch_code,v_interest_fcy,v_exp_bill_type,v_nature_of_bill,
  --v_fb_charges_amt,v_REFUND_INTR_AMT);
  ELSIF v_mig_bank='SBP' THEN
  Dbms_Output.put_line('SBP');
  --mercury_exim_sbp.fetch_EBRCRYSTAL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_ready_amt,v_nego_start_date,v_maturity_date,
  --v_current_status,v_trans_nostroid,v_base_rate,v_spread,v_gross_rate,v_branch_code,v_interest_fcy,v_exp_bill_type,v_nature_of_bill,
  --v_fb_charges_amt,v_REFUND_INTR_AMT);
  ELSIF v_mig_bank='SBM' THEN
  Dbms_Output.put_line('SBM');
  --mercury_exim_sbm.fetch_EBRCRYSTAL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_ready_amt,v_nego_start_date,v_maturity_date,
  --v_current_status,v_trans_nostroid,v_base_rate,v_spread,v_gross_rate,v_branch_code,v_interest_fcy,v_exp_bill_type,v_nature_of_bill,
  --v_fb_charges_amt,v_REFUND_INTR_AMT);
  ELSE
  Dbms_Output.put_line('SBI');
  mercury_exim_fetch_EBRCRYSTAL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_ready_amt,v_nego_start_date,v_maturity_date,
  v_current_status,v_trans_nostroid,v_base_rate,v_spread,v_gross_rate,v_branch_code,v_interest_fcy,v_exp_bill_type,v_nature_of_bill,
  v_fb_charges_amt,v_REFUND_INTR_AMT);
  END IF;
  Dbms_Output.put_line('start 31');


  --Jitesh : 13.04.2012 : Log to maintain data received from Trade Finance.
  INSERT INTO MFX_TF_RAW_DATA(trans_ref_no,trans_type_code,fetch_time,cust_id,trans_curr,trans_amt,ready_amt,nego_start_date,maturity_date,current_status,
  trans_nostroid,base_rate,spread,gross_rate,branch_code,interest_fcy,exp_bill_type,nature_of_bill,FB_CHARGES_AMT,REFUND_INTR_AMT)
  VALUES(v_trans_ref_no,trans_type,SYSDATE,v_cust_id,v_trans_curr,v_trans_amt,v_ready_amt,v_nego_start_date,v_maturity_date,v_current_status,
  v_trans_nostroid,v_base_rate,v_spread,v_gross_rate,v_branch_code,v_interest_fcy,v_exp_bill_type,v_nature_of_bill,v_fb_charges_amt,v_refund_intr_amt);

v_cust_cif_no:=v_cust_id;
  mfx_tf_if_fetch_validation(v_trans_ref_no,trans_type,v_trans_nostroid,v_trans_curr,v_oth_nostroid,v_oth_curr,v_start_date,v_value_date ,v_maturity_date,v_cust_id,
  v_current_status , v_excess_short ,v_nego_disc ,v_mode_disbusal ,v_record_type ,v_contract_type ,v_trans_amt ,
  v_ready_amt ,v_eefc_trans_curr_amt ,v_eefc_conv_amt ,v_pcfc_trans_curr_amt ,v_pcfc_conv_amt ,v_bal_amt,v_bal_amt,v_branch_code,
  a_branch_code ,v_base_rate,v_spread,v_gross_rate,a_user_id  ,v_cust_charges_acc_no ,v_exp_bill_type ,v_nature_of_bill  , v_premium_upto_date,v_rate ,v_conv_curr ,v_conv_corr ,v_interest_fcy,
  v_amt_realised,v_outstanding_nego_amt,tmp_err_code,tmp_err_msg);

IF(tmp_err_code='00') THEN
      mfx_tf_conv_curr_corr(trans_type,v_trans_curr,v_oth_curr,v_trans_nostroid,v_oth_nostroid,v_conv_curr,v_conv_corr);
      INSERT INTO mfx_tf_data(TF_ID,trans_ref_no,trans_type_code,fetch_time,cust_id,trans_curr,trans_amt,ready_amt,nego_start_date,maturity_date,current_status,
      trans_nostroid,base_rate,spread,gross_rate,branch_code,buy_sell,INR_nostroid,branch_user_id,conv_curr,conv_corr,interest_fcy,value_date,
      exp_bill_type,nature_of_bill,FB_CHARGES_AMT,REFUND_INTR_AMT)
      VALUES(V_ID,v_trans_ref_no,trans_type,SYSDATE,v_cust_id,v_trans_curr,v_trans_amt,v_ready_amt,v_nego_start_date,v_maturity_date,v_current_status,
      v_trans_nostroid,v_base_rate,v_spread,v_gross_rate,v_branch_code,v_buy_sell,'OVRAC',a_user_id,v_conv_curr,v_conv_corr,v_interest_fcy,v_value_date,
      v_exp_bill_type,v_nature_of_bill,v_fb_charges_amt,v_refund_intr_amt);

END IF;

WHEN trans_type='PR' Then  Dbms_Output.put_line('PCFC Repay');
Dbms_Output.put_line('start 32');
IF v_mig_bank='SBH' THEN
Dbms_Output.put_line('SBH');
--mercury_exim_sbh.fetch_PCFCREPAY(v_trans_ref_no,v_cust_id,v_trans_curr,v_value_date,v_maturity_date,
--v_current_status,v_base_rate,v_spread,v_gross_rate,v_branch_code,v_BILL_REMITTANCE_NUMBER , v_BILL_REMITTANCE_MFX_NO,v_bal_amt,v_disbursal_mfx_no);
ELSIF v_mig_bank='SBBJ' THEN
Dbms_Output.put_line('SBBJ');
--mercury_exim_sbbj.fetch_PCFCREPAY(v_trans_ref_no,v_cust_id,v_trans_curr,v_value_date,v_maturity_date,
--v_current_status,v_base_rate,v_spread,v_gross_rate,v_branch_code,v_BILL_REMITTANCE_NUMBER , v_BILL_REMITTANCE_MFX_NO,v_bal_amt,v_disbursal_mfx_no);
ELSIF v_mig_bank='SBT' THEN
Dbms_Output.put_line('SBT');
--mercury_exim_sbt.fetch_PCFCREPAY(v_trans_ref_no,v_cust_id,v_trans_curr,v_value_date,v_maturity_date,
--v_current_status,v_base_rate,v_spread,v_gross_rate,v_branch_code,v_BILL_REMITTANCE_NUMBER , v_BILL_REMITTANCE_MFX_NO,v_bal_amt,v_disbursal_mfx_no);
ELSIF v_mig_bank='SBP' THEN
Dbms_Output.put_line('SBP');
--mercury_exim_sbp.fetch_PCFCREPAY(v_trans_ref_no,v_cust_id,v_trans_curr,v_value_date,v_maturity_date,
--v_current_status,v_base_rate,v_spread,v_gross_rate,v_branch_code,v_BILL_REMITTANCE_NUMBER , v_BILL_REMITTANCE_MFX_NO,v_bal_amt,v_disbursal_mfx_no);
ELSIF v_mig_bank='SBM' THEN
Dbms_Output.put_line('SBM');
--mercury_exim_sbm.fetch_PCFCREPAY(v_trans_ref_no,v_cust_id,v_trans_curr,v_value_date,v_maturity_date,
--v_current_status,v_base_rate,v_spread,v_gross_rate,v_branch_code,v_BILL_REMITTANCE_NUMBER , v_BILL_REMITTANCE_MFX_NO,v_bal_amt,v_disbursal_mfx_no);
ELSE
Dbms_Output.put_line('SBI');
mercury_exim_fetch_PCFCREPAY(v_trans_ref_no,v_cust_id,v_trans_curr,v_value_date,v_maturity_date,
v_current_status,v_base_rate,v_spread,v_gross_rate,v_branch_code,v_BILL_REMITTANCE_NUMBER , v_BILL_REMITTANCE_MFX_NO,v_bal_amt,v_disbursal_mfx_no);
END IF ;
Dbms_Output.put_line('END 32');

Dbms_Output.Put_Line('v_bal_amt:'||v_bal_amt);
v_cust_cif_no:=v_cust_id;
  mfx_tf_if_fetch_validation(v_trans_ref_no,trans_type,v_trans_nostroid,v_trans_curr,v_oth_nostroid,v_oth_curr,v_start_date,v_value_date ,v_maturity_date,v_cust_id,
  v_current_status , v_excess_short ,v_nego_disc ,v_mode_disbusal ,v_record_type ,v_contract_type ,v_trans_amt ,
  v_ready_amt ,v_eefc_trans_curr_amt ,v_eefc_conv_amt ,v_pcfc_trans_curr_amt ,v_pcfc_conv_amt ,v_bal_amt,v_bal_amt,v_branch_code,
  a_branch_code ,v_base_rate,v_spread,v_gross_rate,a_user_id  ,v_cust_charges_acc_no ,v_exp_bill_type ,v_nature_of_bill  , v_premium_upto_date,v_rate ,v_conv_curr ,v_conv_corr ,v_interest_fcy,
  v_amt_realised,v_outstanding_nego_amt,tmp_err_code,tmp_err_msg);
  Dbms_Output.Put_Line('v_gross_rate:'||v_gross_rate);
IF(tmp_err_code='00') THEN
    mfx_tf_conv_curr_corr(trans_type,v_trans_curr,v_oth_curr,v_trans_nostroid,v_oth_nostroid,v_conv_curr,v_conv_corr);
    INSERT INTO mfx_tf_data(TF_ID,trans_ref_no,trans_type_code,fetch_time,cust_id,trans_curr,trans_amt,ready_amt,value_date,maturity_date,
    current_status,base_rate,spread,gross_rate,branch_code,buy_sell,INR_nostroid,branch_user_id,conv_curr,conv_corr,
    BILL_REMITTANCE_NUMBER , BILL_REMITTANCE_MFX_NO,bal_amt,disbursal_mfx_no)
    VALUES(V_ID,v_trans_ref_no,trans_type,SYSDATE,v_cust_id,v_trans_curr,v_trans_amt,v_trans_amt,v_value_date,v_maturity_date,
    v_current_status,v_base_rate,v_spread,v_gross_rate,v_branch_code,v_buy_sell,'FCGA',a_user_id,v_conv_curr,v_conv_corr,
    v_BILL_REMITTANCE_NUMBER , v_BILL_REMITTANCE_MFX_NO,v_bal_amt,v_disbursal_mfx_no);
END IF;

WHEN trans_type='PC' Then  Dbms_Output.put_line('PCFC Crystallization');
Dbms_Output.put_line('start 31');
IF v_mig_bank='SBH' THEN
Dbms_Output.put_line('SBH');
--3mercury_exim_sbh.fetch_PCFCCRYSTL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_value_date,v_maturity_date,v_current_status,v_branch_code,v_base_rate,v_spread,v_gross_rate,v_bal_amt,v_disbursal_mfx_no);
ELSIF v_mig_bank='SBBJ' THEN
Dbms_Output.put_line('SBBJ');
--mercury_exim_sbbj.fetch_PCFCCRYSTL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_value_date,v_maturity_date,v_current_status,v_branch_code,v_base_rate,v_spread,v_gross_rate,v_bal_amt,v_disbursal_mfx_no);
ELSIF v_mig_bank='SBT' THEN
Dbms_Output.put_line('SBT');
--mercury_exim_sbt.fetch_PCFCCRYSTL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_value_date,v_maturity_date,v_current_status,v_branch_code,v_base_rate,v_spread,v_gross_rate,v_bal_amt,v_disbursal_mfx_no);
ELSIF v_mig_bank='SBP' THEN
Dbms_Output.put_line('SBP');
--mercury_exim_sbp.fetch_PCFCCRYSTL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_value_date,v_maturity_date,v_current_status,v_branch_code,v_base_rate,v_spread,v_gross_rate,v_bal_amt,v_disbursal_mfx_no);
ELSIF v_mig_bank='SBM' THEN
Dbms_Output.put_line('SBM');
--mercury_exim_sbm.fetch_PCFCCRYSTL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_value_date,v_maturity_date,v_current_status,v_branch_code,v_base_rate,v_spread,v_gross_rate,v_bal_amt,v_disbursal_mfx_no);
ELSE
Dbms_Output.put_line('SBI');
mercury_exim_fetch_PCFCCRYSTL(v_trans_ref_no,v_cust_id,v_trans_curr,v_trans_amt,v_value_date,v_maturity_date,v_current_status,v_branch_code,v_base_rate,v_spread,v_gross_rate,v_bal_amt,v_disbursal_mfx_no);
END IF ;
Dbms_Output.put_line('end 31');

v_cust_cif_no:=v_cust_id;
  mfx_tf_if_fetch_validation(v_trans_ref_no,trans_type,v_trans_nostroid,v_trans_curr,v_oth_nostroid,v_oth_curr,v_start_date,v_value_date ,v_maturity_date,v_cust_id,
  v_current_status , v_excess_short ,v_nego_disc ,v_mode_disbusal ,v_record_type ,v_contract_type ,v_trans_amt ,
  v_ready_amt ,v_eefc_trans_curr_amt ,v_eefc_conv_amt ,v_pcfc_trans_curr_amt ,v_pcfc_conv_amt ,v_bal_amt,v_bal_amt,v_branch_code,
  a_branch_code ,v_base_rate,v_spread,v_gross_rate,a_user_id  ,v_cust_charges_acc_no ,v_exp_bill_type ,v_nature_of_bill  , v_premium_upto_date,v_rate ,v_conv_curr ,v_conv_corr ,v_interest_fcy,
  v_amt_realised,v_outstanding_nego_amt,tmp_err_code,tmp_err_msg);
IF(tmp_err_code='00') THEN
   mfx_tf_conv_curr_corr(trans_type,v_trans_curr,v_oth_curr,v_trans_nostroid,v_oth_nostroid,v_conv_curr,v_conv_corr);
  INSERT INTO mfx_tf_data(TF_ID,trans_ref_no,trans_type_code,fetch_time,cust_id,trans_curr,trans_amt,ready_amt,value_date,maturity_date,current_status,base_rate,spread,gross_rate,branch_code,buy_sell,INR_nostroid,branch_user_id,conv_curr,conv_corr,bal_amt,disbursal_mfx_no,trans_nostroid,oth_nostroid)
  VALUES(V_ID,v_trans_ref_no,trans_type,SYSDATE,v_cust_id,v_trans_curr,v_trans_amt,v_trans_amt,v_value_date,v_maturity_date,v_current_status,v_base_rate,v_spread,v_gross_rate,v_branch_code,v_buy_sell,'OVRAC',a_user_id,v_conv_curr,v_conv_corr,v_bal_amt,v_disbursal_mfx_no,v_trans_nostroid,v_oth_nostroid);
END IF;

 ELSE Dbms_Output.put_line('The owner is another value');
END CASE ;
dbms_output.put_line('v_trans_ref_no=' || v_trans_ref_no|| ' * '  ||v_bill_refno|| ' * '  ||v_cust_id|| ' * '  ||v_trans_curr|| ' * '  ||v_trans_amt|| ' * '  ||v_eefc_trans_curr_amt|| ' * '  ||v_eefc_conv_amt|| ' * '  ||
v_pcfc_trans_curr_amt|| ' * '  || v_pcfc_conv_amt|| ' * '  ||v_oth_curr|| ' * '  ||v_ready_amt|| ' * '  ||v_value_date|| ' * '  ||v_nostro_date|| ' * '  ||v_trans_nostroid|| ' * '  ||v_oth_nostroid|| ' * '  ||v_branch_code);
dbms_output.put_line('v_value_date:' ||v_value_date|| 'v_maturity_date:'||v_maturity_date);
dbms_output.put_line('***** 28234 **** ');
v_err_code:=tmp_err_code;
dbms_output.put_line('***** 28234 -1  **** ');
v_err_msg:=tmp_err_msg;
dbms_output.put_line('***** 28234 - 2 **** ');
ELSE
 SELECT BRANCH_USER_ID,TRANS_TYPE_CODE INTO v_chk_BRANCH_USER_ID,v_chk_TRANS_TYPE_CODE FROM mfx_IF_transaction_Master WHERE
 ref_number=a_trans_ref_no AND Nvl(sent_back,'N')!='Y';
 IF(v_chk_BRANCH_USER_ID!=a_user_id) THEN
    dbms_output.put_line('***** 28234 - 3 **** ');
     v_err_code:='01';
     v_err_msg:=v_err_msg||'<BR> This refrence number is being processed by other user ';
 END IF;
 IF(v_chk_TRANS_TYPE_CODE!=trans_type) THEN
     v_err_code:='01';
     dbms_output.put_line('***** 28234 - 4 **** ');
     v_err_msg:=v_err_msg||'<BR> This refrence number is being processed under '||v_chk_TRANS_TYPE_CODE ||'.Please complete process for this transaction and then pull with different transaction type ';
 END IF;
END IF;
dbms_output.put_line('***** 28234 - 6 **** ');

----
IF(tmp_err_code='00') THEN
dbms_output.put_line('***** 28234 - 8 **** ');
SELECT mfx_IF_Trans_master_id.NEXTVAL INTO v_IF_ID FROM dual;
v_IF_ID:=V_ID; -- temporarily
Dbms_Output.Put_Line('a_branch_code='||a_branch_code);
IF trans_type = 'BN' THEN --poc
  SELECT Count(*) INTO v_poc_cnt FROM mfx_ee_data WHERE mfx_trans_no IS NOT NULL AND contract_no=a_trans_ref_no;
  IF v_poc_cnt = 1 THEN
    SELECT mfx_trans_no INTO v_MFX_TRANS_NO FROM mfx_ee_data WHERE contract_no=a_trans_ref_no;
  ELSE
    mfx_get_trans_no(a_branch_code,v_MFX_TRANS_NO);
  END IF;
ELSE
  mfx_get_trans_no(a_branch_code,v_MFX_TRANS_NO);
END IF;
Dbms_Output.Put_Line('v_MFX_TRANS_NO='||v_MFX_TRANS_NO);
Dbms_Output.Put_Line('V_ID : '||V_ID);
IF (trans_type = 'FP' OR trans_type = 'FS' OR trans_type = 'XP' OR trans_type = 'XS') THEN
  mfx_add_cashflow_details(a_user_id,v_IF_ID,v_trans_ref_no,v_cust_cif_no,v_branch_code,v_cust_id,v_cashflow_urn,v_cashflow_ccy,v_cashflow_expected_end_date,v_cashflow_expected_amt,v_simplified_hedge,trans_type,sysdate);
END IF;
IF(v_odi_flag = '1') THEN
  mfx_tf_markoff_odi(v_odi_uin,v_IF_ID,v_odi_trn_no,a_user_id);
END IF;
INSERT INTO  mfx_IF_transaction_Master(IF_ID,branch_user_id,branch_code,trans_date,trans_type_code,ref_number,total_amt,curr_code,eqvt_curr_code,option_date,
maturity_date,customer_code,curr_corr_code,eqvt_curr_corr_code,value_date,nostro_date,base_rate, gross_rate,spread,MFX_TRANS_NO,BOOKING_RATE,cif_number,mtm_account,pfe_account,delv_type)
SELECT v_IF_ID,branch_user_id,branch_code,fetch_time,trans_type_code,trans_ref_no,TRANS_AMT,TRANS_CURR ,OTH_CURR,start_date,
maturity_date,CUST_ID,TRANS_NOSTROID,OTH_NOSTROID,value_date,Decode(nostro_date,'',nostro_real_date,nostro_date),
base_rate, gross_rate,spread,v_MFX_TRANS_NO,v_rate,v_cust_cif_no,mtm_account,pfe_account,delv_type FROM mfx_tf_data WHERE TF_ID=V_ID;
--to store the TF CIF manoj 25-apr-08 v_cust_cif_no
UPDATE mfx_IF_transaction_Master SET funding_req=a_funding_req WHERE if_id=v_if_id;
UPDATE mfx_tf_data SET IF_ID=v_IF_ID WHERE  TF_ID=V_ID;
IF trans_type = 'BN' THEN --poc
  updateDataForPOC('saveBN',a_trans_ref_no);
END IF;
OPEN cr_fetch;
  LOOP
        FETCH cr_fetch INTO v_sq1,v_chk,v_cmt;
        EXIT WHEN cr_fetch%NOTFOUND;
        print_out('TYPE :=>'||v_cmt ||'v_chk::=>'||v_chk);
      --  print_out(v_cmt);
        EXECUTE IMMEDIATE  v_chk  USING out v_chk_cnt,IN V_ID;
        IF (v_chk_cnt=1) THEN
           print_out('INSERT  ----  - -  '||v_cmt);
          print_out(v_sq1);
          EXECUTE IMMEDIATE  v_sq1  USING IN OUT V_Out3,IN V_ID ;
        END IF;
    END LOOP;
CLOSE cr_fetch;
dbms_output.put_line('***** 28234 - 9 **** ');
     mfx_tf_fetch_lcy_changes(v_IF_ID,v_err_code_lcy,v_err_msg_lcy);
dbms_output.put_line('*****  out of loop');
    mfx_tf_add_mm_conv(v_IF_ID,v_err_code_mm_conv,v_err_msg_mm_conv);
dbms_output.put_line('*****  out of loop -1');
     IF(v_err_code_mm_conv='01') THEN
      DELETE FROM mfx_IF_transaction_Master where IF_id=v_IF_ID;
      DELETE FROM mfx_tf_data where IF_id=v_IF_ID;
      DELETE FROM TRANSACTION WHERE trans_ref_code=v_IF_ID;
      DELETE FROM mfx_TRANSACTION_mm WHERE trans_ref_code=v_IF_ID;
      v_err_msg:=v_err_msg|| v_err_msg_mm_conv;
    END IF ;
  dbms_output.put_line('*****  out of loop -2 ');

ELSE
  DELETE FROM mfx_IF_transaction_Master where IF_id=v_IF_ID;
  DELETE FROM mfx_tf_data where IF_id=v_IF_ID;
END IF;
dbms_output.put_line('***** 28234 - 9 **** ');

EXCEPTION  WHEN OTHERS THEN
dbms_output.put_line('***** 28234 - 10 **** ');
   err_num := SQLCODE;
   err_msg := SQLERRM ;
   print_out('Error : ==>' ||err_msg );
   v_err_code:='01';
   IF(SQLCODE='100') THEN
       v_err_msg :='<BR> No Data Found in Trade Finance';
   ELSE
        v_err_msg :='<BR> ERROR in Fetching Information from Trade Finance <BR> '||mfx_tf_disp_err_msg(' '||err_msg||' ');
   end if;
    DELETE FROM mfx_IF_transaction_Master where IF_id=v_IF_ID;
    DELETE FROM mfx_tf_data WHERE  IF_id=v_IF_ID OR tf_id=v_IF_ID;
   --v_err_msg:=SQLERRM;
   dbms_output.put_line('*****  putting in log ');

--  INSERT INTO mfx_tf_error_log(TRANS_REF_NO,TRANS_TYPE_CODE,FETCH_TIME,ERR_CODE,ERR_DESC,send_recv) VALUES
--    (a_trans_ref_no,trans_type,SYSDATE,'1',err_msg,'R');

  IF err_msg = '' OR err_msg IS NULL THEN
    err_msg:=v_err_msg;
  END IF;

  INSERT INTO mfx_tf_error_log(TRANS_REF_NO,TRANS_TYPE_CODE,FETCH_TIME,ERR_CODE,ERR_DESC,send_recv)
    VALUES (a_trans_ref_no,trans_type,SYSDATE,'1',err_msg,'R');


END;
/*
declare
       a_trans_ref_no varchar2(20):='1637618FS0074500';
       trans_type varchar2(20):='FSC';
       a_branch_code varchar2(20):='16376';
       a_user_id VARCHAR2(10):='1515594';
       a_funding_req varchar2(1);
       v_err_code VARCHAR2(100);
       v_err_msg clob;
begin
mfx_tf_fetch_data(a_trans_ref_no,trans_type,a_branch_code,
a_user_id,a_funding_req,v_err_code,v_err_msg);
end;
*/
/

