/**
 *Submitted for verification at Etherscan.io on 2022-11-09
*/

// File: contracts/learnweb3/sophomore/whitelist.sol

// "SPDX-License-Identifier: MIT"

pragma solidity^0.8.7;

contract whitelist{
 
   
   uint8 maxWhitelistedAddresses;
   mapping(address=>bool) public whitelistedAddress;
   uint8 public numAddressesWhitelisted;

   constructor(uint8 _maxWhitelistedAddresses){
       maxWhitelistedAddresses = _maxWhitelistedAddresses;
   }

   function addAdressTowhitelist() public {

       require(numAddressesWhitelisted<maxWhitelistedAddresses, "whitelist limit reached");
       require(!whitelistedAddress[msg.sender], "Address already whitelisted");

       numAddressesWhitelisted = numAddressesWhitelisted +1;
       whitelistedAddress[msg.sender] = true;

   } 

}