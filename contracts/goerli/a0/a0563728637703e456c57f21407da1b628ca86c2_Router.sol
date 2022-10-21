/**
 *Submitted for verification at Etherscan.io on 2022-10-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;




interface _treasury{
  function deposit()external payable; 
  function market(address from ,address payable to, uint256 dcf_amount)external;
  function ETH_DCF(uint256 dcf_amount)external view returns(uint256);
}





contract Router {   

  _treasury treasuryCtrl = _treasury(0xA5A8E7c70cb7b670551C3C5F0B1c4D2D2cB384C6);

  


  function deposit()external payable{
      treasuryCtrl.deposit{value: msg.value}();
  }



  function market(address payable to ,uint256 dcf_amount)external {
      treasuryCtrl.market(msg.sender,to,dcf_amount);     
  }


  function ETH_DCF(uint256 dcf_amount)public view returns(uint256){
      return treasuryCtrl.ETH_DCF(dcf_amount);
  }
   
  

}