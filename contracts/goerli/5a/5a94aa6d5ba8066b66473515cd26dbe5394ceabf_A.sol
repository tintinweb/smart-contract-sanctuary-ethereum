/**
 *Submitted for verification at Etherscan.io on 2022-12-08
*/

pragma solidity >=0.7.0 <0.9.0;

contract A {

  event gasEmit(uint256 x);

  function aa(uint256 a, uint256 loopSize)
    external  
    returns (uint256)
  { 
    emit gasEmit(gasleft());
    uint256 result;
    for(uint256 i=0; i< loopSize; i++)
        result = result + a; 

    emit gasEmit(gasleft());
    return result;
  }


}