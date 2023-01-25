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

interface IGelatoTreasury {
    function userTokenBalance(address _user, address _token) external view returns (uint256);
}

/**
 * @title CheckGelatoLow
 * @notice DripCheck for checking if an account's Gelato ETH balance is below some threshold.
 */
contract CheckGelatoLow is IDripCheck {
    struct Params {
        address treasury;
        uint256 threshold;
        address recipient;
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

        // Check GelatoTreasury ETH balance is below threshold.
        return
            IGelatoTreasury(params.treasury).userTokenBalance(
                params.recipient,
                // Gelato represents ETH as 0xeeeee....eeeee
                0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
            ) < params.threshold;
    }
}