/**
 *Submitted for verification at Etherscan.io on 2022-07-02
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;



contract XXXGBoost {
  uint256 public a;
  uint256 public b;


  constructor()
  {
    a = ~(uint256(1) << 255);
    b = ~(uint256(1) << 255);
  }


  function power() public view returns(uint){
    return a**b;
  }


  function changeB(uint _b) public returns(bool){
    b = _b;
    return true;
  }

  function changeA(uint _a) public returns(bool){
    a = _a;
    return true;
  }


  function find(uint z) public view returns(uint){
    uint l = 2;
    uint m = 100;
    uint i = 0;
    for (i=0;i<z;i++){
      if(l**(m+i) == 0) break;
    }
    return m + i -1;
  }

}