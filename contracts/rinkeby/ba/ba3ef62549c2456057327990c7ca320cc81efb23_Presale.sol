/**
 *Submitted for verification at Etherscan.io on 2022-07-19
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IERC20{
//Functions
function totalSupply() external  view returns (uint256);
function balanceOf(address tokenOwner) external view returns (uint);
function allowance(address tokenOwner, address spender)external view returns (uint);
function transfer(address to, uint tokens) external returns (bool);
function approve(address spender, uint tokens)  external returns (bool);
function transferFrom(address from, address to, uint tokens) external returns (bool);

//Events
event Approval(address indexed tokenOwner, address indexed spender,uint tokens);
event Transfer(address indexed from, address indexed to,uint tokens);

}

contract Presale  {
     IERC20 token;
     uint public tokenQuantity = 50;
     address tokenOwner;
       
    constructor(address tokenAddress){
        token = IERC20(address(tokenAddress));
        tokenOwner=msg.sender;

    }
     
     function buy ()   payable external    returns (bool){

         uint presaleBalance = token.balanceOf(address(this));
         
         uint amounttoBuy = ((msg.value)/(10**18))*tokenQuantity;
        //  uint dexBalance = token.balanceOf(address(this));
         require(amounttoBuy>0,"You need to pay some ether");
         require (amounttoBuy<=presaleBalance,"Not Enough token in Reserve");
         token.transfer(msg.sender,amounttoBuy);
         return true;
     }
}