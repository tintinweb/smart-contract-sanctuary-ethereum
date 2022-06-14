/**
 *Submitted for verification at Etherscan.io on 2022-06-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;


contract Whitelist{

    uint8 maxNoOfWhitelistAddress;
    uint8 countOfWhiteListedAddress;
    address[] public allWhiteListedAddress;
    mapping(address=>bool) public whitelistedAddressMap;

    constructor(uint8 _maxNoOfWhitelistAddress){
         maxNoOfWhitelistAddress = _maxNoOfWhitelistAddress;
     }

     function whitelist() public {
         require(!whitelistedAddressMap[msg.sender], "Address already whitelisted");
         require(countOfWhiteListedAddress<maxNoOfWhitelistAddress, "Max limit exceeded");

         whitelistedAddressMap[msg.sender] = true;
         allWhiteListedAddress.push(msg.sender);
         countOfWhiteListedAddress = countOfWhiteListedAddress + 1;
     }
}