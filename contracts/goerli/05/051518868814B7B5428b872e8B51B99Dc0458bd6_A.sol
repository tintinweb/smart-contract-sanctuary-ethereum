/**
 *Submitted for verification at Etherscan.io on 2022-12-08
*/

pragma solidity >=0.7.0 <0.9.0;

contract A {



  function aa(uint256 a, uint256 loopSize)
    external pure 
    returns (uint256)
  { 
    uint256 result;
    for(uint256 i=0; i< loopSize; i++)
        result = result + a; 

    return result;
  }


}