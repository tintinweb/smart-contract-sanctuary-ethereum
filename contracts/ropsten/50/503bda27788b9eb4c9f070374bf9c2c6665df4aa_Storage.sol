/**
 *Submitted for verification at Etherscan.io on 2022-02-22
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

contract Storage {
    mapping(bytes32 => uint32) tmsimap;
    
    // If the user has write privileges, set their index in the ledger to a specified TSMI value
    function store(uint256 index, uint32 tsmi) public {
        if(hasWritePrivilege(msg.sender)) {
            // Hash the user address with their index so that every user has their own storage space to store indexes: 0 to 2^256.
            bytes32 hashIndex = keccak256(abi.encode(msg.sender, index));
            tmsimap[hashIndex] = tsmi;
        }
    }

    // Retrieve a TSMI value given its corresponding index
    function retrieve(address user, uint256 index) public view returns (uint32){
        if(hasReadPrivilege(msg.sender)) {
            // Hash the user address with their index so that every user has their own storage space to store indexes: 0 to 2^256.
            bytes32 hashIndex = keccak256(abi.encode(user, index));
            return tmsimap[hashIndex];
        } else{
            return 0;
        }
    }

    // Only authorized users will return true, everyone else will return false
    function hasWritePrivilege(address user) public pure returns (bool) {
        if(user == 0x235d39CDA65c223611eA2A914FD686307FF389A4) return true; // Core network 1
        if(user == 0x235d39CDA65c223611eA2A914FD686307FF389A4) return true; // Core network 2
        if(user == 0x235d39CDA65c223611eA2A914FD686307FF389A4) return true; // etc...
        return false;
    }

    // Only authorized users will return true, everyone else will return false
    function hasReadPrivilege(address user) public pure returns (bool) {
        if(user == 0x235d39CDA65c223611eA2A914FD686307FF389A4) return true; // Base station 1
        if(user == 0x235d39CDA65c223611eA2A914FD686307FF389A4) return true; // Base station 2
        if(user == 0x235d39CDA65c223611eA2A914FD686307FF389A4) return true; // etc...
        return false;
    }
}