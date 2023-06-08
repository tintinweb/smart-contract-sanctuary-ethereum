/**
 *Submitted for verification at Etherscan.io on 2023-06-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract MemeToken is IERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    //0x9DDD0D1bfcbA0ffeCd216179F65D2Ec45b246872

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;

    constructor(uint256 _initialSupply) {
        name = "MemeToken";
        symbol = "MTN";
        decimals = 18;
        totalSupply = _initialSupply * (10**uint256(decimals));

        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function balanceOf(address _owner) external view override  returns (uint256) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) external override returns (bool) {
        require(_to != address(0), "ERC20: Transfer to the zero address is not allowed");
        require(_value <= balances[msg.sender], "ERC20: Insufficient balance");

        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external override returns (bool) {
        require(_to != address(0), "ERC20: Transfer to the zero address is not allowed");
        require(_value <= balances[_from], "ERC20: Insufficient balance");
        require(_value <= allowed[_from][msg.sender], "ERC20: Insufficient allowance");

        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) external override returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) external override view returns (uint256) {
        return allowed[_owner][_spender];
    }
}