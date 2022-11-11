// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

error DiffusedMarketplace__TokenNotApprovedForMarketplace();
error DiffusedMarketplace__TokenAlreadyListed();
error DiffusedMarketplace__InsufficientPrice();
error DiffusedMarketplace__ItemNotListed();
error DiffusedMarketplace__NotOwner();
error DiffusedMarketplace__SellerNotOwner();
error DiffusedMarketplace__PriceNotMet();
error DiffusedMarketplace__NoProceeds();
error DiffusedMarketplace__WithdrawFailed();
error DiffusedMarketplace__NullishAddress();

/**
 * @title NFT marketplace of AI-generated images
 * @author Uladzimir Kireyeu
 * @notice It's connected to the only one contract address to prevent
 * flooding of the tokens
 * @dev You will have to deploy copy of this contract to
 * work with other nft contracts
 */
contract DiffusedMarketplace is ReentrancyGuard {
    struct Listing {
        address seller;
        uint256 price;
    }

    event ItemListed(
        uint256 indexed tokenId,
        address indexed seller,
        uint256 price
    );
    event ItemBought(
        uint256 indexed tokenId,
        address indexed buyer,
        uint256 price
    );
    event ItemRemoved(uint256 indexed tokenId, address indexed seller);

    mapping(uint256 => Listing) private s_listings;
    mapping(address => uint256) private s_proceeds;
    address private immutable i_nftAddress;

    constructor(address nftAddress) {
        // Check that contract address is not nullish
        if (nftAddress == address(0)) {
            revert DiffusedMarketplace__NullishAddress();
        }

        i_nftAddress = nftAddress;
    }

    /**
     * @notice Lists item to the marketplace, price is permanent
     * @dev Token must be approved to the contract in advance
     * @param tokenId Token ID derived from the nft contract
     * @param price The price of item in WEI
     */
    function listItem(uint256 tokenId, uint256 price) public nonReentrant {
        IERC721 nftContract = IERC721(i_nftAddress);

        if (nftContract.getApproved(tokenId) != address(this)) {
            revert DiffusedMarketplace__TokenNotApprovedForMarketplace();
        }

        if (nftContract.ownerOf(tokenId) != msg.sender) {
            revert DiffusedMarketplace__SellerNotOwner();
        }

        if (s_listings[tokenId].price != 0) {
            revert DiffusedMarketplace__TokenAlreadyListed();
        }

        if (price <= 0) {
            revert DiffusedMarketplace__InsufficientPrice();
        }

        emit ItemListed(tokenId, msg.sender, price);

        s_listings[tokenId] = Listing(msg.sender, price);
    }

    /**
     * @notice Buys an item and transfers ownership to the buyer
     * @param tokenId Token ID derived from the nft contract
     */
    function buyItem(uint256 tokenId) public payable nonReentrant {
        IERC721 nftContract = IERC721(i_nftAddress);
        Listing memory item = s_listings[tokenId];

        if (item.price == 0) {
            revert DiffusedMarketplace__ItemNotListed();
        }

        if (msg.value < item.price) {
            revert DiffusedMarketplace__PriceNotMet();
        }

        delete s_listings[tokenId];

        s_proceeds[item.seller] += msg.value;

        emit ItemBought(tokenId, msg.sender, msg.value);

        nftContract.safeTransferFrom(item.seller, msg.sender, tokenId);
    }

    /**
     * @notice Withdraw all proceedings from the marketplace
     */
    function withdrawProceeds() public nonReentrant {
        if (s_proceeds[msg.sender] == 0) {
            revert DiffusedMarketplace__NoProceeds();
        }

        // Reentrance protection reinforcement
        uint256 totalProceeds = s_proceeds[msg.sender];
        s_proceeds[msg.sender] = 0;

        (bool success, ) = address(msg.sender).call{value: totalProceeds}('');

        if (!success) {
            revert DiffusedMarketplace__WithdrawFailed();
        }
    }

    /**
     * @notice Removes item from the list, you can't change the listing
     * @param tokenId Token id derived from the nft contract
     */
    function removeItem(uint256 tokenId) public nonReentrant {
        Listing memory item = s_listings[tokenId];

        if (msg.sender != item.seller) {
            revert DiffusedMarketplace__NotOwner();
        }

        delete s_listings[tokenId];

        emit ItemRemoved(tokenId, msg.sender);
    }

    function getNftAddress() external view returns (address) {
        return i_nftAddress;
    }

    function getListing(uint256 tokenId)
        external
        view
        returns (Listing memory)
    {
        return s_listings[tokenId];
    }

    function getProceeds(address user) external view returns (uint256) {
        return s_proceeds[user];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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