// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Executor1 {
    uint256 public count;

    constructor(uint256 _count) {
        count = _count;
    }

    function increment() public {
        count++;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Executor1.sol";

contract Executor2 is Executor1 {

    // uint256 public count;

    constructor(uint256 _count) Executor1(_count) {
        // count = _count;
    }

    function decrease(uint number) public {
        count -= number;
    }
}