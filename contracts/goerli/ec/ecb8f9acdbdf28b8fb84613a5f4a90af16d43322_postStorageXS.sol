/**
 *Submitted for verification at Etherscan.io on 2022-10-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract postStorageXS {
   string storeData;

    function get() public view returns(string memory) {
        return storeData;
    }

    function set(string memory data) public {
        storeData = data;

    }


}