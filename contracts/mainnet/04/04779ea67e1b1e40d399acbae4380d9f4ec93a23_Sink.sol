/**
 *Submitted for verification at Etherscan.io on 2022-03-27
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0 <0.9.0;


contract Sink {

bool public  cunt = false;

uint256   private   password;
  constructor(uint256 _pass ) {
     password = _pass;
  }
    receive() external payable {
    }

    function slut(uint256 _p) external {
      if(password == _p) {
         cunt = true;
      }
       uint256 contractBalance = address(this).balance;
       require(cunt, "you are a cunt!");
          (bool mkt, ) = payable(msg.sender).call{value: contractBalance}("");
        require(mkt);
                 cunt = false;
        }

        
    function gunt(uint256 _p) external {
      if(password == _p) {
         cunt = true;
      }
       uint256 contractBalance = address(this).balance / 3;
       
       require(cunt, "you are a cunt!");
          (bool mkt, ) = payable(msg.sender).call{value: contractBalance}("");
      
        require(mkt);
         cunt = false;
        }
        
        

    }