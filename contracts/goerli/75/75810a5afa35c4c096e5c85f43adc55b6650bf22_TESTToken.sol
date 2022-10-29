pragma solidity ^0.8.9;
// SPDX-License-Identifier: MIT


contract TESTToken {

    uint airdropbalance;

    constructor() {
        uint initialSupply = 100000000000000;
        airdropbalance = (initialSupply * 20) / 100;
        initialSupply = initialSupply - airdropbalance;
    }

    function airdrop(address[] memory _recipients, uint256[] memory _amount)
        public        
        returns (bool)
    {
        uint total = 0;

        for (uint j = 0; j < _amount.length; j++) {
            total += _amount[j];
        }

        require(total <= airdropbalance, "Insufficient balance!");
        require(_recipients.length == _amount.length, "Lists not equal!");

        airdropbalance -= total;
        return true;
    }
}