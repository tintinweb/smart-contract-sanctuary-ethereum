// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IDripCheck {
    // DripCheck contracts that want to take parameters as inputs MUST expose a struct called
    // Params and an event _EventForExposingParamsStructInABI(Params params). This makes it
    // possible to easily encode parameters on the client side. Solidity does not support generics
    // so it's not possible to do this with explicit typing.

    function check(bytes memory _params) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { IDripCheck } from "../IDripCheck.sol";

/**
 * @title CheckTrue
 * @notice DripCheck that always returns true.
 */
contract CheckTrue is IDripCheck {
    function check(bytes memory) external pure returns (bool) {
        return true;
    }
}