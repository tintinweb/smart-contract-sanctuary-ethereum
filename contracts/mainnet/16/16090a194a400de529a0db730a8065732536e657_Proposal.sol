/**
 *Submitted for verification at Etherscan.io on 2022-06-23
*/

pragma solidity 0.6.7;

abstract contract Auth {
  function addAuthorization(address) public virtual;
  function removeAuthorization(address) public virtual;
}

abstract contract Setter is Auth {
  function modifyParameters(bytes32, address) public virtual;
  function modifyParameters(bytes32, uint) public virtual;
  function addFundedFunction(address, bytes4, uint) public virtual;
  function removeFundedFunction(address, bytes4) public virtual;
  function addFundingReceiver(address, bytes4, uint, uint, uint, uint) public virtual;
  function removeFundingReceiver(address, bytes4) public virtual;
  function toggleReimburser(address) public virtual;
  function modifyParameters(bytes32, uint256, uint256, bytes4, address) public virtual;
}

contract Proposal {
  // new contracts
  address public constant DEPLOYER = 0x3E0139cE3533a42A7D342841aEE69aB2BfEE1d51;
  address public constant GEB_AUTO_SURPLUS_BUFFER_OLD = 0x9fe16154582ecCe3414536FdE57A201c17398b2A;
  Setter public constant GEB_AUTO_SURPLUS_BUFFER_NEW = Setter(0x5376BC11C92189684B4B73282F8d6b30a434D31C);
  Setter public constant AUTO_SURPLUS_BUFFER_SETTER_OVERLAY_NEW = Setter(0x66D18df8a6f3b2399691249A11465e7c93F2240A);

  // addresses present in changelog
  Setter public constant GEB_ACCOUNTING_ENGINE = Setter(0xcEe6Aa1aB47d0Fb0f24f51A3072EC16E20F90fcE);
  Setter public constant INCREASING_TREASURY_REIMBURSEMENT_OVERLAY = Setter(0x1dCeE093a7C952260f591D9B8401318f2d2d72Ac);
  Setter public constant GEB_MINMAX_REWARDS_ADJUSTER = Setter(0x86EBA7b7dAaFEC537A2357f8A3a46026AF5Cb7bA);
  Setter public constant GEB_TREASURY_CORE_PARAM_ADJUSTER = Setter(0x73FEb3C2DBb87c8E0d040A7CD708F7497853B787);
  Setter public constant GEB_REWARD_ADJUSTER_BUNDLER = Setter(0x7F55e74C25647c100256D87629dee379D68bdCDe);

  function execute(bool) public {
    // Swapping the auto surplus buffer
    // params
    GEB_AUTO_SURPLUS_BUFFER_NEW.modifyParameters("maxRewardIncreaseDelay", 10800);   // 3 hours

    // auth in accounting engine
    GEB_ACCOUNTING_ENGINE.addAuthorization(address(GEB_AUTO_SURPLUS_BUFFER_NEW));

    // deauth old auto surplus buffer in accounting engine
    GEB_ACCOUNTING_ENGINE.removeAuthorization(GEB_AUTO_SURPLUS_BUFFER_OLD);

    // auth treasury reimbursement overlay on auto surplus buffer
    GEB_AUTO_SURPLUS_BUFFER_NEW.addAuthorization(address(INCREASING_TREASURY_REIMBURSEMENT_OVERLAY));
    INCREASING_TREASURY_REIMBURSEMENT_OVERLAY.toggleReimburser(address(GEB_AUTO_SURPLUS_BUFFER_NEW));
    INCREASING_TREASURY_REIMBURSEMENT_OVERLAY.toggleReimburser(GEB_AUTO_SURPLUS_BUFFER_OLD);

    // auth new AUTO_SURPLUS_BUFFER_SETTER_OVERLAY
    GEB_AUTO_SURPLUS_BUFFER_NEW.addAuthorization(address(AUTO_SURPLUS_BUFFER_SETTER_OVERLAY_NEW));

    // deauth DEPLOYER
    GEB_AUTO_SURPLUS_BUFFER_NEW.removeAuthorization(DEPLOYER);

    // remove DEPLOYER auth from new overlay
    AUTO_SURPLUS_BUFFER_SETTER_OVERLAY_NEW.removeAuthorization(DEPLOYER);

    // authing GEB_MINMAX_REWARDS_ADJUSTER
    GEB_AUTO_SURPLUS_BUFFER_NEW.addAuthorization(address(GEB_MINMAX_REWARDS_ADJUSTER));

    // add/remove old from GEB_TREASURY_CORE_PARAM_ADJUSTER, adjustSurplusBuffer(address), current latestExpectedCalls
    GEB_TREASURY_CORE_PARAM_ADJUSTER.addFundedFunction(address(GEB_AUTO_SURPLUS_BUFFER_NEW), 0xbf1ad0db, 26);
    GEB_TREASURY_CORE_PARAM_ADJUSTER.removeFundedFunction(GEB_AUTO_SURPLUS_BUFFER_OLD, 0xbf1ad0db);

    // add/remove old from GEB_MINMAX_REWARDS_ADJUSTER, same params
    GEB_MINMAX_REWARDS_ADJUSTER.addFundingReceiver(address(GEB_AUTO_SURPLUS_BUFFER_NEW), 0xbf1ad0db, 86400, 1000, 100, 200);
    GEB_MINMAX_REWARDS_ADJUSTER.removeFundingReceiver(GEB_AUTO_SURPLUS_BUFFER_OLD, 0xbf1ad0db);

    // adding new contract to GEB_REWARD_ADJUSTER_BUNDLER
    GEB_REWARD_ADJUSTER_BUNDLER.modifyParameters("addFunction", 0, 1, bytes4(0xbf1ad0db), address(GEB_AUTO_SURPLUS_BUFFER_NEW));

    // removing old contract from GEB_REWARD_ADJUSTER_BUNDLER
    GEB_REWARD_ADJUSTER_BUNDLER.modifyParameters("removeFunction", 12, 1, 0x0, address(0));
  }
}