// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./RentContract.sol";

error HouseMarketplace__PiceMustBeAboveZero();
error HouseMarketplace__NotApprovedForMarketplace();
error HouseMarketplace__AlreadyListed(address nftAddress,uint256 tokenId);
error HouseMarketplace__NotListed(address nftAddress,uint256 tokenId);
error HouseMarketplace__NotOwner();
error HouseMarketplace__PriceNotMet(address nftAddress,uint256 tokenId,uint256 price);
error HouseMarketplace__NoProceeds();
error HouseMarketplace__TransferFailed();

contract HouseMarketplace is ReentrancyGuard{

    struct SellListing{
        address seller;
        uint256 price;
    }
    struct RentListing{
        address owner;
        uint256 period;
        uint256 rentPerPeriod;
        uint256 numberOfPeriods;
        uint256 bufferTime;
    }

    mapping(address=> mapping(uint256=>SellListing)) private s_sellListings;
    mapping(address=> mapping(uint256=>RentListing)) private s_rentListings;
    mapping(address=>uint256) private s_proceeds;
    address private rentContractAddress;

    modifier notListedToSell(address nftAddress,uint256 tokenId){
        SellListing memory listing=s_sellListings[nftAddress][tokenId];
        if(listing.price>0){
            revert HouseMarketplace__AlreadyListed(nftAddress,tokenId);
        }
        _;
    }

    modifier notListedToRent(address nftAddress,uint256 tokenId){
        RentListing memory listing=s_rentListings[nftAddress][tokenId];
        if(listing.rentPerPeriod>0){
            revert HouseMarketplace__AlreadyListed(nftAddress,tokenId);
        }
        _;
    }

    modifier isListedToSell(address nftAddress,uint256 tokenId){
        SellListing memory listing=s_sellListings[nftAddress][tokenId];
        if(listing.price<=0){
            revert HouseMarketplace__NotListed(nftAddress,tokenId);
        }
        _;
    }

    modifier isListedToRent(address nftAddress,uint256 tokenId){
        RentListing memory listing=s_rentListings[nftAddress][tokenId];
        if(listing.rentPerPeriod<=0){
            revert HouseMarketplace__NotListed(nftAddress,tokenId);
        }
        _;
    }

    modifier isOwner(address nftAddress,uint256 tokenId,address spender){
        IERC721 nft =IERC721(nftAddress);
        address owner=nft.ownerOf(tokenId);
        if(spender !=owner)
        {
            revert HouseMarketplace__NotOwner();
        }
        _;
    }
    constructor(address _rentContractAddress){
        rentContractAddress=_rentContractAddress;
    }

    event ItemListedToSell(address indexed nftAddress,uint256 indexed tokenId,SellListing indexed sellListing);
    event ItemListedToRent(address indexed nftAddress,uint256 indexed tokenId,RentListing indexed rentListings);
    event ItemBought(address indexed nftAddress,uint256 indexed tokenId,SellListing indexed sellListing);
    event ItemRented(address indexed nftAddress,uint256 indexed tokenId,RentListing indexed rentListing);
    event ItemCanceledToSell(address indexed nftAddress,uint256 indexed tokenId,SellListing indexed sellListing);
    event ItemCanceledToRent(address indexed nftAddress,uint256 indexed tokenId,RentListing indexed RentListing);

    function listItemToSell(address nftAddress,uint256 tokenId,uint256 price) 
    external 
    notListedToSell(nftAddress,tokenId) 
    isOwner(nftAddress,tokenId,msg.sender)
    {
        if(price<=0){
            revert HouseMarketplace__PiceMustBeAboveZero();
        }
        IERC721 nft=IERC721(nftAddress);
        if(nft.getApprovedToSell(tokenId)!=address(this)){
            revert HouseMarketplace__NotApprovedForMarketplace();
        }
        SellListing memory newSellListing=SellListing(msg.sender,price);
        s_sellListings[nftAddress][tokenId]=newSellListing;
        emit ItemListedToSell(nftAddress,tokenId,newSellListing);
    }

    function listItemToRent(address nftAddress,uint256 tokenId,RentListing memory newRentListing) 
    external 
    notListedToRent(nftAddress,tokenId) 
    isOwner(nftAddress,tokenId,msg.sender)
    {
        if(newRentListing.rentPerPeriod<=0){
            revert HouseMarketplace__PiceMustBeAboveZero();
        }
        IERC721 nft=IERC721(nftAddress);
        if(nft.getApprovedToRent(tokenId)!=address(this)){
            revert HouseMarketplace__NotApprovedForMarketplace();
        }
        s_rentListings[nftAddress][tokenId]=newRentListing;
        emit ItemListedToRent(nftAddress,tokenId,newRentListing);
    }

    function buyItem(address nftAddress,uint256 tokenId) 
    external payable
    nonReentrant
    isListedToSell(nftAddress,tokenId)
    {
        SellListing memory listedItem=s_sellListings[nftAddress][tokenId];
        if(msg.value<listedItem.price)
        {
            revert HouseMarketplace__PriceNotMet(nftAddress,tokenId,listedItem.price);
        }
        s_proceeds[listedItem.seller]+=msg.value;
        delete (s_sellListings[nftAddress][tokenId]);
        IERC721(nftAddress).safeTransferFrom(listedItem.seller,msg.sender,tokenId);
        emit ItemBought(nftAddress,tokenId,listedItem);
    }

    function rentItem(address nftAddress,uint256 tokenId) 
    external payable
    nonReentrant
    isListedToRent(nftAddress,tokenId)
    {
        RentListing memory listedItem=s_rentListings[nftAddress][tokenId];
        if(msg.value<listedItem.rentPerPeriod)
        {
            revert HouseMarketplace__PriceNotMet(nftAddress,tokenId,listedItem.rentPerPeriod);
        }
        s_proceeds[listedItem.owner]+=msg.value;
        delete (s_rentListings[nftAddress][tokenId]);
        RentContract(rentContractAddress).startAgreement(nftAddress, tokenId,listedItem.period,listedItem.rentPerPeriod,listedItem.numberOfPeriods,listedItem.bufferTime);
        IERC721(nftAddress).setTenant(listedItem.owner, msg.sender, rentContractAddress, tokenId);
        emit ItemRented(nftAddress,tokenId,listedItem);
    }

    function cancelListingToSell(address nftAddress,uint256 tokenId) 
    external 
    isOwner(nftAddress,tokenId,msg.sender) 
    isListedToSell(nftAddress,tokenId)
    {
        SellListing memory sellListing=s_sellListings[nftAddress][tokenId];
        delete(s_sellListings[nftAddress][tokenId]);
        emit ItemCanceledToSell(nftAddress,tokenId,sellListing);
    }

    function cancelListingToRent(address nftAddress,uint256 tokenId) 
    external 
    isOwner(nftAddress,tokenId,msg.sender) 
    isListedToRent(nftAddress,tokenId)
    {
        RentListing memory rentListing=s_rentListings[nftAddress][tokenId];
        delete(s_rentListings[nftAddress][tokenId]);
        emit ItemCanceledToRent(nftAddress,tokenId,rentListing);
    }

    function updateListingToSell(address nftAddress,uint256 tokenId,SellListing memory updatedSellListing)
    external
    isOwner(nftAddress,tokenId,msg.sender)
    isListedToSell(nftAddress,tokenId)
    {
        s_sellListings[nftAddress][tokenId]=updatedSellListing;
        emit ItemListedToSell(nftAddress,tokenId,updatedSellListing);
    }

    function updateListingToRent(address nftAddress,uint256 tokenId,RentListing memory updatedRentListing)
    external
    isOwner(nftAddress,tokenId,msg.sender)
    isListedToRent(nftAddress,tokenId)
    {
        s_rentListings[nftAddress][tokenId]=updatedRentListing;
        emit ItemListedToRent(nftAddress,tokenId,updatedRentListing);
    }

    function withdrawProceeds() external 
    {
        uint256 proceeds=s_proceeds[msg.sender];
        if(proceeds<=0){
            revert HouseMarketplace__NoProceeds();
        }
        s_proceeds[msg.sender]=0;
        (bool success,)=payable(msg.sender).call{value:proceeds}("");
        if(!success){
            revert HouseMarketplace__TransferFailed();
        }
    }

    function getListingToSell(address nftAddress,uint256 tokenId)
    external
    view
    returns(SellListing memory)
    {
        return s_sellListings[nftAddress][tokenId];
    }

    function getListingToRent(address nftAddress,uint256 tokenId)
    external
    view
    returns(RentListing memory)
    {
        return s_rentListings[nftAddress][tokenId];
    }

    function getProceeds(address seller)
    external
    view
    returns(uint256)
    {
        return s_proceeds[seller];
    }

    function getRentContractAddress()
    external
    view
    returns(address)
    {
        return rentContractAddress;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./interface/IRentContract.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";


error __NotOwner();

contract RentContract{
        
    enum status {
        Started,
        Ended
    }
    struct RentalAgreement{
        status contractStatus;
        uint256 period;
        uint256 costPerPeriod;
        uint256 numberOfPeriods;
        uint256 bufferTime;
    }


    mapping(address=>mapping(uint256=>RentalAgreement)) public rentalAgreements;

    bool public contractStatus;
    function startAgreement(address nftAddress,uint256 tokenId,uint256 _period,uint256 _costPerPeriod,uint256 _numberOfPeriods,uint256 _bufferTime) public{
        rentalAgreements[nftAddress][tokenId]=RentalAgreement(status.Started,_period,_costPerPeriod,_numberOfPeriods,_bufferTime);

    }
    function endAgreement(address nftAddress,uint256 tokenId) public{
        delete(rentalAgreements[nftAddress][tokenId]);
    }
    function getAgreementStatus(address nftAddress,uint256 tokenId) public view returns(RentalAgreement memory){
        return rentalAgreements[nftAddress][tokenId];
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
    event Rented(address indexed owner,address indexed rentedTo,uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event ApprovalToSell(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalToRent(address indexed owner, address indexed approved, uint256 indexed tokenId);

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
    function tenantOf(uint256 tokenId) external view returns (address tenant);
    function contractOf(uint256 tokenId) external view returns (address tenant);

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

    function setTenant(
        address owener,
        address rentedTo,
        address rentContractAddress,
        uint256 tokenId
    ) external;

    function removeTenant(
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
    function approveToSell(address to, uint256 tokenId) external;
    function approveToRent(address to, uint256 tokenId) external;

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
    function setApprovalToSellForAll(address operator, bool _approved) external;

    function setApprovalToRentForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApprovedToSell(uint256 tokenId) external view returns (address operator);

    function getApprovedToRent(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedToSellForAll(address owner, address operator) external view returns (bool);
    function isApprovedToRentForAll(address owner, address operator) external view returns (bool);
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
pragma solidity ^0.8.7;

interface IRentContract{
    function nftOwner() external view returns(address);
    function nftTenant() external view returns(address);
    function nftTokenId() external view returns(uint256);
    function contractStarted() external view returns(bool isContractStarted);
    function contractEnded() external view returns(bool isContractEnded);
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