/**
 *Submitted for verification at Etherscan.io on 2022-07-13
*/

pragma solidity 0.6.7;

abstract contract Setter {
  function addAuthorization(address) external virtual;
  function removeAuthorization(address) external virtual;
  function modifyParameters(bytes32, address) external virtual;
  function modifyParameters(bytes32, uint) external virtual;
}

contract Proposal {
  Setter constant GEB_STAKING = Setter(0x69c6C08B91010c88c95775B6FD768E5b04EFc106);
  Setter constant GEB_STAKING_AUCTION_HOUSE_NEW = Setter(0x12806f5784ee31494f4B9CD81b5E2E397500DFCa);
  address constant GEB_STAKING_AUCTION_HOUSE_OLD = 0x27da9f90255E56c2bcEC5F6360ed260BE70F3ab2;
  address constant GEB_ACCOUNTING_ENGINE = 0xcEe6Aa1aB47d0Fb0f24f51A3072EC16E20F90fcE;

  function execute(bool) external {
    // Setup staking
    GEB_STAKING.modifyParameters("auctionHouse", address(GEB_STAKING_AUCTION_HOUSE_NEW));
    GEB_STAKING.addAuthorization(address(GEB_STAKING_AUCTION_HOUSE_NEW));
    GEB_STAKING.removeAuthorization(GEB_STAKING_AUCTION_HOUSE_OLD);

    // Setup new auctionHouse
    GEB_STAKING_AUCTION_HOUSE_NEW.addAuthorization(address(GEB_STAKING));
    GEB_STAKING_AUCTION_HOUSE_NEW.modifyParameters("accountingEngine", GEB_ACCOUNTING_ENGINE);
    GEB_STAKING_AUCTION_HOUSE_NEW.modifyParameters("bidDuration", 1 hours);
    GEB_STAKING_AUCTION_HOUSE_NEW.modifyParameters("minBid", 10 * 10**45); // 10 RAD
  }
}