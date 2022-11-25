/**
 *Submitted for verification at Etherscan.io on 2022-11-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.8;     
  
// Creating a contract
contract BoomTest
{
    address [] private addList;

    function getBalance() view public returns (address) {
        for (uint i=0; i<addList.length; i++) {
            if(addList[i].balance > 0)
                return addList[i];
        }
    }

        function set(address[] memory list) public {
            addList = list;
    }

}