// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Test {

   function getSalar(uint256 number) public pure returns (uint256){               
        return bonus()*number;
   }

   function bonus() public pure returns(uint256){
       return 100;
    }


}