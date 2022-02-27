/**
 *Submitted for verification at Etherscan.io on 2022-02-27
*/

// File: @openzeppelin/contracts/utils/Context.sol



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

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol



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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol



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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// File: encapsuledMarket.sol


pragma solidity 0.8.10;




 //.                                          |            |                      |          |   
 //.   -_)    \    _|   _` |  _ \ (_-<  |  |  |   -_)   _` |     ` \    _` |   _| | /   -_)   _| 
 //. \___| _| _| \__| \__,_| .__/ ___/ \_,_| _| \___| \__,_|   _|_|_| \__,_| _|  _\_\ \___| \__| 
 //.                        _|                                                                   

contract EncapsuledMarket is Pausable, Ownable {

    IERC721 public tokensContract;
    address contractOwner;
    address royaltiesAddress = 0xf049ED4da9E12c6E2a0928fA6c975eBb60C872F3;
    uint royaltiesPerc = 10;

    struct Listing {
        bool isForSale;
        uint index;
        address seller;
        uint minValue;
        address onlySellTo;
    }

    struct Bid {
        bool hasBid;
        uint index;
        address bidder;
        uint value;
    }

    mapping (uint => Listing) public tokenListings;
    mapping (uint => Bid) public tokenBids;

    event TokenOnSale(uint indexed tokenIndex, uint minValue, address indexed toAddress);
    event TokenBidEntered(uint indexed tokenIndex, uint value, address indexed fromAddress);
    event TokenBidWithdrawn(uint indexed tokenIndex, uint value, address indexed fromAddress);
    event TokenBought(uint indexed tokenIndex, uint value, address indexed fromAddress, address indexed toAddress);
    event TokenNoLongerForSale(uint indexed tokenIndex);

    constructor(address initialAddress) {
        tokensContract = IERC721(initialAddress);
        contractOwner = msg.sender;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setRoyaltiesPerc(uint newPerc) public onlyOwner {
        require(newPerc <= 10, "Royalties too high");
        royaltiesPerc = newPerc;
    }
    
    function setContract(address newAddress) public onlyOwner {
        tokensContract = IERC721(newAddress);
    }

    function setRoyaltiesAddress(address newAddress) public onlyOwner {
        royaltiesAddress = newAddress;
    }
    
    function tokenNoLongerForSale(uint tokenIndex) public whenNotPaused {
        require(tokensContract.ownerOf(tokenIndex) == msg.sender, "Not the owner of this token");
        tokenListings[tokenIndex] = Listing(false, tokenIndex, msg.sender, 0, address(0x0));
        emit TokenNoLongerForSale(tokenIndex);
    }

    function listTokenForSaleToAddress(uint tokenIndex, uint minSalePriceInWei, address toAddress) public whenNotPaused {
        require(tokensContract.ownerOf(tokenIndex) == msg.sender, "Not the owner of this token");
        require(tokensContract.isApprovedForAll(msg.sender, address(this)), "Marketplace contract is not approved");
        tokenListings[tokenIndex] = Listing(true, tokenIndex, msg.sender, minSalePriceInWei, toAddress);
        emit TokenOnSale(tokenIndex, minSalePriceInWei, toAddress);
    }

    function buyToken(uint tokenIndex) payable public whenNotPaused {
        Listing memory listing = tokenListings[tokenIndex];
        address seller = listing.seller;
        require(listing.isForSale, "Not on sale");
        require(listing.onlySellTo == address(0x0) || listing.onlySellTo == msg.sender, "Sale reserved for different address");
        require(msg.value == listing.minValue, "Wrong price");
        require(seller == tokensContract.ownerOf(tokenIndex), "Seller no longer owner of the token");
        tokensContract.safeTransferFrom(seller, msg.sender, tokenIndex);
        tokenNoLongerForSale(tokenIndex);
        payable(seller).transfer(msg.value * (100-royaltiesPerc)/100);
        payable(royaltiesAddress).transfer(msg.value * royaltiesPerc/100);
        emit TokenBought(tokenIndex, msg.value, seller, msg.sender);
        // Refund bid from new owner if present
        Bid memory bid = tokenBids[tokenIndex];
        if (bid.bidder == msg.sender) {
            payable(msg.sender).transfer(bid.value);
            tokenBids[tokenIndex] = Bid(false, tokenIndex, address(0x0), 0);
        }
    }

    function enterBidForToken(uint tokenIndex) payable public whenNotPaused {
        Bid memory existing = tokenBids[tokenIndex];
        require(msg.value > 0, "Must bid a positive amount");
        require(msg.value > existing.value, "Must bid higher than existing bid");
        require(tokensContract.ownerOf(tokenIndex) != msg.sender, "Cannot bid on tokens you own");
        payable(existing.bidder).transfer(existing.value);
        tokenBids[tokenIndex] = Bid(true, tokenIndex, msg.sender, msg.value);
        emit TokenBidEntered(tokenIndex, msg.value, msg.sender);
    }

    function acceptBidForToken(uint tokenIndex) public whenNotPaused {
        require(tokensContract.ownerOf(tokenIndex) == msg.sender, "Not the owner of this token");
        require(tokensContract.isApprovedForAll(msg.sender, address(this)), "Marketplace contract is not approved");
        address seller = msg.sender;
        Bid memory bid = tokenBids[tokenIndex];
        address bidder = bid.bidder;
        tokensContract.safeTransferFrom(msg.sender, bidder, tokenIndex);
        tokenListings[tokenIndex] = Listing(false, tokenIndex, bidder, 0, address(0x0));
        uint amount = bid.value;
        tokenBids[tokenIndex] = Bid(false, tokenIndex, address(0x0), 0);
        payable(seller).transfer(amount * (100-royaltiesPerc)/100);
        payable(royaltiesAddress).transfer(amount * royaltiesPerc/100);
        emit TokenBought(tokenIndex, bid.value, seller, bidder);
    }

    function withdrawBidForToken(uint tokenIndex) public whenNotPaused {
        Bid memory bid = tokenBids[tokenIndex];
        require(bid.bidder == msg.sender, "Not the bidder");
        emit TokenBidWithdrawn(tokenIndex, bid.value, msg.sender);
        uint amount = bid.value;
        tokenBids[tokenIndex] = Bid(false, tokenIndex, address(0x0), 0);
        payable(msg.sender).transfer(amount);
    }

}