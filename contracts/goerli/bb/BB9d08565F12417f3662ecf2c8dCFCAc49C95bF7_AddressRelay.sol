// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IAddressRelay, Implementation} from "./interfaces/IAddressRelay.sol";
import {IERC165} from "./interfaces/IERC165.sol";
import {IERC173} from "./interfaces/IERC173.sol";

/**
 * @author Created by HeyMint Launchpad https://join.heymint.xyz
 * @notice This contract contains the base logic for ERC-721A tokens deployed with HeyMint
 */
contract AddressRelay is IAddressRelay, Ownable {
    mapping(bytes4 => address) public selectorToImplAddress;
    mapping(bytes4 => bool) public supportedInterfaces;
    bytes4[] selectors;
    address[] implAddresses;
    address public fallbackImplAddress;
    bool public relayFrozen;

    constructor() {
        supportedInterfaces[0x01ffc9a7] = true; // IERC165
        supportedInterfaces[0x7f5828d0] = true; // IERC173
        supportedInterfaces[0xd9b67a26] = true; // ERC-1155
        supportedInterfaces[0x0e89341c] = true; // ERC1155MetadataURI
        supportedInterfaces[0x2a55205a] = true; // IERC2981
    }

    /**
     * @notice Permanently freezes the relay so no more selectors can be added or removed
     */
    function freezeRelay() external onlyOwner {
        relayFrozen = true;
    }

    /**
     * @notice Adds or updates selectors and their implementation addresses
     * @param _selectors The selectors to add or update
     * @param _implAddress The implementation address the selectors will point to
     */
    function addOrUpdateSelectors(
        bytes4[] memory _selectors,
        address _implAddress
    ) external onlyOwner {
        require(!relayFrozen, "RELAY_FROZEN");
        for (uint256 i = 0; i < _selectors.length; i++) {
            bytes4 selector = _selectors[i];
            selectorToImplAddress[selector] = _implAddress;
            selectors.push(selector);
        }
        bool implAddressExists = false;
        for (uint256 i = 0; i < implAddresses.length; i++) {
            if (implAddresses[i] == _implAddress) {
                implAddressExists = true;
                break;
            }
        }
        if (!implAddressExists) {
            implAddresses.push(_implAddress);
        }
    }

    /**
     * @notice Removes selectors
     * @param _selectors The selectors to remove
     */
    function removeSelectors(bytes4[] memory _selectors) external onlyOwner {
        require(!relayFrozen, "RELAY_FROZEN");
        for (uint256 i = 0; i < _selectors.length; i++) {
            bytes4 selector = _selectors[i];
            delete selectorToImplAddress[selector];
            for (uint256 j = 0; j < selectors.length; j++) {
                if (selectors[j] == selector) {
                    // this just sets the value to 0, but doesn't remove it from the array
                    delete selectors[j];
                    break;
                }
            }
        }
    }

    /**
     * @notice Removes an implementation address and all the selectors that point to it
     * @param _implAddress The implementation address to remove
     */
    function removeImplAddressAndAllSelectors(
        address _implAddress
    ) external onlyOwner {
        require(!relayFrozen, "RELAY_FROZEN");
        for (uint256 i = 0; i < implAddresses.length; i++) {
            if (implAddresses[i] == _implAddress) {
                // this just sets the value to 0, but doesn't remove it from the array
                delete implAddresses[i];
                break;
            }
        }
        for (uint256 i = 0; i < selectors.length; i++) {
            if (selectorToImplAddress[selectors[i]] == _implAddress) {
                delete selectorToImplAddress[selectors[i]];
                delete selectors[i];
            }
        }
    }

    /**
     * @notice Returns the implementation address for a given function selector
     * @param _functionSelector The function selector to get the implementation address for
     */
    function getImplAddress(
        bytes4 _functionSelector
    ) external view returns (address) {
        address implAddress = selectorToImplAddress[_functionSelector];
        if (implAddress == address(0)) {
            implAddress = fallbackImplAddress;
        }
        require(implAddress != address(0), "Function does not exist");
        return implAddress;
    }

    /**
     * @notice Returns the implementation address for a given function selector. Throws an error if function does not exist.
     * @param _functionSelector The function selector to get the implementation address for
     */
    function getImplAddressNoFallback(
        bytes4 _functionSelector
    ) external view returns (address) {
        address implAddress = selectorToImplAddress[_functionSelector];
        require(implAddress != address(0), "Function does not exist");
        return implAddress;
    }

    /**
     * @notice Returns all the implementation addresses and the selectors they support
     * @return impls_ An array of Implementation structs
     */
    function getAllImplAddressesAndSelectors()
        external
        view
        returns (Implementation[] memory)
    {
        uint256 trueImplAddressCount = 0;
        uint256 implAddressesLength = implAddresses.length;
        for (uint256 i = 0; i < implAddressesLength; i++) {
            if (implAddresses[i] != address(0)) {
                trueImplAddressCount++;
            }
        }
        Implementation[] memory impls = new Implementation[](
            trueImplAddressCount
        );
        for (uint256 i = 0; i < implAddressesLength; i++) {
            if (implAddresses[i] == address(0)) {
                continue;
            }
            address implAddress = implAddresses[i];
            bytes4[] memory selectors_;
            uint256 selectorCount = 0;
            uint256 selectorsLength = selectors.length;
            for (uint256 j = 0; j < selectorsLength; j++) {
                if (selectorToImplAddress[selectors[j]] == implAddress) {
                    selectorCount++;
                }
            }
            selectors_ = new bytes4[](selectorCount);
            uint256 selectorIndex = 0;
            for (uint256 j = 0; j < selectorsLength; j++) {
                if (selectorToImplAddress[selectors[j]] == implAddress) {
                    selectors_[selectorIndex] = selectors[j];
                    selectorIndex++;
                }
            }
            impls[i] = Implementation(implAddress, selectors_);
        }
        return impls;
    }

    /**
     * @notice Return all the function selectors associated with an implementation address
     * @param _implAddress The implementation address to get the selectors for
     */
    function getSelectorsForImplAddress(
        address _implAddress
    ) external view returns (bytes4[] memory) {
        uint256 selectorCount = 0;
        uint256 selectorsLength = selectors.length;
        for (uint256 i = 0; i < selectorsLength; i++) {
            if (selectorToImplAddress[selectors[i]] == _implAddress) {
                selectorCount++;
            }
        }
        bytes4[] memory selectorArr = new bytes4[](selectorCount);
        uint256 selectorIndex = 0;
        for (uint256 i = 0; i < selectorsLength; i++) {
            if (selectorToImplAddress[selectors[i]] == _implAddress) {
                selectorArr[selectorIndex] = selectors[i];
                selectorIndex++;
            }
        }
        return selectorArr;
    }

    /**
     * @notice Sets the fallback implementation address to use when a function selector is not found
     * @param _fallbackAddress The fallback implementation address
     */
    function setFallbackImplAddress(
        address _fallbackAddress
    ) external onlyOwner {
        require(!relayFrozen, "RELAY_FROZEN");
        fallbackImplAddress = _fallbackAddress;
    }

    /**
     * @notice Updates the supported interfaces
     * @param _interfaceId The interface ID to update
     * @param _supported Whether the interface is supported or not
     */
    function updateSupportedInterfaces(
        bytes4 _interfaceId,
        bool _supported
    ) external onlyOwner {
        supportedInterfaces[_interfaceId] = _supported;
    }

    /**
     * @notice Returns whether the interface is supported or not
     * @param _interfaceId The interface ID to check
     */
    function supportsInterface(
        bytes4 _interfaceId
    ) external view returns (bool) {
        return supportedInterfaces[_interfaceId];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
pragma solidity ^0.8.18;

struct Implementation {
    address implAddress;
    bytes4[] selectors;
}

interface IAddressRelay {
    /**
     * @notice Returns the fallback implementation address
     */
    function fallbackImplAddress() external returns (address);

    /**
     * @notice Adds or updates selectors and their implementation addresses
     * @param _selectors The selectors to add or update
     * @param _implAddress The implementation address the selectors will point to
     */
    function addOrUpdateSelectors(
        bytes4[] memory _selectors,
        address _implAddress
    ) external;

    /**
     * @notice Removes selectors
     * @param _selectors The selectors to remove
     */
    function removeSelectors(bytes4[] memory _selectors) external;

    /**
     * @notice Removes an implementation address and all the selectors that point to it
     * @param _implAddress The implementation address to remove
     */
    function removeImplAddressAndAllSelectors(address _implAddress) external;

    /**
     * @notice Returns the implementation address for a given function selector
     * @param _functionSelector The function selector to get the implementation address for
     */
    function getImplAddress(
        bytes4 _functionSelector
    ) external view returns (address implAddress_);

    /**
     * @notice Returns all the implementation addresses and the selectors they support
     * @return impls_ An array of Implementation structs
     */
    function getAllImplAddressesAndSelectors()
        external
        view
        returns (Implementation[] memory impls_);

    /**
     * @notice Return all the fucntion selectors associated with an implementation address
     * @param _implAddress The implementation address to get the selectors for
     */
    function getSelectorsForImplAddress(
        address _implAddress
    ) external view returns (bytes4[] memory selectors_);

    /**
     * @notice Sets the fallback implementation address to use when a function selector is not found
     * @param _fallbackAddress The fallback implementation address
     */
    function setFallbackImplAddress(address _fallbackAddress) external;

    /**
     * @notice Updates the supported interfaces
     * @param _interfaceId The interface ID to update
     * @param _supported Whether the interface is supported or not
     */
    function updateSupportedInterfaces(
        bytes4 _interfaceId,
        bool _supported
    ) external;

    /**
     * @notice Returns whether the interface is supported or not
     * @param _interfaceId The interface ID to check
     */
    function supportsInterface(
        bytes4 _interfaceId
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
interface IERC173 {
    /// @dev This emits when ownership of a contract changes.
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /// @notice Get the address of the owner
    /// @return owner_ The address of the owner.
    function owner() external view returns (address owner_);

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}