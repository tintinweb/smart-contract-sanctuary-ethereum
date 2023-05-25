// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
interface IERC173 {
    /// @notice This emits when ownership of a contract changes.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() external view returns (address owner_);
    function transferOwnership(address _newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDiamond {
    enum FacetCutAction {
        Add,     // 0
        Replace, // 1
        Remove   // 2
    }

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    struct DiamondArgs {
        address owner;
        address init;
        bytes initCalldata;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IDiamond} from "./IDiamond.sol";

/**
 * @title DiamondCutFacet
 * @author Nick Mudge <[email protected]> (https://twitter.com/mudgen)
 * @notice Required function selector modification to support EIP-2535
 */
interface IDiamondCut is IDiamond {
    function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IDiamondLoupe
 * @author Nick Mudge <[email protected]> (https://twitter.com/mudgen)
 * @notice Required introspection functions for EIP-2535 Diamond Standard
 */
 interface IDiamondLoupe {

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    function facets() external view returns (Facet[] memory facets_);
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);
    function facetAddresses() external view returns (address[] memory facetAddresses_);
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IDiamond} from "src/interfaces/diamond-core/IDiamond.sol";

error NoSelectorsGivenToAdd();
error NotContractOwner(address _user, address _contractOwner);
error NoSelectorsProvidedForFacetForCut(address _facetAddress);
error CannotAddSelectorsToZeroAddress(bytes4[] _selectors);
error NoBytecodeAtAddress(address _contractAddress, string _message);
error IncorrectFacetCutAction(uint8 _action);
error CannotAddFunctionToDiamondThatAlreadyExists(bytes4 _selector);
error CannotReplaceFunctionsFromFacetWithZeroAddress(bytes4[] _selectors);
error CannotReplaceImmutableFunction(bytes4 _selector);
error CannotReplaceFunctionWithTheSameFunctionFromTheSameFacet(bytes4 _selector);
error CannotReplaceFunctionThatDoesNotExists(bytes4 _selector);
error RemoveFacetAddressMustBeZeroAddress(address _facetAddress);
error CannotRemoveFunctionThatDoesNotExist(bytes4 _selector);
error CannotRemoveImmutableFunction(bytes4 _selector);
error InitializationFunctionReverted(address _initializationContractAddress, bytes _calldata);

/**
 * @title LibDiamond
 * @author Nick Mudge <[email protected]> (https://twitter.com/mudgen)
 * @notice Library of Diamond Functions
 */
library LibDiamond {

    struct FacetAddressAndSelectorPosition {
        address facetAddress;
        uint16 selectorPosition;
    }

    struct DiamondStorage {
        mapping(bytes4 => FacetAddressAndSelectorPosition) facetAddressAndSelectorPosition;
        bytes4[] selectors;
        mapping(bytes4 => bool) supportedInterfaces;
        address contractOwner;
    }

    /// @dev Standard storage slot for the shared diamond storage
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    /// @notice Emitted when Ownership of the diamond is transferred
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Emitted when a DiamondCut takes place
    event DiamondCut(IDiamond.FacetCut[] _diamondCut, address _init, bytes _calldata);


    /// @dev Returns data stored at the `DIAMOND_STORAGE_POSITION`
    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /**
     * @notice Transfers ownership of the diamond to the provided owner
     *
     * @dev    Throws if caller is not the current owner
     *
     * @dev    <h4>Postconditions</h4>
     * @dev    1. The provided address is the new owner
     * @dev    2. The previous owner is no longer the owner
     *
     * @param  _newOwner address of the new owner
     */
    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    /// @dev Returns the contract owner of the Diamond
    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    /// @dev Internal function version of diamondCut
    function diamondCut(IDiamond.FacetCut[] memory _diamondCut, address _init, bytes memory _calldata) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            bytes4[] memory functionSelectors = _diamondCut[facetIndex].functionSelectors;
            address facetAddress = _diamondCut[facetIndex].facetAddress;
            if (functionSelectors.length == 0) {
                revert NoSelectorsProvidedForFacetForCut(facetAddress);
            }
            IDiamond.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamond.FacetCutAction.Add) {
                addFunctions(facetAddress, functionSelectors);
            } else if (action == IDiamond.FacetCutAction.Replace) {
                replaceFunctions(facetAddress, functionSelectors);
            } else if (action == IDiamond.FacetCutAction.Remove) {
                removeFunctions(facetAddress, functionSelectors);
            } else {
                revert IncorrectFacetCutAction(uint8(action));
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    /**
     * @dev Associates a facet address with an array of function selectors
     *
     * @dev Throws if the facet address is address(0)
     * @dev Throws if the facet address does not contain code
     * @dev Throws if the function selector is already assigned a facet
     *
     * @dev <h4>Postconditions</h4>
     * @dev 1. The facet address is associated with the list of function selectors
     */
    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        if (_facetAddress == address(0)) {
            revert CannotAddSelectorsToZeroAddress(_functionSelectors);
        }
        DiamondStorage storage ds = diamondStorage();
        uint16 selectorCount = uint16(ds.selectors.length);
        enforceHasContractCode(_facetAddress, "LibDiamondCut: Add facet has no code");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            if (oldFacetAddress != address(0)) {
                revert CannotAddFunctionToDiamondThatAlreadyExists(selector);
            }
            ds.facetAddressAndSelectorPosition[selector] = FacetAddressAndSelectorPosition(_facetAddress, selectorCount);
            ds.selectors.push(selector);
            selectorCount++;
        }
    }

    /**
     * @dev Replaces an array of function selectors with a new facet address
     *
     * @dev Throws if the provided facet address is the zero address
     * @dev Throws if the provided facet address does not contain code
     * @dev Throws if trying to replace an immutable function selector
     * @dev Throws if trying to replace with the same facet address and function selector
     * @dev Throws if any function selector in the `_functionSelectors` array does not exist
     *
     * @dev <h4>Postconditions</h4>
     * @dev 1. The list of function selectors are replaced with the new facet address
     */
    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        DiamondStorage storage ds = diamondStorage();
        if (_facetAddress == address(0)) {
            revert CannotReplaceFunctionsFromFacetWithZeroAddress(_functionSelectors);
        }
        enforceHasContractCode(_facetAddress, "LibDiamondCut: Replace facet has no code");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            // can't replace immutable functions -- functions defined directly in the diamond in this case
            if (oldFacetAddress == address(this)) {
                revert CannotReplaceImmutableFunction(selector);
            }
            if (oldFacetAddress == _facetAddress) {
                revert CannotReplaceFunctionWithTheSameFunctionFromTheSameFacet(selector);
            }
            if (oldFacetAddress == address(0)) {
                revert CannotReplaceFunctionThatDoesNotExists(selector);
            }
            // replace old facet address
            ds.facetAddressAndSelectorPosition[selector].facetAddress = _facetAddress;
        }
    }

    /**
     * @dev Removes functions from the Diamond
     *
     * @dev Throws if the provided facet address is not address(0)
     * @dev Throws if any function in the `_functionSelectors` does not exist
     * @dev Throws if any function in the `_functionSelectors` array is immutable
     *
     * @dev <h4>Postconditions</h4>
     * @dev 1. The provided array of function selectors have been removed from the Diamond
     */
    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        DiamondStorage storage ds = diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        if (_facetAddress != address(0)) {
            revert RemoveFacetAddressMustBeZeroAddress(_facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            FacetAddressAndSelectorPosition memory oldFacetAddressAndSelectorPosition =
                ds.facetAddressAndSelectorPosition[selector];
            if (oldFacetAddressAndSelectorPosition.facetAddress == address(0)) {
                revert CannotRemoveFunctionThatDoesNotExist(selector);
            }

            // can't remove immutable functions -- functions defined directly in the diamond
            if (oldFacetAddressAndSelectorPosition.facetAddress == address(this)) {
                revert CannotRemoveImmutableFunction(selector);
            }
            // replace selector with last selector
            selectorCount--;
            if (oldFacetAddressAndSelectorPosition.selectorPosition != selectorCount) {
                bytes4 lastSelector = ds.selectors[selectorCount];
                ds.selectors[oldFacetAddressAndSelectorPosition.selectorPosition] = lastSelector;
                ds.facetAddressAndSelectorPosition[lastSelector].selectorPosition =
                    oldFacetAddressAndSelectorPosition.selectorPosition;
            }
            // delete last selector
            ds.selectors.pop();
            delete ds.facetAddressAndSelectorPosition[selector];
        }
    }

    /**
     * @dev Calls the initialization address with the provide abi encoded calldata
     *
     * @dev Throws if invalid calldata is provided
     *
     * @dev <h4>Postconditions</h4>
     * @dev 1. The initialization address has performed any updates in the provided calldata
     */
    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            return;
        }
        enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
        (bool success, bytes memory error) = _init.delegatecall(_calldata);
        if (!success) {
            if (error.length > 0) {
                // bubble up error
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(error)
                    revert(add(32, error), returndata_size)
                }
            } else {
                revert InitializationFunctionReverted(_init, _calldata);
            }
        }
    }

    /// @dev Enforces the msg.sender is the contract owner, reverts if not
    function requireContractOwner() internal view {
        if (msg.sender != diamondStorage().contractOwner) {
            revert NotContractOwner(msg.sender, diamondStorage().contractOwner);
        }
    }

    /// @dev Enforces the provided address has code, reverts if not 
    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        if (contractSize == 0) {
            revert NoBytecodeAtAddress(_contract, _errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "src/libraries/diamond-core/LibDiamond.sol";
import {IDiamondLoupe} from "src/interfaces/diamond-core/IDiamondLoupe.sol";
import {IDiamondCut} from "src/interfaces/diamond-core/IDiamondCut.sol";
import {IERC173} from "src/interfaces/access/IERC173.sol";
import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

/**
 * @title DiamondInit
 * @author Nick Mudge <[email protected]> (https://twitter.com/mudgen)
 * @notice Initialization contract called to set required state variables
 */
contract DiamondInit {

    /**
     * @notice Initializes the diamond
     *
     * @dev    <h4>Postconditions</h4>
     * @dev    1. The diamond's supported interfaces are set
     * @dev    2. Any other state variables are set
     */
    function init() external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;
        ds.supportedInterfaces[type(IAccessControl).interfaceId] = true;
    }
}