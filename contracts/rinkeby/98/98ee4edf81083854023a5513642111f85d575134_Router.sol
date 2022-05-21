/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;




interface _treasury{
  function subscribe(address subscriber)external payable;   
  function market(address payable seller, uint256 dcf_amount)external; 
  function ETH_DCF(uint256 eth_amount)external view returns(uint256);
  function DCF_ETH(uint256 dcf_amount)external view returns(uint256);
}


contract Router {   

  _treasury treasuryCtrl = _treasury(0x063243b32833d9398Fb2186d900bbdAa2A05326D);
 

 
  function Subscribe()external payable{
      treasuryCtrl.subscribe{value: msg.value}(msg.sender);
  }  

  function Market(uint256 dcf_amount)external{
      treasuryCtrl.market(payable(msg.sender),dcf_amount);
  }


  function ETH_DCF(uint256 eth_amount)external view returns(uint256){
      uint price = treasuryCtrl.ETH_DCF(eth_amount);
      return price;
  }


  function DCF_ETH(uint256 dcf_amount)external view returns(uint256){
      uint price = treasuryCtrl.DCF_ETH(dcf_amount);
      return price;
  }
   
  

}