/**
 *Submitted for verification at Etherscan.io on 2022-10-08
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

// File: contracts/Marketplace.sol


pragma solidity ^0.8.4;





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



contract TerrapinMarket is ReentrancyGuard, Pausable, Ownable {

    IERC721 terrapinContract;     // Terrapin contract

    struct Offer {
        bool isForSale;
        uint terrapinIndex;
        address seller;
        uint minValue;          // in ether
        address onlySellTo;
    }

    Offer[] private _offers;
    uint public totalVolume = 0;

    struct Bid {
        bool hasBid;
        uint terrapinIndex;
        address bidder;
        uint value;
    }

    mapping (uint => Offer) public terrapinOfferedForSale;
    mapping (uint => Bid) public terrapinBids;
    mapping(uint256 => uint256) private _tokenIdToOfferId;
    mapping (address => uint) public pendingWithdrawals;

    event TerrapinOffered(uint indexed terrapinIndex, uint minValue, address indexed toAddress, uint blockTimestamp);
    event TerrapinBidEntered(uint indexed terrapinIndex, uint value, address indexed fromAddress);
    event TerrapinBidWithdrawn(uint indexed terrapinIndex, uint value, address indexed fromAddress);
    event TerrapinBought(uint indexed terrapinIndex, uint value, address indexed fromAddress, address indexed toAddress, uint blockTimestamp);
    event TerrapinNoLongerForSale(uint indexed terrapinIndex);

    constructor(address initialTerrapinAddress) {
        IERC721(initialTerrapinAddress).balanceOf(address(this));
        terrapinContract = IERC721(initialTerrapinAddress);
    }

    function pause() public whenNotPaused onlyOwner {
        _pause();
    }

    function unpause() public whenPaused onlyOwner {
        _unpause();
    }

    function terrapinAddress() public view returns (address) {
      return address(terrapinContract);
    }

    function setTerrapinContract(address newTerrapinAddress) public onlyOwner {
      terrapinContract = IERC721(newTerrapinAddress);
    }

    function offeredForSaleTokens() public view returns (uint256[] memory ListOfToken) {
            uint256 totalOffers = _offers.length;
            if (totalOffers == 0) {
                return new uint256[](0);
            } else {
                uint256[] memory resultOfToken = new uint256[](totalOffers);
                for (uint256 i = 0; i < totalOffers; i++) {
                    if (_offers[i].isForSale != false) {
                        resultOfToken[i] = _offers[i].terrapinIndex;
                    }
                }
                return resultOfToken;
            }
     }

    function offeredForSalePrices() public view returns (uint256[] memory ListOfPrices) {
            uint256 totalOffers = _offers.length;
            if (totalOffers == 0) {
                return new uint256[](0);
            } else {
                uint256[] memory resultOfToken = new uint256[](totalOffers);
                for (uint256 i = 0; i < totalOffers; i++) {
                    if (_offers[i].isForSale != false) {
                        resultOfToken[i] = _offers[i].minValue;
                    }
                }
                return resultOfToken;
            }
     }

    function terrapinNoLongerForSale(uint terrapinIndex) public nonReentrant() {
        if (terrapinIndex >= 10000) revert('token index not valid');
        if (terrapinContract.ownerOf(terrapinIndex) != msg.sender) revert('you are not the owner of this token');
        terrapinOfferedForSale[terrapinIndex] = Offer(false, terrapinIndex, msg.sender, 0, address(0x0));
        _offers[_tokenIdToOfferId[terrapinIndex]] = _offers[_offers.length - 1];
        _offers.pop();
        emit TerrapinNoLongerForSale(terrapinIndex);
    }

    function offerTerrapinForSale(uint terrapinIndex, uint minSalePriceInWei) public whenNotPaused nonReentrant()  {
        if (terrapinIndex >= 10000) revert('token index not valid');
        if (terrapinContract.ownerOf(terrapinIndex) != msg.sender) revert('you are not the owner of this token');
        if (terrapinContract.isApprovedForAll(msg.sender, address(this)) != true) revert('Please SetApprovalForAll before offering your Turtle for sale.');
        terrapinOfferedForSale[terrapinIndex] = Offer(true, terrapinIndex, msg.sender, minSalePriceInWei, address(0x0));
        Offer memory _offer = Offer({isForSale: true, terrapinIndex: terrapinIndex, seller: msg.sender, minValue: minSalePriceInWei, onlySellTo: address(0x0)});
        terrapinOfferedForSale[terrapinIndex] = _offer;
        _offers.push(_offer);
        uint256 index = _offers.length - 1;
        _tokenIdToOfferId[terrapinIndex] = index;
        emit TerrapinOffered(terrapinIndex, minSalePriceInWei, address(0x0), block.timestamp);
    }

    function offerTerrapinForSaleToAddress(uint terrapinIndex, uint minSalePriceInWei, address toAddress) public whenNotPaused nonReentrant() {
        if (terrapinIndex >= 10000) revert();
        if (terrapinContract.ownerOf(terrapinIndex) != msg.sender) revert('you are not the owner of this token');
        terrapinOfferedForSale[terrapinIndex] = Offer(true, terrapinIndex, msg.sender, minSalePriceInWei, toAddress);
        Offer memory _offer = Offer({isForSale: true, terrapinIndex: terrapinIndex, seller: msg.sender, minValue: minSalePriceInWei, onlySellTo: toAddress});
        terrapinOfferedForSale[terrapinIndex] = _offer;
        _offers.push(_offer);
        uint256 index = _offers.length - 1;
        _tokenIdToOfferId[terrapinIndex] = index;
        emit TerrapinOffered(terrapinIndex, minSalePriceInWei, toAddress, block.timestamp);
    }
    

    function buyTerrapin(uint terrapinIndex) payable public whenNotPaused nonReentrant() {
        if (terrapinIndex >= 10000) revert('token index not valid');
        Offer memory offer = terrapinOfferedForSale[terrapinIndex];
        if (!offer.isForSale) revert('Terrapin is not for sale'); // not actually for sale
        if (offer.onlySellTo != address(0x0) && offer.onlySellTo != msg.sender) revert();                
        if (msg.value != offer.minValue) revert('not enough ether');          // Didn't send enough ETH
        address seller = offer.seller;
        if (seller == msg.sender) revert('seller == msg.sender');
        if (seller != terrapinContract.ownerOf(terrapinIndex)) revert('seller no longer owner of terrapin'); // Seller no longer owner of terrapin

        terrapinOfferedForSale[terrapinIndex] = Offer(false, terrapinIndex, msg.sender, 0, address(0x0));
        terrapinContract.safeTransferFrom(seller, msg.sender, terrapinIndex);
        _offers[_tokenIdToOfferId[terrapinIndex]] = _offers[_offers.length - 1];
        _offers.pop();
        pendingWithdrawals[seller] += msg.value;
        totalVolume = totalVolume + msg.value;
        emit TerrapinBought(terrapinIndex, msg.value, seller, msg.sender, block.timestamp);

        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        Bid memory bid = terrapinBids[terrapinIndex];
        if (bid.bidder == msg.sender) {
            // Kill bid and refund value
            pendingWithdrawals[msg.sender] += bid.value;
            terrapinBids[terrapinIndex] = Bid(false, terrapinIndex, address(0x0), 0);
        }
    }


    /* Allows users to retrieve ETH from sales */
    function withdraw() public nonReentrant() {
        uint amount = pendingWithdrawals[msg.sender];
        // Remember to zero the pending refund before
        // sending to prevent re-entrancy attacks
        pendingWithdrawals[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    function enterBidForTerrapin(uint terrapinIndex) payable public whenNotPaused nonReentrant() {
        if (terrapinIndex >= 10000) revert('token index not valid');
        if (terrapinContract.ownerOf(terrapinIndex) == msg.sender) revert('you already own this terrapin');
        if (msg.value == 0) revert('cannot enter bid of zero');
        Bid memory existing = terrapinBids[terrapinIndex];
        if (msg.value <= existing.value) revert('your bid is too low');
        if (existing.value > 0) {
            // Refund the failing bid
            pendingWithdrawals[existing.bidder] += existing.value;
        }
        terrapinBids[terrapinIndex] = Bid(true, terrapinIndex, msg.sender, msg.value);
        emit TerrapinBidEntered(terrapinIndex, msg.value, msg.sender);
    }

    function acceptBidForTerrapin(uint terrapinIndex, uint minPrice) public whenNotPaused nonReentrant() {
        if (terrapinIndex >= 10000) revert('token index not valid');
        if (terrapinContract.ownerOf(terrapinIndex) != msg.sender) revert('you do not own this token');
        if (terrapinContract.isApprovedForAll(msg.sender, address(this)) != true) revert('Please SetApprovalForAll before offering your Turtle for sale.');
        address seller = msg.sender;
        Bid memory bid = terrapinBids[terrapinIndex];
        if (bid.value == 0) revert('cannot enter bid of zero');
        if (bid.value < minPrice) revert('your bid is too low');

        address bidder = bid.bidder;
        if (seller == bidder) revert('you already own this token');
        terrapinOfferedForSale[terrapinIndex] = Offer(false, terrapinIndex, bidder, 0, address(0x0));
        uint amount = bid.value;
        terrapinBids[terrapinIndex] = Bid(false, terrapinIndex, address(0x0), 0);
        terrapinContract.safeTransferFrom(msg.sender, bidder, terrapinIndex);
        pendingWithdrawals[seller] += amount;
        totalVolume = totalVolume + amount;
        emit TerrapinBought(terrapinIndex, bid.value, seller, bidder, block.timestamp);
    }

    function withdrawBidForTerrapin(uint terrapinIndex) public nonReentrant() {
        if (terrapinIndex >= 10000) revert('token index not valid');
        Bid memory bid = terrapinBids[terrapinIndex];
        if (bid.bidder != msg.sender) revert('the bidder is not message sender');
        emit TerrapinBidWithdrawn(terrapinIndex, bid.value, msg.sender);
        uint amount = bid.value;
        terrapinBids[terrapinIndex] = Bid(false, terrapinIndex, address(0x0), 0);
        // Refund the bid money
        payable(msg.sender).transfer(amount);
    }

}