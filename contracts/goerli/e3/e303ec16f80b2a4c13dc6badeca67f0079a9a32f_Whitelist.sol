/**
 *Submitted for verification at Etherscan.io on 2022-08-22
*/

// SDPX-License-Identifier: Unlicense

pragma solidity ^0.8.9;

contract Whitelist {

    address public owner;
    uint8 public numberOfWhitelistedAddresses;
    uint8 public maxWhitelistedAddresses;

    event Whitelisted(address whitelistAddress);

    mapping(address => bool) public _whitelistedAddresses;

    constructor(uint8 _maxWhitelistedAddresses) {
        owner = msg.sender;
        maxWhitelistedAddresses = _maxWhitelistedAddresses;
    }

    function whitelistAddress() external returns(bool success) {

        require(!_whitelistedAddresses[msg.sender], "User is already whitelisted");
        require(numberOfWhitelistedAddresses < maxWhitelistedAddresses, "The max whitelisted has exceeded");
        
        _whitelistedAddresses[msg.sender] = true;
        numberOfWhitelistedAddresses += 1;

        emit Whitelisted(msg.sender);

        return true;
    }


    function deWhitelistAddress(address addr) external returns(bool success) {

        require(_whitelistedAddresses[addr], "Address hasn't been whitelisted");
        require(msg.sender == owner, "Only the owner can dewhitelist an address");

        _whitelistedAddresses[addr] = false;
        numberOfWhitelistedAddresses -= 1;

        return true;
    }

}