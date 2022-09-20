/**
 *Submitted for verification at Etherscan.io on 2022-09-20
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface Erc20_SD
{
function name() external view  returns (string memory);
function symbol() external view returns (string memory);
function decimals() external view returns (uint8);

function totalSupply() external view returns (uint256);
function balanceOf(address _owner) external view returns (uint256 balance);
function transfer(address _to, uint256 _value) external returns (bool success);
function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
function approve(address _spender, uint256 _value) external returns (bool success);
function allowance(address _owner, address _spender) external view returns (uint256 remaining);

}

contract Presale{

      Erc20_SD token;
      address public Owner;
      constructor(address _token, address _owner){
          token = Erc20_SD(_token);
          Owner = _owner; 
      }

      uint256 tokenPrice =500;
      
    function buy() payable public{
        require(msg.value>0,"Pay the Required price");
        uint value = tokenPrice*10**token.decimals()*msg.value/10**18;
        // uint value = msg.value*tokenPrice*token.decimals();
        token.transferFrom(Owner,msg.sender,value);
    }

    function sell(uint value) public{
        require(value>0,"please enter some amount of tokens");
        uint _value =value*10**18/10**token.decimals()/tokenPrice; 
        token.transferFrom(msg.sender,Owner,value);
        payable (msg.sender).transfer(_value);
    }
}