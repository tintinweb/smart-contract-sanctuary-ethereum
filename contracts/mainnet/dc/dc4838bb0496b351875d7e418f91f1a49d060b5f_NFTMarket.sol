/**
 *Submitted for verification at Etherscan.io on 2022-04-22
*/

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


// File @openzeppelin/contracts/token/ERC1155/[email protected]

// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)


/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}


// File @openzeppelin/contracts/security/[email protected]

// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)


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


// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)


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


// File contracts/NFTMarketplace.sol

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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

/**
 * @dev Contract module which provides access control
 *
 * the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * mapped to
 * `onlyOwner`
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }


    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}



contract NFTMarket is ReentrancyGuard, Pausable, Ownable {

    IERC1155 xPhunk;     // instance of the xPhunk contract
    uint256 listingFee = 20; // 2%
    address payable treasury;

    struct Offer {
        bool isForSale;
        uint phunkIndex;
        address seller;
        uint minValue;          // in ether
        address onlySellTo;
    }

    struct Bid {
        bool hasBid;
        uint phunkIndex;
        address bidder;
        uint value;
    }

    // A record of phunks that are offered for sale at a specific minimum value, and perhaps to a specific person
    mapping (uint => Offer) public phunksOfferedForSale;

    // A record of the highest phunk bid
    mapping (uint => Bid) public phunkBids;

    // A record of pending ETH withdrawls by address
    mapping (address => uint) public pendingWithdrawals;

    event PhunkOffered(uint indexed phunkIndex, uint minValue, address indexed toAddress);
    event PhunkBidEntered(uint indexed phunkIndex, uint value, address indexed fromAddress);
    event PhunkBidWithdrawn(uint indexed phunkIndex, uint value, address indexed fromAddress);
    event PhunkBought(uint indexed phunkIndex, uint value, address indexed fromAddress, address indexed toAddress);
    event PhunkNoLongerForSale(uint indexed phunkIndex);

    /* Initializes contract with an instance of xPhunk contract, and sets deployer as owner */
    constructor(address _treasury, address _xPhunkAddress) {
        treasury = payable(_treasury);
        xPhunk = IERC1155(_xPhunkAddress);
    }

    function pause() public whenNotPaused onlyOwner {
        _pause();
    }

    function unpause() public whenPaused onlyOwner {
        _unpause();
    }

    /* Updates the listing Fee of the contract */
    function updateListingFee(uint _listingFee) public payable {
      require(treasury == msg.sender, "Only marketplace owner can update listing Fee.");
      listingFee = _listingFee;
    }

    /* Returns the listing Fee of the contract */
    function getListingFee() public view returns (uint256) {
      return listingFee;
    }

    /* Returns the xPhunk contract address currently being used */
    function phunksAddress() public view returns (address) {
      return address(xPhunk);
    }

    /* Allows the owner of the contract to set a new xPhunk contract address */
    function setxPhunkAddress(address newPhunksAddress) public onlyOwner {
      xPhunk = IERC1155(newPhunksAddress);
    }

    /* Returns the sale price for the offered phunk */
    function getOfferedPrice(uint256 phunkIndex) external view returns (uint) {
        Offer memory offer = phunksOfferedForSale[phunkIndex];

        if (!offer.isForSale) {
            return 0;
        }

        return offer.minValue;
    }

    /** Returns the pending withdrawal amount for the phunk sale */
    function getPendingWithdrawal() external view returns (uint pendingWithdrawal) {
        return pendingWithdrawals[msg.sender];
    }

    /* Returns the highest bid for the phunk */
    function getHighestBid(uint256 phunkIndex) external view returns (uint) {
        Bid memory bid = phunkBids[phunkIndex];
        if (!bid.hasBid) { return 0; }
        return bid.value;
    }

    /* Returns the highest bidder for the phunk */
    function getHighestBidder(uint256 phunkIndex) external view returns (address) {
        Bid memory bid = phunkBids[phunkIndex];
        if (!bid.hasBid) {
            return address(0);
        }
        return bid.bidder;
    }

    /* Allows the owner of a xPhunk to stop offering it for sale */
    function phunkNoLongerForSale(uint phunkIndex) public nonReentrant() {
        if (xPhunk.balanceOf(msg.sender, phunkIndex) == 0) revert('you are not the owner of this token');
        phunksOfferedForSale[phunkIndex] = Offer(false, phunkIndex, msg.sender, 0, address(0x0));
        emit PhunkNoLongerForSale(phunkIndex);
    }

    /* Allows a xPhunks owner to offer it for sale */
    function offerPhunkForSale(uint phunkIndex, uint minSalePriceInWei) public whenNotPaused nonReentrant()  {
        if (xPhunk.balanceOf(msg.sender, phunkIndex) == 0) revert('you are not the owner of this token');
        phunksOfferedForSale[phunkIndex] = Offer(true, phunkIndex, msg.sender, minSalePriceInWei, address(0x0));
        emit PhunkOffered(phunkIndex, minSalePriceInWei, address(0x0));
    }

    /* Allows a xPhunks owner to offer it for sale to a specific address */
    function offerPhunkForSaleToAddress(uint phunkIndex, uint minSalePriceInWei, address toAddress) public whenNotPaused nonReentrant() {
        if (xPhunk.balanceOf(msg.sender, phunkIndex) == 0) revert('you are not the owner of this token');
        phunksOfferedForSale[phunkIndex] = Offer(true, phunkIndex, msg.sender, minSalePriceInWei, toAddress);
        emit PhunkOffered(phunkIndex, minSalePriceInWei, toAddress);
    }

    /* Allows users to buy a xPhunks offered for sale */
    function buyPhunk(uint phunkIndex) payable public whenNotPaused nonReentrant() {
        Offer memory offer = phunksOfferedForSale[phunkIndex];
        if (!offer.isForSale) revert('phunk is not for sale'); // phunk not actually for sale
        if (offer.onlySellTo != address(0x0) && offer.onlySellTo != msg.sender) revert();
        if (msg.value != offer.minValue) revert('not enough ether'); // Didn't send enough ETH
        address seller = offer.seller;
        if (seller == msg.sender) revert('seller == msg.sender');
        if (xPhunk.balanceOf(seller, phunkIndex) == 0) revert('seller no longer owner of phunk'); // Seller no longer owner of phunk

        phunksOfferedForSale[phunkIndex] = Offer(false, phunkIndex, msg.sender, 0, address(0x0));
        xPhunk.safeTransferFrom(seller, msg.sender, phunkIndex, 1, "");
        pendingWithdrawals[seller] += msg.value;
        emit PhunkBought(phunkIndex, msg.value, seller, msg.sender);

        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        Bid memory bid = phunkBids[phunkIndex];
        if (bid.bidder == msg.sender) {
            // Kill bid and refund value
            pendingWithdrawals[msg.sender] += bid.value;
            phunkBids[phunkIndex] = Bid(false, phunkIndex, address(0x0), 0);
        }
    }

    /* Allows users to retrieve ETH from sales */
    function withdraw() public nonReentrant() {
        uint amount = pendingWithdrawals[msg.sender];
        // Remember to zero the pending refund before
        // sending to prevent re-entrancy attacks
        pendingWithdrawals[msg.sender] = 0;

        // transfer the listing price to the market owner(loyalti feature)
        uint256 listingPrice = (amount * listingFee) / 1000;
        payable(treasury).transfer(listingPrice);

        // transfer sell price to the seller
        payable(msg.sender).transfer(amount - listingPrice);
    }

    /* Allows users to enter bids for any xPhunks */
    function enterBidForPhunk(uint phunkIndex) payable public whenNotPaused nonReentrant() {
        if (xPhunk.balanceOf(msg.sender, phunkIndex) != 0) revert('you already own this phunk');
        if (msg.value == 0) revert('cannot enter bid of zero');
        Bid memory existing = phunkBids[phunkIndex];
        if (msg.value <= existing.value) revert('your bid is too low');
        if (existing.value > 0) {
            // Refund the failing bid
            pendingWithdrawals[existing.bidder] += existing.value;
        }
        phunkBids[phunkIndex] = Bid(true, phunkIndex, msg.sender, msg.value);
        emit PhunkBidEntered(phunkIndex, msg.value, msg.sender);
    }

    /* Allows xPhunks owners to accept bids for their Phunks */
    function acceptBidForPhunk(uint phunkIndex, uint minPrice) public whenNotPaused nonReentrant() {
        if (xPhunk.balanceOf(msg.sender, phunkIndex) == 0) revert('you do not own this token');
        address seller = msg.sender;
        Bid memory bid = phunkBids[phunkIndex];
        if (bid.value == 0) revert('cannot enter bid of zero');
        if (bid.value < minPrice) revert('your bid is too low');

        address bidder = bid.bidder;
        if (seller == bidder) revert('you already own this token');
        phunksOfferedForSale[phunkIndex] = Offer(false, phunkIndex, bidder, 0, address(0x0));
        uint amount = bid.value;
        phunkBids[phunkIndex] = Bid(false, phunkIndex, address(0x0), 0);
        xPhunk.safeTransferFrom(msg.sender, bidder, phunkIndex, 1, "");
        pendingWithdrawals[seller] += amount;
        emit PhunkBought(phunkIndex, bid.value, seller, bidder);
    }

    /* Allows bidders to withdraw their bids */
    function withdrawBidForPhunk(uint phunkIndex) public nonReentrant() {
        Bid memory bid = phunkBids[phunkIndex];
        if (bid.bidder != msg.sender) revert('the bidder is not message sender');
        emit PhunkBidWithdrawn(phunkIndex, bid.value, msg.sender);
        uint amount = bid.value;
        phunkBids[phunkIndex] = Bid(false, phunkIndex, address(0x0), 0);
        // Refund the bid money
        payable(msg.sender).transfer(amount);
    }

    function withdrawAll() public onlyOwner() {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }
}