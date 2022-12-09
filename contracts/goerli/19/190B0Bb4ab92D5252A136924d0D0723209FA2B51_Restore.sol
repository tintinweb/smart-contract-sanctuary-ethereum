/**
 *Submitted for verification at Etherscan.io on 2022-12-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Restore {

    mapping (address => uint256) public keyNums;
    mapping (address => string[100]) public keyLists; 

    constructor() {

    }

    function addKey(string memory newKey) public {

        uint256 account_key_num = keyNums[msg.sender];

        for (uint i = 0; i < account_key_num; i++) {
            string memory oldKey = keyLists[msg.sender][i];
            require(keccak256(bytes(oldKey)) == keccak256(bytes(newKey)), "Key is already exist!");
        }

        account_key_num = account_key_num + 1;
        keyNums[msg.sender] = account_key_num;
        keyLists[msg.sender][account_key_num] = newKey;

    }

    function removeKey(string memory delKey) public {
        uint256 account_key_num = keyNums[msg.sender];
        uint256 delIdx;

       for (uint i = 0; i < account_key_num; i++) {
            string memory oldKey = keyLists[msg.sender][i];
            if(keccak256(bytes(oldKey)) == keccak256(bytes(delKey))) {
                delIdx = i;
                break;
            }
        }

        // Replace the delete item with the last item and reset the last item.
        keyLists[msg.sender][delIdx] = keyLists[msg.sender][account_key_num-1];
        keyLists[msg.sender][account_key_num-1] = '';
        keyNums[msg.sender] = keyNums[msg.sender] - 1;
    }

    function getKey(address addr) public view returns (string[100] memory) {
        return keyLists[addr];

    }



}