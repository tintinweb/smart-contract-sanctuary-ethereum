// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;
import {SimplerExample} from "./SimplerExample.sol";
import {SimpleSideEffectDeploy} from "./SimpleSideEffectDeploy.sol";

contract SimpleExample is SimplerExample {
    uint256 public a;
    address public b;
    SimpleSideEffectDeploy public sideEffect;

    constructor(
        uint256 _a,
        address _b,
        uint256 _c
    ) SimplerExample(_c) {
        a = _a;
        b = _b;
        sideEffect = new SimpleSideEffectDeploy(_c);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

contract SimpleSideEffectDeploy {
    uint256 public d;

    constructor(uint256 _c) {
        d = _c;
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