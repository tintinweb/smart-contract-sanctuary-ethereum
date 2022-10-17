// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.6;

import {IERC173} from "../interfaces/IERC173.sol";
import {LibOwnership} from "../libraries/LibOwnership.sol";

contract OwnershipFacet is IERC173 {
    function transferOwnership(address _newOwner) external override {
        LibOwnership._enforceIsContractOwner();
        LibOwnership._setContractOwner(_newOwner);
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.6;

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
interface IERC173 {
    /**
     * @dev This emits when ownership of a contract changes.
     */
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @notice Set the address of the new owner of the contract.
     * @dev Set _newOwner to address(0) to renounce any ownership.
     * @param _newOwner The address of the new owner of the contract
     */
    function transferOwnership(address _newOwner) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.6;

import {LibDiamondStorage} from "./LibDiamondStorage.sol";

// Thrown if `msg.sender` is not contract owner
error NotContractOwner(address _user, address _contractOwner);

library LibOwnership {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function _setContractOwner(address _newOwner) internal {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage
            ._diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function _contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = LibDiamondStorage._diamondStorage().contractOwner;
    }

    function _enforceIsContractOwner() internal view {
        if (msg.sender != LibDiamondStorage._diamondStorage().contractOwner)
            revert NotContractOwner(
                msg.sender,
                LibDiamondStorage._diamondStorage().contractOwner
            );
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.6;

library LibDiamondStorage {
    // The hash for diamond storage position, which is:
    // keccak256("diamond.standard.diamond.storage")
    bytes32 constant DIAMOND_STORAGE_POSITION =
        0xc8fcad8db84d3cc18b4c41d551ea0ee66dd599cde068d998e57d5e09332c131c;

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // Maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // Maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // Facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // Owner of the contract
        address contractOwner;
    }

    function _diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}