/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

pragma solidity 0.6.7;

abstract contract Setter {
  function removeAuthorization(address) public virtual;
}

contract UngovernanceProposal1 {
  // addresses
  address public constant GEB_TAX_COLLECTOR                  = 0xcDB05aEda142a1B0D6044C09C64e4226c1a281EB;
  address public constant GEB_LIQUIDATION_ENGINE             = 0x27Efc6FFE79692E0521E7e27657cF228240A06c2;
  address public constant GEB_SURPLUS_AUCTION_HOUSE          = 0x4EEfDaE928ca97817302242a851f317Be1B85C90;
  address public constant GEB_DEBT_AUCTION_HOUSE             = 0x1896adBE708bF91158748B3F33738Ba497A69e8f;
  address public constant GEB_ORACLE_RELAYER                 = 0x4ed9C0dCa0479bC64d8f4EB3007126D5791f7851;
  address public constant GEB_ESM                            = 0xa33Ea2Ac39902d4A206D6A1F8D38c7330C80f094;
  address public constant GEB_ESM_THRESHOLD_SETTER           = 0x5E79C6Db9a04039B593877B96f885374470eFB90;
  address public constant GEB_COLLATERAL_AUCTION_HOUSE_ETH_A = 0x9fC9ae5c87FD07368e87D1EA0970a6fC1E6dD6Cb;
  address public constant GEB_PAUSE_PROXY                    = 0xa57A4e6170930ac547C147CdF26aE4682FA8262E;

  function execute(bool) public {
    Setter(GEB_TAX_COLLECTOR).removeAuthorization(GEB_PAUSE_PROXY);
    Setter(GEB_LIQUIDATION_ENGINE).removeAuthorization(GEB_PAUSE_PROXY);
    Setter(GEB_SURPLUS_AUCTION_HOUSE).removeAuthorization(GEB_PAUSE_PROXY);
    Setter(GEB_DEBT_AUCTION_HOUSE).removeAuthorization(GEB_PAUSE_PROXY);
    Setter(GEB_ORACLE_RELAYER).removeAuthorization(GEB_PAUSE_PROXY);
    Setter(GEB_ESM).removeAuthorization(GEB_PAUSE_PROXY);
    Setter(GEB_ESM_THRESHOLD_SETTER).removeAuthorization(GEB_PAUSE_PROXY);
    Setter(GEB_COLLATERAL_AUCTION_HOUSE_ETH_A).removeAuthorization(GEB_PAUSE_PROXY);
  }
}