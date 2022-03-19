/**
 *Submitted for verification at Etherscan.io on 2022-03-18
*/

pragma solidity ^0.4.0;
contract ERC20{
mapping(address =>uint256) public amount;
uint256 totalAmount;
string tokenName;
string tokenSymbol;
uint256 decimal;
constructor() public{
totalAmount = 10000 * 10**18;
amount[msg.sender]=totalAmount;
tokenName="Mytoken";
tokenSymbol="Mytoken";
decimal=18;
}
function totalSupply() public view returns(uint256){
return totalAmount;
}
function balanceOf(address to_who) public view
returns(uint256){
return amount[to_who];
}
function transfer(address to_a, uint256 _value) public
returns(bool){
require(_value<=amount[msg.sender]);
amount[msg.sender]=amount[msg.sender]-_value;
amount[to_a]=amount[to_a]+_value;
return true;
}
}