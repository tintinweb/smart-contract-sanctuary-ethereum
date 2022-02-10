// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
interface Ownable {
  function owner() external returns (address);
}
contract Royalty {
  struct Royaltydef {
    address receiver;
    uint32 amount;
    bool permanent;
  }
  mapping (address => Royaltydef) public royalty;
  function set(address collection, Royaltydef calldata def) external {
    require(Ownable(collection).owner() == msg.sender, "1");
    require(def.amount <= 1000000, "2");
    require(royalty[collection].permanent == false, "3");
    royalty[collection] = def;
  }
  function get(address collection, uint tokenId, uint value) external view returns (address, uint) {
    Royaltydef memory r = royalty[collection];
    return(r.receiver, value * r.amount/1000000);
  }
}