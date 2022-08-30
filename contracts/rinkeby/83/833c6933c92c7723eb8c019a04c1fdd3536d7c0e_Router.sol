/**
 *Submitted for verification at Etherscan.io on 2022-08-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;




interface _treasury{
  function deposit()external payable; 
  function market(address payable seller, uint256 dcf_amount)external;
  function ETH_DCF(uint256 dcf_amount)external view returns(uint256);
}





contract Router {   

  _treasury treasuryCtrl = _treasury(0xA91Cc70B32b219856f4759f6d276771D27328844);


  function deposit()external payable{
      treasuryCtrl.deposit{value: msg.value}();
  }



  function market(uint256 dcf_amount)external {
      treasuryCtrl.market(payable(msg.sender),dcf_amount);
  }


  function ETH_DCF(uint256 dcf_amount)external view returns(uint256){
      return treasuryCtrl.ETH_DCF(dcf_amount);
  }
   
  

}