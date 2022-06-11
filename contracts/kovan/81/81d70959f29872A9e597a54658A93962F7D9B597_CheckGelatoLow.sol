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

interface IGelatoTreasury {
    function userTokenBalance(address _user, address _token) external view returns (uint256);
}

/**
 * @title CheckGelatoLow
 * @notice DripCheck for checking if an account's Gelato ETH balance is below some threshold.
 */
contract CheckGelatoLow is IDripCheck {
    event _EventToExposeStructInABI__Params(Params params);
    struct Params {
        address treasury;
        uint256 threshold;
        address recipient;
    }

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