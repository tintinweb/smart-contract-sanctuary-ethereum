// SPDX-License-Identifier: CC-BY-NC-ND
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

import "../IRoyaltyFeeManager.sol";
import "./IRoyaltyRegistry.sol";
import "../libraries/OrderTypes.sol";

contract RoyaltyFeeManager is IRoyaltyFeeManager, Ownable {
    // https://eips.ethereum.org/EIPS/eip-2981
    bytes4 public constant INTERFACE_ID_ERC2981 = 0x2a55205a;

    IRoyaltyRegistry public immutable royaltyRegistry;

    constructor(address _royaltyRegistry) {
        royaltyRegistry = IRoyaltyRegistry(_royaltyRegistry);
    }

    function getOrderRoyaltyFeeDetails(
        OrderTypes.MakerOrder calldata makerOrder
    ) external view override returns(address, uint256) {
        (address collectionTreasuryAddress, uint256 fee) = royaltyRegistry.getRoyaltyFeeAndInfo(
            makerOrder.collectionAddress,
            makerOrder.price
        );

        // If collections implement ERC 2981, use their royalty
        if(collectionTreasuryAddress == address(0) || fee == 0 ) {
            if (IERC165(makerOrder.collectionAddress).supportsInterface(INTERFACE_ID_ERC2981)) {
                (collectionTreasuryAddress, fee) = IERC2981(makerOrder.collectionAddress).royaltyInfo(
                    makerOrder.tokenID,
                    makerOrder.price
                );
            }
        }

        return (collectionTreasuryAddress, fee);
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

    function updatePlatformFeeRegistry(address _platformFeeRegistry) external;
    
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

import "./libraries/OrderTypes.sol";

interface IRoyaltyFeeManager {
    function getOrderRoyaltyFeeDetails(
        OrderTypes.MakerOrder calldata makerOrder
    ) external returns(address collectionTreasuryAddress, uint256 fee);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
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