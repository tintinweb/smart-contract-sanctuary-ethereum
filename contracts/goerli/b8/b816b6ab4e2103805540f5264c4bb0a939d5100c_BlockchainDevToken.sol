// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

import "./StandardToken.sol";

contract BlockchainDevToken is StandardToken{

    string public name;
    uint8 public decimals;
    string public symbol;
    uint256 public unitsOneEthCanBuy;
    uint256 public totalRaisedEthInWei;
    address payable public owner;

    constructor(){
        decimals = 18;
        _totalSupply = 1000000000000000000000;
        _balances[msg.sender] = _totalSupply;
        name = "Meta Mask Token";
        symbol = "MMT";
        unitsOneEthCanBuy = 10;
        owner = payable(msg.sender);
    }

    function recieve() external payable {
        totalRaisedEthInWei = totalRaisedEthInWei + msg.value;
        uint256 amount = msg.value * unitsOneEthCanBuy;
        require(_balances[owner] >= amount);
        _balances[owner] -= amount;
        _balances[msg.sender] += amount;
        emit Transfer(owner, msg.sender, amount);
        owner.transfer(msg.value);
    }
}