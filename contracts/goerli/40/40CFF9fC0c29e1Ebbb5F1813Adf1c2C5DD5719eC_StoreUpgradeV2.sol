// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract StoreUpgradeV2 {
    uint public mew;
    uint public mewtwo;
    uint public mewnew;

    // function initialize(uint _val) external {
    //     mew = _val;
    // }

    function inc() external {
        mew += 1;
        mewnew += 4;
    }
}