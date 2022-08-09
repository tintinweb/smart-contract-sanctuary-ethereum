/**
 *Submitted for verification at Etherscan.io on 2022-08-09
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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


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

// File: @openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// File: contracts/AuctionHouse.sol


pragma solidity ^0.8.7;




contract AuctionHouse is ERC721Holder, Ownable {
    address public feeAddress;
    uint16 public feePercent;

    /// @param _feeAddress must be either an EOA or a contract must have payable receive func and doesn't have some codes in that func.
    /// If not, it might be that it won't be receive any fee.
    function setFeeAddress(address _feeAddress) external onlyOwner {
        feeAddress = _feeAddress;
    }

    function setFeePercent(uint16 _percent) external onlyOwner {
        require(_percent <= 10000, "input value is more than 100%");
        feePercent = _percent;
    }

    struct Auction {
        IERC721 token;
        uint256 tokenId;
        uint8 auctionType;  // 0: Fixed Price, 1: Dutch Auction, 2: English Auction
        uint256 startPrice;
        uint256 endPrice;
        uint256 startBlock;
        uint256 endBlock;
        uint256 lastBidPrice;
        address seller;
        address lastBidder;
        bool isSold;
    }

    mapping (IERC721 => mapping (uint256 => bytes32[])) public auctionIdByToken;
    mapping (address => bytes32[]) public auctionIdBySeller;
    mapping (bytes32 => Auction) public auctionInfo;
    mapping (address => uint) public bids;

    event AuctionCreated(IERC721 indexed token, uint256 id, bytes32 indexed auctionId, address seller);
    event ListingCreated(IERC721 indexed token, uint256 id, bytes32 indexed auctionId, address seller);
    event AuctionCanceled(IERC721 indexed token, uint256 id, bytes32 indexed auctionId, address seller);
    event BidPlaced(IERC721 indexed token, uint256 id, bytes32 indexed auctionId, address bidder, uint256 bidPrice);
    event TokenClaimed(IERC721 indexed token, uint256 id, bytes32 indexed auctionId, address seller, address buyer, uint256 price);
    event WithdrawBid(IERC721 indexed token, uint256 id, bytes32 indexed auctionId, address bidder, uint256 bidPrice);

    constructor(uint16 _feePercent) {
        require(_feePercent <= 10000, "The input value cannot be more than 100%");
        feeAddress = payable(msg.sender);
        feePercent = _feePercent;
    }

    function getCurrentPrice(bytes32 _auction) public view returns (uint256) {
        Auction storage a = auctionInfo[_auction];
        uint8 auctionType = a.auctionType;
        if (auctionType == 0) {
            return a.startPrice;
        } else if (auctionType == 2) {  // English Auction
            uint256 lastBidPrice = a.lastBidPrice;
            return lastBidPrice == 0 ? a.startPrice : lastBidPrice;
        } else {
            uint256 _startPrice = a.startPrice;
            uint256 _startBlock = a.startBlock;
            uint256 tickPerBlock = (_startPrice - a.endPrice) / (a.endBlock - _startBlock);
            return _startPrice - ((block.number - _startBlock) * tickPerBlock);
        }
    }

    function _auctionId(IERC721 _token, uint256 _id, address _seller) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(block.number, _token, _id, _seller));
    }

    function _createAuction(
        uint8 _auctionType,
        IERC721 _token,
        uint256 _id,
        uint256 _startPrice,
        uint256 _endPrice,
        uint256 _endBlock
    ) internal {
        require(_endBlock > block.number, "Duration must be a positive value in the future");

        // push
        bytes32 auctionId = _auctionId(_token, _id, msg.sender);
        auctionInfo[auctionId] = Auction(_token, _id, _auctionType, _startPrice, _endPrice, block.number, _endBlock, 0, msg.sender, address(0), false);
        auctionIdByToken[_token][_id].push(auctionId);
        auctionIdBySeller[msg.sender].push(auctionId);

        // check if seller has a right to transfer the NFT token.
        _token.safeTransferFrom(msg.sender, address(this), _id);

        if (_auctionType == 0) {
            emit ListingCreated(_token, _id, auctionId, msg.sender);
        } else {
            emit AuctionCreated(_token, _id, auctionId, msg.sender);
        }
    }

    // 0: Fixed Price
    function fixedPrice(IERC721 _token, uint256 _id, uint256 _price, uint256 _endBlock) public {
        _createAuction(0, _token, _id, _price, 0, _endBlock); // endPrice = 0 for saving gas
    }

    // 1: Dutch Auction,
    function dutchAuction(IERC721 _token, uint256 _id, uint256 _startPrice, uint256 _endPrice, uint256 _endBlock) public {
        require(_startPrice > _endPrice, "End price should be lower than start price");
        _createAuction(1, _token, _id, _startPrice, _endPrice, _endBlock); // startPrice != endPrice
    }

    // 2: English Auction
    function englishAuction(IERC721 _token, uint256 _id, uint256 _startPrice, uint256 _endBlock) public {
        _createAuction(2, _token, _id, _startPrice, 0, _endBlock); // endPrice = 0 for saving gas
    }

    function cancelAuction(bytes32 _auction) external {
        Auction storage a = auctionInfo[_auction];
        require(a.seller == msg.sender, "Access denied");
        require(a.lastBidPrice == 0, "You cannot cancel the auction since one or more bids already exist"); // for EA. but even in DA, FP, seller can withdraw their token with this func.
        require(a.isSold == false, "Item is already sold");

        IERC721 token = a.token;
        uint256 tokenId = a.tokenId;
        
        // endBlock = 0 means the auction was canceled.
        a.endBlock = 0;

        token.safeTransferFrom(address(this), msg.sender, tokenId);
        emit AuctionCanceled(token, tokenId, _auction, msg.sender);
    }

    function buyInstantly(bytes32 _auction) payable external {
        Auction storage a = auctionInfo[_auction];
        uint256 endBlock = a.endBlock;
        require(endBlock != 0, "The Auction is canceled");
        require(endBlock > block.number, "The auction has ended");
        require(a.auctionType < 2, "You cannot buy instantly in an English Auction");
        require(a.isSold == false, "The item is already sold");

        uint256 currentPrice = getCurrentPrice(_auction);
        require(msg.value >= currentPrice, "The price value supplied doesn't match with the current price");

        // reentrancy proof
        a.isSold = true;

        uint256 fee = currentPrice * feePercent / 10000;
        payable(a.seller).transfer(currentPrice - fee);
        payable(feeAddress).transfer(fee);
        if (msg.value > currentPrice) {
            payable(msg.sender).transfer(msg.value - currentPrice);
        }

        a.token.safeTransferFrom(address(this), msg.sender, a.tokenId);

        emit TokenClaimed(a.token, a.tokenId, _auction, a.seller, msg.sender, currentPrice);
    }
  
    // bid function
    // you have to pay only ETH for bidding and buying.

    // In this contract, since send function is used instead of transfer or low-level call function,
    // if a participant is a contract, it must have receive payable function.
    // But if it has some code in either receive or fallback func, they might not be able to receive their ETH.
    // Even though some contracts can't receive their ETH, the transaction won't be failed.

    // Bids must be at least 1% higher than the previous bid.
    // If someone bids in the last 5 minutes of an auction, the auction will automatically extend by 5 minutes.
    function bid(bytes32 _auction) payable external {
        Auction storage a = auctionInfo[_auction];
        uint256 endBlock = a.endBlock;
        uint256 lastBidPrice = a.lastBidPrice;
        address lastBidder = a.lastBidder;

        require(a.auctionType == 2, "Bidding is supported only in english auction");
        require(endBlock != 0, "The auction is canceled");
        require(block.number <= endBlock, "The auction has ended");
        require(a.seller != msg.sender, "You cannot bid in your own auction");

        // Bid / price increment restrictions
        if (lastBidPrice != 0) {
            require(msg.value >= lastBidPrice + (lastBidPrice / 100), "The bid must be at least 1% higher than the last bid");  // 1%
        } else {
            require(msg.value >= a.startPrice && msg.value > 0, "The bid must be higher than the start price");
        }

        // 20 blocks = 5 mins in Ethereum.
        if (block.number > endBlock - 20) {
            a.endBlock = endBlock + 20;
        }

        a.lastBidder = msg.sender;
        a.lastBidPrice = msg.value;
        bids[a.lastBidder] += a.lastBidPrice;

        if (lastBidPrice != 0) {
            payable(lastBidder).transfer(lastBidPrice);
        }
        
        emit BidPlaced(a.token, a.tokenId, _auction, msg.sender, msg.value);
    }

    // Use this to withdraw your bids from an ongoing auction.
    function withdrawBid(bytes32 _auction) external {
        Auction storage a = auctionInfo[_auction];
        require(a.auctionType != 0, "You can only call withdraw in an auction");

        address bidder = msg.sender;
        uint bidAmount = bids[bidder];
        require(bidAmount > 0, "Insufficient balance to withdraw");

        if (a.isSold != true) {
            if (bidder == a.lastBidder) {
                bidAmount -= a.lastBidPrice;
                require(bidAmount > 0 && bidAmount < a.lastBidPrice, "You cannot withdraw your highest bid");
            }
        }

        payable(bidder).transfer(bidAmount);
        bids[bidder] = 0;
        emit WithdrawBid(a.token, a.tokenId, _auction, bidder, bidAmount);     
    }

    // both seller and buyer can call this func in English Auction. Probably the buyer (last bidder) might call this func.
    // In both DA and FP, buyInstantly func include claim func.
    function claim(bytes32 _auction) external {
        Auction storage a = auctionInfo[_auction];
        address seller = a.seller;
        address lastBidder = a.lastBidder;

        require(a.isSold == false, "Item is already sold");
        require(seller == msg.sender || lastBidder == msg.sender, "You cannot claim this auction as you are neither the seller nor the highest bidder");
        require(a.auctionType == 2, "You can only claim in an English Auction");
        require(block.number > a.endBlock, "You cannot claim when the auction is still running");

        IERC721 token = a.token;
        uint256 tokenId = a.tokenId;
        uint256 lastBidPrice = a.lastBidPrice;
        uint256 fee = lastBidPrice * feePercent / 10000;

        payable(seller).transfer(lastBidPrice - fee);
        payable(feeAddress).transfer(fee);
        token.safeTransferFrom(address(this), lastBidder, tokenId);

        a.isSold = true;
        bids[lastBidder] -= lastBidPrice;

        emit TokenClaimed(token, tokenId, _auction, seller, lastBidder, lastBidPrice);
    }
}