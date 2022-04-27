// SPDX-License-Identifier: CC-BY-NC-ND
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";

import "./IRoyaltyFeeSetter.sol";
import "./IRoyaltyRegistry.sol";
import "../IRoleManager.sol";
import "../libraries/IOwnable.sol";


contract RoyaltyFeeSetter is IRoyaltyFeeSetter, Ownable {
    // ERC721 interfaceID
    bytes4 public constant INTERFACE_ID_ERC721 = 0x80ac58cd;

    // ERC1155 interfaceID
    bytes4 public constant INTERFACE_ID_ERC1155 = 0xd9b67a26;

    // ERC2981 interfaceID
    bytes4 public constant INTERFACE_ID_ERC2981 = 0x2a55205a;

    IRoleManager private adminRoleManger;
    address public immutable royaltyRegistry;

    constructor(address _royaltyRegistry, address _adminRoleManger) {
        adminRoleManger = IRoleManager(_adminRoleManger);
        royaltyRegistry = _royaltyRegistry;
    }

    // Collections must not be ERC2981 since they already have their own royalty management.
    // Collections must be an NFT collections, so it must be either ERC 721 or ERC 1155.
    modifier royaltyRegistryable(address collectionAddress) {
        require(!IERC165(collectionAddress).supportsInterface(INTERFACE_ID_ERC2981), "Collection: Must not be ERC2981");
        require(
            IERC165(collectionAddress).supportsInterface(INTERFACE_ID_ERC721) ||
            IERC165(collectionAddress).supportsInterface(INTERFACE_ID_ERC1155),
            "Collection: Must be an NFT Collection"
        );
        _;
    }

    // checking admin access using adminRoleManager.
    modifier hasAdminAccess() {
        require(adminRoleManger.hasAccess(address(this), msg.sig, _msgSender()), "Authorization: Forbidden");
        _;
    }

    // Since we will set Royalty Registry to mostly accessible by onlyOwner
    // We have to make sure that the ownership of Registry is transferable
    function updateOwnerOfRoyaltyRegistry(address _owner) external override onlyOwner {
        IOwnable(royaltyRegistry).transferOwnership(_owner);
    }

    // This function is the user facing endpoint to set RoyaltyFeeLimit on RoyaltyRegistry.
    function updateRoyaltyFeeLimit(uint256 newLimit) external override hasAdminAccess {
        IRoyaltyRegistry(royaltyRegistry).updateRoyaltyFeeLimit(newLimit);
    }

    // Admin with the right role will be able to change collections royalty
    // Admin role will be checked using adminRoleManager that holds all admin role centrally.
    function adminUpdateCollectionRoyaltyInfo(
        address collectionAddress,
        uint256 feePercentage,
        address feeTreasury
    ) external override hasAdminAccess royaltyRegistryable(collectionAddress) {
        IRoyaltyRegistry(royaltyRegistry).updateCollectionRoyaltyInfo(collectionAddress, feePercentage, feeTreasury);
    }

    // Only Owner of the collection that can change their Royalty Info.
    // Collection must implement ownable so that we can check the owner of the contract.
    function ownerUpdateCollectionRoyaltyInfo(
        address collectionAddress,
        uint256 feePercentage,
        address feeTreasury
    ) external override royaltyRegistryable(collectionAddress) {
        require(
            IOwnable(collectionAddress).owner() == _msgSender(),
            "Authorization: Sender Must be Collection Owner"
        );
        IRoyaltyRegistry(royaltyRegistry).updateCollectionRoyaltyInfo(collectionAddress, feePercentage, feeTreasury);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOwnable {
    function transferOwnership(address newOwner) external;

    function owner() external view returns (address);
}

// SPDX-License-Identifier: CC-BY-NC-ND
pragma solidity ^0.8.7;

interface IRoleManager {
    function hasAccess(address contractAddress, bytes4 functionSignature, address account) external returns(bool);
}

// SPDX-License-Identifier: CC-BY-NC-ND
pragma solidity ^0.8.7;

interface IRoyaltyRegistry {
    function getRoyaltyFeeLimit() external view returns(uint256);

    function updateCollectionRoyaltyInfo(
        address collectionAddress,
        uint256 feePercentage,
        address feeTreasury
    ) external;

    function updateRoyaltyFeeLimit(uint256 newLimit) external;

    function getRoyaltyFeeAndInfo(
        address collectionAddress,
        uint256 transactionAmount
    ) external view returns(address, uint256);

    function getRoyaltyInfo(
        address collectionAddress
    ) external view returns(address, uint256);
}

// SPDX-License-Identifier: CC-BY-NC-ND
pragma solidity ^0.8.7;

interface IRoyaltyFeeSetter {
    function updateOwnerOfRoyaltyRegistry(address _owner) external;
    function updateRoyaltyFeeLimit(uint256 newLimit) external;

    function adminUpdateCollectionRoyaltyInfo(
        address collectionAddress,
        uint256 feePercentage,
        address feeTreasury
    ) external;

    function ownerUpdateCollectionRoyaltyInfo(
        address collectionAddress,
        uint256 feePercentage,
        address feeTreasury
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

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