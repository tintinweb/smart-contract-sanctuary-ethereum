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

import {IIntegrationRegister} from "contracts/interfaces/protocol/IIntegrationRegister.sol";

import {DiamondOwnableConsumer} from "contracts/base/DiamondOwnableConsumer.sol";

abstract contract IntegrationRegisterStorage {
    struct Register {
        mapping(bytes32 integrationNameHash => address integrationAddress) integrations;
    }

    bytes32 private constant STORAGE_POSITION =
        keccak256("facets.protocol.layers.integrations.storage");

    function _storage() internal view returns (mapping(bytes32 => address) storage) {
        bytes32 storageSlot = STORAGE_POSITION;
        Register storage register;
        assembly {
            register.slot := storageSlot
        }
        return register.integrations;
    }
}

contract IntegrationRegister is
    IIntegrationRegister,
    IntegrationRegisterStorage,
    DiamondOwnableConsumer
{
    using String2Hash for string;

    /// @inheritdoc IIntegrationRegister
    function registerIntegration(
        string calldata _integrationName,
        address _integrationAddress
    ) external override onlyOwner {
        _storage()[_integrationName.hash()] = _integrationAddress;
    }

    /// @inheritdoc IIntegrationRegister
    function getIntegrationAddress(
        string calldata _integrationName
    ) external view override returns (address integration_) {
        require((integration_ = _storage()[_integrationName.hash()]) != address(0), "INR"); // Integration is not registered
    }
}

library String2Hash {
    function hash(string calldata _name) internal pure returns (bytes32 hash_) {
        hash_ = keccak256(abi.encodePacked(_name));
    }
}