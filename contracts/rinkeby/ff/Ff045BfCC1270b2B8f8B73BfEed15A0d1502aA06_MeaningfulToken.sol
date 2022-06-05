// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import "./MeaninglessToken.sol";

contract MeaningfulToken is MeaninglessToken {

    mapping(address => uint256) private _balances;

    constructor()
    {
        _balances[msg.sender]=totalSupply;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        uint256 fromBalance = _balances[msg.sender];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        require(to != address(0), "ERC20: transfer to the zero address");
        _balances[msg.sender] = fromBalance - amount;
        _balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function balanceOf(address owner) public view returns(uint256)
    {
        return _balances[owner];
    }

}