// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// @notice Utility for the diamond that allows to have internal facets
/// @dev In order to make facet functions internal just add "onlyInternal" modifier to them
abstract contract InternalCallee {
    modifier onlyInternal() {
        require(msg.sender == address(this), "CNT"); // Caller is not address(this)
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {BytesLibrary} from "contracts/libraries/BytesLibrary.sol";

library Path {
    using BytesLibrary for bytes;

    uint256 internal constant ADDRESS_LEN = 20;
    uint256 internal constant POOL_ID_LEN = 4;
    uint256 internal constant NEXT_OFFSET = ADDRESS_LEN + POOL_ID_LEN;

    function extractPool(
        bytes calldata _path,
        uint256 _poolNumber
    ) internal pure returns (address tokenIn__, address tokenOut_, uint32 poolId___) {
        uint256 ptr = _poolNumber * NEXT_OFFSET;

        tokenIn__ = bytes(_path[ptr:(ptr = ptr + ADDRESS_LEN)]).toAddress();
        poolId___ = bytes(_path[ptr:(ptr = ptr + POOL_ID_LEN)]).toUint32();
        tokenOut_ = bytes(_path[ptr:(ptr = ptr + ADDRESS_LEN)]).toAddress();
    }

    function getNumberOfPools(bytes calldata _path) internal pure returns (uint256) {
        return (_path.length - ADDRESS_LEN) / NEXT_OFFSET;
    }

    function ensureValid(bytes calldata _path) internal pure {
        require(isValid(_path), "IPL"); // Invalid path length
    }

    function isValid(bytes calldata _path) private pure returns (bool) {
        return (_path.length - ADDRESS_LEN) % NEXT_OFFSET == 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IDexIntegrationActions {
    /// @dev _path: 20 bytes(tokenA) + 4 byte(poolId_A_B) + 20 bytes(tokenB) + ... + 4 byte(poolId_N-1_N) + 20 bytes(tokenN)
    /// @param _path Packed encoded path for the swap in format (tokenA . poolId_AB . tokenB . poolId_BC . tokenC)
    /// @param _operator Address from which the tokenA will be transferred
    /// @param _amountIn Amount of tokenA to spend
    /// @param _minAmountOut Minimum expected amount of tokenC to receive after swap, or 0
    /// @param _recipient Recipient of tokenC
    /// @return amountOut_ Amount of tokenC received after the swap
    function exactInput(
        bytes calldata _path,
        address _operator,
        uint256 _amountIn,
        uint256 _minAmountOut,
        address _recipient
    ) external returns (uint256 amountOut_);
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

import {IIntegrationActions} from "../integrations/IIntegrationActions.sol";

interface IProtocolActions {
    /// @notice General order information
    /// integration - name of the integration where order should be executed
    /// targetChainId - id of the target chain where order should be executed
    struct Order {
        string integration;
        uint256 targetChainId;
    }

    struct MarketOrder {
        Order info;
        bytes path;
        uint256 amountIn;
        uint256 minAmountOut;
        address recipient;
    }

    struct IncreasePositionOrder {
        Order info;
        IIntegrationActions.IncreasePositionParams request;
    }

    struct DecreasePositionOrder {
        Order info;
        IIntegrationActions.DecreasePositionParams request;
    }

    struct HarvestYieldOrder {
        Order info;
        IIntegrationActions.PositionDescriptor request;
    }

    /// @param _order info General order information,
    /// path Packed encoded path for the swap in format (tokenA . poolId_AB . tokenB . poolId_BC . tokenC),
    /// amountIn Amount of tokenA to spend,
    /// minAmountOut Minimum expected amount of tokenC to receive after swap, or 0,
    /// recipient Recipient of tokenC
    function executeOrder(MarketOrder calldata _order) external;

    /// @param _params info General order information,
    /// request Specific order information
    function increasePosition(IncreasePositionOrder calldata _params) external;

    /// @param _params info General order information,
    /// request Specific order information
    /// @return An array of received tokens
    function decreasePosition(
        DecreasePositionOrder calldata _params
    ) external returns (IIntegrationActions.Input[] memory);

    /// @param _params info General order information,
    /// request Specific order information
    /// @return An array of received tokens
    function harvestYield(
        HarvestYieldOrder calldata _params
    ) external returns (IIntegrationActions.Input[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IProtocolActions} from "../IProtocolActions.sol";

interface ISwapValidator {
    /// @dev Validates order params and delegates execution to dedicated integration
    function validateOrderAndExecuteSwap(
        address _operator,
        IProtocolActions.MarketOrder memory _order
    ) external;
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

import {IProtocolActions} from "contracts/interfaces/protocol/IProtocolActions.sol";
import {ISwapValidator} from "contracts/interfaces/protocol/layers/ISwapValidator.sol";
import {IIntegrationRegister} from "contracts/interfaces/protocol/IIntegrationRegister.sol";
import {IDexIntegrationActions} from "contracts/interfaces/integrations/dex/IDexIntegrationActions.sol";

import {InternalCallee} from "contracts/base/InternalCallee.sol";
import {ProtocolCommon} from "../base/ProtocolCommon.sol";
import {Path} from "contracts/integrations/libraries/Path.sol";
import {SafeDelegateCall} from "contracts/libraries/SafeDelegateCall.sol";

contract SwapValidator is ISwapValidator, InternalCallee, ProtocolCommon {
    using Path for bytes;
    using SafeDelegateCall for address;

    /// @inheritdoc ISwapValidator
    function validateOrderAndExecuteSwap(
        address _operator,
        IProtocolActions.MarketOrder calldata _order
    ) external override onlyInternal {
        _order.path.ensureValid();

        address integration = getRegister().getIntegrationAddress(_order.info.integration);

        integration.safeDelegateCall(
            abi.encodeCall(
                IDexIntegrationActions.exactInput,
                (_order.path, _operator, _order.amountIn, _order.minAmountOut, _order.recipient)
            )
        );
    }
}