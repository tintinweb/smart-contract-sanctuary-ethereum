/**
 *Submitted for verification at Etherscan.io on 2022-02-12
*/

pragma solidity 0.6.7;

abstract contract Setter {
  function modifyParameters(bytes32, uint256) public virtual;
  function modifyParameters(bytes32, uint256, uint256, address) public virtual;
  function modifyParameters(bytes32, uint256, uint256, bytes4, address) public virtual;
  function addManualSetter(address) public virtual;
  function removeManualSetter(address) public virtual;
  function updateResult(uint256) public virtual;
  function addAuthorization(address) public virtual;
  function removeAuthorization(address) public virtual;
  function setPerBlockAllowance(address, uint256) public virtual;
  function setTotalAllowance(address, uint256) public virtual;
  function toggleReimburser(address) public virtual;
  function addFundedFunction(address, bytes4, uint256) external virtual;
  function removeFundedFunction(address, bytes4) external virtual;
  function addFundingReceiver(address, bytes4, uint256, uint256, uint256, uint256) external virtual;
  function removeFundingReceiver(address, bytes4) external virtual;
}

contract Proposal {
  // addresses
  address public constant GEB_DEBT_AUCTION_INITIAL_PARAM_SETTER     = 0x7df2d51e69aA58B69C3dF18D75b8e9ACc3C1B04E;
  address public constant GEB_DEBT_FLOOR_ADJUSTER                   = 0x0262Bd031B99c5fb99B47Dc4bEa691052f671447;
  address public constant GEB_PAUSE_PROXY                           = 0xa57A4e6170930ac547C147CdF26aE4682FA8262E;
  address public constant GEB_GAS_PRICE_ORACLE                      = 0x3a3e9d4D1AfC6f9d7e0E9A4032a7ddBc1500D7a5;
  address public constant GEB_SINGLE_CEILING_SETTER                 = 0x54999Ee378b339f405a4a8a1c2f7722CD25960fa;
  address public constant GEB_ESM                                   = 0xa33Ea2Ac39902d4A206D6A1F8D38c7330C80f094;
  address public constant GEB_TAX_COLLECTOR                         = 0xcDB05aEda142a1B0D6044C09C64e4226c1a281EB;
  address public constant GEB_STABILITY_FEE_TREASURY                = 0x83533fdd3285f48204215E9CF38C785371258E76;
  address public constant GEB_LIQUIDATION_ENGINE                    = 0x27Efc6FFE79692E0521E7e27657cF228240A06c2;
  address public constant INCREASING_TREASURY_REIMBURSEMENT_OVERLAY = 0x1dCeE093a7C952260f591D9B8401318f2d2d72Ac;
  address public constant GEB_MINMAX_REWARDS_ADJUSTER               = 0x86EBA7b7dAaFEC537A2357f8A3a46026AF5Cb7bA;
  address public constant GEB_TREASURY_CORE_PARAM_ADJUSTER          = 0x73FEb3C2DBb87c8E0d040A7CD708F7497853B787;
  address public constant GEB_REWARD_ADJUSTER_BUNDLER               = 0x7F55e74C25647c100256D87629dee379D68bdCDe;

  // contracts being replaced
  address public constant NEW_GEB_ESM_THRESHOLD_SETTER              = 0x5E79C6Db9a04039B593877B96f885374470eFB90;
  address public constant OLD_GEB_ESM_THRESHOLD_SETTER              = 0x93EBA2905a2293E5C367eF053B5c2c07dc401311;
  address public constant NEW_COLLATERAL_AUCTION_THROTTLER          = 0x1Ae2d91adf997027B7e766021ADcA477F481044d;
  address public constant OLD_COLLATERAL_AUCTION_THROTTLER          = 0x59536C9Ad1a390fA0F60813b2a4e8B957903Efc7;

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

    // GEB_TAX_COLLECTOR - Set secondary receiver percentage to 30% (SF Treasury, 30 RAY)
    Setter(GEB_TAX_COLLECTOR).modifyParameters("ETH-A", 1, 30000000000000000000000000000, GEB_STABILITY_FEE_TREASURY);

    // COLLATERAL_AUCTION_THROTTLER - surplus holders are the SF treasury and the accounting engine // need new contract
    // setting params
    Setter(NEW_COLLATERAL_AUCTION_THROTTLER).modifyParameters("maxRewardIncreaseDelay", 10800);
    Setter(NEW_COLLATERAL_AUCTION_THROTTLER).modifyParameters("minAuctionLimit", 500000 * 10**45);

    // auth throttler in LiquidationEngine
    Setter(GEB_LIQUIDATION_ENGINE).addAuthorization(NEW_COLLATERAL_AUCTION_THROTTLER);
    Setter(GEB_LIQUIDATION_ENGINE).removeAuthorization(OLD_COLLATERAL_AUCTION_THROTTLER);

    // setting up reward adjuster harness / allowances
    // auth INCREASING_TREASURY_REIMBURSEMENT_OVERLAY on collateral auction throttler
    Setter(NEW_COLLATERAL_AUCTION_THROTTLER).addAuthorization(INCREASING_TREASURY_REIMBURSEMENT_OVERLAY);
    Setter(INCREASING_TREASURY_REIMBURSEMENT_OVERLAY).toggleReimburser(NEW_COLLATERAL_AUCTION_THROTTLER);
    Setter(INCREASING_TREASURY_REIMBURSEMENT_OVERLAY).toggleReimburser(OLD_COLLATERAL_AUCTION_THROTTLER); // old

    // authing GEB_MINMAX_REWARDS_ADJUSTER
    Setter(NEW_COLLATERAL_AUCTION_THROTTLER).addAuthorization(GEB_MINMAX_REWARDS_ADJUSTER);

    // add/remove old from GEB_TREASURY_CORE_PARAM_ADJUSTER, adjustSurplusBuffer(address), current latestExpectedCalls
    Setter(GEB_TREASURY_CORE_PARAM_ADJUSTER).addFundedFunction(NEW_COLLATERAL_AUCTION_THROTTLER, 0x36b8b425, 26);
    Setter(GEB_TREASURY_CORE_PARAM_ADJUSTER).removeFundedFunction(OLD_COLLATERAL_AUCTION_THROTTLER, 0x36b8b425);

    // add/remove old from GEB_MINMAX_REWARDS_ADJUSTER, same params
    Setter(GEB_MINMAX_REWARDS_ADJUSTER).addFundingReceiver(NEW_COLLATERAL_AUCTION_THROTTLER, 0x36b8b425, 86400, 1000, 100, 200);
    Setter(GEB_MINMAX_REWARDS_ADJUSTER).removeFundingReceiver(OLD_COLLATERAL_AUCTION_THROTTLER, 0x36b8b425);

    // adding new contract to GEB_REWARD_ADJUSTER_BUNDLER
    Setter(GEB_REWARD_ADJUSTER_BUNDLER).modifyParameters("addFunction", 0, 1, bytes4(0x36b8b425), NEW_COLLATERAL_AUCTION_THROTTLER);

    // removing old contract from GEB_REWARD_ADJUSTER_BUNDLER
    Setter(GEB_REWARD_ADJUSTER_BUNDLER).modifyParameters("removeFunction", 7, 1, 0x0, address(0));

    // removing old contract allowances on stability fee treasury
    Setter(GEB_STABILITY_FEE_TREASURY).setPerBlockAllowance(OLD_COLLATERAL_AUCTION_THROTTLER, 0);
    Setter(GEB_STABILITY_FEE_TREASURY).setTotalAllowance(OLD_COLLATERAL_AUCTION_THROTTLER, 0);
    Setter(GEB_STABILITY_FEE_TREASURY).setTotalAllowance(NEW_COLLATERAL_AUCTION_THROTTLER, uint(-1));
  }
}