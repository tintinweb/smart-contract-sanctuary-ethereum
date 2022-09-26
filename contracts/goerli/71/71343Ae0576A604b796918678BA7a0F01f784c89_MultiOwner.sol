/**
 *Submitted for verification at Etherscan.io on 2022-09-25
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract MultiOwner {
    string private text;
    address[] public owners;
    bool ownerExists;

    constructor() {
        owners = [msg.sender, 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2];
    }

    function listOwners() public view returns(address[] memory) {
        return owners;
    }

    function addOwner(address i) public onlyOwner {
        require(!checkOwnerExists(i) , "owner exists mister");
        owners.push(i);
    }

    function removeOwner(address owner) public onlyOwner { 
        require(checkOwnerExists(owner) , "nope");
        uint loc;
        for (uint i=0; i < owners.length; i++ ) {
            if (owner == owners[i]) {
                loc = i;
            }
        }
        delete owners[loc];
        for (uint i = loc; i < owners.length-1; i++ ) {
            owners[i] = owners[i+1];
        }
        owners.pop();
    }

    function checkOwnerExists(address addressOwner) internal returns (bool) {
        for (uint i=0; i < owners.length; i++ ) {
            if (addressOwner == owners[i]) {
                return ownerExists = true;
            }
        }
        return ownerExists = false;
    }

    modifier onlyOwner() {
        require(checkOwnerExists(msg.sender), "pls ser, u are not the owner");
        _;
    }
}