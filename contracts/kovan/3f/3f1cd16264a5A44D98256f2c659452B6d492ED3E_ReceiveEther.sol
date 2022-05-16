/**
 *Submitted for verification at Etherscan.io on 2022-05-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract ReceiveEther {
    bytes public funcName;
    uint public totalBalance;
    event FuncActive(string funcName);
    fallback() external payable {
        funcName = "fallback";
        emit FuncActive("fallback");
    }

    receive() external payable {
        funcName = "receive";
        emit FuncActive("receive");
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function deposit() public payable {
        totalBalance += msg.value;
    }
}