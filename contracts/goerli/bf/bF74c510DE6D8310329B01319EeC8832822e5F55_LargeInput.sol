// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract LargeInput {
    uint16[] private s_arr;

    function setArr(uint16[] calldata arr) external {
        s_arr = arr;
    }

    function getNum(uint256 index) external view returns (uint16) {
        return s_arr[index];
    }
}