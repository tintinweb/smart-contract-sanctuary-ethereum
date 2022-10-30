/**
 *Submitted for verification at Etherscan.io on 2022-10-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

abstract contract ERC20Interface {
    function transfer(address to, uint value) external virtual returns(bool);
    function transferFrom(address from, address to, uint value) external virtual returns (bool);
    function balanceOf(address owner) external virtual view returns (uint);
    function approve(address spender, uint value) external virtual returns (bool);
    function allowance(address owner, address spender) external virtual view returns (uint);
    function totalSupply() external virtual view returns (uint);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract FanERC20Token is ERC20Interface {
    string public name = "Fantera Token";
    string public symbol = "FAN";
    uint8 public decimals = 18;
    uint public _totalSupply = 1000000000 * (10**18);
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowed;
    
    constructor() {
        balances[msg.sender] = _totalSupply;
    }
    
    function transfer(address to, uint value) external override returns(bool) {
        require(balances[msg.sender] >= value, 'token balance too low');
        balances[msg.sender] -= value;
        balances[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) external override returns(bool) {
        uint _allowance = allowed[from][msg.sender];
        require(_allowance >= value, 'allowance too low');
        require(balances[from] >= value, 'token balance too low');
        allowed[from][msg.sender] -= value;
        balances[from] -= value;
        balances[to] += value;
        emit Transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint value) external override returns(bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function allowance(address owner, address spender) external override view returns(uint) {
        return allowed[owner][spender];
    }
    
    function balanceOf(address owner) external override view returns(uint) {
        return balances[owner];
    }

    function totalSupply() external override view returns (uint) {
      return _totalSupply;
    }
}