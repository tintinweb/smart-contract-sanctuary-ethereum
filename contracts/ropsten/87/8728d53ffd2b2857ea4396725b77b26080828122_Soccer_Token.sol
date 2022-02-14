/**
 *Submitted for verification at Etherscan.io on 2022-02-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract Soccer_Token {
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totalSupply_;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed TK_own, address indexed TK_spend, uint256 value);

    mapping(address => uint256) public balance;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(string memory nm, string memory sym, uint deci, uint supp) {
        name = nm;
        symbol = sym;
        decimals = deci;
        totalSupply_ = supp;
        balance[msg.sender] = supp;
    }

    function totalSupply() public view returns (uint256) {
	return totalSupply_;
    }
    
    function balanceOf(address Tk_own) public view returns (uint) {
        return balance[Tk_own];
    }

    function transfer(address _to, uint256 _value) external returns (bool success) {
        require(balance[msg.sender] >= _value);
        inttrans(msg.sender, _to, _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function inttrans(address from, address to, uint256 value) internal {
        balance[from] = balance[from] - (value);
        balance[to] = balance[to] + (value);
        emit Transfer(from, to, value);
    }

    function approve(address spend, uint256 val) external returns (bool) {
        require(spend != address(0));
        allowance[msg.sender][spend] = val;
        emit Approval(msg.sender, spend, val);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(value <= balance[from]);
        require(value <= allowance[from][msg.sender]);
        allowance[from][msg.sender] = allowance[from][msg.sender] - (value);
        inttrans(from, to, value);
        return true;
    }

}