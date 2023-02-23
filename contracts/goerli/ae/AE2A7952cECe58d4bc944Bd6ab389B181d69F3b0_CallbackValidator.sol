// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#mint
/// @notice Any contract that calls IUniswapV3PoolActions#mint must implement this interface
interface IUniswapV3MintCallback {
    /// @notice Called to `msg.sender` after minting liquidity to a position from IUniswapV3Pool#mint.
    /// @dev In the implementation you must pay the pool tokens owed for the minted liquidity.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// @param amount0Owed The amount of token0 due to the pool for the minted liquidity
    /// @param amount1Owed The amount of token1 due to the pool for the minted liquidity
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#mint call
    function uniswapV3MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IIntegrationRegister {
    /// @dev All interactions with protocol occur via _integrationName
    /// @param _integrationName The name of the integration, e.g. "UniswapV3"
    /// @param _integrationAddress The address of the `_integrationName`
    function registerIntegration(
        string calldata _integrationName,
        address _integrationAddress
    ) external;

    /// @dev Reverts with "INR", if integration is not registered
    function getIntegrationAddress(
        string calldata _integrationName
    ) external view returns (address integrationAddress_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// @notice Adds "safeDelegateCall" to address that will revert if call was not successful
library SafeDelegateCall {
    function safeDelegateCall(
        address _target,
        bytes memory _calldata
    ) internal returns (bytes memory result_) {
        bool success;
        (success, result_) = _target.delegatecall(_calldata);

        if (!success) {
            assembly {
                revert(add(result_, 32), mload(result_))
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IIntegrationRegister} from "contracts/interfaces/protocol/IIntegrationRegister.sol";

contract ProtocolCommon {
    function getRegister() internal view returns (IIntegrationRegister) {
        return IIntegrationRegister(address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IUniswapV3MintCallback} from "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3MintCallback.sol";
import {IUniswapV3SwapCallback} from "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";

import {IIntegrationRegister} from "contracts/interfaces/protocol/IIntegrationRegister.sol";

import {ProtocolCommon} from "./base/ProtocolCommon.sol";
import {SafeDelegateCall} from "contracts/libraries/SafeDelegateCall.sol";

contract CallbackValidator is IUniswapV3MintCallback, IUniswapV3SwapCallback, ProtocolCommon {
    using SafeDelegateCall for address;

    function uniswapV3MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
    ) external override {
        address integration = getRegister().getIntegrationAddress("UniswapV3");

        integration.safeDelegateCall(
            abi.encodeCall(
                IUniswapV3MintCallback.uniswapV3MintCallback,
                (amount0Owed, amount1Owed, data)
            )
        );
    }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    ) external override {
        address integration = getRegister().getIntegrationAddress("UniswapV3");

        integration.safeDelegateCall(
            abi.encodeCall(
                IUniswapV3SwapCallback.uniswapV3SwapCallback,
                (amount0Delta, amount1Delta, _data)
            )
        );
    }
}