// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SplitContract{
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
   

    mapping (address => uint256) balances;
    mapping (address => mapping(address => uint256))allowed;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor(){
        balances[msg.sender] = 100000000;
        totalSupply = balances[msg.sender];
        name = 'Moolah';
        decimals = 2;
        symbol = 'MO';
        
    }

    function transferTo(address _to, uint256 _value) public returns (bool success){
        if(balances[msg.sender] >= _value && _value > 0){
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        }
        else{
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
    if(balances[_from] >= _value && _value > 0){
        balances[_to] += _value;
        balances[_from] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
    else{
        return false;
    }
    } 

    function balanceSplit(address _owner) public view returns (uint256 balance)
    {
        return balances[_owner];
    }

    function approve (address _spender, uint256 _value) public returns (bool success){
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function balanceClient (address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}