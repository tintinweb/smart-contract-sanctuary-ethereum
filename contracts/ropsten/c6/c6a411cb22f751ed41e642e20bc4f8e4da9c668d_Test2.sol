/**
 *Submitted for verification at Etherscan.io on 2022-02-08
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

interface Test{
  function setAge(uint x) external;
  function getAge() external returns(uint);
}

contract Test2 {
	Test myContract;
	constructor() {
		address myaddr = 0xEe98fF20010347bB158902FFcBc55A9b07868255;
		myContract = Test(myaddr);
 	}

   function getAge() public  returns(uint) {
     return myContract.getAge();
   }

   function  setAge(uint x) public {
      myContract.setAge(x);
   }

}