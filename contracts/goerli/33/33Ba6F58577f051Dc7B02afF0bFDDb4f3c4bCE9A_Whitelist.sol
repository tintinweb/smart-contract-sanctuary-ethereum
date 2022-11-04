// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.9;

contract Whitelist{
    //set the total number of whitelist addressses allowed
    uint8 public maxWhitelistedAddresses;

    //gives the current number of addresse whitelisted
    uint8 public numAddressesWhitelisted;

    //tracking addresses if whitelisted or not
    mapping(address => bool) public whitelistedAddresses;

    //all whitelistedAddres
    address[] whitelistedAddress;

    constructor(uint8 _maxWhitelistedAddresses) {
        maxWhitelistedAddresses =  _maxWhitelistedAddresses;
      }
    
    //Event
    event addressWhitelisted(address whitelistaddress, uint numAddressesWhitelisted);


    //function to whitelist address
    function addAddressToWhitelist() public {
    require(!whitelistedAddresses[msg.sender], "Address already whitelisted");
    require(numAddressesWhitelisted < maxWhitelistedAddresses, "maximum addresses allowed reached");

    whitelistedAddresses[msg.sender] = true;
    numAddressesWhitelisted += 1;

    whitelistedAddress.push(msg.sender);

    emit addressWhitelisted(msg.sender, numAddressesWhitelisted);
    }

    //this isn't gas efficient. suitable for limited address
    function allWhitelistedAddress() public view returns(address[] memory){

        return whitelistedAddress;
    }

}