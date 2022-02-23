// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Market {
    using SafeMath for uint256;

    address public feeCollector;

    struct Listing {
        // Listing ID
        bytes32 listinId;
        // Owner of the NFT
        address sellerAddress;
        // NFT registry address
        address contractAddress;
        // Price in wei
        uint256 priceInWei;
        // Time when the sale ends
        uint256 expiresAt;
    }

    // mapping of token listings mapped by collection address and token ID
    mapping(address => mapping(uint256 => Listing))
        public listingByCollectionAndTokenId;

    // EVENTS
    event ListingCreated(
        bytes32 listinId,
        uint256 indexed tokenId,
        address indexed seller,
        address contractAddress,
        uint256 priceInWei,
        uint256 expiresAt
    );
    event ListingSuccessful(
        bytes32 listinId,
        uint256 indexed tokenId,
        address indexed seller,
        address contractAddress,
        uint256 totalPrice,
        address indexed buyer
    );
    event ListingCancelled(
        bytes32 listinId,
        uint256 indexed tokenId,
        address indexed seller,
        address contractAddress
    );

    /**
     * @dev Initialize this contract, setting fee collector
     * to the address who created the contract.
     */
    constructor() {
        feeCollector = msg.sender;
    }

    /**
     * @dev Creates a new listing
     * @param contractAddress - Non fungible registry address
     * @param tokenId - ID of the published NFT
     * @param priceInWei - Price in Wei for the supported coin
     * @param expiresAt - Duration of the listing (in hours)
     */
    function createListing(
        address contractAddress,
        uint256 tokenId,
        uint256 priceInWei,
        uint256 expiresAt
    ) external {
        require(priceInWei > 0, "Price should be bigger than 0 wei.");

        require(
            block.timestamp + expiresAt * 1 hours >= block.timestamp + 1 hours,
            "Expires must be longer than 1 hour in the future."
        );

        require(
            block.timestamp + expiresAt * 1 hours <= block.timestamp + 30 days,
            "Expires must be less than 30 days in the future."
        );

        IERC721 collection = IERC721(contractAddress);
        address tokenOwner = collection.ownerOf(tokenId);

        require(
            msg.sender == tokenOwner,
            "You must be the owner of the token."
        );

        require(
            collection.getApproved(tokenId) == address(this) ||
                collection.isApprovedForAll(tokenOwner, address(this)),
            "The contract is not authorized to manage the token"
        );

        bytes32 orderId = keccak256(
            abi.encodePacked(
                block.timestamp,
                tokenOwner,
                tokenId,
                contractAddress,
                priceInWei
            )
        );

        listingByCollectionAndTokenId[contractAddress][tokenId] = Listing({
            listinId: orderId,
            sellerAddress: tokenOwner,
            contractAddress: contractAddress,
            priceInWei: priceInWei,
            expiresAt: block.timestamp + expiresAt * 1 hours
        });

        emit ListingCreated(
            orderId,
            tokenId,
            tokenOwner,
            contractAddress,
            priceInWei,
            expiresAt
        );
    }

    /**
     * @dev Cancel an already published listing, can only be canceled by seller
     * @param contractAddress - Address of the NFT contract
     * @param tokenId - ID of the published NFT
     */
    function cancelListing(address contractAddress, uint256 tokenId) external {
        Listing memory listing = listingByCollectionAndTokenId[contractAddress][
            tokenId
        ];
        require(listing.listinId != 0, "INVALID_LISTING");
        require(listing.sellerAddress == msg.sender, "UNAUTHORIZED_USER");

        bytes32 listingId = listing.listinId;
        address listingSeller = listing.sellerAddress;
        address listingNftAddress = listing.contractAddress;
        delete listingByCollectionAndTokenId[contractAddress][tokenId];

        emit ListingCancelled(
            listingId,
            tokenId,
            listingSeller,
            listingNftAddress
        );
    }

    /**
     * @dev Purchase a listing
     * @param contractAddress - Address of the NFT contract
     * @param tokenId - ID of the published NFT
     */
    function purchaseListing(address contractAddress, uint256 tokenId)
        external
        payable
    {
        IERC721 collection = IERC721(contractAddress);

        address sender = msg.sender;

        Listing memory listing = listingByCollectionAndTokenId[contractAddress][
            tokenId
        ];

        require(listing.listinId != 0, "ASSET_NOT_FOR_SALE");

        require(listing.priceInWei == msg.value, "PRICE_MISMATCH");
        require(block.timestamp < listing.expiresAt, "ORDER_EXPIRED");
        require(
            listing.sellerAddress == collection.ownerOf(tokenId),
            "SELLER_NOT_OWNER"
        );

        delete listingByCollectionAndTokenId[contractAddress][tokenId];

        uint256 feeAmount = msg
            .value
            .mul(1_000_000 * 0.01)
            .div(1_000_000);

        uint256 listingPriceMinusFees = msg.value - feeAmount;

        payable(listing.sellerAddress).transfer(listingPriceMinusFees);
        collection.safeTransferFrom(listing.sellerAddress, sender, tokenId);

        emit ListingSuccessful(
            listing.listinId,
            tokenId,
            listing.sellerAddress,
            contractAddress,
            listing.priceInWei,
            sender
        );
    }

    /**
     * @dev Withdraws any fees collected from the contract
     */
    function withdraw() external returns (bool) {
        require(address(this).balance > 0, "EMPTY_FEE_BALANCE");
        payable(feeCollector).transfer(address(this).balance);
        return true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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