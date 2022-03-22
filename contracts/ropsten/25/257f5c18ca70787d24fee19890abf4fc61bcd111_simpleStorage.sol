/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
//set and get a value in solidity

contract simpleStorage {
    uint storedData = 5;

    function setStoredData(uint x) public {
        storedData = x;
    }

    function getStoredData() public view returns (uint){
return storedData;

    }

}