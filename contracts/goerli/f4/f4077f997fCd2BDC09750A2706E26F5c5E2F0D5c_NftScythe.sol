// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NftScythe is ReentrancyGuard, IERC721Receiver, Ownable, Pausable {

    struct SoldItemDetail {
        address seller;
        uint256 expiration; // easier to keep track of soldTime but expiration ensures that at sale time, you are guaranteed the buyback period
    }

    /**********************
     * Variables *
     **********************/
    uint256 private _sellerPrice; // price paid to sellers in ETH, must be greater than zero
    uint256 private _exclusiveBuyerPrice; // price paid by original seller in ETH, must be >0 and >sellerPrice
    uint256 private _unrestrictedBuyerPrice; // price paid by any buyer in ETH, must >0 and >sellerPrice

    uint256 private _exclusiveBuybackPeriod = 86400*30; // time period in seconds
    mapping (address => mapping(uint256 => SoldItemDetail)) private _buybackItemsByItemAddress; // lookup by NFT address
    
    bool private _unrestrictedBuyingEnabled = false; // if items can be bought from the contract
    bool private _exclusiveBuybackEnabled = true;

    /**********************
     *  Modifiers  *
     **********************/
    modifier unpaused() {
        require(!paused(), 'Scythe paused');
        _;
    }

    modifier enoughFunds(uint256 amount) {
        require(address(this).balance >= amount, "Not enough funds");
        _;
    }

    modifier itemOwnedByScythe(address nftAddress, uint256 tokenId) {
        require(IERC721(nftAddress).ownerOf(tokenId) == address(this), "Item must be owned by Scythe");
        _;
    }

    modifier priceGreaterThanZero(uint256 price) {
        require (price > 0, "Price must be greater than 0");
        _;
    }

    /**********************
     *  Functions  *
     **********************/
    constructor(uint256 sPrice, uint256 exclusiveBPrice, uint256 unrestrictedBPrice){
        require(sPrice > 0 && exclusiveBPrice > 0 && unrestrictedBPrice > 0, "Prices must be greater than 0");
        require(sPrice < exclusiveBPrice && sPrice < unrestrictedBPrice, "Seller price must be less than buyer prices");
 
        _sellerPrice = sPrice;
        _exclusiveBuyerPrice = exclusiveBPrice;
        _unrestrictedBuyerPrice = unrestrictedBPrice;
    }

    // hook called when an ERC721 received
    function onERC721Received(address, address from, uint256 tokenId, bytes memory) 
        external 
        virtual 
        override
        unpaused
        nonReentrant
        itemOwnedByScythe(msg.sender,tokenId)
        enoughFunds(_sellerPrice)
        returns (bytes4) {

        // record sale in the item mappings
        _buybackItemsByItemAddress[msg.sender][tokenId] = SoldItemDetail(from, block.timestamp+_exclusiveBuybackPeriod);

        // make the payment
        // "msg.sender" is now the nftcontract's address. 'from' is the seller.
        (bool success, ) = payable(from).call{value: _sellerPrice}("");
        require(success, "Transfer failed");

        // generate event
        emit ItemSold(from, msg.sender, tokenId, _sellerPrice);
        return this.onERC721Received.selector;
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IERC721Receiver).interfaceId;
    }

    // generic function to allow receiving Ether, needed to fund contract initially
    receive() external payable {}

    // Allows protocol owner to withdraw from the contract
    function withdrawProtocolFunds(uint256 amount) 
        external 
        nonReentrant 
        enoughFunds(amount)
        onlyOwner {

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
    }

    /**********************
     *  Buying Functions  *
     **********************/

    // private function to move items
    function _transferItem(address to, address nftAddress, uint256 tokenId) 
        private {

        IERC721(nftAddress).safeTransferFrom(address(this), to, tokenId);        
        // delete mapping
        delete _buybackItemsByItemAddress[nftAddress][tokenId];
    }
    
    // allows Contract owner to move NFT out of the contract
    // listed as a failsafe to always be able to move NFTs out
    // Can also enable future use cases like an Auction
    function transferItem(address nftAddress, uint256 tokenId) external onlyOwner{
        _transferItem(msg.sender, nftAddress, tokenId);
    }

    // Anyone can buy any NFT for the price set in the contract
    function buyItemUnrestricted(address nftAddress, uint256 tokenId) 
        external 
        payable 
        nonReentrant
        unpaused
        itemOwnedByScythe(nftAddress, tokenId) {
        
        // check conditions
        require(_unrestrictedBuyingEnabled, "Unrestricted buying is not enabled");
        require((msg.value == _unrestrictedBuyerPrice), "Incorrect buy price");
        require((_fetchInitializedBuybackItem(nftAddress, tokenId).expiration <= block.timestamp), "Item still under exclusive buyback period");

        // transfer
        _transferItem(msg.sender, nftAddress, tokenId);
        emit ItemBought(msg.sender, nftAddress, tokenId, _unrestrictedBuyerPrice);
    }

    // Allows buyback exclusively to the seller
    function buybackItem(address nftAddress, uint256 tokenId) 
        external 
        payable 
        nonReentrant
        unpaused
        itemOwnedByScythe(nftAddress, tokenId) {

        // check conditions
        require(_exclusiveBuybackEnabled, "Exclusive buyback is not enabled");
        require(msg.value == _exclusiveBuyerPrice, "Incorrect buy price");
        SoldItemDetail memory itemDetail = _fetchInitializedBuybackItem(nftAddress, tokenId);
        require(itemDetail.seller == msg.sender, "Only seller can buyback");
        require(itemDetail.expiration >= block.timestamp, "Item no longer under exclusive period");


        // transfer
        _transferItem(msg.sender, nftAddress, tokenId);
        emit ItemBought(msg.sender, nftAddress, tokenId, _exclusiveBuyerPrice);
    }

    /**********************
     *  Getters  *
     **********************/

    function getSellerPrice() external view returns (uint256) {
        return _sellerPrice;
    }

    function getUnrestrictedBuyerPrice() external view returns (uint256) {
        return _unrestrictedBuyerPrice;
    }

    function getExclusiveBuyerPrice() external view returns (uint256) {
        return _exclusiveBuyerPrice;
    }
    
    function getExclusiveBuybackPeriod() public view returns (uint256) {
        return _exclusiveBuybackPeriod;
    }

    function checkUnrestrictedBuyingEnabled() external view returns (bool) {
        return _unrestrictedBuyingEnabled;
    }

    function checkExclusiveBuybackEnabled() external view returns (bool) {
        return _exclusiveBuybackEnabled;
    }

    function checkBuybackStatusByItem(address nftAddress, uint256 tokenId) public view returns (SoldItemDetail memory) {
        return _buybackItemsByItemAddress[nftAddress][tokenId];
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**********************
     *  Setters  *
     **********************/

    function setSellerPrice(uint256 newSellerPrice) 
        external 
        onlyOwner
        priceGreaterThanZero(newSellerPrice) {
        require(newSellerPrice <= _exclusiveBuyerPrice && newSellerPrice <= _unrestrictedBuyerPrice, "Seller price can't be more than buyer prices");
        _sellerPrice = newSellerPrice;
    }

    function setUnrestrictedBuyerPrice(uint256 newPrice) 
        external 
        onlyOwner 
        priceGreaterThanZero(newPrice){

        require(newPrice >= _sellerPrice, "Buyer price can't be less than seller price");
        _unrestrictedBuyerPrice = newPrice;
    }

    function setExclusiveBuyerPrice(uint256 newPrice) 
        external 
        onlyOwner 
        priceGreaterThanZero(newPrice) {
            
        require(newPrice >= _sellerPrice, "Buyer price can't be less than seller price");
        _exclusiveBuyerPrice = newPrice;
    }

    function setUnrestrictedBuying(bool value) external onlyOwner {
        _unrestrictedBuyingEnabled = value;
    }

    function setExclusiveBuyback(bool value) external onlyOwner {
        _exclusiveBuybackEnabled = value;
    }

    function setExclusiveBuybackPeriod(uint256 period) external onlyOwner {
        require(period >= 0, "Exclusive buyback period can't be less than 0");
        _exclusiveBuybackPeriod = period;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /**********************
     *  Helpers  *
     **********************/

    function _fetchInitializedBuybackItem(address nftAddress, uint256 tokenId) private view returns (SoldItemDetail memory) {
        SoldItemDetail memory itemDetail = _buybackItemsByItemAddress[nftAddress][tokenId];
        require(itemDetail.seller != address(0x0), "Item not registered in Scythe");
        return itemDetail;
    }

    /**********************
     *  Events  *
     **********************/

    // when item is sold to Scythe
    event ItemSold (
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );

    // when item is bought from Scythe
    event ItemBought (
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );
}