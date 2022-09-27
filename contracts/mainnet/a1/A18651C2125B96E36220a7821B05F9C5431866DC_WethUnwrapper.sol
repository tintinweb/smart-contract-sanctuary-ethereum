// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;
pragma abicoder v1;

import "../interfaces/InteractiveNotificationReceiver.sol";
import "../interfaces/IWithdrawable.sol";

contract WethUnwrapper is InteractiveNotificationReceiver {
    error ETHTransferFailed();

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    uint256 private constant _RAW_CALL_GAS_LIMIT = 5000;

    function notifyFillOrder(
        address /* taker */,
        address /* makerAsset */,
        address takerAsset,
        uint256 /* makingAmount */,
        uint256 takingAmount,
        bytes calldata interactiveData
    ) external override {
        address payable makerAddress;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            makerAddress := shr(96, calldataload(interactiveData.offset))
        }
        IWithdrawable(takerAsset).withdraw(takingAmount);
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = makerAddress.call{value: takingAmount, gas: _RAW_CALL_GAS_LIMIT}("");
        if (!success) revert ETHTransferFailed();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;
pragma abicoder v1;

interface IWithdrawable {
    function withdraw(uint wad) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;
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