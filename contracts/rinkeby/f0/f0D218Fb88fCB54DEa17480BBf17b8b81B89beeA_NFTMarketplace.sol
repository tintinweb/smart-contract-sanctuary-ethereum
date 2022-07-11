// SPDX-License-Identifier: mMIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

error NFTMarketplace__PriceMustBePositive();
error NFTMarketplace__AlreadyListed(address, uint256);
error NFTMarketplace__NotApproved();
error NFTMarketplace__NotOwner();
error NFTMarketplace__PriceNotMet(address,uint256,uint256);
error NFTMarketplace__NotListed(address, uint256);
error NFTMarketplace__NoProceeds();
error NFTMarketplace__TransferFailed();
error NFTMarketplace__NotAllowed();

contract NFTMarketplace { 

    struct Listing { 
        uint256 price;
        address seller;
    }
    // NFT Contract Address -> NFT TokenID -> Listing

    mapping(address =>mapping(uint256 => Listing))  private s_listings;
    mapping(address=>uint256) private s_proceeds;

    address immutable i_owner;

    event ItemListed(
        address indexed sender,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
        // This Contract can accept payment in different coins/tokens
    );

    event ItemBought(
        address indexed buyer,
        address indexed NFTAddress,
        uint256 indexed tokenId,
        uint256 price
    );

    event ItemCanceled(
        address indexed seller,
        address indexed NFTAddress,
        uint256 indexed tokenId
        );

    event ItemUpdated(
        address indexed seller,
        address indexed NFTAddress,
        uint256 indexed tokenId,
        uint256  newPrice
        );



modifier notListed(address NFTAddress,uint256 tokenId,address owner){
    Listing memory listing = s_listings[NFTAddress][tokenId];
    if(listing.price>0){
        revert NFTMarketplace__AlreadyListed(NFTAddress,tokenId);
    }
    _;
}

modifier isAdmin(address caller){
    if(caller!=i_owner) revert NFTMarketplace__NotAllowed();
    _;
}

modifier isOwner(address NFTAddress, uint256 tokenId , address owner){ 
    IERC721 NFTContract =  IERC721(NFTAddress);
    address realOwner = NFTContract.ownerOf(tokenId);
    if(owner!=realOwner)
        revert NFTMarketplace__NotOwner();
    _;
} 

modifier isListed(address NFTAddress, uint256 tokenId){
    Listing memory listing = s_listings[NFTAddress][tokenId];
    if(listing.price<=0){
        revert NFTMarketplace__NotListed(NFTAddress,tokenId);
    }
    _;
}

constructor(){
    i_owner=msg.sender;
}

/*
* @notice Method for lising your NFT on the marketplace
* @param NFTAddress Address of the NFT contract
* @param tokenId NFT Token ID (Unique per contract)
* @param price Price of the listing

* @dev we should make the owner pass the ownership of the NFT to the marketplace when listed.
*/

function listItem(address NFTAddress,uint256 tokenId,uint256 price) external
    notListed(NFTAddress,tokenId,msg.sender)
    isOwner(NFTAddress,tokenId,msg.sender)
 {
    if(price<=0 ){
        revert NFTMarketplace__PriceMustBePositive();
    }

    IERC721 nft= IERC721(NFTAddress);
    if(nft.getApproved(tokenId)!=address(this)){
        revert NFTMarketplace__NotApproved();
    }

    s_listings[NFTAddress][tokenId]=Listing(price,msg.sender);

    emit ItemListed(msg.sender,NFTAddress,tokenId,price);
    // 1. Send the NFT to the contract. Transfer -> Contract
    // 2. Owners can still hold their NFT and give the marketplace approval
    // to sell NFT for them
 } 

 function buyItem(address NFTAddress,uint256 tokenId) external payable 
 isListed(NFTAddress,tokenId)
 {
    Listing memory listedItem = s_listings[NFTAddress][tokenId];

    if(msg.value<listedItem.price){
        revert NFTMarketplace__PriceNotMet(NFTAddress,tokenId,listedItem.price);
    }

    s_proceeds[listedItem.seller]+=listedItem.price;
    delete(s_listings[NFTAddress][tokenId]);   // Remove the listing from the marketplace 
    IERC721 nft= IERC721(NFTAddress);
    nft.safeTransferFrom(listedItem.seller,msg.sender,tokenId);

    emit ItemBought(msg.sender,NFTAddress,tokenId,listedItem.price);
 }

 function cancelListing(address NFTAddress,uint256 tokenId) external
 isOwner(NFTAddress,tokenId,msg.sender)
 {
    if(s_listings[NFTAddress][tokenId].price==0){
        revert NFTMarketplace__NotListed(NFTAddress,tokenId);
    }
    delete (s_listings[NFTAddress][tokenId]);
    emit ItemCanceled(msg.sender,NFTAddress,tokenId);
 }

 function updateListing(address NFTAddress, uint256 tokenId,uint256 newPrice)
    external 
    isListed(NFTAddress,tokenId)
    isOwner(NFTAddress,tokenId,msg.sender)
 {
    s_listings[NFTAddress][tokenId].price=newPrice;

    emit ItemUpdated(msg.sender,NFTAddress,tokenId,newPrice);

 } 
  function withdrawProceeds() external {
        uint256 proceeds = s_proceeds[msg.sender];
        if (proceeds <= 0) {
            revert NFTMarketplace__NoProceeds();
        }
        s_proceeds[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: proceeds}("");
        require(success, "Transfer failed");
    }


 function getListing(address NFTAddress,uint256 tokenId) public view returns (Listing memory listing){
    return s_listings[NFTAddress][tokenId];
 }

 function getProcceeds()public view returns(uint256){
    return s_proceeds[msg.sender];
 }

 function getAnyProcceeds(address seller) public view 
 isAdmin(msg.sender)
returns(uint256)
 {
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