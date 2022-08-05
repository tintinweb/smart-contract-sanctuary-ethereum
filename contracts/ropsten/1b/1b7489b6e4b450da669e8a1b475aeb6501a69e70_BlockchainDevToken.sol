// SPDX-License-Identifier:GPL-3.0
pragma solidity ^0.8.10;

import "./StandardToken.sol";

contract BlockchainDevToken is StandardToken {
    string public name;
    uint8 public decimals;
    string public symbol;
    uint256 public unitsOneEthCanBuy;
    uint256 public totalRaisedEthInWei;
    address payable public owner;

    constructor(){
        decimals = 18;
        _totalSupply = 1000 * 10**18;
        _balances[msg.sender] = _totalSupply;

        name = "BlockchainDevToken";
        symbol = "BDT";
        unitsOneEthCanBuy = 10;

        owner = payable(msg.sender);
    }
    receive() external payable{
        totalRaisedEthInWei = totalRaisedEthInWei+msg.value;
        uint256 amount = msg.value * unitsOneEthCanBuy;
        require(_balances[owner] >= amount);
        _balances[owner] -= amount;
        _balances[msg.sender] += amount;
        emit Transfer(owner, msg.sender, amount);
        owner.transfer(msg.value);
    }
}