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
 * @title CheckBalanceLow
 * @notice DripCheck for checking if an account's balance is below a given threshold.
 */
contract CheckBalanceLow is IDripCheck {
    event _EventToExposeStructInABI__Params(Params params);
    struct Params {
        address target;
        uint256 threshold;
    }

    function check(bytes memory _params) external view returns (bool) {
        Params memory params = abi.decode(_params, (Params));

        // Check target ETH balance is below threshold.
        return params.target.balance < params.threshold;
    }
}