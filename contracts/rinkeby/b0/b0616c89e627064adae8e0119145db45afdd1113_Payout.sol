/**
 *Submitted for verification at Etherscan.io on 2022-03-18
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract Payout {
    string _name;
    string _symbol;
    uint8 _decimals;
    uint256 _totalSupply;
    mapping(address => uint256) _balances;

    constructor (string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = totalSupply_;
        _balances[msg.sender] = totalSupply_;
    }

    event Transfer( address indexed From, address indexed To, uint256 amount);

    function name() public view returns (string memory Name){
        return _name;
    }

    function symbol() public view returns (string memory Symbol){
        return _symbol;
    }

    function decimals() public view returns (uint8 Decimals){
        return _decimals;
    }
    
    function totalSupply() public view returns (uint256 TotalSupply){
        return _totalSupply;
    }

    function balanceof(address _owner) public view returns (uint256 Balance){
        return _balances[_owner];
    }

    function transfer(address _to, uint _amount) public returns (bool success){
        require(_balances[msg.sender] >= _amount , "The sender has insufficient balance");
        _balances[msg.sender] -= _amount;
        _balances[_to] += _amount;
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

}