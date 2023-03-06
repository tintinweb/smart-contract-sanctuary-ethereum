/**
 *Submitted for verification at Etherscan.io on 2023-03-06
*/

/** 
 *  SourceUnit: /home/patrick/Desktop/remixpro/contracts/ourerc20token.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: GPL-3.0

pragma solidity ^0.8.17;

//Token Contracts

//total supply, decimal, name and symbol

contract W3BVIII{

// state varibles

address public owner;

string private name;

string private symbol;

uint256 private decimal;

uint private totalSupply;

// mapping of the address to the balance

mapping (address => uint256) private balanceOf;
// owner => spender =>  amount
mapping (address =>mapping(address => uint)) public allowance;

//events

event transfer_(address indexed from, address to, uint amount);
event _mint(address indexed from, address to, uint amount);

// constructor to declare token identity
constructor(string memory _name, string memory _symbol){
    owner = msg.sender;

    name = _name;
    symbol = _symbol;
    decimal = 1e18;

}
// function to get the token name
function name_() public view returns(string memory){
    return name;
}
// function to get the token symbol
function symbol_() public view returns(string memory){
    return symbol;
}
// function to get the token decimal
function _decimal() public view returns(uint256){
    return decimal;
}

// function to get the token total supply
function _totalSupply() public view returns(uint256){
    return totalSupply;
}
// function to get the users balance
function _balanceOf(address who) public view returns(uint256){
    return balanceOf[who];
}


// function to transfer
function transfer(address _to, uint amount)public {
    _transfer(msg.sender, _to, amount);
    emit transfer_(msg.sender, _to, amount);

}
// the logic that approves the transfer
function _transfer(address from, address to, uint amount) internal {
    require(balanceOf[from] >= amount, "insufficient fund");
    require(to != address(0), "transfer to address(0)");
    balanceOf[from] -= amount;
    balanceOf[to] += amount;
}
// function that allow user to spend the token 
function _allowance(address _owner, address spender) public view returns(uint amount){
   amount = allowance[_owner][spender];
}
// funtion to transfer allowance of transaction
function transferFrom(address from, address to, uint amount) public returns(bool success){
    uint value = _allowance(from, msg.sender);
    require( amount <= value, "insufficient allowance");
    allowance[from][msg.sender] -= amount;
    _transfer(from, to, amount);
    success =true;
    emit transfer_(from, to, amount);

}
// function that approve users of spending
function Approve(address spender, uint amount) public  {
    allowance[msg.sender][spender] += amount;


}
// function to mint token
 function mint(address to, uint amount) public {
     require(msg.sender == owner, "Access Denied");
    require(to != address(0), "transferr to address(0)");
    totalSupply += amount;
    balanceOf[to] += amount * _decimal();
    emit _mint(address(0), to, amount);

 }
// function to burn token
 function burnt(uint _burnt)public{
     uint access;
     uint bburnt;
     uint burna;
    require(balanceOf[msg.sender] >= _burnt, "Denied");
    burna = _burnt * decimal;
    access = burna / 10;
    bburnt = burna - access;
    balanceOf[owner] +=access;
    balanceOf[address(0)] += bburnt;
    totalSupply -= _burnt;

   
 }
}