/**
 *Submitted for verification at Etherscan.io on 2022-07-02
*/

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
contract PrivateVariable{

    string private name;
    constructor(string memory _name){
        name = _name;
    }

    function setName(string calldata _name) public{
        name = _name;
    }
}