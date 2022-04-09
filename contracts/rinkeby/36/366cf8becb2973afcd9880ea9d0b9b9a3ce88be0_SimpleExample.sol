// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;
import {SimplerExample} from "./SimplerExample.sol";

contract SimpleExample is SimplerExample {
    uint256 public a;
    address public b;

    constructor(
        uint256 _a,
        address _b,
        uint256 _c
    ) SimplerExample(_c) {
        a = _a;
        b = _b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

contract SimplerExample {
    uint256 public c;

    constructor(uint256 _c) {
        c = _c;
    }
}