/**
 *Submitted for verification at Etherscan.io on 2022-09-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Whitelist {
  uint8 public maxWhitelistedAddresses;

  mapping(address => bool) public whitelistedAddresses;

  uint8 public numAddressesWhitelisted;

  constructor(uint8 _maxWhitelistedAddresses){
    maxWhitelistedAddresses = _maxWhitelistedAddresses;
  }

  function addAddressToWhitelist() public {
    require(!whitelistedAddresses[msg.sender], "Sender has already been whitelisted");

    require(numAddressesWhitelisted<maxWhitelistedAddresses, "Sender has already been whitelisted");

    whitelistedAddresses[msg.sender] = true;

    numAddressesWhitelisted++;
  }
}