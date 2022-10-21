//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//`listItem`: List NFT on the marketplace
//`buyItem` : Buy NFT on the marketplace
//`cancelIteam` : cancle listing of NFT
//`updatelisting` : update listing data of the NFT
//`withdrawprocessed` : withdraw mony from marketplace

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

//error functions
error NftMarketPlace_PriceMustBeAboveZero();
error NftMarketPlace_NotApprovedForMarketPlace();
error NftMarketPlace_AlreadyListed(address nftContractAddress, uint256 tokenId);
error NftMarketPlace_NotOwner();
error NftMarketPlace_NftNotListed(address nftContractAddress, uint256 tokenId);
error NftMarketPlace_PriceNotMet(address nftContractAddress, uint256 tokenId, uint256 price);
error NftMarketPlace_NoProceed();
error NftMarketPlace_TransactionFailed();

contract NftMarketPlace is ReentrancyGuard {
    /**Structs*/
    struct Listing {
        uint256 price;
        address seller;
    }

    /**Mappings*/
    /**NFT contract mapping => tokenID => Listing struct*/
    mapping(address => mapping(uint256 => Listing)) private s_listings;
    //Mapping bet seller's address and Amount earned
    mapping(address => uint256) private s_proceeds;
    uint256 test;

    //**Events */
    event itemListed(
        address indexed seller,
        address indexed nftContractAddress,
        uint256 indexed tokensId,
        uint256 price
    );

    event ItemBought(
        address indexed buyer,
        address indexed nftContract,
        uint256 tokenId,
        uint256 price
    );

    event ItemCanceled(address indexed seller, address indexed NftContractAddress, uint256 tokenId);

    //**Modifiers*/

    //**Checking if NFT is already listed or not  */
    modifier notListed(
        address nftContractAddress,
        uint256 tokenId,
        address owner
    ) {
        Listing memory listing = s_listings[nftContractAddress][tokenId];
        if (listing.price > 0) {
            revert NftMarketPlace_AlreadyListed(nftContractAddress, tokenId);
        }
        _;
    }

    //**Checking the Owner of the NFT is msg.sender or not */
    modifier isOwner(
        address nftContractAddress,
        uint256 tokenId,
        address spender
    ) {
        IERC721 nft = IERC721(nftContractAddress);
        address owner = nft.ownerOf(tokenId);
        if (spender != owner) {
            revert NftMarketPlace_NotOwner();
        }
        _;
    }

    //**Checking if the NFT is listed or not */
    modifier isListed(address nftContractAddress, uint256 tokenId) {
        Listing memory listing = s_listings[nftContractAddress][tokenId];

        if (listing.price <= 0) {
            revert NftMarketPlace_NftNotListed(nftContractAddress, tokenId);
        }

        _;
    }

    ////////Main Functions////////

    /**
     * @dev listNft() is used to list NFTs on the markeplace
     * @param nftContractAddress address of the NFT contract
     * @param tokenId token number of the NFT
     * @param price set price of the NFT
     * @notice The list NFT function is gonna list NFT on the MarketPlace, user still hold NFT and give the marketplace approval to sell the NFT for them
     */
    function listNft(
        address nftContractAddress,
        uint256 tokenId,
        uint256 price
    )
        external
        notListed(nftContractAddress, tokenId, msg.sender)
        isOwner(nftContractAddress, tokenId, msg.sender)
    {
        if (price <= 0) {
            revert NftMarketPlace_PriceMustBeAboveZero();
        }

        //Checking if contract approve to marketplace
        IERC721 nft = IERC721(nftContractAddress);
        if (nft.getApproved(tokenId) != address(this)) {
            revert NftMarketPlace_NotApprovedForMarketPlace();
        }

        //mapping listing NFT details
        s_listings[nftContractAddress][tokenId] = Listing(price, msg.sender);
        emit itemListed(msg.sender, nftContractAddress, tokenId, price);
    }

    /**
     * @dev This function is used to buy NFTs
     * @param nftContractAddress address of the NFT contract
     * @param tokenId token number of the NFT
     * @notice When buyer buy NFT with paying correct amount this function safe transfer that NFT and add Amount to the seller's address
     */
    function buyItem(address nftContractAddress, uint256 tokenId)
        external
        payable
        isListed(nftContractAddress, tokenId)
    {
        Listing memory listedItem = s_listings[nftContractAddress][tokenId];

        //Revert transation when correct amount is not send
        if (msg.value < listedItem.price) {
            revert NftMarketPlace_PriceNotMet(nftContractAddress, tokenId, listedItem.price);
        }

        //mapping seller => amount
        s_proceeds[listedItem.seller] = s_proceeds[listedItem.seller] + msg.value;
        //Delete listing after selling NFT
        delete (s_listings[nftContractAddress][tokenId]);

        //Transfer toke to buyer
        IERC721(nftContractAddress).safeTransferFrom(listedItem.seller, msg.sender, tokenId);

        //make sure NFT was transferred
        emit ItemBought(msg.sender, nftContractAddress, tokenId, listedItem.price);
    }

    /**This function cancle NFT listing  */

    function cancleListing(address nftContractAddress, uint256 tokenId)
        external
        isOwner(nftContractAddress, tokenId, msg.sender)
        isListed(nftContractAddress, tokenId)
    {
        delete (s_listings[nftContractAddress][tokenId]);
        emit ItemCanceled(msg.sender, nftContractAddress, tokenId);
    }

    /**This function update listed NFT price */
    function updateListing(
        address nftContractAddress,
        uint256 tokenId,
        uint256 newPrice
    )
        external
        isOwner(nftContractAddress, tokenId, msg.sender)
        isListed(nftContractAddress, tokenId)
    {
        s_listings[nftContractAddress][tokenId].price = newPrice;
        emit itemListed(msg.sender, nftContractAddress, tokenId, newPrice);
    }

    /**This function withdraw Amount to seller's address */
    function withdrawProceeds() external nonReentrant {
        uint256 proceeds = s_proceeds[msg.sender];

        if (proceeds <= 0) {
            revert NftMarketPlace_NoProceed();
        }

        s_proceeds[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: proceeds}("");
        if (!success) {
            revert NftMarketPlace_TransactionFailed();
        }
    }

    ////////Getter Functions////////

    function getListing(address NftContractAddress, uint256 tokenId)
        external
        view
        returns (Listing memory)
    {
        return s_listings[NftContractAddress][tokenId];
    }

    function getProceeds(address seller) external view returns (uint256) {
        return s_proceeds[seller];
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