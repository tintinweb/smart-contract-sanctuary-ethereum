// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract BoxV2 {
    uint public val;

    // only called once when the first version of the contract is deployed
    // function initialize(uint _val) external {
    //     val = _val;
    // }

    // increments the state variable val
    function inc() external {
        val += 1;
    }
}