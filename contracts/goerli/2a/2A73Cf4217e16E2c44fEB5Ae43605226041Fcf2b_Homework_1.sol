/**
 *Submitted for verification at Etherscan.io on 2022-11-15
*/

// SPDX-License-Identifier: UNLICENCED

pragma solidity ^0.8.17;

contract Homework_1 {

    uint transferValue;
    address public owner;
    mapping (address => uint) public senderToValue;

    constructor(){
        owner = msg.sender;
    }

    // Not needed since it's accessible in line 9
    function getSecretValue(address _user) external view returns(uint){
        return senderToValue[_user];
    }
    function sendSecretValue(uint _number) external {
        senderToValue[msg.sender] = _number;
    }

}