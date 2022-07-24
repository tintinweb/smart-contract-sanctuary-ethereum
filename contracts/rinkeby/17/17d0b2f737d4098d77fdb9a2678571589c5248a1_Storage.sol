/**
 *Submitted for verification at Etherscan.io on 2022-07-24
*/

pragma solidity >=0.4.17 <0.9.0;contract Storage {
  uint data; 

  function set(uint newData) public {
    data = newData;
  }  

  function get() public view returns (uint) {
    return data;
  }
  
}