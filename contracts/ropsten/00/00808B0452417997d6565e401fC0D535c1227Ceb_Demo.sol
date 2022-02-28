/**
 *Submitted for verification at Etherscan.io on 2022-02-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Demo {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    string public constant name = "bibi";
    string public constant symbol = "LYU";
    uint8 public constant decimals = 18;
    uint256 public _total;
    address public owner;
    mapping(address => uint256) _balances;
    mapping(
        address => mapping(
            address => uint256
        )
    ) _approve;

    modifier isOwner (){
        require(msg.sender == owner);
        _;
    }
    
    constructor(uint256 total) {
        _total = total;
        owner = msg.sender;
    }
    
    function airDrop(address _to, uint256 _value) isOwner public {
        require(_to != address(0));
        _balances[_to] += _value;
    }
    
    function totalSupply() public view returns (uint256 total) {
        total = _total;
        return total;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        require(_owner != address(0), "The owner cannot be empty");
        return _balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success){
        require(_to != address(0), "The _to cannot be empty");
        require(_balances[msg.sender] >= _value && _value > 0, "Lack of balance");
        require(_to != msg.sender,"");
        _balances[msg.sender] -= _value;
        _balances[_to] += _value;
        success = true;
        
        emit Transfer(msg.sender, _to, _value);
        return success;
    }

    function transferFrom( address _from, address _to, uint256 _value) public returns (bool success) { 
        require(_from != address(0) && _to != address(0),"11");
        require(_approve[_from][msg.sender] >= _value && _value > 0, "22");
        
        _approve[_from][msg.sender] -= _value;
        _balances[_to] += _value;
        success = true;

        emit Transfer(_from, _to, _value);
        return success;
    }

    function approve(address _spender, uint256 _value) public returns (bool success){
        require(_spender != address(0),"");
        require(_balances[_spender] >= _value && _value > 0,"");

        _approve[msg.sender][_spender] += _value;
        _balances[msg.sender] -= _value;
        success = true;

        emit Approval(msg.sender, _spender, _value);
        return success;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        remaining = _approve[_owner][_spender];
        return remaining;
    }
}