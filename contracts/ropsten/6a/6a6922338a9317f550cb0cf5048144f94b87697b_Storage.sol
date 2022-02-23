/**
 *Submitted for verification at Etherscan.io on 2022-02-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.1;

contract Storage {

    mapping(bytes32 => uint32) tmsimap;

    // If the user has write privileges, set their index in the ledger to a specified TSMI value
    function store(uint256 index, uint32 tsmi) public {
        if(hasWritePrivilege(msg.sender)) {
            // Hash the user address with their index so that every user has their own storage space to store indexes 0 to 2^256.
            bytes32 hashIndex = keccak256(abi.encode(msg.sender, index));
            tmsimap[hashIndex] = tsmi;
        }
    }

    // Retrieve a TSMI value given its corresponding index
    function retrieve(bytes32 index) public view returns (uint32){
        return tmsimap[index];
    }

    // Only authorized users will return true, everyone else will return false
    function hasWritePrivilege(address user) public pure returns (bool) {
        if(user == 0x955C7eD6FEEBb09B924913c25e22A92913e4A1Df) return true; // AT&T address
        if(user == 0x955C7eD6FEEBb09B924913c25e22A92913e4A1Df) return true; // T-Mobile address
        if(user == 0x955C7eD6FEEBb09B924913c25e22A92913e4A1Df) return true; // etc...
        return false;
    }
}