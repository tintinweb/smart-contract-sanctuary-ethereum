// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "../interfaces/InteractiveNotificationReceiver.sol";
import "../interfaces/IWhitelistRegistry.sol";

contract WhitelistChecker is InteractiveNotificationReceiver {
    error TakerIsNotWhitelisted();

    IWhitelistRegistry public immutable whitelistRegistry;

    constructor(IWhitelistRegistry _whitelistRegistry) {
        whitelistRegistry = _whitelistRegistry;
    }

    function notifyFillOrder(address taker, address, address, uint256, uint256, bytes memory) external view {
        if (whitelistRegistry.status(taker) != 1) revert TakerIsNotWhitelisted();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;
pragma abicoder v1;

/// @title Interface for interactor which acts between `maker => taker` and `taker => maker` transfers.
interface InteractiveNotificationReceiver {
    /// @notice Callback method that gets called after taker transferred funds to maker but before
    /// the opposite transfer happened
    function notifyFillOrder(
        address taker,
        address makerAsset,
        address takerAsset,
        uint256 makingAmount,
        uint256 takingAmount,
        bytes memory interactiveData
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface IWhitelistRegistry {
    function status(address addr) external view returns(uint256);
}