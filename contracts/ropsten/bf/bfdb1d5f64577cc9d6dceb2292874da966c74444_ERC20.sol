/**
 *Submitted for verification at Etherscan.io on 2022-04-15
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);

    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address to, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address from, address to, uint amount) external returns (bool);
}

contract ERC20 is IERC20 {
    uint private _totalSupply;
    mapping(address => uint) private _balanceOf;
    mapping(address => mapping(address => uint)) private _allowance;
    string public name = "MyErc20";
    string public symbol = "MYERC20";
    uint public decimals = 18;

    constructor() {
        _totalSupply = 1000000000000000000;
        _balanceOf[msg.sender] = _totalSupply;
    }

    function totalSupply() external view override returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint) {
        return _balanceOf[account];
    }

    function transfer(address to, uint amount) external override returns (bool) {
        require(to != address(0), "invalid recipent");

        _balanceOf[msg.sender] -= amount;
        _balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint) {
        return _allowance[owner][spender];
    }

    function approve(address spender, uint amount) external override returns (bool) {
        require(spender != address(0), "invalid spender");

        _allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint amount) external override returns (bool) {
        require(from != address(0), "invalid owner");
        require(to != address(0), "invalid recipent");

        _allowance[from][msg.sender] -= amount;
        _balanceOf[from] -= amount;
        _balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }
}