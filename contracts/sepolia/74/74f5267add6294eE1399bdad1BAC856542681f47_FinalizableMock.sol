// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IFinalize} from "../rollup/interfaces/IFinalize.sol";

/// @dev This is a mock for testing.

contract FinalizableMock is IFinalize {
    bool public initialized;

    function initialize() external {
        initialized = true;
    }

    function finalize(bytes calldata) external {
        // noop
    }
}

// SPDX-License-Identifier: UNLICENSED
// SEE LICENSE IN https://files.altlayer.io/Alt-Research-License-1.md
// Copyright Alt Research Ltd. 2023. All rights reserved.
//
// You acknowledge and agree that Alt Research Ltd. ("Alt Research") (or Alt
// Research's licensors) own all legal rights, titles and interests in and to the
// work, software, application, source code, documentation and any other documents

pragma solidity ^0.8.18;

interface IFinalize {
    /********************
     * Public Functions *
     ********************/

    /// @notice Finalizes state transition.
    /// @param data The data to be finalized.
    function finalize(bytes calldata data) external;
}