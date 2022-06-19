//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ZyncNFTMArketplace is Ownable, ReentrancyGuard {
    uint16 public constant defaultListingLife = 1000;
    uint16 public constant defaultAuctionTime = 1000;
    uint256 public feePercentage = 0;
    bool public paused = false;
    uint256 public totalFee = 0;
    uint256 public minimumPrice = 1;
    uint256 public minimumAuctionTime = 86400;
    uint256 public lastListingId = 0;
    uint256 public lastAuctionId = 0;

    address public spendingToken;
    mapping(uint256 => Listing) public nftListing;
    mapping(uint256 => Auction) public nftAuction;
    mapping(address => uint256) public userDeposited;

    constructor(address _spendingToken) {
        spendingToken = _spendingToken;
    }

    /*
        Modifier
    */
    modifier isNotPaused() {
        require(!paused, "Market place is paused");
        _;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier isNotSettled(uint256 _listingId) {
        require(nftListing[_listingId].sold == false, "NFT already sold");
        _;
    }

    /*
        Owner Function
    */
    function setSpendingToken(address _token) public onlyOwner {
        spendingToken = _token;
    }

    function setMinimumPrice(uint256 _price) public onlyOwner {
        minimumPrice = _price;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    /**
    @notice Transfer fee to owner address
     */
    function withdrawFee() public onlyOwner {
        IERC20(spendingToken).transfer(owner(), totalFee);
        totalFee = 0;
    }

    /*
        Event
    */

    event ListingCreated(
        uint256 listingId,
        uint256 listedAt,
        address nftSeller,
        address nftContractAddress,
        uint256 tokenId,
        uint256 price
    );

    event ListingSold(
        uint256 listingId,
        uint256 soldAt,
        address nftBuyer,
        address nftContractAddress
    );

    event DelistListing(
        uint256 listingId,
        uint256 delistedAt
    );

    event AuctionCreated(uint32 listedAt, address nftSeller);

    event BidPlace();

    event AuctionDelisted();

    event AuctionSettled();

    struct Listing {
        uint256 listedAt; //blockNumber
        uint256 buyAt;
        uint256 price; //listing price
        uint256 tokenId;
        address nftAddress;
        address nftSeller;
        address nftBuyer;
        address specificBuyer;
        bool sold;
    }

    struct Auction {
        uint256 listedAt; //blockNumber
        uint256 buyAt;
        uint256 startPrice;
        uint256 currentPrice; //listing price
        uint256 tokenId;
        uint256 expiryTime;
        address nftAddress;
        address nftSeller;
        address lastBidder;
        bool settled;
    }

    /**
    @notice Create NFT listing and transfer NFT to this contract
    @param _nftContractAddress NFT Contract Addres to be listed.
    @param _tokenId Token id of NFT to be listed.
    @param _price Listing price.
     */
    function createNFTListing(
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 _price
        // address _specificBuyer
    ) public nonReentrant {
        require(_price >= minimumPrice, "Price too low");
        IERC721(_nftContractAddress).transferFrom(
            msg.sender,
            address(this),
            _tokenId
        );

        nftListing[lastListingId].listedAt = block.timestamp;
        nftListing[lastListingId].buyAt = 0;
        nftListing[lastListingId].price = _price;
        nftListing[lastListingId].tokenId = _tokenId;
        nftListing[lastListingId].nftAddress = _nftContractAddress;
        nftListing[lastListingId].nftSeller = msg.sender;
        nftListing[lastListingId].sold = false;
        //nftListing[lastListingId].nftBuyer = 0x0;
        //nftListing[lastListingId].specificBuyer = 0x0;

        
        //emit event

        emit ListingCreated(lastListingId, block.timestamp, msg.sender, _nftContractAddress, _tokenId, _price);
        lastListingId++;
    }

    /**
    @notice Buy listed NFT
    @param _listingId NFT listing id to be purchased.
     */
    function buyNFT(uint256 _listingId)
        public
        nonReentrant
        isNotSettled(_listingId)
    {
        nftListing[_listingId].sold = true;

        //TODO check result of transfer
        IERC20(spendingToken).transferFrom(
            msg.sender,
            nftListing[_listingId].nftSeller,
            nftListing[_listingId].price
        );

        address nftAddress = nftListing[_listingId].nftAddress;
        uint256 tokenId = nftListing[_listingId].tokenId;

        // Transfer NFT to buyer
        //TODO check transfer result
        IERC721(nftAddress).transferFrom(
            address(this),
            msg.sender,
            tokenId
        );
    }

    /**
    @notice Cancel specific NFT listing and transfer NFT Back to nft seller.
    @param _listingId NFT Contract address
     */
    function cancelNFTListing(uint256 _listingId)
        public
    {
        require(
            nftListing[_listingId].nftSeller == msg.sender,
            "Only Seller"
        );
        require(
            nftListing[_listingId].sold == false,
            "Already Sold"
        );

        nftListing[_listingId].sold = true;

        address nftAddress = nftListing[_listingId].nftAddress;
        uint256 tokenId = nftListing[_listingId].tokenId;

        //TODO check transfer result
        IERC721(nftAddress).transferFrom(
            address(this),
            nftListing[_listingId].nftSeller,
            tokenId
        );

        emit DelistListing(_listingId, block.timestamp);
    }

    /**
    @notice Get NFT Listing
    @param _listingId NFT listing to gets
     */
    function getListing(uint256 _listingId)
        public
        view
        returns (Listing memory)
    {
        return nftListing[_listingId];
    }


    // AUCTION SECTION

    /**
    @notice Deposit Spending token for further use in this contract.
    @param _amount amount of token to be deposited.
     */
    function deposit(uint256 _amount)
        public
        callerIsUser
        nonReentrant
        isNotPaused
    {
        //TODO Check transfer result
        IERC20(spendingToken).transferFrom(msg.sender, address(this), _amount);
        
        userDeposited[msg.sender] += _amount;
    }

    /**
    @notice Withdraw Spending token to sender
     */
    function withdraw() public callerIsUser nonReentrant isNotPaused {
        require(userDeposited[msg.sender] > 0, "No deposited");
        uint256 amount = userDeposited[msg.sender];
        userDeposited[msg.sender] = 0;

        //TODO Check transfer result
        IERC20(spendingToken).transfer(address(this), amount);
    }

    /**
    @notice Create an NFT Auction
    @param _nftContractAddress address of NFT Contract
    @param _tokenId token id of NFT
    @param _price initial price of auction
    @param _expiry expiry time of this auction in millis.
     */
    function createNFTAuction(
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 _price,
        uint256 _expiry
    ) public {
        require(_price >= minimumPrice, "Price too low");
        require(_expiry >= minimumAuctionTime, "Auction Time too low");

        //TODO Check transfer result
        IERC721(_nftContractAddress).transferFrom(
            msg.sender,
            address(this),
            _tokenId
        );

        nftAuction[lastAuctionId].listedAt = block.timestamp;
        nftAuction[lastAuctionId].nftSeller = msg.sender;
        nftAuction[lastAuctionId].startPrice = _price;
        nftAuction[lastAuctionId].currentPrice = _price;
        nftAuction[lastAuctionId].lastBidder = address(0);
        nftAuction[lastAuctionId].expiryTime =block.timestamp + _expiry;

        lastAuctionId++;
    }

    /**
    @notice Place bid on specific NFT Auction
    @param _auctionId Address of NFT to place bid
     */
    function placeBid(
        uint256 _auctionId,
        uint256 _bidAmount
    ) public {
        require(_bidAmount < userDeposited[msg.sender], "Not enough fund");
        require(
            _bidAmount > nftAuction[_auctionId].currentPrice,
            "Bid to low."
        );
        require(
            nftAuction[_auctionId].expiryTime > block.timestamp,
            "Auction ended"
        );

        address prevBidder = nftAuction[_auctionId].lastBidder;

        // restore bid placed by previous bidder to userDeposited
        if (prevBidder != address(0)) {
            userDeposited[prevBidder] += nftAuction[_auctionId].currentPrice;
        }

        nftAuction[_auctionId].lastBidder = msg.sender;
        nftAuction[_auctionId].currentPrice = _bidAmount;

        // deduct bid from userDeposited of current bidder
        userDeposited[msg.sender] -= _bidAmount;
    }

    /**
    @notice Settle fund from finished auction
    @param _auctionId Aucrtion Id to be settled
     */
    function settleAuction(uint256 _auctionId)
        public
        nonReentrant
    {
        require(
            nftAuction[_auctionId].expiryTime < block.timestamp,
            "Auction not ended"
        );

        require(
            nftAuction[_auctionId].settled == false,
            "Already Settled"
        );
        
        // require(
        //     msg.sender == nftAuction[_nftContractAddress][_tokenId].nftSeller ||
        //         msg.sender ==
        //         nftAuction[_nftContractAddress][_tokenId].latestBidder,
        //     "Not eligible"
        // );

        // add fund to seller userDeposited.
        address nftSeller = nftAuction[_auctionId].nftSeller;
        address lastBidder = nftAuction[_auctionId].lastBidder;

        //TODO TAX
        userDeposited[nftSeller] += nftAuction[_auctionId].currentPrice;

        // Transfer NFT to last bidder
        //TODO Check transfer result
        address nftAddress = nftAuction[_auctionId].nftAddress;
        IERC721(nftAddress).transferFrom(
            address(this),
            lastBidder,
            nftAuction[_auctionId].tokenId
        );
    }

    /**
    @notice Cancel specific auction and transfer NFT back to nftSeller
     */
    function cancelAuction(address _nftContractAddress, uint256 _tokenId)
        public
        onlyOwner
    {}

    function getAuction(uint256 _auctionId)
        public
        view
        returns (Auction memory)
    {
        return nftAuction[_auctionId];
    }

    /**
    @notice Get amount of remaining token of specific user
    @param _user address of user
    @return amount amount of remaining token in userDeposited
     */
    function getUserDeposit(address _user)
        public
        view
        returns (uint256)
    {
        return userDeposited[_user];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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