// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.8;

// 🚨 Warning! This contract contains a critical bug. Can you find it and exploit it?

contract Vault {

    mapping(address => uint256) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw() public {
        require(balances[msg.sender] > 0, "You don't have money in this contract");
        (bool sent, ) = msg.sender.call{value: balances[msg.sender]}("");
        require(sent, "Send failed");
        balances[msg.sender] = 0;
    }

}