// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;




contract WhatIsTimeDeposit {

    event Add(address indexed from, address indexed to, uint256 indexed amount);

    address payable immutable owner = payable(0x3aF62191AEAdDE80188d86597fB57CaDaA919DdF);

    function BuyTime() external payable {
        require(msg.value > 0);
        emit Add(msg.sender, owner, msg.value);
    }

    function withdraw() external {
        require(msg.sender == owner);
        owner.transfer(address(this).balance);
    }
}