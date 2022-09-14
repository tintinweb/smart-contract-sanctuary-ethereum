// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

error Whitelist__AlreadyWhitelisted();
error Whitelist__WhitelistLimitReached();

contract Whitelist 
{
  // max number of whitelisted addresses
  uint256 public s_maxWhitelistedAddresses;
  uint256 public s_addressesWhitelisted;
  mapping(address => bool) public s_whitelistedAddresses;

  constructor(uint256 maxWhitelistedAddress_)
  {
    s_maxWhitelistedAddresses = maxWhitelistedAddress_;
  }

  /**
   * this function adds the sender address to the whitelist mapping
   */

  function addAddress() public {
    if(!s_whitelistedAddresses[msg.sender]){revert Whitelist__AlreadyWhitelisted();}
    if(s_addressesWhitelisted >= s_maxWhitelistedAddresses){revert Whitelist__WhitelistLimitReached();}
    s_whitelistedAddresses[msg.sender] = true;
    s_addressesWhitelisted += 1;
  }
}