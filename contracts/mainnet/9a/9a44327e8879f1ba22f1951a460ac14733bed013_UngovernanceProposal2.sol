/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

pragma solidity 0.6.7;

abstract contract Setter {
  function removeAuthorization(address) public virtual;
}

contract UngovernanceProposal2 {
  // addresses
  address public constant GEB_COIN_JOIN       = 0x0A5653CCa4DB1B6E265F47CAf6969e64f1CFdC45;
  address public constant GEB_COIN            = 0x03ab458634910AaD20eF5f1C8ee96F1D6ac54919;
  address public constant GEB_JOIN_ETH_A      = 0x2D3cD7b81c93f188F3CB8aD87c8Acc73d6226e3A;
  address public constant GEB_PAUSE_PROXY     = 0xa57A4e6170930ac547C147CdF26aE4682FA8262E;

  function execute(bool) public {
    Setter(GEB_COIN_JOIN).removeAuthorization(GEB_PAUSE_PROXY);
    Setter(GEB_COIN).removeAuthorization(GEB_PAUSE_PROXY);
    Setter(GEB_JOIN_ETH_A).removeAuthorization(GEB_PAUSE_PROXY);
  }
}