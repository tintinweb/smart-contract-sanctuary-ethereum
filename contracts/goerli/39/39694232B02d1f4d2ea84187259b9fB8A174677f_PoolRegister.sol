// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {DiamondLib} from "../libraries/DiamondLib.sol";

/// @notice Adaptation of "Ownable" contract made by OpenZeppelin for the diamond
abstract contract DiamondOwnableConsumer {
    modifier onlyOwner() {
        enforceIsContractOwner();
        _;
    }

    function enforceIsContractOwner() private view {
        require(msg.sender == contractOwner(), "CNO"); // Caller is not the owner
    }

    function contractOwner() private view returns (address contractOwner_) {
        contractOwner_ = DiamondLib.diamondStorage().contractOwner;
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

interface IIntegrationRestricted {
    /// @param _encodedPool Encoded data of the pool that can be decoded by the integration
    /// @return poolId_ The id of the enabled pool
    function enablePool(bytes calldata _encodedPool) external returns (uint256 poolId_);
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

interface IPoolRegister {
    event PoolEnabled(uint256 poolId, string indexed integrationName, bytes encodedPool);

    /// @notice Admin method for enabling pools
    /// @param _encodedPools An array of the encoded data of the pool
    function enablePools(string calldata _integrationName, bytes[] calldata _encodedPools) external;

    /// @param _integrationName The name of the integration where pool exists
    /// @param _encodedPool An encoded data of the pool
    /// @return poolId_ The id of the pool
    function getPoolId(
        string calldata _integrationName,
        bytes calldata _encodedPool
    ) external returns (uint256 poolId_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library DiamondLib {
    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    bytes32 private constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage");

    function diamondStorage() internal pure returns (DiamondStorage storage ds_) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds_.slot := position
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

import {IPoolRegister} from "contracts/interfaces/protocol/IPoolRegister.sol";

import {IIntegrationRestricted} from "contracts/interfaces/integrations/IIntegrationRestricted.sol";
import {IIntegrationGetters} from "contracts/interfaces/integrations/IIntegrationGetters.sol";

import {ProtocolCommon} from "./base/ProtocolCommon.sol";
import {DiamondOwnableConsumer} from "contracts/base/DiamondOwnableConsumer.sol";
import {SafeDelegateCall} from "contracts/libraries/SafeDelegateCall.sol";

contract PoolRegister is IPoolRegister, ProtocolCommon, DiamondOwnableConsumer {
    using SafeDelegateCall for address;

    /// @inheritdoc IPoolRegister
    function enablePools(
        string calldata _integrationName,
        bytes[] calldata _encodedPools
    ) external onlyOwner {
        address integration = getRegister().getIntegrationAddress(_integrationName);

        for (uint256 i; i < _encodedPools.length; ) {
            bytes memory encoded = integration.safeDelegateCall(
                abi.encodeCall(IIntegrationRestricted.enablePool, (_encodedPools[i]))
            );

            emit PoolEnabled(abi.decode(encoded, (uint256)), _integrationName, _encodedPools[i]);

            unchecked {
                i++;
            }
        }
    }

    /// @inheritdoc IPoolRegister
    function getPoolId(
        string calldata _integration,
        bytes calldata _encodedPool
    ) external override returns (uint256 poolId_) {
        address integration = getRegister().getIntegrationAddress(_integration);

        bytes memory encoded = integration.safeDelegateCall(
            abi.encodeCall(IIntegrationGetters.getPoolId, (_encodedPool))
        );

        poolId_ = abi.decode(encoded, (uint256));
    }
}