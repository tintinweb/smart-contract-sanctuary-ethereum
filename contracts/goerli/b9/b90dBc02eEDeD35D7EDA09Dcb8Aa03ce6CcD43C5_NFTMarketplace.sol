// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// ^IERC721 is the ERC721 Interface it can initiate an ERC721 nft contract with
// the nft contract address

error NFTMarketplace__PriceMustBeAboveZero();
error NFTMarketplace__NotApprovedForMarketPlace();
error NFTMarketplace__AlreadyListed(address nftAddress_, uint256 tokenId_);
error NFTMarketplace__NotOwner();
error NFTMarketplace__NotListed(address nftAddress_, uint256 tokenId_);
error NFTMarketplace__PriceNotMet(address nftAddress_, uint256 tokenId_, uint256 price_);
error NFTMarketplace__NoProceeds();
error NFTMarketplace__TransferFailed();

contract NFTMarketplace is ReentrancyGuard
{
  // TYPES
  struct Listing // a marketplace listing
  {
    uint256 price;
    address seller;
  }

  // EVENTS
  event ItemListed
  (
    address indexed seller_,
    address indexed nftAddress_,
    uint256 indexed tokenId_,
    uint256 price_
  );

  event ItemBought
  (
    address indexed buyer_,
    address indexed nftAddress_,
    uint256 indexed tokenId_,
    uint256 price_
  );

  event ItemRemoved
  (
    address indexed seller_,
    address indexed nftAddress_,
    uint256 indexed tokenId_
  );
  
  // VARIABLES
  // nft contract address -> nft tokenId -> listing
  mapping(address => mapping(uint256 => Listing)) private s_listings; 
  // ^items in the marketplace
  // seller address(i.e. merchant) -> amount earned
  mapping(address => uint256) private s_proceeds;
  // ^how much a merchant has earned

  // MODIFIERS
  modifier notListed(address nftAddress_, uint256 tokenId_, address owner_) 
  {  // modifier checking to see if nft hasn't been listed already
    Listing memory listing = s_listings[nftAddress_][tokenId_];
    if(listing.price > 0){revert NFTMarketplace__AlreadyListed(nftAddress_, tokenId_);}
    // if listing price is 0 it means it hasn't been listed yet otherwise it has
    _;
  }

  modifier isOwner(address nftAddress_, uint256 tokenId_, address spender_)
  {  // modifier checking to see if msg.sender owns the nft
    IERC721 nft = IERC721(nftAddress_);
    address owner = nft.ownerOf(tokenId_);
    if(spender_ != owner){revert NFTMarketplace__NotOwner();}
    _;
  }

  modifier isListed(address nftAddress_, uint256 tokenId_)
  {  // making sure item is listed before buyItem()
    Listing memory listing = s_listings[nftAddress_][tokenId_];
    if(listing.price <= 0){revert NFTMarketplace__NotListed(nftAddress_, tokenId_);}
    _;
  }

  // MAIN FUNCTIONS
  // listing items
  /**@dev a function that lists nfts for sale in the marketplace
    *it requires approval from the owner of the nft to list the nft for sale
    *it uses chainlink pricefeeds to display the price of the nft in 
     different erc20 token units
   */
  function listItem(address nftAddress_, uint256 tokenId_, uint256 price_) external
  notListed(nftAddress_, tokenId_, msg.sender)  // notListed modifier
  isOwner(nftAddress_, tokenId_, msg.sender)
  {  // nftAddress_ is the nft contract address
    if(price_ <= 0){revert NFTMarketplace__PriceMustBeAboveZero();}
    // 2.Owners can still own their nfts just give the marketplace the approval to sell it 
    // for them
    // that we can get from IERC721 which can wrap an address and require
    // approval before the address can be used
    IERC721 nft = IERC721(nftAddress_); 
    // ^wrapping it around the nft contract address initiating an IERC721 contract
    if(nft.getApproved(tokenId_) != address(this))
    {
      revert NFTMarketplace__NotApprovedForMarketPlace();
    }
    s_listings[nftAddress_][tokenId_] = Listing(price_, msg.sender);
    emit ItemListed(msg.sender, nftAddress_, tokenId_, price_);
  }

  function buyItem(address nftAddress_, uint256 tokenId_) external payable 
  isListed(nftAddress_, tokenId_)
  nonReentrant
  {
    Listing memory listedItem = s_listings[nftAddress_][tokenId_];
    if(msg.value < listedItem.price)
    {
      revert NFTMarketplace__PriceNotMet(nftAddress_, tokenId_, listedItem.price);
    }
    s_proceeds[listedItem.seller] = s_proceeds[listedItem.seller] + msg.value;
    // ^merchant has earned his proceeds
    delete(s_listings[nftAddress_][tokenId_]);
    // ^listing has been removed from marketplace
    IERC721(nftAddress_).safeTransferFrom(listedItem.seller, msg.sender, tokenId_);
    // ^ERC721 transfering the nft to the buyer safetransfer to ensure EOA exists
    // ^note that we transfer only after all checks have been made preventing 
    // re-entrancy attacks
    // emit an even when you update a mapping
    emit ItemBought(msg.sender, nftAddress_, tokenId_, listedItem.price);
  }

  function cancelListing(address nftAddress_, uint256 tokenId_) external
  isOwner(nftAddress_, tokenId_, msg.sender)
  isListed(nftAddress_, tokenId_)
  {
    delete(s_listings[nftAddress_][tokenId_]);
    emit ItemRemoved(msg.sender, nftAddress_, tokenId_);
  }

  function updateListing(address nftAddress_, uint256 tokenId_, uint256 newPrice_) 
  external
  isOwner(nftAddress_, tokenId_, msg.sender)
  isListed(nftAddress_, tokenId_)
  {
    s_listings[nftAddress_][tokenId_].price = newPrice_;
    emit ItemListed(msg.sender, nftAddress_, tokenId_, newPrice_);
  }

  function withdrawProceeds() external nonReentrant
  {
    uint256 proceeds = s_proceeds[msg.sender];
    if(proceeds <= 0){revert NFTMarketplace__NoProceeds();}
    s_proceeds[msg.sender] = 0;  // checks before action (reentracy guard)
    (bool success, ) = payable(msg.sender).call{value: proceeds}("");
    if(!success){revert NFTMarketplace__TransferFailed();}
  }

  // GETTER FUNCTIONS
  function getListing(address nftAddress_, uint256 tokenId_) external view 
  returns(Listing memory)
  {
    return s_listings[nftAddress_][tokenId_];
  }

  function getProceeds(address seller_) external view returns(uint256)
  {
    return s_proceeds[seller_];
  }
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