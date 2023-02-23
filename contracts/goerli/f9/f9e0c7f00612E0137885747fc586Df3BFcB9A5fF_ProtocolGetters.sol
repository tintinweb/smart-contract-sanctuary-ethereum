// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IDexIntegrationGetters {
    /// @dev Some integrations may not calculate output in a view function but rather by simulating the swap
    /// This function is NOT designed to be called on-chain due to possible poor gas optimization in particular integrations
    /// @param _path Packed encoded path for the swap (See IDexIntegrationActions#exactInput)
    /// @param _amountIn Amount of tokenA to spend
    /// @return amountOut_ Exact amount of tokenN to receive after swap execution
    function estimateExactInput(
        bytes calldata _path,
        uint256 _amountIn
    ) external returns (uint256 amountOut_);

    /// @dev Simular to estimateExactInput but designed to make multiple requests in a single call
    /// @param _paths An array of paths with packed data about desired pools
    /// @param _amountsIn An array of amounts corresponding to values in _paths array
    /// @return amountsOut_ An array of amounts of tokensN that will be received after swap execution
    function estimateExactInputs(
        bytes[] calldata _paths,
        uint256[] calldata _amountsIn
    ) external returns (uint256[] memory amountsOut_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IIntegrationActions {
    /// @notice Position id and optional additional info, that can specify the position
    struct PositionDescriptor {
        uint256 poolId;
        bytes extraData;
    }

    struct Input {
        address token;
        uint256 amount;
    }

    struct IncreasePositionParams {
        PositionDescriptor descriptor;
        Input[] input;
    }

    struct DecreasePositionParams {
        PositionDescriptor descriptor;
        uint256 liquidity;
    }

    struct HarvestYieldParams {
        PositionDescriptor descriptor;
        uint256 yield;
    }

    /// @param _payer The address that will pay for the position increasing
    /// @param _params descriptor Pool id with any arbitrary encoded data,
    /// input An array of tuple (token, amount) that should be added to the position
    /// @return liquidity_ An amount of liquidity received
    function increasePosition(
        address _payer,
        IncreasePositionParams calldata _params
    ) external returns (uint256 liquidity_);

    /// @param _recipient The address that will receive token(s) from the position
    /// @param _params descriptor Pool id with any arbitrary encoded data,
    /// liquidity Amount of liquidity to retrieve from the pool
    /// @return receivedTokens_ An array of received tokens
    function decreasePosition(
        address _recipient,
        DecreasePositionParams calldata _params
    ) external returns (Input[] memory receivedTokens_);

    /// @notice Prepares a position to be able to harvest all the accumulated yield
    /// @dev Will be called right before `harvestYield`. Can be empty if not needed
    /// @param _descriptor Pool id with any arbitrary encoded data,
    function prepareYield(PositionDescriptor calldata _descriptor) external;

    /// @param _recipient The address that will receive token(s) from the yield
    /// @param _params Pdescriptor Pool id with any arbitrary encoded data,
    /// yield Debt of tokens that should be transferred to the `_recipient`
    /// @return receivedTokens_ An array of received tokens
    function harvestYield(
        address _recipient,
        HarvestYieldParams calldata _params
    ) external returns (Input[] memory receivedTokens_);
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

import {IIntegrationActions} from "contracts/interfaces/integrations/IIntegrationActions.sol";

interface IProtocolGetters {
    /// @dev See (IDexIntegrationGetters#estimateExactInput)
    /// @param _integration Name of integration where order will be executed
    /// @param _path Packed encoded path for the swap in format (tokenA . poolId_AB . tokenB . poolId_BC . tokenC),
    /// @param _amountIn Amount of tokenA to spend
    /// @return amountOut_ Exact amount of tokenOut to receive after swap execution
    function simulateOrder(
        string calldata _integration,
        bytes calldata _path,
        uint256 _amountIn
    ) external returns (uint256 amountOut_);

    /// @dev Simular to simulateOrder but designed to make multiple requests in a single call
    function simulateOrders(
        string calldata _integration,
        bytes[] calldata _paths,
        uint256[] calldata _amountsIn
    ) external returns (uint256[] memory amountsOut_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library BytesLibrary {
    /// @dev Converts 20 + 20 bytes to address
    function toAddress(bytes memory _tightSlice) internal pure returns (address result_) {
        assembly {
            result_ := mload(add(_tightSlice, 20))
        }
    }

    /// @dev Converts 4 + 4 bytes to uint32
    function toUint32(bytes memory _tightSlice) internal pure returns (uint32 result_) {
        assembly {
            result_ := mload(add(_tightSlice, 4))
        }
    }

    /// @dev Converts 32 + 32 bytes to uint256
    function toUint256(bytes memory _tightSlice) internal pure returns (uint256 result_) {
        assembly {
            result_ := mload(add(_tightSlice, 32))
        }
    }
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

import {IProtocolGetters} from "contracts/interfaces/protocol/IProtocolGetters.sol";
import {IIntegrationActions} from "contracts/interfaces/integrations/IIntegrationActions.sol";
import {IDexIntegrationGetters} from "contracts/interfaces/integrations/dex/IDexIntegrationGetters.sol";

import {ProtocolCommon} from "./base/ProtocolCommon.sol";
import {SafeDelegateCall} from "contracts/libraries/SafeDelegateCall.sol";
import {BytesLibrary} from "contracts/libraries/BytesLibrary.sol";

contract ProtocolGetters is IProtocolGetters, ProtocolCommon {
    using SafeDelegateCall for address;
    using BytesLibrary for bytes;

    function simulateOrder(
        string calldata _integration,
        bytes calldata _path,
        uint256 _amountIn
    ) external override returns (uint256 amountOut_) {
        address integration = getRegister().getIntegrationAddress(_integration);

        bytes memory encoded = integration.safeDelegateCall(
            abi.encodeCall(IDexIntegrationGetters.estimateExactInput, (_path, _amountIn))
        );

        amountOut_ = abi.decode(encoded, (uint256));
    }

    function simulateOrders(
        string calldata _integration,
        bytes[] calldata _paths,
        uint256[] calldata _amountsIn
    ) external override returns (uint256[] memory amountsOut_) {
        // solhint-disable-next-line reason-string
        require(_paths.length == _amountsIn.length);

        address integration = getRegister().getIntegrationAddress(_integration);

        bytes memory encoded = integration.safeDelegateCall(
            abi.encodeCall(IDexIntegrationGetters.estimateExactInputs, (_paths, _amountsIn))
        );

        amountsOut_ = abi.decode(encoded, (uint256[]));
    }
}