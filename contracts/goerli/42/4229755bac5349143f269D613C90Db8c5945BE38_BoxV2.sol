// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract BoxV2 {
    uint public mewtwo;
    uint public mew;

    // function initialize(uint _val) external {
    //     mew = _val;
    // }

    function inc() external {
        mew += 1;
    }
}