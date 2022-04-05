// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

import "./StandardToken.sol";

contract BlockchainDevToken is StandardToken {
    // Public variables of the token
    // NOTE: the following variables are OPTIONAL vanities. They don't have to be included to create a token
    // They allow you to customize the token contract and don't influence the functionality
    // Some wallets/interface may not even look at this information

    string public name; // Token name
    uint8 public decimals; // Nomer of decimals the token will have. To be standard compiant keep it at 18
    string public symbol; // Short identifier for contract
    uint256 public unitsOneEthCanBuy; // How many units of this token can be bought with 1 ETH?
    uint256 public totalRaisedEthInWei; // Total raised ETH in WEI of the ICO
    address payable public owner; // Raised ETH will go to this account

    constructor() {
        decimals = 18;
        _totalSupply = (1000 * (10**18));
        _balances[msg.sender] = _totalSupply;
        name = "Blockchain Dev Token";
        symbol = "BDT";
        unitsOneEthCanBuy = 10;
        owner = payable(msg.sender);
    }

    receive() external payable {
        totalRaisedEthInWei = totalRaisedEthInWei + msg.value;
        uint256 amount = msg.value * unitsOneEthCanBuy;
        require(_balances[owner] >= amount);
        _balances[owner] -= amount;
        _balances[msg.sender] += amount;
        emit Transfer(owner, msg.sender, amount);
        owner.transfer(msg.value);
    }
}