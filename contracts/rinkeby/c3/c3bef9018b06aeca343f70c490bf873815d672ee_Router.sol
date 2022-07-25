/**
 *Submitted for verification at Etherscan.io on 2022-07-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;




interface _treasury{
  function deposit()external payable; 
  function market(address payable seller, uint256 dcf_amount)external;
  function ETH_DCF(uint256 dcf_amount)external view returns(uint256);
}





contract Router {   

  _treasury treasuryCtrl = _treasury(0x1F32fA361eDfc947e1cb48B575f4498e88e267a6);


  function deposit()external payable{
      treasuryCtrl.deposit{value: msg.value}();
  }



  function market(address payable seller, uint256 dcf_amount)external {
      treasuryCtrl.market(seller,dcf_amount);
  }


  function ETH_DCF(uint256 dcf_amount)external view returns(uint256){
      return treasuryCtrl.ETH_DCF(dcf_amount);
  }
   
  

}