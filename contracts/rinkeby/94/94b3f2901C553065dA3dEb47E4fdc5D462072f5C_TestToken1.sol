/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

pragma solidity ^0.8.0;


// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
contract TestToken1 {
  address cowner;
    constructor(address owner) {
        cowner =owner;
    }

    function getOwner() public view returns(address) {
          return cowner;
    }

     function setOwner(address owner) public  {
          cowner =owner;
    }
}