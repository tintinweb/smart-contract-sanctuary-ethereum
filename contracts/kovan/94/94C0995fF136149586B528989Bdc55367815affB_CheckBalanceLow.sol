// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IDripCheck {
    // DripCheck contracts that want to take parameters as inputs MUST expose a struct called
    // Params and a variable named params (with a type Params). This makes it possible to properly
    // encode parameters. Solidity does not support generics so it's not possible to do this with
    // explicit typing.

    function check(address _recipient, bytes memory _params) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { IDripCheck } from "../IDripCheck.sol";

contract CheckBalanceLow is IDripCheck {
    struct Params {
        uint256 threshold;
    }
    Params public params;

    function check(address _recipient, bytes memory _params) external view returns (bool) {
        Params memory p = abi.decode(_params, (Params));
        return _recipient.balance < p.threshold;
    }
}