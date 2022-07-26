/**
 *Submitted for verification at Etherscan.io on 2022-07-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;




interface _treasury{
  function deposit()external payable; 
  function market(address payable seller, uint256 dcf_amount)external;
  function ETH_DCF(uint256 dcf_amount)external view returns(uint256);
}





contract Router {   

  _treasury treasuryCtrl = _treasury(0xCcdD432Be76cdE50d62033E82C18c70d01191994);


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