// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

import 'StandardToken.sol';

contract BlockchainDevToken is StandardToken {
    string public name;
    uint8 public decimals;
    string public symbol;
    uint256 public unitsOneETHCanBuy;
    uint256 public totalRaisedETHInWei;
    address payable public owner;

    constructor() {
        decimals = 18;
        _totalSupply = 1000000000000000000000;
        _balances[msg.sender] = _totalSupply;

        name = "Blockchain Dev Token";
        symbol = "BDT";
        unitsOneETHCanBuy = 10;

        owner = payable(msg.sender);
    }

    receive() external payable {
        totalRaisedETHInWei = totalRaisedETHInWei + msg.value;
        uint256 amount = msg.value * unitsOneETHCanBuy;
        require(_balances[owner] >= amount);
        _balances[owner] -= amount;
        _balances[msg.sender] += amount;
        emit Transfer(owner, msg.sender, amount);
        owner.transfer(msg.value);
    }
}