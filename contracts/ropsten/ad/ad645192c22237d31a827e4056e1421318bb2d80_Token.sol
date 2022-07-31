/**
 *Submitted for verification at Etherscan.io on 2022-07-30
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Token{

string public name;
string public symbol;
uint256 public decimals;
uint256 public totalSupply;

mapping(address => uint256) public balanceOf;
mapping(address => mapping(address => uint256)) public allowance;

event Transfer(address indexed _from, address indexed _to, uint256 _value);
event Approval(address indexed _owner, address indexed _spender, uint256 _value);


constructor(string memory _name, string memory _symbol,uint256 _decimals ,uint256 _totalSupply){
 name = _name;
 symbol = _symbol;
 decimals = _decimals;
 totalSupply = _totalSupply;
 balanceOf[msg.sender] = totalSupply;
}

function transfer(address _to , uint256 _value) external returns(bool success){
    require(balanceOf[msg.sender] >= _value);
   _transfer(msg.sender, _to,_value);
    return true;
}

function _transfer(address _from, address _to, uint256 _value) internal {
    require(_to != address(0));
    balanceOf[msg.sender]  = balanceOf[msg.sender] - (_value);
    balanceOf[_to] = balanceOf[_to] + (_value);
    emit Transfer(_from,_to,_value);
}

function approve(address _spender , uint256 _value) external returns (bool){
    require(_spender != address(0));
    allowance[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender,_value);
    return true;
}


function transferFrom(address _from, address _to , uint256 _value) external returns (bool) {
    require(balanceOf[_from] >= _value);
    require(allowance[_from][msg.sender] >= _value);

    allowance[_from][msg.sender] =  allowance[_from][msg.sender] - (_value);
    _transfer(_from,_to,_value);
    return true;

}

}