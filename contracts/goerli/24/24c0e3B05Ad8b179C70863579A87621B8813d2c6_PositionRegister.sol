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

import {IIntegrationActions} from "./IIntegrationActions.sol";

interface IIntegrationGetters {
    /// @param _encodedPool Encoded data of the pool that can be decoded by the integration
    /// @return poolId_ The id of the pool
    function getPoolId(bytes calldata _encodedPool) external view returns (uint256 poolId_);

    /// @param _descriptor Pool id with any arbitrary encoded data
    /// @return yield_ Abstract yield amount that may be interpreted differently depending on the integration
    function getPositionYield(
        IIntegrationActions.PositionDescriptor calldata _descriptor
    ) external view returns (uint256 yield_);
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
import {IPositionRegister} from "contracts/interfaces/protocol/layers/IPositionRegister.sol";
import {IIntegrationRegister} from "contracts/interfaces/protocol/IIntegrationRegister.sol";

import {IIntegrationActions} from "contracts/interfaces/integrations/IIntegrationActions.sol";
import {IIntegrationGetters} from "contracts/interfaces/integrations/IIntegrationGetters.sol";

import {InternalCallee} from "contracts/base/InternalCallee.sol";
import {ProtocolCommon} from "../base/ProtocolCommon.sol";
import {BytesLibrary} from "contracts/libraries/BytesLibrary.sol";
import {SafeDelegateCall} from "contracts/libraries/SafeDelegateCall.sol";
import {LiquidityStaking} from "../libraries/LiquidityStaking.sol";

contract PositionRegister is IPositionRegister, InternalCallee, ProtocolCommon {
    using BytesLibrary for bytes;
    using SafeDelegateCall for address;
    using LiquidityStaking for IIntegrationActions.PositionDescriptor;

    /// @inheritdoc IPositionRegister
    function validateAndIncreasePosition(
        address _operator,
        IProtocolActions.IncreasePositionOrder calldata _orderParams
    ) external override onlyInternal {
        address integration = getRegister().getIntegrationAddress(_orderParams.info.integration);

        uint256 liquidity = integration
            .safeDelegateCall(
                abi.encodeCall(
                    IIntegrationActions.increasePosition,
                    (_operator, _orderParams.request)
                )
            )
            .toUint256();

        _orderParams.request.descriptor.updateUserPosition(
            currentYield(integration, _orderParams.request.descriptor),
            _operator,
            int256(liquidity)
        );
    }

    /// @inheritdoc IPositionRegister
    function validateAndDecreasePosition(
        address _operator,
        IProtocolActions.DecreasePositionOrder calldata _orderParams
    ) external override onlyInternal returns (IIntegrationActions.Input[] memory) {
        address integration = getRegister().getIntegrationAddress(_orderParams.info.integration);

        _orderParams.request.descriptor.updateUserPosition(
            currentYield(integration, _orderParams.request.descriptor),
            _operator,
            -int256(_orderParams.request.liquidity)
        );

        return
            parseReceivedTokens(
                integration.safeDelegateCall(
                    abi.encodeCall(
                        IIntegrationActions.decreasePosition,
                        (_operator, _orderParams.request)
                    )
                )
            );
    }

    /// @inheritdoc IPositionRegister
    function validateParamsAndHarvestYield(
        address _operator,
        IProtocolActions.HarvestYieldOrder calldata _orderParams
    ) external override onlyInternal returns (IIntegrationActions.Input[] memory) {
        address integration = getRegister().getIntegrationAddress(_orderParams.info.integration);

        // Allowing the integration prepare yield in case it has to
        integration.safeDelegateCall(
            abi.encodeCall(IIntegrationActions.prepareYield, (_orderParams.request))
        );

        uint256 lastYield = currentYield(integration, _orderParams.request);

        _orderParams.request.updateUserPosition(lastYield, _operator, 0);

        return
            parseReceivedTokens(
                integration.safeDelegateCall(
                    abi.encodeCall(
                        IIntegrationActions.harvestYield,
                        (
                            _operator,
                            IIntegrationActions.HarvestYieldParams({
                                descriptor: _orderParams.request,
                                yield: _orderParams.request.pullUserYield(lastYield, _operator)
                            })
                        )
                    )
                )
            );
    }

    function getUserLiquidity(
        IIntegrationActions.PositionDescriptor calldata _descriptor,
        address _user
    ) external view returns (uint256) {
        return _descriptor.getLiquidity(_user);
    }

    function currentYield(
        address _integration,
        IIntegrationActions.PositionDescriptor calldata _descriptor
    ) private returns (uint256) {
        return
            _integration
                .safeDelegateCall(
                    abi.encodeCall(IIntegrationGetters.getPositionYield, (_descriptor))
                )
                .toUint256();
    }

    function parseReceivedTokens(
        bytes memory _data
    ) private pure returns (IIntegrationActions.Input[] memory) {
        return abi.decode(_data, (IIntegrationActions.Input[]));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IIntegrationActions} from "contracts/interfaces/integrations/IIntegrationActions.sol";
import {UFixed256x32Math, UFixed256x32} from "./UFixed256x32Math.sol";

library LiquidityStaking {
    using DescriptorHash for IIntegrationActions.PositionDescriptor;
    using UFixed256x32Math for uint256;
    using UFixed256x32Math for UFixed256x32;

    struct User {
        uint256 liquidity;
        UFixed256x32 lastYPL;
        uint256 yieldDebt;
    }

    struct Position {
        uint256 lastYield;
        UFixed256x32 yieldPerLiquidity;
        uint256 totalLiquidity;
        mapping(address => User) users;
    }

    struct State {
        mapping(bytes32 descriptorHash => Position) positions;
    }

    function updateUserPosition(
        IIntegrationActions.PositionDescriptor calldata _descriptor,
        uint256 _currentYield,
        address _userAddress,
        int256 _liquidityDelta
    ) internal {
        User storage user = positions(_descriptor.hash()).users[_userAddress];
        if (_liquidityDelta < 0) require(uint256(-_liquidityDelta) <= user.liquidity, "NEL"); // Not enough liquidity

        updatePosition(_descriptor, _currentYield, _liquidityDelta);

        Position storage position = positions(_descriptor.hash());

        user.yieldDebt += position
            .yieldPerLiquidity
            .sub(user.lastYPL)
            .mul(user.liquidity)
            .toUint256();
        user.lastYPL = position.yieldPerLiquidity;
        user.liquidity = uint256(int256(user.liquidity) + _liquidityDelta);
    }

    function pullUserYield(
        IIntegrationActions.PositionDescriptor calldata _descriptor,
        uint256 _currentYield,
        address _userAddress
    ) internal returns (uint256 yieldDebt_) {
        updateUserPosition(_descriptor, _currentYield, _userAddress, 0);

        User storage user = positions(_descriptor.hash()).users[_userAddress];

        yieldDebt_ = user.yieldDebt;
        delete user.yieldDebt;
        positions(_descriptor.hash()).lastYield -= yieldDebt_;
    }

    function getLiquidity(
        IIntegrationActions.PositionDescriptor calldata _descriptor,
        address _userAddress
    ) internal view returns (uint256) {
        return positions(_descriptor.hash()).users[_userAddress].liquidity;
    }

    function updatePosition(
        IIntegrationActions.PositionDescriptor calldata _descriptor,
        uint256 _currentYield,
        int256 _liquidityDelta
    ) private {
        Position storage position = positions(_descriptor.hash());

        if (position.totalLiquidity > 0) {
            position.yieldPerLiquidity = position.yieldPerLiquidity.add(
                (_currentYield - position.lastYield).toUFixed256x32().div(position.totalLiquidity)
            );
        }
        position.lastYield = _currentYield;
        position.totalLiquidity = uint256(int256(position.totalLiquidity) + _liquidityDelta);
    }

    function positions(bytes32 _key) private view returns (Position storage) {
        bytes32 storageSlot = keccak256("facets.protocol.layers.positions.storage");
        State storage state;
        assembly {
            state.slot := storageSlot
        }
        return state.positions[_key];
    }
}

library DescriptorHash {
    function hash(
        IIntegrationActions.PositionDescriptor calldata _descriptor
    ) internal pure returns (bytes32) {
        return keccak256(bytes.concat(bytes32(_descriptor.poolId), _descriptor.extraData));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

type UFixed256x32 is uint256;

/// @notice Implements common math functions for the "UFixed256x32" type
library UFixed256x32Math {
    uint private constant RESOLUTION = 10 ** 32;

    function add(UFixed256x32 a, UFixed256x32 b) internal pure returns (UFixed256x32) {
        return UFixed256x32.wrap(UFixed256x32.unwrap(a) + UFixed256x32.unwrap(b));
    }

    function sub(UFixed256x32 a, UFixed256x32 b) internal pure returns (UFixed256x32) {
        return UFixed256x32.wrap(UFixed256x32.unwrap(a) - UFixed256x32.unwrap(b));
    }

    function mul(UFixed256x32 a, uint256 b) internal pure returns (UFixed256x32) {
        return UFixed256x32.wrap(UFixed256x32.unwrap(a) * b);
    }

    function div(UFixed256x32 a, uint256 b) internal pure returns (UFixed256x32) {
        return UFixed256x32.wrap(UFixed256x32.unwrap(a) / b);
    }

    function toUFixed256x32(uint256 a) internal pure returns (UFixed256x32) {
        return UFixed256x32.wrap(a * RESOLUTION);
    }

    function toUint256(UFixed256x32 a) internal pure returns (uint256) {
        return UFixed256x32.unwrap(a) / RESOLUTION;
    }
}