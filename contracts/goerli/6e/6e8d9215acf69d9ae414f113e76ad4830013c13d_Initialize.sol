// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @dev Interface for an Initialization target contract.
interface IInitializer {
    function initialize(bytes memory _data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IInitializer} from "../interfaces/IInitializer.sol";

contract Initialize is IInitializer {
    address immutable module;

    constructor(address _module) {
        module = _module;
    }

    function initialize(bytes memory _data) external {
        IInitializer(module).initialize(_data);
    }
}