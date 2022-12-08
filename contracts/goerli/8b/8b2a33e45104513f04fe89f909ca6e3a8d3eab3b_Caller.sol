/**
 *Submitted for verification at Etherscan.io on 2022-12-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface Scontract {

   function store(uint256 num) external;
   function retrieve() external view returns (uint256);

}

contract Caller {

   Scontract private remoteContract;

   constructor( address addrRC ){
       remoteContract = Scontract(addrRC);

   }
  

   function remoteStore(uint256 num) public {
       remoteContract.store(num);
   }

   function remoteRetrieve() public view returns (uint256){
       return remoteContract.retrieve();
   }

}