// contracts/BoxV2.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Box.sol";

contract BoxV2 is Box {
    // Increments the stored value by 1
    function increment() public {
        store(retrieve()+1);
    }
}