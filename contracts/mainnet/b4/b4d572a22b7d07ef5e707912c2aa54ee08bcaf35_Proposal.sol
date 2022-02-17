/**
 *Submitted for verification at Etherscan.io on 2022-02-17
*/

pragma solidity 0.6.7;

abstract contract Setter {
  function modifyParameters(bytes32, uint256) public virtual;
  function addAuthorization(address) public virtual;
  function removeAuthorization(address) public virtual;
}

contract Proposal {
  // addresses
  address public constant OLD_TAX_COLLECTOR_OVERLAY     = 0x42Fc2F8A6C712d4cbf00fC67FE05aDAcFEbDe382;
  address public constant NEW_TAX_COLLECTOR_OVERLAY     = 0x95f5B549E4FDdde4433Ab20Bae35F97F473f4A6F;
  address public constant GEB_TAX_COLLECTOR             = 0xcDB05aEda142a1B0D6044C09C64e4226c1a281EB;
  address public constant GEB_SINGLE_CEILING_SETTER     = 0x54999Ee378b339f405a4a8a1c2f7722CD25960fa;
  address public constant DEBT_CEILING_SETTER_OVERLAY   = 0x840004858f8293D2BBc9F52bAf2bEC895088d683;
  address public constant GEB_SURPLUS_AUCTION_HOUSE     = 0x4EEfDaE928ca97817302242a851f317Be1B85C90;
  address public constant GEB_ACCOUNTING_ENGINE         = 0xcEe6Aa1aB47d0Fb0f24f51A3072EC16E20F90fcE;
  address public constant deployer                      = 0x3E0139cE3533a42A7D342841aEE69aB2BfEE1d51;


  function execute(bool) public {
    // Set the ETH-A SF bounds to 0.1% and 2% - Upper bound ok, lower bound to be adjusted in the proposal.
    Setter(GEB_TAX_COLLECTOR).addAuthorization(NEW_TAX_COLLECTOR_OVERLAY);
    Setter(GEB_TAX_COLLECTOR).removeAuthorization(OLD_TAX_COLLECTOR_OVERLAY);
    // remove deployer access
    Setter(NEW_TAX_COLLECTOR_OVERLAY).removeAuthorization(deployer);

    // Deauthorize the ceiling setter overlay from the single ceiling setter contract.
    Setter(GEB_SINGLE_CEILING_SETTER).removeAuthorization(DEBT_CEILING_SETTER_OVERLAY);

    // Surplus auction params
    // Set bidDuration in surplus auction house to 90 minutes.
    Setter(GEB_SURPLUS_AUCTION_HOUSE).modifyParameters("bidDuration", 5400);
    // Set surplusAuctionDelay on accountingEngine to 2 hours.
    Setter(GEB_ACCOUNTING_ENGINE).modifyParameters("surplusAuctionDelay", 7200);
  }
}