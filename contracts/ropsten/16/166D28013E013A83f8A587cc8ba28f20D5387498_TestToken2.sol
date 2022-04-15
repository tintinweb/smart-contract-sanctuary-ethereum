/**
 *Submitted for verification at Etherscan.io on 2022-04-15
*/

pragma solidity ^0.8.0;


// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
contract TestToken2 {
  address downer;
    constructor(address owner) {
        downer =owner;
    }

    function getOwner() public view returns(address) {
          return downer;
    }

     function setOwner(address owner) public  {
          downer =owner;
    }
}