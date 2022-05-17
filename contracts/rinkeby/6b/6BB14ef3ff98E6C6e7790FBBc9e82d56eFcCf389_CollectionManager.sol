// SPDX-License-Identifier: CC-BY-NC-ND
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../ICollectionManager.sol";
import "../IRoleManager.sol";

// @title CollectionManager hold all collection that is allowed to list and have a transaction in the Exchange.
contract CollectionManager is ICollectionManager, Ownable {
    address[] private allowedCollectionsArray;
    mapping(address => bool) private allowedCollectionsMap;

    IRoleManager public adminRoleManager;

    event AddAllowedCollection(
        address indexed account,
        address indexed allowedCollection
    );

    event RemoveCollection(
        address indexed account,
        address indexed allowedCollection
    );

    event UpdateAdminRoleManager(
        address indexed account,
        address indexed adminRoleManager
    );

    constructor(address _adminRoleManager) {
        adminRoleManager = IRoleManager(_adminRoleManager);
    }

    modifier hasAdminAccess() {
        require(adminRoleManager.hasAccess(address(this), msg.sig, _msgSender()), "Authorization: Forbidden");
        _;
    }

    function updateAdminRoleManager(address _adminRoleManager) external onlyOwner {
        adminRoleManager = IRoleManager(_adminRoleManager);

        emit UpdateAdminRoleManager(_msgSender(), _adminRoleManager);
    }

    function collectionIsAllowed(address collectionAddress) external view override returns(bool) {
        return allowedCollectionsMap[collectionAddress];
    }

    function getAllAllowedCollections() external view returns(address[] memory) {
        return allowedCollectionsArray;
    }

    function addAllowedCollection(address collectionAddress) external hasAdminAccess {
        // If it is already allowed, just return true
        if (allowedCollectionsMap[collectionAddress]) {
            return;
        }
        // Allowing collections
        allowedCollectionsMap[collectionAddress] = true;
        allowedCollectionsArray.push(collectionAddress);

        emit AddAllowedCollection(_msgSender(), collectionAddress);
    }

    function removeCollection(address collectionAddress) external hasAdminAccess {
        // Remove collection from allowed collections map
        delete(allowedCollectionsMap[collectionAddress]);

        // Loop through allowedCollectionsArray and remove the collections from list.
        for (uint i = 0; i < allowedCollectionsArray.length; i++){
            if (allowedCollectionsArray[i] == collectionAddress) {
                allowedCollectionsArray[i] = allowedCollectionsArray[allowedCollectionsArray.length - 1];
                delete(allowedCollectionsArray[allowedCollectionsArray.length - 1]);
            }
        }

        emit RemoveCollection(_msgSender(), collectionAddress);
    }
}

// SPDX-License-Identifier: CC-BY-NC-ND
pragma solidity ^0.8.7;

interface IRoleManager {
    function hasAccess(address contractAddress, bytes4 functionSignature, address account) external returns(bool);
}

// SPDX-License-Identifier: CC-BY-NC-ND
pragma solidity ^0.8.7;

import "../libraries/OrderTypes.sol";

interface ICollectionManager {
    function collectionIsAllowed(address collectionAddress) external returns(bool);
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

// SPDX-License-Identifier: CC-BY-NC-ND
pragma solidity ^0.8.7;

library OrderTypes {
    // keccak256("MakerOrder(address signer, bool listingOrder, uint256 nonce, address collectionAddress,
    // uint256 tokenID, uint256 amount, uint256 price, address currencyAddress, address matcherAddress,
    // uint256 startedAt, uint256 expiredAt, uint256 minSellerReceived, bytes params)")
    bytes32 internal constant MAKER_ORDER_HASH = 0xead6d6e109168364d2f3ba52a2e2cb50e1eb1ebcbe5c3ab0edc15a1f1445173a;

    struct MakerOrder {
        address signer;
        bool listingOrder;
        uint256 nonce;
        address collectionAddress;
        uint256 tokenID;
        uint256 amount;
        uint256 chainID;
        uint256 price;
        address currencyAddress;
        address matcherAddress;
        uint256 startedAt;
        uint256 expiredAt;
        uint256 minSellerReceived;
        bytes params;
        bytes signature;
    }

    struct TakerOrder {
        address taker;
        bool buyingOrder;
        address collectionAddress;
        uint256 tokenID;
        uint256 amount;
        uint256 chainID;
        uint256 price;
        address currencyAddress;
        uint256 minSellerReceived;
    }

    function hash(MakerOrder memory makerOrder) internal pure returns (bytes32) {
        return
        keccak256(
            abi.encode(
                MAKER_ORDER_HASH,
                makerOrder.signer,
                makerOrder.listingOrder,
                makerOrder.nonce,
                makerOrder.collectionAddress,
                makerOrder.tokenID,
                makerOrder.amount,
                makerOrder.price,
                makerOrder.currencyAddress,
                makerOrder.matcherAddress,
                makerOrder.startedAt,
                makerOrder.expiredAt,
                makerOrder.minSellerReceived,
                keccak256(makerOrder.params)
            )
        );
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