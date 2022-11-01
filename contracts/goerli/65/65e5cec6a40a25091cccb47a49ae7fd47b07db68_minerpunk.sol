/**
 *Submitted for verification at Etherscan.io on 2022-11-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;





contract minerpunk {  


  
  constructor() {    
    invertory = 54000;     
    k= invertory*1e16;  
  }

  
  uint256 public invertory;
  uint256 public k;

  event hottoy(uint256 fuck);

 


  function market(uint256 _unit)public view returns(uint256){
      uint256 a = invertory-_unit+1;
      uint256 top = price(invertory);
      uint256 bottom = price(a);
      uint256 b = (top+bottom)*(_unit)/2;
      return b;
  }

   function price(uint256 _invertory)public view returns(uint256){
      return k/_invertory;
  }


  function setHOT(uint256 _a)public {
     invertory = _a;
     emit hottoy(_a);
  }

  

  






  





  

}