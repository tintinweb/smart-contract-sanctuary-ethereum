// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDripCheck {
    // DripCheck contracts that want to take parameters as inputs MUST expose a struct called
    // Params and an event _EventForExposingParamsStructInABI(Params params). This makes it
    // possible to easily encode parameters on the client side. Solidity does not support generics
    // so it's not possible to do this with explicit typing.

    /**
     * @notice Checks whether a drip should be executable.
     *
     * @param _params Encoded parameters for the drip check.
     *
     * @return Whether the drip should be executed.
     */
    function check(bytes memory _params) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { IDripCheck } from "../IDripCheck.sol";

/**
 * @title CheckBalanceLow
 * @notice DripCheck for checking if an account's balance is below a given threshold.
 */
contract CheckBalanceLow is IDripCheck {
    struct Params {
        address target;
        uint256 threshold;
    }

    /**
     * @notice External event used to help client-side tooling encode parameters.
     *
     * @param params Parameters to encode.
     */
    event _EventToExposeStructInABI__Params(Params params);

    /**
     * @inheritdoc IDripCheck
     */
    function check(bytes memory _params) external view returns (bool) {
        Params memory params = abi.decode(_params, (Params));

        // Check target ETH balance is below threshold.
        return params.target.balance < params.threshold;
    }
}