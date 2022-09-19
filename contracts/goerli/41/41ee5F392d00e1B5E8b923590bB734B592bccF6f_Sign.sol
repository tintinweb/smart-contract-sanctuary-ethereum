/**
 *Submitted for verification at Etherscan.io on 2022-09-18
*/

// SPDX-License-Identifier: GPL-3.0


pragma solidity 0.8.17;

contract Sign{

    //EnumerableSet.Bytes32Set private transactions;
    string public name; // 0x1234564566546
    string public signPrefix = "Recorded Hash: ";

    constructor(string memory initialName){
        name = initialName;
    }

    function setName(string memory newName)public {
        name = newName;
    }


    function getSign() public view returns (string memory){
        return string(abi.encodePacked(signPrefix, name));
    }
}