// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract BoxV20 {
    uint public val;
    receive() external  payable {}
    fallback() external  payable {}

    // function initialize(uint _val) external {
    //     val = _val;
    // }

    function inc() external {
        val += 1;
    }
}