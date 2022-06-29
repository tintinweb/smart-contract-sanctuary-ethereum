// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./interfaces/IMarket.sol";
import "./abstract/Base.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Market is IMarket, ReentrancyGuard, Base {
    /// @dev Listing information for each nft token
    /// NFT Address -> TokenId -> Listing
    mapping(IERC721 => mapping(uint256 => Listing)) internal s_listings;

    /// @dev Store the cumulative amount of ETH owed to each seller
    /// Seller Address -> Amount of ETH owed
    mapping(address => uint256) internal s_owedProceeds;

    /* -------------------------------- Modifiers ------------------------------- */
    /// @dev Checks whether the Market is approved to transfer the NFT.
    modifier isApproved(IERC721 _nft, uint256 _tokenId) {
        if (_nft.getApproved(_tokenId) != address(this))
            revert NotApproved(address(_nft), _tokenId);
        _;
    }

    modifier isListed(IERC721 _nft, uint256 _tokenId) {
        if (s_listings[_nft][_tokenId].price == 0)
            revert NotListed(address(_nft), _tokenId);

        _;
    }

    modifier isNotListed(IERC721 _nft, uint256 _tokenId) {
        if (s_listings[_nft][_tokenId].price > 0)
            revert AlreadyListed(address(_nft), _tokenId);

        _;
    }

    modifier isOwner(
        IERC721 _nft,
        uint256 _tokenId,
        address _sender
    ) {
        if (_nft.ownerOf(_tokenId) != _sender)
            revert NotOwner(address(_nft), _tokenId);
        _;
    }

    /* -------------------------------- Functions ------------------------------- */
    /// @inheritdoc IMarket
    function listItem(
        IERC721 _nft,
        uint256 _tokenId,
        uint256 _price
    )
        external
        override
        checkNonZeroAddress(address(_nft))
        checkNonZeroValue(_price)
        isApproved(_nft, _tokenId)
        isNotListed(_nft, _tokenId)
        isOwner(_nft, _tokenId, msg.sender)
    {
        s_listings[_nft][_tokenId] = Listing(msg.sender, _price);

        emit ListedItem(msg.sender, _nft, _tokenId, _price);
    }

    /// @inheritdoc IMarket
    function buyItem(IERC721 _nft, uint256 _tokenId)
        external
        payable
        override
        nonReentrant
        checkNonZeroAddress(address(_nft))
        isListed(_nft, _tokenId)
    {
        Listing memory listing = s_listings[_nft][_tokenId];
        // Check that the correct amount of ETH was paid
        if (msg.value != listing.price) revert InvalidAmountPayed(msg.value);

        // Clear the listing
        delete s_listings[_nft][_tokenId];

        // Transfer the NFT to the buyer
        _nft.safeTransferFrom(listing.owner, msg.sender, _tokenId);

        // Add the amount of ETH owed to the seller
        s_owedProceeds[listing.owner] += listing.price;

        emit BoughtItem(
            msg.sender,
            listing.owner,
            _nft,
            _tokenId,
            listing.price
        );
    }

    /// @inheritdoc IMarket
    function withdrawItem(IERC721 _nft, uint256 _tokenId)
        external
        override
        checkNonZeroAddress(address(_nft))
        isOwner(_nft, _tokenId, msg.sender)
        isListed(_nft, _tokenId)
    {
        // Clear the listing
        delete s_listings[_nft][_tokenId];

        emit WithdrawnItem(_nft, _tokenId);
    }

    /// @inheritdoc IMarket
    function updateItem(
        IERC721 _nft,
        uint256 _tokenId,
        uint256 _newPrice
    )
        external
        override
        checkNonZeroAddress(address(_nft))
        isOwner(_nft, _tokenId, msg.sender)
        isListed(_nft, _tokenId)
    {
        // Update the listing price
        s_listings[_nft][_tokenId].price = _newPrice;

        emit UpdatedItem(msg.sender, _nft, _tokenId, _newPrice);
    }

    /// @inheritdoc IMarket
    function claimProceeds() external override nonReentrant {
        uint256 proceeds = s_owedProceeds[msg.sender];
        // Check that there's something to claim
        if (proceeds == 0) revert NoProceedsToClaim();

        // Check that the payment can be done. (Critical Failure if not)
        if (address(this).balance < proceeds) revert NotEnoughBalance();

        s_owedProceeds[msg.sender] = 0;

        // Transfer the ETH owed to the sender
        (bool success, ) = address(msg.sender).call{value: proceeds}("");

        if (!success) revert TransferFailed();

        emit ClaimedProceeds(msg.sender, proceeds);
    }

    /* ---------------------------------- Views --------------------------------- */
    function getListing(IERC721 _nft, uint256 _tokenId)
        external
        view
        override
        returns (Listing memory)
    {
        return s_listings[_nft][_tokenId];
    }

    function getOwedProceeds(address _seller)
        external
        view
        override
        returns (uint256)
    {
        return s_owedProceeds[_seller];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/interfaces/IERC721.sol";

interface IMarket {
    struct Listing {
        address owner;
        uint256 price;
    }

    /* --------------------------------- Errors --------------------------------- */
    error NotApproved(address nft, uint256 tokenId);

    error NotListed(address nft, uint256 tokenId);

    error AlreadyListed(address nft, uint256 tokenId);

    error NotOwner(address nft, uint256 tokenId);

    error InvalidAmountPayed(uint256 price);

    error NoProceedsToClaim();

    error NotEnoughContractBalance();

    /* --------------------------------- Events --------------------------------- */

    event ListedItem(
        address indexed owner,
        IERC721 indexed nft,
        uint256 indexed tokenId,
        uint256 price
    );

    event BoughtItem(
        address indexed buyer,
        address seller,
        IERC721 indexed nft,
        uint256 indexed tokenId,
        uint256 price
    );

    event WithdrawnItem(IERC721 indexed nft, uint256 indexed tokenId);

    event UpdatedItem(
        address indexed owner,
        IERC721 indexed nft,
        uint256 indexed tokenId,
        uint256 newPrice
    );

    event ClaimedProceeds(address indexed owner, uint256 indexed amount);

    /* -------------------------------- Functions ------------------------------- */

    /// @notice Lists an item on the marketplace.
    /// @dev The submitted NFT is approved for the contract to transfer it when the listing is confirmed.
    /// @param nft Address of the NFT contract.
    /// @param tokenId NFT token ID.
    /// @param price Price of the item.
    function listItem(
        IERC721 nft,
        uint256 tokenId,
        uint256 price
    ) external;

    /// @notice Buys a listed item on the marketplace.
    /// @dev The buyer is charged the price of the item.
    /// @param nft Address of the NFT contract.
    /// @param tokenId NFT token ID.
    function buyItem(IERC721 nft, uint256 tokenId) external payable;

    /// @notice Cancels a listing on the marketplace.
    /// @param nft Address of the NFT contract.
    /// @param tokenId NFT token ID.
    function withdrawItem(IERC721 nft, uint256 tokenId) external;

    //7 @notice Updates the price of a listing on the marketplace.
    /// @param nft Address of the NFT contract.
    /// @param tokenId NFT token ID.
    /// @param newPrice New price of the item.
    function updateItem(
        IERC721 nft,
        uint256 tokenId,
        uint256 newPrice
    ) external;

    function claimProceeds() external;

    /* ---------------------------------- View ---------------------------------- */
    function getListing(IERC721 _nft, uint256 _tokenId)
        external
        view
        returns (Listing memory);

    function getOwedProceeds(address seller) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../error/Errors.sol";

/// @title Base
/// @author @C-Mierez
/// @notice Base contract that defines commonly used modifiers for other contracts
/// to inherit.
abstract contract Base {
    /* -------------------------------- Modifiers ------------------------------- */
    modifier checkNonZeroAddress(address addr) {
        if (addr == address(0)) revert ZeroAddress();
        _;
    }

    modifier checkNonZeroValue(uint256 value) {
        if (value == 0) revert ZeroValue();
        _;
    }

    modifier checkExpectedCaller(address caller, address expected) {
        if (caller != expected) revert UnexpectedCaller(caller, expected);
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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

pragma solidity ^0.8.4;

/* -------------------------- Global Custom Errors -------------------------- */

/// @notice Emitted when the submitted address is the zero address
error ZeroAddress();

/// @notice Emitted when the submitted value is zero.
error ZeroValue();

/// @notice Emitted when the submitted value is zero or less
/// @dev Technically uint can't be negative, so it wouldn't make
/// sense for this error to happen when [value] is an uint.
/// Hence I'm defining it as an int256 instead.
error ZeroOrNegativeValue(int256 value);

/// @notice Emitted when the caller is not the expected address
error UnexpectedCaller(address caller, address expected);

/// @notice Emitted when the caller does not have the required permissions
error UnauthorizedCaller(address caller);

/// @notice Emitted when the address does not have enough balance
error NotEnoughBalance();

error TransferFailed();

/* ---------------------------- ERC Token Errors ---------------------------- */

/// @notice Emitted when an ERC20 transfer fails. Catching boolean return from
/// the transfer methods.
/// @dev I believe it makes sense to return all the information below, since this
/// error just catches any kind of failure. It'd likely be useful to have this
/// information to understand what exactly went wrong.
error ERC20TransferFailed(address from, address to, uint256 amount);