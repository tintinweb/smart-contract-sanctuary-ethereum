// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SampleEthereumContract {
    uint256 public data = 10;

    function getData() external view returns (uint256) {
        return data;
    }
}