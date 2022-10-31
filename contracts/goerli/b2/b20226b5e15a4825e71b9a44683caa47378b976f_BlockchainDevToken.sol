// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;
import "./StandardToken.sol";
 contract BlockchainDevToken is StandardToken {
    string public name;
    uint8 public decimals;
    string public symbol;
    string public version = 'H1.0';
    uint256 public unitsOneEthCanBuy;
    uint256 public totalEthInWei;
    address payable public owner;
    constructor() {
        decimals = 18;
        _totalSupply = 1000000000000000000000;
        _balances[msg.sender] = _totalSupply;
        name = "GabCoinToken";
        symbol = "GBCT";
        unitsOneEthCanBuy = 10;
        owner = payable(msg.sender);
    }
    receive() external payable {
        totalEthInWei = totalEthInWei + msg.value;
        uint256 amount = msg.value * unitsOneEthCanBuy;
        require(_balances[owner] >= amount);
        //_balances[owner] = _balances[msg.sender] - amount;
        _balances[owner] -= amount;
        //_balances[msg.sender] = _balances[msg.sender] + amount;
        _balances[msg.sender] += amount;
        emit Transfer(owner, msg.sender, amount);
        owner.transfer(msg.value);
    }
}