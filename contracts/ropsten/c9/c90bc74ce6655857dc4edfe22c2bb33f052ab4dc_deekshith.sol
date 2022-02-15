/**
 *Submitted for verification at Etherscan.io on 2022-02-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

contract deekshith {

    mapping(address => uint256) public balanceof;
    string public name = "deekshith";
    string public symbol = "DEK";
    uint8 public decimal = 18;
    uint256 public totalsupply = 1000*(10**decimal);

    mapping(address => mapping(address=> uint256)) public allowance;

    constructor() {
        balanceof[msg.sender] = totalsupply;
        emit Transfer(address(0),msg.sender,totalsupply);
    }
    
    //events
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

function transfer(address _to,uint256 _value) public returns (bool success){
    require(balanceof[msg.sender] >= _value, "not enough tokens to transfer");
    balanceof[msg.sender] -= _value;
    balanceof[_to] += _value;

    emit Transfer(msg.sender,_to,_value);
    return true;
}

function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
    require(allowance[_from][msg.sender] >= _value,"Not approved to transfer");
    require(balanceof[_from] >= _value,"Not enough token to transfer");

    balanceof[_from] -= _value;
    balanceof[_to] += _value;
    allowance[_from][msg.sender] -= _value;

    emit Transfer( _from,_to,_value);
    return true;
}

function approve(address _spender, uint256 _value) public returns (bool success){
    allowance[msg.sender][_spender] = _value;
    emit Approval(msg.sender,_spender,_value);
    return true;

}
}