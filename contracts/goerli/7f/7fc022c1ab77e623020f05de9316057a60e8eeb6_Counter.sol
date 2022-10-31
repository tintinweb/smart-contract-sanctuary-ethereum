/**
 *Submitted for verification at Etherscan.io on 2022-10-31
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

contract Counter {

    uint public count;

    function increment() public {
        count += 1;
    }

    function get() public view returns (uint) {
        return count;
    }

}