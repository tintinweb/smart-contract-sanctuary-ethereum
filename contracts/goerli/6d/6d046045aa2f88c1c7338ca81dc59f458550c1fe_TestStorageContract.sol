/**
 *Submitted for verification at Etherscan.io on 2022-11-14
*/

/**
 *Submitted for verification at Etherscan.io on 2022-11-14
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

contract TestStorageContract {
    uint storedData;
      address private _owner;

   constructor ()  {
    _owner = msg.sender; // Whoever deploys smart contract becomes the owner
  } 
    function setDataInSC(uint x) public {
        storedData = x;
    }

   
    function getDataInSC() public view returns (uint) {
        return storedData;
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
}