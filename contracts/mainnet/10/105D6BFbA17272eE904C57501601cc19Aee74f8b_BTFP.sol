/**
 *Submitted for verification at Etherscan.io on 2023-03-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract BTFP {
    string public constant name = "BTFP Token";
    string public constant symbol = "BTFP";
    uint8 public constant decimals = 18;
    uint256 public totalSupply = 1_000_000_000 * 10 ** decimals;
    address public constant taxAddress = 0xEeDF32a3543D6687BeEab416C8B299Ad454054F3;
    uint256 public constant buyTax = 5;
    uint256 public constant sellTax = 5;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0), "Cannot transfer to zero address");
        uint256 tax = calculateTax(_value, buyTax);
        uint256 afterTax = _value - tax;
        balances[msg.sender] -= _value;
        balances[_to] += afterTax;
        balances[taxAddress] += tax;
        emit Transfer(msg.sender, _to, afterTax);
        emit Transfer(msg.sender, taxAddress, tax);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0), "Cannot transfer to zero address");
        require(allowed[_from][msg.sender] >= _value, "Insufficient allowance");
        uint256 tax = calculateTax(_value, buyTax);
        uint256 afterTax = _value - tax;
        balances[_from] -= _value;
        balances[_to] += afterTax;
        balances[taxAddress] += tax;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, afterTax);
        emit Transfer(_from, taxAddress, tax);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function calculateTax(uint256 _value, uint256 _tax) private pure returns (uint256) {
        return (_value * _tax) / 100;
    }
}