// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract BoxV2 {
    uint public mewtwo;

    // function initialize(uint _val) external {
    //     val = _val;
    // }

    function inc() external {
        mewtwo += 1;
    }
}