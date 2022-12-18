/**
 *Submitted for verification at Etherscan.io on 2022-12-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract test {
    uint[] arr;

    function setArr() external {
        if (arr.length == 0) {
            arr.push(0);
        } else {
            arr.push(1);
        }
    }
}