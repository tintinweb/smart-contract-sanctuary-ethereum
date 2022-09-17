//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;


contract Whitelist {
  uint256 public maxWhitelistedAddress;
  mapping(address => bool) public whitelistAddresses;

  uint256 public numAddressWhitelisted;

  constructor(uint256 _maxWhitelistedAddresses) {
    maxWhitelistedAddress = _maxWhitelistedAddresses;
  }

  function addAddressToWhitelist(address account) public {
    require(!whitelistAddresses[account], "Sender has already been whitelisted");
    require(numAddressWhitelisted < maxWhitelistedAddress, "More addresses can't be added, limit reached");
    whitelistAddresses[account] = true;
    numAddressWhitelisted += 1;
  }
}