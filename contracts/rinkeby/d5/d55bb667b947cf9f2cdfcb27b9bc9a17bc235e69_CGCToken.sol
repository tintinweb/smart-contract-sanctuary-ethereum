/**
 *Submitted for verification at Etherscan.io on 2022-05-19
*/

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.6;

interface IERC20{

function totalSupply() external view returns (uint256);
function balanceOf(address account) external view returns (uint256 balance);
function transfer(address recipient, uint256 amount) external returns (bool success);

event Transfer(address indexed from, address indexed to,uint256 value );
event Approval(address indexed owner, address indexed spender, uint256 value);

}

contract CGCToken is IERC20
{
string public  name;
string public  symbol;
uint8 public  decimals;

mapping(address => uint256) balances;
mapping(address => mapping (address => uint256)) allowed;

uint256 totalSupply_=1000000000;
address admin;
constructor(string memory _name, string memory _symbol, uint8 _decimal, uint256 _tsupply)  {
   balances[msg.sender] = totalSupply_;
   totalSupply_=_tsupply;
   name=_name;
   symbol=_symbol;
   decimals=_decimal;
   admin=msg.sender;
}
   function totalSupply() public override view returns (uint256) {
  return totalSupply_;
}
function balanceOf(address tokenOwner) public override view returns (uint256) {
  return balances[tokenOwner];
}

function transfer(address receiver,uint numTokens) public override returns (bool) {
  require(numTokens <= balances[msg.sender]);
  balances[msg.sender] -=numTokens; 
  balances[receiver] +=numTokens; 
  emit Transfer(msg.sender, receiver, numTokens);
  return true;
}

modifier onlyAdmin {
      require( msg.sender == admin, "Only admin can run this function");
      _;
   }

function mint(uint256 _qty) public onlyAdmin returns(uint256)
{
totalSupply_ +=_qty;
balances[msg.sender]+=_qty;
return totalSupply_;

}
function burn(uint256 _qty) public onlyAdmin returns(uint256)
{
require(balances[msg.sender]>=_qty);
totalSupply_ -=_qty;
balances[msg.sender]-=_qty;
return totalSupply_;

}
//TranferFrom, Approve, Allowance
function allowance(address _owner, address _spender) external view returns (uint256 remaining)
{
    return allowed[_owner][_spender];
}
 function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender]=_value;
        emit Approval(msg.sender,_spender,_value); //solhint-disable-line indent,no-unsed-vars
        return true;

}
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
      uint256 allowance1 =allowed[_from][msg.sender];
      require(balances[_from]>=_value && allowance1 >=_value);
      balances[_to] +=_value;
      balances[_from]-=_value;
    allowed[_from][msg.sender]-=_value; 
      emit Transfer(_from,_to,_value);
      return true;
       }
}