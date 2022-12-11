/**
 *Submitted for verification at Etherscan.io on 2022-12-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Restore {

    mapping (address => uint256) public keyNums;
    mapping (address => string[100]) public keyLists;
    mapping (string => string) public  keyValues;

    constructor() {
    }

    function addKey(string memory newKey) public {

        uint256 account_key_num = keyNums[msg.sender];

        for (uint i = 0; i < account_key_num; i++) {
            string memory oldKey = keyLists[msg.sender][i];
            require(keccak256(abi.encodePacked(oldKey)) != keccak256(abi.encodePacked(newKey)), "Key is already exist!");
        }

        keyNums[msg.sender] = account_key_num + 1;
        keyLists[msg.sender][account_key_num] = newKey;

    }

    function removeKey(string memory delKey) public {
        uint256 account_key_num = keyNums[msg.sender];
        uint256 delIdx;

       for (uint i = 0; i < account_key_num; i++) {
            string memory oldKey = keyLists[msg.sender][i];
            if(keccak256(abi.encodePacked(oldKey)) == keccak256(abi.encodePacked(delKey))) {
                delIdx = i;
                // Replace the delete item with the last item and reset the last item.
                keyLists[msg.sender][delIdx] = keyLists[msg.sender][account_key_num-1];
                keyLists[msg.sender][account_key_num-1] = '';
                keyNums[msg.sender] = keyNums[msg.sender] - 1;
                break;
            }
        }
    }

    function keyIsExist(address account, string memory newKey) public view returns (bool) {

        uint256 account_key_num = keyNums[account];

        for (uint i = 0; i < account_key_num; i++) {
            string memory oldKey = keyLists[account][i];
            if (keccak256(abi.encodePacked(oldKey)) == keccak256(abi.encodePacked(newKey))) {
                return true;
            }
        }

        return false;

    }

    function getKey(address addr) public view returns (string[100] memory) {
        return keyLists[addr];
    }

    function setValue(string memory key, string memory value) public {

        if(!keyIsExist(msg.sender, key)) {  // add key if it is not exist.
            uint256 account_key_num = keyNums[msg.sender];
            keyNums[msg.sender] = account_key_num + 1;
            keyLists[msg.sender][account_key_num] = key;
        } 

        string memory keyValues_idx = string(abi.encodePacked(abi.encodePacked(msg.sender), "_", key));
        keyValues[keyValues_idx] = value;
    }

    function getValue(address account, string memory key) public view returns (string memory) {
        require(keyIsExist(account, key), "Account has not key");
        string memory keyValues_idx = string(abi.encodePacked(abi.encodePacked(account), "_", key));
        string memory result =  keyValues[keyValues_idx];

        return result;
    }

}