// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library ProxyBotConfig {

  // An enum of the three status modes:
  // 0 = Pending: Not boomeranged.
  // 1 = Connected: Boomeranged.
  // 2 = Void: This was once valid but the vault has since boomeranged a new token.
  enum Status { Pending, Connected, Void }

  // Returns a nice string representation of the status of the token with the given ID, suitable for display.
  function prettyStatusOf(Status s) public pure returns (string memory) {
    if(s == Status.Pending){
      return "Pending";
    } else if(s == Status.Connected){
      return "Connected";
    } else {
      return "Void";
    }
  }
  
  // Just a wee helper function to compare string equality.
  function stringsEqual(string memory _a, string memory _b) public pure returns (bool) {
    return keccak256(abi.encodePacked(_a)) == keccak256(abi.encodePacked(_b));
  }

}