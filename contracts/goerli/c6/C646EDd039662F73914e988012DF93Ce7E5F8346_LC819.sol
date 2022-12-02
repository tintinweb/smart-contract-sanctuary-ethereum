/**
 *Submitted for verification at Etherscan.io on 2022-12-02
*/

// SPDX-License-Identifier: MIT
// Credits to OpenZeppelin
pragma solidity ^0.8.0;

contract LC819 {
    uint256 public constant decimals = 18;
    uint256 public totalSupply = 10000; 

    mapping (address => uint256) public _balances;
    mapping (address => mapping (address => uint256)) public _allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor()  {
        _balances[msg.sender] = totalSupply;   
    }


    function balanceOf(address _owner) public view returns (uint256) {
        return _balances[_owner];
    }

    function transfer(address _from, address _to, uint _value) public{
        require(_balances[_from] >= _value);
        _balances[_from] -= _value;
        _balances[_to] += _value;
        emit Transfer(_from, _to, _value);//event log

    }


    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_value <= _allowances[_from][msg.sender]);     // check allowance
        _allowances[_from][msg.sender] -= _value;
        transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        _allowances[msg.sender][_spender] = _value;
        return true;
    }

    function allowance(address _owner, address _spender) public view
        returns (uint256 remaining)
    {
        remaining = _allowances[_owner][_spender];
        return remaining;
    }


    function burn(uint256 _value) public returns (bool) {
        require(_balances[msg.sender] >= _value);   
        _balances[msg.sender] -= _value;            
        totalSupply -= _value;                      
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool) {
        require(_balances[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= _allowances[_from][msg.sender]);    // Check _allowances
        _balances[_from] -= _value;                         // Subtract from the targeted balance
        _allowances[_from][msg.sender] -= _value;             // Subtract from the sender's _allowances
        totalSupply -= _value;                              
        return true;
    }
}