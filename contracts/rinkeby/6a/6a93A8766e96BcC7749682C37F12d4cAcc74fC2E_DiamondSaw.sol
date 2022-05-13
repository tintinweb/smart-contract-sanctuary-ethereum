// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import {IDiamondCut} from "./facets/DiamondClone/IDiamondCut.sol";
import {IDiamondLoupe} from "./facets/DiamondClone/IDiamondLoupe.sol";
import {DiamondSawLib} from "./libraries/DiamondSawLib.sol";
import {AccessControlFacet} from "./facets/AccessControl/AccessControlFacet.sol";
import {AccessControlModifiers} from "./facets/AccessControl/AccessControlModifiers.sol";
import {AccessControlLib} from "./facets/AccessControl/AccessControlLib.sol";

/**
 * DiamondSaw is meant to be used as a
 * Singleton to "cut" many minimal diamond clones
 * In a gas efficient manner for deployments.
 *
 * This is accomplished by handling the storage intensive
 * selector mappings in one contract, "the saw" instead of in each diamond.
 *
 * Adding a new facet to the saw enables new diamond "patterns"
 *
 * This should be used if you
 *
 * 1. Need cheap deployments of many similar cloned diamonds that
 * utilize the same pre-deployed facets
 *
 * 2. Are okay with gas overhead on write txn to the diamonds
 * to communicate with the singleton (saw) to fetch selectors
 *
 */
contract DiamondSaw is AccessControlFacet, AccessControlModifiers {
    constructor() {
        AccessControlLib._transferOwnership(msg.sender);
    }

    function addFacetPattern(
        IDiamondCut.FacetCut[] calldata _facetAdds,
        address _init,
        bytes calldata _calldata
    ) external onlyAdmin {
        DiamondSawLib.diamondCutAddOnly(_facetAdds, _init, _calldata);
    }

    // if a facet has no selectors, it is not supported
    function checkFacetSupported(address _facetAddress) external view {
        DiamondSawLib.checkFacetSupported(_facetAddress);
    }

    function facetAddressForSelector(bytes4 selector) external view returns (address) {
        return DiamondSawLib.diamondSawStorage().selectorToFacetAndPosition[selector].facetAddress;
    }

    function functionSelectorsForFacetAddress(address facetAddress) external view returns (bytes4[] memory) {
        return DiamondSawLib.diamondSawStorage().facetFunctionSelectors[facetAddress].functionSelectors;
    }

    function allFacetAddresses() external view returns (address[] memory) {
        return DiamondSawLib.diamondSawStorage().facetAddresses;
    }

    function allFacetsWithSelectors() external view returns (IDiamondLoupe.Facet[] memory _facetsWithSelectors) {
        DiamondSawLib.DiamondSawStorage storage ds = DiamondSawLib.diamondSawStorage();

        uint256 numFacets = ds.facetAddresses.length;
        _facetsWithSelectors = new IDiamondLoupe.Facet[](numFacets);
        for (uint256 i; i < numFacets; i++) {
            address facetAddress_ = ds.facetAddresses[i];
            _facetsWithSelectors[i].facetAddress = facetAddress_;
            _facetsWithSelectors[i].functionSelectors = ds.facetFunctionSelectors[facetAddress_].functionSelectors;
        }
    }

    function facetAddressForInterface(bytes4 _interface) external view returns (address) {
        DiamondSawLib.DiamondSawStorage storage ds = DiamondSawLib.diamondSawStorage();
        return ds.interfaceToFacet[_interface];
    }

    function setFacetForERC165Interface(bytes4 _interface, address _facet) external onlyAdmin {
        DiamondSawLib.checkFacetSupported(_facet);
        DiamondSawLib.diamondSawStorage().interfaceToFacet[_interface] = _facet;
    }

    function setTransferHooksContractApproved(address tokenTransferHookContract, bool approved) external onlyOwner {
        DiamondSawLib.setTransferHooksContractApproved(tokenTransferHookContract, approved);
    }

    function isTransferHooksContractApproved(address tokenTransferHookContract) external view returns (bool) {
        return DiamondSawLib.diamondSawStorage().approvedTransferHooksContracts[tokenTransferHookContract];
    }

    function setUpgradeSawAddress(address _upgradeSaw) external onlyOwner {
        DiamondSawLib.setUpgradeSawAddress(_upgradeSaw);
    }

    function getUpgradeSawAddress() external view returns (address) {
        return DiamondSawLib.diamondSawStorage().upgradeSawAddress;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import {IDiamondCut} from "../facets/DiamondClone/IDiamondCut.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

library DiamondSawLib {
    bytes32 constant DIAMOND_SAW_STORAGE_POSITION = keccak256("diamond.standard.diamond.saw.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondSawStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a facet implements a given interface
        // Note: this works because no interface can be implemented by
        // two different facets with diamond saw because no
        // selector overlap is permitted!!
        mapping(bytes4 => address) interfaceToFacet;
        // for transfer hooks, contracts must be approved in the saw
        mapping(address => bool) approvedTransferHooksContracts;
        // the next saw contract to upgrade to
        address upgradeSawAddress;
    }

    function diamondSawStorage() internal pure returns (DiamondSawStorage storage ds) {
        bytes32 position = DIAMOND_SAW_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    // only supports adding new selectors
    function diamondCutAddOnly(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            require(_diamondCut[facetIndex].action == IDiamondCut.FacetCutAction.Add, "Only add action supported in saw");
            require(!isFacetSupported(_diamondCut[facetIndex].facetAddress), "Facet already exists in saw");
            addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondSawStorage storage ds = diamondSawStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;

            require(oldFacetAddress == address(0), "Cannot add function that already exists");
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function addFacet(DiamondSawStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }

    function addFunction(
        DiamondSawStorage storage ds,
        bytes4 _selector,
        uint96 _selectorPosition,
        address _facetAddress
    ) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }

    function setFacetSupportsInterface(bytes4 _interface, address _facetAddress) internal {
        checkFacetSupported(_facetAddress);
        DiamondSawStorage storage ds = diamondSawStorage();
        ds.interfaceToFacet[_interface] = _facetAddress;
    }

    function isFacetSupported(address _facetAddress) internal view returns (bool) {
        return diamondSawStorage().facetFunctionSelectors[_facetAddress].functionSelectors.length > 0;
    }

    function checkFacetSupported(address _facetAddress) internal view {
        require(isFacetSupported(_facetAddress), "Facet not supported");
    }

    function setTransferHooksContractApproved(address hookContract, bool approved) internal {
        diamondSawStorage().approvedTransferHooksContracts[hookContract] = approved;
    }

    function setUpgradeSawAddress(address _upgradeSaw) internal {
        diamondSawStorage().upgradeSawAddress = _upgradeSaw;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./AccessControlLib.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract AccessControlFacet is Context {
    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return AccessControlLib.accessControlStorage()._owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual {
        AccessControlLib._enforceOwner();
        AccessControlLib._transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual {
        AccessControlLib._enforceOwner();
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        AccessControlLib._transferOwnership(newOwner);
    }

    function setAdmin(address _admin, bool isAdmin) public virtual {
        AccessControlLib._enforceOwner();
        AccessControlLib.accessControlStorage()._admins[_admin] = isAdmin;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AccessControlLib.sol";

abstract contract AccessControlModifiers {
    modifier onlyAdmin() {
        AccessControlLib._enforceAdmin();
        _;
    }

    modifier onlyOwner() {
        AccessControlLib._enforceOwner();
        _;
    }
}

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/utils/Strings.sol";

pragma solidity ^0.8.0;

library AccessControlLib {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    struct AccessControlStorage {
        address _owner;
        mapping(address => bool) _admins;
    }

    bytes32 constant ACCESS_CONTROL_STORAGE_POSITION = keccak256("Access.Control.library.storage");

    function accessControlStorage() internal pure returns (AccessControlStorage storage s) {
        bytes32 position = ACCESS_CONTROL_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    function _isOwner() internal view returns (bool) {
        return accessControlStorage()._owner == msg.sender;
    }

    function owner() internal view returns (address) {
        return accessControlStorage()._owner;
    }

    function _enforceOwner() internal view {
        require(_isOwner(), "Caller is not the owner");
    }

    function _isAdmin() internal view returns (bool) {
        return accessControlStorage()._admins[msg.sender];
    }

    function _enforceAdmin() internal view {
        require(_isAdmin() || _isOwner(), "Is not admin or owner");
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal {
        address oldOwner = accessControlStorage()._owner;
        accessControlStorage()._owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

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