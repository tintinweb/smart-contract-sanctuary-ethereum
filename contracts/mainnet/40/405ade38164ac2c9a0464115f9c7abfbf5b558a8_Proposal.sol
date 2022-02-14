/**
 *Submitted for verification at Etherscan.io on 2022-02-14
*/

pragma solidity 0.6.7;

abstract contract Setter {
  function modifyParameters(bytes32, uint256) public virtual;
  function addManualSetter(address) public virtual;
  function removeManualSetter(address) public virtual;
  function updateResult(uint256) public virtual;
  function addAuthorization(address) public virtual;
  function removeAuthorization(address) public virtual;
}

contract Proposal {
  // addresses
  address public constant GEB_DEBT_AUCTION_INITIAL_PARAM_SETTER     = 0x7df2d51e69aA58B69C3dF18D75b8e9ACc3C1B04E;
  address public constant GEB_DEBT_FLOOR_ADJUSTER                   = 0x0262Bd031B99c5fb99B47Dc4bEa691052f671447;
  address public constant GEB_PAUSE_PROXY                           = 0xa57A4e6170930ac547C147CdF26aE4682FA8262E;
  address public constant GEB_GAS_PRICE_ORACLE                      = 0x3a3e9d4D1AfC6f9d7e0E9A4032a7ddBc1500D7a5;
  address public constant GEB_SINGLE_CEILING_SETTER                 = 0x54999Ee378b339f405a4a8a1c2f7722CD25960fa;
  address public constant GEB_ESM                                   = 0xa33Ea2Ac39902d4A206D6A1F8D38c7330C80f094;

  // contracts being replaced
  address public constant NEW_GEB_ESM_THRESHOLD_SETTER              = 0x5E79C6Db9a04039B593877B96f885374470eFB90;
  address public constant OLD_GEB_ESM_THRESHOLD_SETTER              = 0x93EBA2905a2293E5C367eF053B5c2c07dc401311;

  function execute(bool) public {
    // GEB_DEBT_AUCTION_INITIAL_PARAM_SETTER - Set update delay to 7 days (604800 seconds)
    Setter(GEB_DEBT_AUCTION_INITIAL_PARAM_SETTER).modifyParameters("updateDelay", 604800);

    // GEB_DEBT_FLOOR_ADJUSTER - Remove 0xfA5e4955a11902f849ECaddEf355Db69C2036de6 from manual setters and add pauseProxy
    Setter(GEB_DEBT_FLOOR_ADJUSTER).addManualSetter(GEB_PAUSE_PROXY);
    Setter(GEB_DEBT_FLOOR_ADJUSTER).removeManualSetter(0xfA5e4955a11902f849ECaddEf355Db69C2036de6);

    // GEB_GAS_PRICE_ORACLE - Increase to 350 gwei
    Setter(GEB_GAS_PRICE_ORACLE).updateResult(350e9);

    // GEB_SINGLE_CEILING_SETTER - Remove pauseProxy from manual setters
    Setter(GEB_SINGLE_CEILING_SETTER).removeManualSetter(GEB_PAUSE_PROXY);

    // GEB_ESM_THRESHOLD_SETTER - Set supplyPercentageToBurn to 100 (10%) // need new contract, authing on the ESM, deauthing the old
    Setter(GEB_ESM).addAuthorization(NEW_GEB_ESM_THRESHOLD_SETTER);
    Setter(GEB_ESM).removeAuthorization(OLD_GEB_ESM_THRESHOLD_SETTER);
  }
}