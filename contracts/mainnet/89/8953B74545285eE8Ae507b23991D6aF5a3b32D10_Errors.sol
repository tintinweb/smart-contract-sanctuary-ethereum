// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
 *  - L = Logic
 *  - VL = ValidationLogic
 *  - P = Privilege
 *  - SET = Configure
 *  - LZ = layerzero
 */

library Errors {
  string public constant VL_TOKEN_NOT_SUPPORT = "1";
  string public constant VL_TOKEN_NOT_MATCH_CREDIT = "2";
  string public constant VL_DEPOSIT_PARAM_INVALID = "3";
  string public constant VL_EDIT_PARAM_INVALID = "4";
  string public constant VL_EDIT_CONDITION_NOT_MATCH = "5";
  string public constant VL_BORROW_ALREADY_FREEZE = "6";
  string public constant VL_BORROW_PARAM_NOT_MATCH = "7";
  string public constant VL_CREDIT_NOT_VALID = "8";
  string public constant VL_REPAY_CONDITION_NOT_MATCH = "9";
  string public constant VL_WITHDRAW_ASSET_CONDITION_NOT_MATCH = "10";
  string public constant VL_LIQUIDATE_NOT_EXPIRED = "11";
  string public constant VL_WITHDRAW_TOKEN_PARAM_NOT_MATCH = "12";
  string public constant VL_REPAY_CREDIT_AMOUNT_0 = "13";
  string public constant VL_REPAY_CREDIT_AMOUNT_TOO_LOW = "14";
  string public constant VL_REPAY_CREDIT_NO_NEED = "15";
  string public constant VL_USER_NOT_IN_CREDIT = "16";
  string public constant VL_RELEASE_TOKEN_CONDITION_NOT_MATCH = "17";

  string public constant P_ONLY_AUDITOR = "51";
  string public constant P_CALLER_MUST_BE_BRIDGE = "52";

  string public constant SET_FEE_TOO_LARGE = '55';
  string public constant SET_VAULT_ADDRESS_INVALID = '56';

  string public constant LZ_NOT_OTHER_CHAIN = "60";
  string public constant LZ_GAS_TOO_LOW = "61";
  string public constant LZ_BAD_SENDER = "62";
  string public constant LZ_BAD_REMOTE_ADDR = "63";
  string public constant LZ_BACK_FEE_FAILED = "64";
  string public constant LZ_ONLY_BRIDGE = "65";

  string public constant L_INVALID_REQ = "80";
}