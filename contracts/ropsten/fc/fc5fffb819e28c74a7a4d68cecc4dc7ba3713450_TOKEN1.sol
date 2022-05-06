/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract TOKEN1{
    uint public totalSupply = 1000000000 * 10**18;
    string public name = "TOKEN DEMO";
    string public symbol = "TOKEN1";
    uint public decimals = 18;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowances;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor(){
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function balanceOf(address _owner) public view returns (uint256 balance){
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success){
        require(balances[msg.sender] >= _value, "Not enough token to transfer.");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true; 
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        require(balances[_from] >= _value, "Not enough token to transfer.");
        require(allowances[_from][msg.sender] >= _value, "The _value more than value that sender is allowed to transfer.");
        allowances[_from][msg.sender] -= _value;
        balances[_from] -= _value;
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true; 
    }

    function approve(address _spender, uint256 _value) public returns (bool success){
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        return allowances[_owner][_spender];
    }
}