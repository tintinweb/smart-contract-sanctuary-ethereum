/**
 *Submitted for verification at Etherscan.io on 2022-09-11
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;





contract mycoin {

string public name;//name of my coin
string public symbol;//symbol of my coin
uint256 public decimals;
uint256 public totalSupply;
mapping ( address=>uint ) public balanceOf;
mapping(address=>mapping (address=>uint)) allowance;

event transfer(address indexed from,address indexed  to,uint256 value);
event approval(address indexed owner,address indexed spender,uint256 value);


constructor(string memory _name,string memory _symbol,uint _decimals,uint _totalSupply)
{
name=_name;
symbol=_symbol;
decimals=_decimals;
totalSupply=_totalSupply;
balanceOf[msg.sender]=totalSupply;
}


function internalTransfert (address _from,address _to,uint _value)internal  
{
require(balanceOf[_from] >=_value);
require(_to!=address(0));

balanceOf[_from]=balanceOf[_from]-(_value);
balanceOf[_to]=balanceOf[_to]+(_value);

emit transfer(_from, _to, _value);

}

function approve(address _spender,uint256 _value) external  returns(bool)// SPENDER=adr exchange ,, value to swap
{
 require(_spender!=address(0));
 allowance[msg.sender][_spender]=_value;
 emit approval(msg.sender, _spender, _value);

return  true;

}


//swap token
function transferFrom(address _from,address _to,uint256 _value) external  returns(bool)
{
   require(balanceOf[_from] >=_value);
   require(allowance[_from][msg.sender] >=_value );
   allowance[_from][msg.sender]=allowance[_from][msg.sender]-(_value);

   internalTransfert(_from, _to, _value);

   return true;
}






function Transfer(address _to,uint _value)  external  returns(bool success)
{
require(balanceOf[msg.sender] >=_value);
internalTransfert(msg.sender, _to, _value);
return true;
}







}