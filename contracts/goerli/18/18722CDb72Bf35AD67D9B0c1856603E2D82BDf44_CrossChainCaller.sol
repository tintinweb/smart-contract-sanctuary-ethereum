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
import {IIntegrationActions} from "contracts/interfaces/integrations/IIntegrationActions.sol";

interface ICrossChainCaller {
    /// @dev Executes order on-chain or sends it to cross-chain module
    function executeOrderOnChainOrCrossChain(
        address _operator,
        IProtocolActions.MarketOrder memory _orderParams
    ) external;

    /// @dev Adds liquidity on-chain or sends request to cross-chain module
    function increasePositionOnChainOrCrossChain(
        address _operator,
        IProtocolActions.IncreasePositionOrder memory _orderParams
    ) external;

    /// @dev Removes liquidity on-chain or sends request to cross-chain module
    /// @return An array of received tokens, should not be requested cross-chain
    function decreasePositionOnChainOrCrossChain(
        address _operator,
        IProtocolActions.DecreasePositionOrder memory _orderParams
    ) external returns (IIntegrationActions.Input[] memory);

    /// @dev Harvests liquidity on-chain or send request to cross-chain module
    /// @return An array of received tokens, should not be requested cross-chain
    function harvestYieldOnChainOrCrossChain(
        address _operator,
        IProtocolActions.HarvestYieldOrder memory _orderParams
    ) external returns (IIntegrationActions.Input[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IIntegrationActions} from "contracts/interfaces/integrations/IIntegrationActions.sol";
import {IProtocolActions} from "../IProtocolActions.sol";

interface IPositionRegister {
    /// @dev Validates request, remembers user position and delegates to the actual integration
    /// position will be opened with address(this) as the owner
    function validateAndIncreasePosition(
        address _operator,
        IProtocolActions.IncreasePositionOrder calldata _orderParams
    ) external;

    /// @dev Validates request, checks if user have specified position and delegates to the actual integration
    /// @return An array of received tokens
    function validateAndDecreasePosition(
        address _operator,
        IProtocolActions.DecreasePositionOrder calldata _orderParams
    ) external returns (IIntegrationActions.Input[] memory);

    /// @dev Validates request, claims yield and sends to the recipient his share
    /// @return An array of received tokens
    function validateParamsAndHarvestYield(
        address _operator,
        IProtocolActions.HarvestYieldOrder calldata _orderParams
    ) external returns (IIntegrationActions.Input[] memory);

    /// @dev Reads user's liquidity in specific position
    /// @return Amount of liquidity that user shares in the `_descriptor` position
    function getUserLiquidity(
        IIntegrationActions.PositionDescriptor calldata _descriptor,
        address _user
    ) external view returns (uint256);
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

import {IProtocolActions} from "contracts/interfaces/protocol/IProtocolActions.sol";
import {ICrossChainCaller} from "contracts/interfaces/protocol/layers/ICrossChainCaller.sol";

import {ISwapValidator} from "contracts/interfaces/protocol/layers/ISwapValidator.sol";
import {IPositionRegister} from "contracts/interfaces/protocol/layers/IPositionRegister.sol";
import {IIntegrationActions} from "contracts/interfaces/integrations/IIntegrationActions.sol";

import {InternalCallee} from "contracts/base/InternalCallee.sol";

contract CrossChainCaller is ICrossChainCaller, InternalCallee {
    uint256 private immutable cachedChainId;

    constructor() {
        cachedChainId = block.chainid;
    }

    /// @inheritdoc ICrossChainCaller
    function executeOrderOnChainOrCrossChain(
        address _operator,
        IProtocolActions.MarketOrder memory _order
    ) external override onlyInternal {
        if (isCrossChainOrder(_order.info)) {
            revert("Cross chain is not exist yet");
        } else {
            ISwapValidator(address(this)).validateOrderAndExecuteSwap(_operator, _order);
        }
    }

    /// @inheritdoc ICrossChainCaller
    function increasePositionOnChainOrCrossChain(
        address _operator,
        IProtocolActions.IncreasePositionOrder memory _order
    ) external override onlyInternal {
        if (isCrossChainOrder(_order.info)) {
            revert("Cross chain is not exist yet");
        } else {
            IPositionRegister(address(this)).validateAndIncreasePosition(_operator, _order);
        }
    }

    /// @inheritdoc ICrossChainCaller
    function decreasePositionOnChainOrCrossChain(
        address _operator,
        IProtocolActions.DecreasePositionOrder memory _order
    ) external override onlyInternal returns (IIntegrationActions.Input[] memory) {
        if (isCrossChainOrder(_order.info)) {
            revert("Cross chain is not exist yet");
        } else {
            return IPositionRegister(address(this)).validateAndDecreasePosition(_operator, _order);
        }
    }

    /// @inheritdoc ICrossChainCaller
    function harvestYieldOnChainOrCrossChain(
        address _operator,
        IProtocolActions.HarvestYieldOrder memory _order
    ) external override onlyInternal returns (IIntegrationActions.Input[] memory) {
        if (isCrossChainOrder(_order.info)) {
            revert("Cross chain is not exist yet");
        } else {
            return
                IPositionRegister(address(this)).validateParamsAndHarvestYield(_operator, _order);
        }
    }

    function isCrossChainOrder(IProtocolActions.Order memory _order) internal view returns (bool) {
        return _order.targetChainId != cachedChainId;
    }
}