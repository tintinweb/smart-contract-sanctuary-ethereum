/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

pragma solidity 0.6.7;

abstract contract Setter {
  function removeAuthorization(address) public virtual;
}

contract UngovernanceProposal3 {
  // addresses
  address public constant GEB_SINGLE_CEILING_SETTER             = 0x54999Ee378b339f405a4a8a1c2f7722CD25960fa;
  address public constant COLLATERAL_AUCTION_THROTTLER          = 0x59536C9Ad1a390fA0F60813b2a4e8B957903Efc7;
  address public constant GEB_DEBT_FLOOR_ADJUSTER               = 0x0262Bd031B99c5fb99B47Dc4bEa691052f671447;
  address public constant GEB_AUTO_SURPLUS_BUFFER               = 0x9fe16154582ecCe3414536FdE57A201c17398b2A;
  address public constant GEB_AUTO_SURPLUS_AUCTIONED            = 0xa43BFA2a04c355128F3f10788232feeB2f42FE98;
  address public constant GEB_DEBT_AUCTION_INITIAL_PARAM_SETTER = 0x7df2d51e69aA58B69C3dF18D75b8e9ACc3C1B04E;
  address public constant GEB_REDEMPTION_PRICE_SNAP             = 0x07210B8871073228626AB79c296d9b22238f63cE;
  address public constant GEB_PAUSE_PROXY                       = 0xa57A4e6170930ac547C147CdF26aE4682FA8262E;

  function execute(bool) public {
    Setter(GEB_SINGLE_CEILING_SETTER).removeAuthorization(GEB_PAUSE_PROXY);
    Setter(COLLATERAL_AUCTION_THROTTLER).removeAuthorization(GEB_PAUSE_PROXY);
    Setter(GEB_DEBT_FLOOR_ADJUSTER).removeAuthorization(GEB_PAUSE_PROXY);
    Setter(GEB_AUTO_SURPLUS_BUFFER).removeAuthorization(GEB_PAUSE_PROXY);
    Setter(GEB_AUTO_SURPLUS_AUCTIONED).removeAuthorization(GEB_PAUSE_PROXY);
    Setter(GEB_DEBT_AUCTION_INITIAL_PARAM_SETTER).removeAuthorization(GEB_PAUSE_PROXY);
    Setter(GEB_REDEMPTION_PRICE_SNAP).removeAuthorization(GEB_PAUSE_PROXY);
  }
}