/**
 *Submitted for verification at Etherscan.io on 2022-06-10
*/

pragma solidity ^0.4.26;

contract Erc20Interface{
string public name;
string public symbol;
uint8 public decimals;
uint256 public totalSupply;

function transfer(address _to,uint256 _value) public returns (bool success);
function  transferFrom(address _from,address _to,uint256 _value) public returns (bool success);
function approve(address spender,uint256 _value) public returns (bool success);
function allowance(address owner, address spender) public view returns (uint256 remains);
event Transfer(address indexed _from, address indexed _to, uint256 _value);
event Approval(address indexed owner,address indexed spender);

}

contract ERC20 is Erc20Interface {
mapping(address=>uint256) public balance; 
mapping(address=>mapping(address=>uint256)) public allowed; 

constructor(string _name) public {
name=_name;
symbol="TTC";
decimals = 2;
totalSupply=100000;
balance[msg.sender] = totalSupply;
}

function transfer(address _to, uint256 _value) public returns (bool success){
require(_to!=address(0));
require(balance[msg.sender]>=_value);
require(balance[_to]+ _value>=_value);
balance[msg.sender] -= _value;
balance[_to] += _value;

emit Transfer(msg.sender,_to,_value);
return true;
}





function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
require(_to!=address(0));
require(allowed[_from][msg.sender]>=_value);
require(balance[_from]>=_value);
require(balance[_to]+ _value>=_value);
balance[_from] -= _value;
balance[_to] += _value;
allowed[_from][msg.sender]-=_value;
emit Transfer(msg.sender,_to,_value);
return true;
}

function approve(address spender,uint256 _value) public returns (bool success){
allowed[msg.sender][spender] = _value;
emit Approval(msg.sender,spender);
return true;
}


function allowance(address owner,address spender) public view returns (uint256 remains){
return allowed[owner][spender];
}

}