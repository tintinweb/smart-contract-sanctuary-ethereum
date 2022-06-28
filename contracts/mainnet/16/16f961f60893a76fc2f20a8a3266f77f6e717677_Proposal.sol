/**
 *Submitted for verification at Etherscan.io on 2022-06-28
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
  address public constant DEBT_FLOOR_ADJUSTER_OVERLAY = 0xC6141Cbe06c4f0FA296C23308fDac9Da9bb7777a;
  Setter public constant GEB_DEBT_FLOOR_ADJUSTER_NEW = Setter(0x2de894805e1c8F955a81219F1D32b902E919a855);

  // addresses present in changelog
  address public constant GEB_DEBT_FLOOR_ADJUSTER_OLD = 0x0262Bd031B99c5fb99B47Dc4bEa691052f671447;
  Setter public constant GEB_COLLATERAL_AUCTION_HOUSE_ETH_A = Setter(0x7fFdF1Dfef2bfeE32054C8E922959fB235679aDE);
  Setter public constant GEB_SAFE_ENGINE = Setter(0xCC88a9d330da1133Df3A7bD823B95e52511A6962);
  Setter public constant INCREASING_TREASURY_REIMBURSEMENT_OVERLAY = Setter(0x1dCeE093a7C952260f591D9B8401318f2d2d72Ac);
  Setter public constant GEB_MINMAX_REWARDS_ADJUSTER = Setter(0x86EBA7b7dAaFEC537A2357f8A3a46026AF5Cb7bA);
  Setter public constant GEB_TREASURY_CORE_PARAM_ADJUSTER = Setter(0x73FEb3C2DBb87c8E0d040A7CD708F7497853B787);
  Setter public constant GEB_REWARD_ADJUSTER_BUNDLER = Setter(0x7F55e74C25647c100256D87629dee379D68bdCDe);

  function execute(bool) public {
    // Adjusting ETH-A collateral auction house discount
    GEB_COLLATERAL_AUCTION_HOUSE_ETH_A.modifyParameters("minDiscount", 980000000000000000); // 2% discount
    GEB_COLLATERAL_AUCTION_HOUSE_ETH_A.modifyParameters("perSecondDiscountUpdateRate", 999969118399461609393879753); // ~ 8%/45m

    // Swapping the auto surplus buffer
    // params
    GEB_DEBT_FLOOR_ADJUSTER_NEW.modifyParameters("maxRewardIncreaseDelay", 10800);   // 3 hours

    // auth in safe engine
    GEB_SAFE_ENGINE.addAuthorization(address(GEB_DEBT_FLOOR_ADJUSTER_NEW));

    // deauth old auto surplus buffer in safe engine
    GEB_SAFE_ENGINE.removeAuthorization(GEB_DEBT_FLOOR_ADJUSTER_OLD);

    // auth treasury reimbursement overlay on debt floor adjuster
    GEB_DEBT_FLOOR_ADJUSTER_NEW.addAuthorization(address(INCREASING_TREASURY_REIMBURSEMENT_OVERLAY));
    INCREASING_TREASURY_REIMBURSEMENT_OVERLAY.toggleReimburser(address(GEB_DEBT_FLOOR_ADJUSTER_NEW));
    INCREASING_TREASURY_REIMBURSEMENT_OVERLAY.toggleReimburser(GEB_DEBT_FLOOR_ADJUSTER_OLD);

    // auth new AUTO_SURPLUS_BUFFER_SETTER_OVERLAY
    GEB_DEBT_FLOOR_ADJUSTER_NEW.addAuthorization(address(DEBT_FLOOR_ADJUSTER_OVERLAY));
    GEB_DEBT_FLOOR_ADJUSTER_NEW.modifyParameters("auctionDiscount", 100000000000000000); // 10%

    // deauth DEPLOYER
    GEB_DEBT_FLOOR_ADJUSTER_NEW.removeAuthorization(DEPLOYER);

    // authing GEB_MINMAX_REWARDS_ADJUSTER
    GEB_DEBT_FLOOR_ADJUSTER_NEW.addAuthorization(address(GEB_MINMAX_REWARDS_ADJUSTER));

    // add/remove old from GEB_TREASURY_CORE_PARAM_ADJUSTER,  recomputeCollateralDebtFloor(address)
    GEB_TREASURY_CORE_PARAM_ADJUSTER.addFundedFunction(address(GEB_DEBT_FLOOR_ADJUSTER_NEW), 0x341369c1, 26);
    GEB_TREASURY_CORE_PARAM_ADJUSTER.removeFundedFunction(GEB_DEBT_FLOOR_ADJUSTER_OLD, 0x341369c1);

    // add/remove old from GEB_MINMAX_REWARDS_ADJUSTER, same params
    GEB_MINMAX_REWARDS_ADJUSTER.addFundingReceiver(address(GEB_DEBT_FLOOR_ADJUSTER_NEW), 0x341369c1, 86400, 150000, 100, 200);
    GEB_MINMAX_REWARDS_ADJUSTER.removeFundingReceiver(GEB_DEBT_FLOOR_ADJUSTER_OLD, 0x341369c1);

    // adding new contract to GEB_REWARD_ADJUSTER_BUNDLER
    GEB_REWARD_ADJUSTER_BUNDLER.modifyParameters("addFunction", 0, 1, bytes4(0x341369c1), address(GEB_DEBT_FLOOR_ADJUSTER_NEW));

    // removing old contract from GEB_REWARD_ADJUSTER_BUNDLER
    GEB_REWARD_ADJUSTER_BUNDLER.modifyParameters("removeFunction", 8, 1, 0x0, address(0));
  }
}