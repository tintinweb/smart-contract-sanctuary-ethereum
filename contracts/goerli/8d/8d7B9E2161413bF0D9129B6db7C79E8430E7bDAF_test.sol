// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract test {

    function claim() external payable returns (uint256) {
        return msg.value;
    }
}