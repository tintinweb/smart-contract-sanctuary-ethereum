/**
 *Submitted for verification at Etherscan.io on 2022-10-20
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

//This is a Whitelist-Dapp tutorial from LearnWeb3Dao

contract Whitelist {

  // Max number of whitelisted addresses allowed
  uint8 public maxWhitelistedAddresses;

  // Create a mapping of maxWhitelistedAddresses
  // if an address is whitelisted, we would set it to true, it is false by default for al other addresses.
  mapping(address => bool) public whitelistedAddresses;

  // numAddressesWhitelisted would be used to keep track of how many addresses have been whitelistedAddresses
  // NOTE: Don't change this variable name, as it will be part of verification
  uint8 public numAddressesWhitelisted;

  // Setting the Max number of whitelisted addresses
  // User will put the value at the time of deployment
  constructor(uint8 _maxWhitelistedAddresses) {
    maxWhitelistedAddresses = _maxWhitelistedAddresses;
  }

  /**
    addAddressToWhitelist - This function adds the address of the sender to the whitelist
  */
  function addAddressToWhitelist() public {
    // check if the user has already been whitelisted
    require(!whitelistedAddresses[msg.sender], "Sender has already been whitelisted");
    require(numAddressesWhitelisted < maxWhitelistedAddresses, "More addresses cant be aded, limit reached");
    // add the address which called the function to the whitelistedAddress Array
    whitelistedAddresses[msg.sender] = true;
    // increaes the number of whitelisted numAddressesWhitelisted
    numAddressesWhitelisted += 1;
  }
}