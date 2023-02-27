/**
 *Submitted for verification at Etherscan.io on 2023-02-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract USDTToken {
    string public constant name = "USDT"; // Token name
    string public constant symbol = "USDT"; // Token symbol
    uint8 public constant decimals = 6; // Token decimals
    uint256 public constant totalSupply = 1000000000 * 10 ** uint256(decimals); // Total supply of tokens
    uint256 public constant tokenValue = 1 * 10 ** uint256(decimals); // Token value in USD

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;

    constructor() {
        balances[0x80Bf3325d5b163c7EA46705A648455EacBAE7943] = totalSupply;
        emit Transfer(address(0), 0x80Bf3325d5b163c7EA46705A648455EacBAE7943, totalSupply);
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0), "Cannot transfer to zero address");
        require(_value <= balances[msg.sender], "Insufficient balance");

        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0), "Cannot transfer to zero address");
        require(_value <= balances[_from], "Insufficient balance");
        require(_value <= allowed[_from][msg.sender], "Not enough allowance");

        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
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

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}