// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Bank {
    mapping(address => uint) balances;

    function withdraw() external {
        require(balances[msg.sender] > 0, "You don't have enough funds...");
        uint balance = balances[msg.sender];
        balances[msg.sender] = 0;
        (bool received, ) = msg.sender.call{value: balance}("");
        require(received, "Withdarw failed");
    }

    function deposit() external payable {
        require(msg.value >= 1, "Not enough funds provided");
        balances[msg.sender] += msg.value;
    }
}