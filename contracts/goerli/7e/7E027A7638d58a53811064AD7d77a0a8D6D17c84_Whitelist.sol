// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Whitelist {

    // Max number of whitelisted addresses allowe
    uint8 public maxwhitelistedAddresses;
     uint8 public numAddressesWhitelisted;
    // create mapping of WhitelistedAddress;
    // if an address is whitelisted , we should set it to true; it is false by default for al the address;
    mapping(address=>bool) public whitelistedAddresses;
   
    // setting the max number of whitelisted address
    // User will put the value at the time deployment

    constructor (uint8 _maxwhitelistedAddresses){
        maxwhitelistedAddresses = _maxwhitelistedAddresses;
    }
    // addressToWhitelist-This function adds the address of the sender to the whitelist
    function addAddressToWhitelist() public{
        // check if the user has already been whitelisted
        require(!whitelistedAddresses[msg.sender] ,"send has already been Whitelisted" );
        // check if the numAddresswhitelisted < maxwhitelistedAddress,if not then throw an error
        require(numAddressesWhitelisted < maxwhitelistedAddresses, "mores Address can't be added,limit reached");
        // add the address which called the function to the whitelistedAddress array
        whitelistedAddresses[msg.sender]= true; 
        // increase the number of whitelisted addresses
        numAddressesWhitelisted +=1;

    }
}