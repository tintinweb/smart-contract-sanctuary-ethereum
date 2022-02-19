//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Listing management for Behold The Ocean NFTs
/// @author Sam King (samking.eth)
/// @notice Allows the owner to list ERC721 tokens for sale after minting
contract BeholdTheOceanListings is Ownable {
    /**************************************************************************
     * STORAGE
     *************************************************************************/

    /// @notice The address of the contract with tokens e.g. Manifold
    address private tokenAddress;

    /// @notice The original minter of the tokens
    /// @dev Used in `safeTransferFrom` when a user purchases a token
    address private tokenOwnerAddress;

    /// @notice The address where purchase proceeds will be sent
    address payable private payoutAddress;

    /// @notice Status for listings
    /// @dev Payments revert for listings that are inactive or executed
    enum ListingStatus {
        ACTIVE,
        INACTIVE,
        EXECUTED
    }

    /// @notice Stores price and status for a listing
    struct Listing {
        uint256 price;
        ListingStatus status;
    }

    /// @notice Listing storgage by token id
    mapping(uint256 => Listing) public listings;

    /**************************************************************************
     * ERRORS
     *************************************************************************/

    error IncorrectPaymentAmount();
    error IncorrectConfiguration();
    error ListingExecuted();
    error ListingInactive();
    error PaymentFailed();

    /**************************************************************************
     * INIT
     *************************************************************************/

    /// @param _tokenAddress The address of the contract with tokens
    /// @param _tokenOwnerAddress The original minter of the tokens
    constructor(address _tokenAddress, address _tokenOwnerAddress) {
        tokenAddress = _tokenAddress;
        tokenOwnerAddress = _tokenOwnerAddress;
    }

    /**************************************************************************
     * ADMIN FUNCTIONALITY
     *************************************************************************/

    /// @notice Internal function to set listing values in storage
    /// @dev Reverts on listings that have already been executed
    /// @param tokenId The tokenId to set listing information for
    /// @param price The price to list the token at
    /// @param setActive If the listing should be set to active or not
    function _setListing(
        uint256 tokenId,
        uint256 price,
        bool setActive
    ) internal {
        Listing storage listing = listings[tokenId];
        if (listing.status == ListingStatus.EXECUTED) revert ListingExecuted();
        listing.price = price;
        listing.status = setActive
            ? ListingStatus.ACTIVE
            : ListingStatus.INACTIVE;
    }

    /// @notice Sets information about a listing
    /// @param tokenId The token id to set listing information for
    /// @param price The price to list the token id at
    /// @param setActive If the listing should be set to active or not
    function setListing(
        uint256 tokenId,
        uint256 price,
        bool setActive
    ) public onlyOwner {
        _setListing(tokenId, price, setActive);
    }

    /// @notice Sets information about multiple listings
    /// @dev tokenIds and prices should be the same length
    /// @param tokenIds An array of token ids to set listing information for
    /// @param prices An array of prices to list each token id at
    /// @param setActive If the listings should be set to active or not
    function setListingBatch(
        uint256[] memory tokenIds,
        uint256[] memory prices,
        bool setActive
    ) public onlyOwner {
        if (tokenIds.length != prices.length) {
            revert IncorrectConfiguration();
        }
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _setListing(tokenIds[i], prices[i], setActive);
        }
    }

    /// @notice Updates the price of a specific listing
    /// @param tokenId The token id to update the price for
    /// @param newPrice The new price to set
    function updateListingPrice(uint256 tokenId, uint256 newPrice)
        public
        onlyOwner
    {
        Listing storage listing = listings[tokenId];
        if (listing.status == ListingStatus.EXECUTED) revert ListingExecuted();
        listing.price = newPrice;
    }

    /// @notice Flips the listing state between ACTIVE and INACTIVE
    /// @dev Only flips between ACTIVE and INACTIVE. Reverts if EXECUTED
    /// @param tokenId The token id to update the listing status for
    function toggleListingStatus(uint256 tokenId) public onlyOwner {
        Listing storage listing = listings[tokenId];
        if (listing.status == ListingStatus.EXECUTED) revert ListingExecuted();
        listing.status = listing.status == ListingStatus.ACTIVE
            ? ListingStatus.INACTIVE
            : ListingStatus.ACTIVE;
    }

    /// @notice Updates the address that minted the original tokens
    /// @dev The address is used in the purchase flow to transfer tokens
    /// @param _tokenOwnerAddress The original minter of the tokens
    function setTokenOwnerAddress(address _tokenOwnerAddress) public onlyOwner {
        tokenOwnerAddress = _tokenOwnerAddress;
    }

    /// @notice Updates the address that receives sale proceeds
    /// @param _payoutAddress The address where sale proceeds should be paid to
    function setPayoutAddress(address _payoutAddress) public onlyOwner {
        payoutAddress = payable(_payoutAddress);
    }

    /**************************************************************************
     * PURCHASING
     *************************************************************************/

    /// @notice Allows someone to purchase a token
    /// @dev Accepts payment, checks if listing can be purchased,
    ///      transfers token to new owner and sends payment to payout address
    /// @param tokenId The token id to purchase
    function purchase(uint256 tokenId) public payable {
        Listing storage listing = listings[tokenId];

        // Check if the token can be purchased
        if (listing.status == ListingStatus.EXECUTED) revert ListingExecuted();
        if (listing.status == ListingStatus.INACTIVE) revert ListingInactive();
        if (msg.value != listing.price) revert IncorrectPaymentAmount();

        // Send the payment to the token contract
        (bool sent, ) = payoutAddress.call{value: msg.value}("");
        if (!sent) revert PaymentFailed();

        // Transfer the token from the owner to the buyer
        IERC721(tokenAddress).safeTransferFrom(
            tokenOwnerAddress,
            msg.sender,
            tokenId
        );

        // Set the listing to executed
        listing.status = ListingStatus.EXECUTED;
    }

    /**************************************************************************
     * GETTERS
     *************************************************************************/

    /// @notice Gets listing information for a token id
    /// @param tokenId The token id to get listing information for
    /// @return listing Listing information
    function getListing(uint256 tokenId)
        public
        view
        returns (Listing memory listing)
    {
        listing = listings[tokenId];
    }

    /// @notice Gets the listing price for a token id
    /// @param tokenId The token id to get the listing price for
    /// @return price Listing price
    function getListingPrice(uint256 tokenId)
        public
        view
        returns (uint256 price)
    {
        price = listings[tokenId].price;
    }

    /// @notice Gets the listing status for a token id
    /// @param tokenId The token id to get the listing status for
    /// @return status Listing status
    function getListingStatus(uint256 tokenId)
        public
        view
        returns (ListingStatus status)
    {
        status = listings[tokenId].status;
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