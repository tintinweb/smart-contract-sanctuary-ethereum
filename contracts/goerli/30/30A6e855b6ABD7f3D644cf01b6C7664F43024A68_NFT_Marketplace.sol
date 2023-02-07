// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error NFT_Marketplace_Need_Amount_More_Than_Zero();
error NFT_Marketplace_NFT_IS_NOT_APPROVED_TO_MARKETPLACE();
error NFT_Marketplace_Already_Listed();
error NFT_Marketplace_Not_Owner();
error NFT_Marketplace_Not_Listed(address nftAddress,uint256 tokenId);
error NFT_Marketplace_Insufficient_Balance(address nftAddress, uint256 tokenId);
error NFT_Marketplace_Update_Price_GreaterThanZero(address nftAddress,uint256 tokenId,uint256 price);
error NFT_Marketplace_Transfer_Failed();
error  NFT_Marketplace_No_Proceeds();
// Uncomment this line to use console.log
// import "hardhat/console.sol";
contract NFT_Marketplace is ReentrancyGuard {

//Events
event itemListed(address indexed seller, address indexed nftAddress, uint256 indexed tokenId,uint256 Price);
event itemBought(address indexed buyer,address indexed nftAddress, uint256 indexed tokenId,uint256 price);
event itemRemoved(address indexed owner,address indexed nftAddress,uint256 indexed tokenId);

struct Listing{
uint256 price;
address seller;
}
// NFT Address -> token_id -> Listing (price, seller)
mapping(address => mapping(uint256 => Listing)) private s_listings;

// Owner's Address -> Withdrawable balance of the owner 
mapping(address => uint256) private s_proceeds;

// Modifiers

modifier notListed(address nftAddress,uint256 tokenId,address owner) {
Listing memory listing = s_listings[nftAddress][tokenId];
if(listing.price != 0){
    revert NFT_Marketplace_Already_Listed();
}
_;
}

modifier isOwner(address nftAddress,uint256 tokenId,address spender) {
IERC721 nft = IERC721(nftAddress);
address owner  = nft.ownerOf(tokenId);
if(owner != spender){
    revert NFT_Marketplace_Not_Owner();
}
_;
}

modifier isListed(address nftAddress,uint256 tokenId){
Listing memory listing = s_listings[nftAddress][tokenId];
if (listing.price <= 0) {
    revert NFT_Marketplace_Not_Listed(nftAddress,tokenId);
}
_;
}


// Main Functions

function list_item(address nft_address,uint256 token_id, uint256 price) external notListed(nft_address,token_id,msg.sender) isOwner(nft_address,token_id, msg.sender) {
if(price <=0){
    revert NFT_Marketplace_Need_Amount_More_Than_Zero();
}

IERC721 nft = IERC721(nft_address);

if(nft.getApproved(token_id) != address(this)){
revert NFT_Marketplace_NFT_IS_NOT_APPROVED_TO_MARKETPLACE();
}

s_listings[nft_address][token_id] = Listing(price,msg.sender);
emit itemListed(msg.sender,nft_address,token_id,price);

}


function buyItem(address nft_address,uint256 token_id) external payable isListed(nft_address,token_id)
nonReentrant
{
Listing memory listing = s_listings[nft_address][token_id];

// Transfering NFT To The Buyer From The Seller
if(msg.value < listing.price){
    revert NFT_Marketplace_Insufficient_Balance(nft_address,token_id);
}
s_proceeds[listing.seller] = s_proceeds[listing.seller] + msg.value;
delete (s_listings[nft_address][token_id]);
IERC721(nft_address).safeTransferFrom(listing.seller,msg.sender,token_id);
emit itemBought(listing.seller,nft_address,token_id,listing.price);

}


function cancel_listing(address nft_address,uint256 token_id) external  isOwner(nft_address,token_id,msg.sender) isListed(nft_address,token_id){
delete (s_listings[nft_address][token_id]);
emit itemRemoved(msg.sender,nft_address,token_id);
}

function update_listing(address nft_address,uint256 token_id,uint256 new_price) isOwner(nft_address,token_id,msg.sender) isListed(nft_address,token_id) external {
if(new_price <= 0){
    revert NFT_Marketplace_Update_Price_GreaterThanZero(nft_address,token_id,new_price);
}
s_listings[nft_address][token_id].price = new_price;
emit itemListed(msg.sender,nft_address,token_id,new_price);
}


function withdraw() external {
    uint256 proceeds = s_proceeds[msg.sender];
    if(proceeds <=0){
        revert NFT_Marketplace_No_Proceeds();
    }
s_proceeds[msg.sender] = 0;
(bool success,) = payable(msg.sender).call{value:proceeds}("");

if(!success){
    revert NFT_Marketplace_Transfer_Failed();
}

}

// Getter Functions

function getListings(address nft_address,uint256 token_id) external view returns(Listing memory) {
return s_listings[nft_address][token_id];
}


function getProceeds(address seller) external view returns(uint256){
return s_proceeds[seller];
}

// list_item ☑️
// update_price ☑️
// cancel_listing ☑️
// withdraw processing ☑️
// buy_item ☑️


}