// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IDripCheck {
    // DripCheck contracts that want to take parameters as inputs MUST expose a struct called
    // Params and a function named encode that takes a single Params as input and returns no output.
    // This makes it possible to easily encode parameters on the client-side. Solidity does not
    // support generics so it's not possible to do this with explicit typing.

    function check(address _recipient, bytes memory _params) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { IDripCheck } from "../IDripCheck.sol";

contract CheckTrue is IDripCheck {
    function check(address, bytes memory) external pure returns (bool) {
        return true;
    }
}