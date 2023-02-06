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
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";

import "./lib/OfferMarket.sol";

contract AuctionMarket is OfferMarket {
    using Counters for Counters.Counter;

    Counters.Counter private _auctionIdCounter;

    // nftAddress => tokenId => Auction
    mapping(address => mapping(uint256 => Auction)) private _auctions;
    mapping(address => mapping(uint256 => Bid[])) private _bids;
    uint32 public bidIncrementRatio; // bid increment ratio in basis points (1/10000)
    uint32 public extendDuration; // extend duration in seconds

    struct Auction {
        uint256 id;
        address paymentToken;
        uint256 startPrice;
        uint64 startDate;
        uint64 duration;
        uint256 highestBid;
        address highestBidder;
    }

    struct Bid {
        address bidder;
        uint256 amount;
    }

    event AuctionCreated(
        uint256 indexed auctionId,
        address indexed nftAddress,
        uint256 indexed nftTokenId,
        address paymentToken,
        uint256 startPrice,
        uint64 startDate,
        uint64 duration
    );

    event AuctionUpdated(
        uint256 indexed auctionId,
        address indexed nftAddress,
        uint256 indexed nftTokenId,
        address paymentToken,
        uint256 startPrice,
        uint64 startDate,
        uint64 duration
    );

    event AuctionCancelled(
        uint256 indexed auctionId,
        address indexed nftAddress,
        uint256 indexed nftTokenId
    );

    event AuctionSettled(
        uint256 indexed auctionId,
        address indexed nftAddress,
        uint256 indexed nftTokenId,
        address buyer,
        uint256 price
    );

    event AuctionBid(
        uint256 indexed auctionId,
        address indexed nftAddress,
        uint256 indexed nftTokenId,
        address bidder,
        uint256 amount
    );

    modifier onlyPendingAuction(address nftAddress, uint256 nftTokenId) {
        require(_isAuctionPending(nftAddress, nftTokenId), "already started");
        _;
    }

    modifier onlyOverAuction(address nftAddress, uint256 nftTokenId) {
        require(_isAuctionOver(nftAddress, nftTokenId), "not over");
        _;
    }

    modifier onlyRunningAuction(address nftAddress, uint256 nftTokenId) {
        require(
            _isAuctionRunning(nftAddress, nftTokenId),
            "over or not started"
        );
        _;
    }

    constructor(
        uint32 bidIncrementRatio_,
        uint32 extendDuration_,
        uint32 fee_
    ) OfferMarket(fee_) {
        bidIncrementRatio = bidIncrementRatio_;
        extendDuration = extendDuration_;
    }

    function _isAuctionPending(
        address nftAddress,
        uint256 nftTokenId
    ) internal view returns (bool) {
        uint64 startDate = _auctions[nftAddress][nftTokenId].startDate;
        return block.timestamp < startDate;
    }

    function _isAuctionOver(
        address nftAddress,
        uint256 nftTokenId
    ) internal view returns (bool) {
        uint64 startDate = _auctions[nftAddress][nftTokenId].startDate;
        uint64 endDate = startDate + _auctions[nftAddress][nftTokenId].duration;

        return block.timestamp > endDate;
    }

    function _isAuctionRunning(
        address nftAddress,
        uint256 nftTokenId
    ) internal view returns (bool) {
        return
            !_isAuctionPending(nftAddress, nftTokenId) &&
            !_isAuctionOver(nftAddress, nftTokenId);
    }

    function _isValidBid(
        address nftAddress,
        uint256 nftTokenId,
        uint256 amount
    ) internal view returns (bool) {
        uint256 highestBid = _auctions[nftAddress][nftTokenId].highestBid;
        uint256 bidIncrement = _bidIncrement(highestBid);

        return amount >= highestBid + bidIncrement;
    }

    function _bidIncrement(uint256 highestBid) internal view returns (uint256) {
        return (highestBid * bidIncrementRatio) / 10000;
    }

    function _shouldAuctionExtend(
        address nftAddress,
        uint256 nftTokenId
    ) internal view returns (bool) {
        return
            _auctions[nftAddress][nftTokenId].startDate +
                _auctions[nftAddress][nftTokenId].duration -
                extendDuration <
            block.timestamp;
    }

    function _extendAuction(
        address nftAddress,
        uint256 nftTokenId,
        uint64 by
    ) internal {
        require(by > 0, "duration must be greater than 0");
        _auctions[nftAddress][nftTokenId].duration += by;

        emit AuctionUpdated(
            _auctions[nftAddress][nftTokenId].id,
            nftAddress,
            nftTokenId,
            _auctions[nftAddress][nftTokenId].paymentToken,
            _auctions[nftAddress][nftTokenId].startPrice,
            _auctions[nftAddress][nftTokenId].startDate,
            _auctions[nftAddress][nftTokenId].duration
        );
    }

    function _deleteAuction(address nftAddress, uint256 nftTokenId) internal {
        delete _auctions[nftAddress][nftTokenId];
        delete _bids[nftAddress][nftTokenId];
    }

    function _releaseAuctionFunds(
        address nftAddress,
        uint256 nftTokenId
    ) internal {
        uint256 bidCount = _bids[nftAddress][nftTokenId].length;
        address highestBidder = _auctions[nftAddress][nftTokenId].highestBidder;

        for (uint256 i = 0; i < bidCount; i++) {
            address bidder = _bids[nftAddress][nftTokenId][i].bidder;
            uint256 amount = _bids[nftAddress][nftTokenId][i].amount;
            address paymentToken = _auctions[nftAddress][nftTokenId]
                .paymentToken;

            if (bidder == highestBidder) {
                continue;
            }

            if (paymentToken == address(0)) {
                _sendEther(payable(bidder), amount);
            } else {
                _sendToken(paymentToken, bidder, amount);
            }
        }
    }

    function _bid(
        address nftAddress,
        uint256 nftTokenId,
        address bidder,
        uint256 amount
    ) internal {
        require(_isValidBid(nftAddress, nftTokenId, amount), "Invalid bid");

        _auctions[nftAddress][nftTokenId].highestBid = amount;
        _auctions[nftAddress][nftTokenId].highestBidder = bidder;

        // Update bid
        uint256 bidCount = _bids[nftAddress][nftTokenId].length;
        bool isBidderFound = false;
        for (uint256 i = 0; i < bidCount; i++) {
            if (_bids[nftAddress][nftTokenId][i].bidder == bidder) {
                _bids[nftAddress][nftTokenId][i].amount = amount;
                isBidderFound = true;
                break;
            }
        }

        // If bidder is not found, add new bid
        if (!isBidderFound) {
            _bids[nftAddress][nftTokenId].push(Bid(bidder, amount));
        }

        emit AuctionBid(
            _auctions[nftAddress][nftTokenId].id,
            nftAddress,
            nftTokenId,
            bidder,
            amount
        );

        if (_shouldAuctionExtend(nftAddress, nftTokenId)) {
            _extendAuction(
                nftAddress,
                nftTokenId,
                _auctions[nftAddress][nftTokenId].duration + extendDuration
            );
        }
    }

    function setBidIncrementRatio(
        uint32 bidIncrementRatio_
    ) external onlyOwner {
        bidIncrementRatio = bidIncrementRatio_;
    }

    function setExtendDuration(uint32 extendDuration_) external onlyOwner {
        extendDuration = extendDuration_;
    }

    function createAuction(
        address nftAddress,
        uint256 nftTokenId,
        address paymentToken,
        uint256 startPrice,
        uint64 startDate,
        uint32 duration
    )
        external
        onlyNftOwner(nftAddress, nftTokenId)
        onlyAcceptedToken(paymentToken)
    {
        require(startPrice > 0, "Start price must be greater than 0");
        require(duration > 0, "Duration must be greater than 0");

        uint64 startDateOrNow = startDate > 0
            ? startDate
            : uint32(block.timestamp);

        _addNftForSale(nftAddress, nftTokenId, msg.sender);

        uint256 auctionId = _auctionIdCounter.current();
        _auctionIdCounter.increment();
        _auctions[nftAddress][nftTokenId] = Auction({
            id: auctionId,
            paymentToken: paymentToken,
            startPrice: startPrice,
            startDate: startDateOrNow,
            duration: duration,
            highestBid: 0,
            highestBidder: address(0)
        });
        delete _bids[nftAddress][nftTokenId];

        emit AuctionCreated(
            auctionId,
            nftAddress,
            nftTokenId,
            paymentToken,
            startPrice,
            startDate,
            duration
        );
    }

    function updateAuction(
        address nftAddress,
        uint256 nftTokenId,
        address paymentToken,
        uint256 startPrice,
        uint64 startDate,
        uint32 duration
    )
        external
        onlySeller(nftAddress, nftTokenId)
        onlyAcceptedToken(paymentToken)
        onlyPendingAuction(nftAddress, nftTokenId)
    {
        require(startPrice > 0, "Start price must be greater than 0");
        require(duration > 0, "Duration must be greater than 0");

        uint64 startDateOrNow = startDate > 0
            ? startDate
            : uint32(block.timestamp);

        _auctions[nftAddress][nftTokenId].paymentToken = paymentToken;
        _auctions[nftAddress][nftTokenId].startPrice = startPrice;
        _auctions[nftAddress][nftTokenId].startDate = startDateOrNow;
        _auctions[nftAddress][nftTokenId].duration = duration;

        emit AuctionUpdated(
            _auctions[nftAddress][nftTokenId].id,
            nftAddress,
            nftTokenId,
            paymentToken,
            startPrice,
            startDate,
            duration
        );
    }

    function cancelAuction(
        address nftAddress,
        uint256 nftTokenId
    ) external onlySeller(nftAddress, nftTokenId) {
        _auctions[nftAddress][nftTokenId].highestBidder = address(0);

        _releaseAuctionFunds(nftAddress, nftTokenId);
        _releaseNft(nftAddress, nftTokenId);
        _deleteAuction(nftAddress, nftTokenId);

        emit AuctionCancelled(
            _auctions[nftAddress][nftTokenId].id,
            nftAddress,
            nftTokenId
        );
    }

    function bid(
        address nftAddress,
        uint256 nftTokenId
    ) external payable onlyRunningAuction(nftAddress, nftTokenId) {
        address paymentToken = _auctions[nftAddress][nftTokenId].paymentToken;
        require(
            paymentToken == address(0),
            "This auction only accepts ETH as payment"
        );

        _bid(nftAddress, nftTokenId, msg.sender, msg.value);
    }

    function bid(
        address nftAddress,
        uint256 nftTokenId,
        uint256 amount
    ) external onlyRunningAuction(nftAddress, nftTokenId) {
        address paymentToken = _auctions[nftAddress][nftTokenId].paymentToken;
        require(
            paymentToken != address(0),
            "This auction only accepts ERC20 tokens as payment"
        );

        _bid(nftAddress, nftTokenId, msg.sender, amount);
    }

    function settleAuction(
        address nftAddress,
        uint256 nftTokenId
    ) external onlyOwner onlyOverAuction(nftAddress, nftTokenId) {
        _releaseAuctionFunds(nftAddress, nftTokenId);

        address buyer = _auctions[nftAddress][nftTokenId].highestBidder;
        address paymentToken = _auctions[nftAddress][nftTokenId].paymentToken;
        uint256 price = _auctions[nftAddress][nftTokenId].highestBid;

        if (paymentToken == address(0)) {
            _sellNft(nftAddress, nftTokenId, buyer, price);
        } else {
            _sellNft(nftAddress, nftTokenId, buyer, paymentToken, price);
        }

        _deleteAuction(nftAddress, nftTokenId);

        emit AuctionSettled(
            _auctions[nftAddress][nftTokenId].id,
            nftAddress,
            nftTokenId,
            buyer,
            price
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";

import "./Payable.sol";
import "./NftLocker.sol";

contract Market is Ownable, NftLocker, Payable {
    mapping(address => mapping(uint256 => address)) private _sellers;
    uint32 public fee; // fee in basis points (1/10000)

    event Sale(
        address indexed nftAddress,
        uint256 indexed nftTokenId,
        address indexed seller,
        address buyer,
        uint256 price
    );

    modifier onlySeller(address nftAddress, uint256 nftTokenId) {
        require(_sellers[nftAddress][nftTokenId] == msg.sender, "Not seller");
        _;
    }

    modifier onlySellingNft(address nftAddress, uint256 nftTokenId) {
        require(
            _sellers[nftAddress][nftTokenId] != address(0),
            "NFT not selling"
        );
        _;
    }

    constructor(uint32 fee_) {
        fee = fee_;
    }

    function _setFee(uint32 fee_) internal {
        fee = fee_;
    }

    function _feeOf(uint256 amount) internal view returns (uint256) {
        return (amount * fee) / 10000;
    }

    function _royaltyInfo(
        address nftAddress,
        uint256 nftTokenId,
        uint256 price
    ) internal view returns (address, uint256) {
        if (IERC165(nftAddress).supportsInterface(type(IERC2981).interfaceId)) {
            (address receiver, uint256 amount) = IERC2981(nftAddress)
                .royaltyInfo(nftTokenId, price);
            return (receiver, amount);
        }
        return (address(0), 0);
    }

    function _addNftForSale(
        address nftAddress,
        uint256 nftTokenId,
        address seller
    ) internal {
        _sellers[nftAddress][nftTokenId] = seller;
        _lockNft(nftAddress, nftTokenId);
    }

    function _removeNftFromSale(
        address nftAddress,
        uint256 nftTokenId
    ) internal {
        _sellers[nftAddress][nftTokenId] = address(0);
        _releaseNft(nftAddress, nftTokenId);
    }

    function _sellNft(
        address nftAddress,
        uint256 nftTokenId,
        address buyer,
        uint256 price
    ) internal {
        address seller = _sellers[nftAddress][nftTokenId];

        uint256 marketFee = _feeOf(price);
        (address royalityReceiver, uint256 royalityAmount) = _royaltyInfo(
            nftAddress,
            nftTokenId,
            price
        );
        uint256 sellerGain = price - marketFee - royalityAmount;

        _sendEther(payable(seller), sellerGain);
        if (royalityReceiver != address(0))
            _sendEther(payable(royalityReceiver), royalityAmount);
        _releaseNft(nftAddress, nftTokenId, buyer);

        emit Sale(nftAddress, nftTokenId, seller, buyer, price);
    }

    function _sellNft(
        address nftAddress,
        uint256 nftTokenId,
        address buyer,
        address paymentToken,
        uint256 price
    ) internal {
        address seller = _sellers[nftAddress][nftTokenId];

        uint256 marketFee = _feeOf(price);
        (address royalityReceiver, uint256 royalityAmount) = _royaltyInfo(
            nftAddress,
            nftTokenId,
            price
        );
        uint256 sellerGain = price - marketFee - royalityAmount;

        _sendToken(paymentToken, seller, sellerGain);
        if (royalityReceiver != address(0))
            _sendToken(paymentToken, royalityReceiver, royalityAmount);
        _releaseNft(nftAddress, nftTokenId, buyer);

        emit Sale(nftAddress, nftTokenId, seller, buyer, price);
    }

    function _releaseNft(address nftAddress, uint256 nftTokenId) internal {
        address seller = _sellers[nftAddress][nftTokenId];
        _releaseNft(nftAddress, nftTokenId, seller);
    }

    function setFee(uint32 fee_) external onlyOwner {
        _setFee(fee_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";

contract NftLocker {
    modifier onlyNftOwner(address nftAddress, uint256 nftTokenId) {
        require(
            IERC721(nftAddress).ownerOf(nftTokenId) == msg.sender,
            "Not NFT owner"
        );
        _;
    }

    function _lockNft(address nftAddress, uint256 nftTokenId) internal {
        address owner = IERC721(nftAddress).ownerOf(nftTokenId);
        IERC721(nftAddress).transferFrom(owner, address(this), nftTokenId);

        require(
            IERC721(nftAddress).ownerOf(nftTokenId) == address(this),
            "NFT transfer failed"
        );
    }

    function _releaseNft(
        address nftAddress,
        uint256 nftTokenId,
        address to
    ) internal {
        IERC721(nftAddress).transferFrom(address(this), to, nftTokenId);

        require(
            IERC721(nftAddress).ownerOf(nftTokenId) == address(this),
            "NFT transfer failed"
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";

import "./Market.sol";

contract OfferMarket is Market {
    // nftAddress => nftTokenId => offerer => Offer
    mapping(address => mapping(uint256 => mapping(address => Offer)))
        private _offers;

    struct Offer {
        address paymentToken;
        uint256 price;
        uint64 endDate;
    }

    event NewOffer(
        address indexed nftAddress,
        uint256 indexed nftTokenId,
        address indexed offerer,
        address paymentToken,
        uint256 price,
        uint64 endDate
    );

    event OfferRemoved(
        address indexed nftAddress,
        uint256 indexed nftTokenId,
        address indexed offerer
    );

    event OfferAccepted(
        address indexed nftAddress,
        uint256 indexed nftTokenId,
        address indexed offerer,
        address paymentToken,
        uint256 price
    );

    constructor(uint32 fee_) Market(fee_) {}

    function addForSale(
        address nftAddress,
        uint256 nftTokenId
    ) external onlyNftOwner(nftAddress, nftTokenId) {
        _addNftForSale(nftAddress, nftTokenId, msg.sender);
    }

    function setOffer(
        address nftAddress,
        uint256 nftTokenId,
        address paymentToken,
        uint256 price,
        uint64 endDate
    ) external onlySellingNft(nftAddress, nftTokenId) {
        _offers[nftAddress][nftTokenId][msg.sender] = Offer({
            paymentToken: paymentToken,
            price: price,
            endDate: endDate
        });

        emit NewOffer(
            nftAddress,
            nftTokenId,
            msg.sender,
            paymentToken,
            price,
            endDate
        );
    }

    function removeOffer(address nftAddress, uint256 nftTokenId) external {
        delete _offers[nftAddress][nftTokenId][msg.sender];
        emit OfferRemoved(nftAddress, nftTokenId, msg.sender);
    }

    function acceptOffer(
        address nftAddress,
        uint256 nftTokenId,
        address offerer
    ) external onlySeller(nftAddress, nftTokenId) {
        address paymentToken = _offers[nftAddress][nftTokenId][offerer]
            .paymentToken;
        uint256 price = _offers[nftAddress][nftTokenId][offerer].price;

        if (paymentToken == address(0)) {
            _sellNft(nftAddress, nftTokenId, offerer, price);
        } else {
            _sellNft(nftAddress, nftTokenId, offerer, paymentToken, price);
        }

        delete _offers[nftAddress][nftTokenId][offerer];

        emit OfferAccepted(
            nftAddress,
            nftTokenId,
            offerer,
            paymentToken,
            price
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Payable is Ownable {
    mapping(address => uint256) private _etherFunds;
    mapping(address => mapping(address => uint256)) private _tokenFunds;

    mapping(address => bool) private _acceptedTokens;

    event WithdrawEther(address indexed to, uint256 amount);
    event WithdrawEtherFailed(address indexed to, uint256 amount);
    event WithdrawToken(
        address indexed token,
        address indexed to,
        uint256 amount
    );
    event WithdrawTokenFailed(
        address indexed token,
        address indexed to,
        uint256 amount
    );

    modifier onlyAcceptedToken(address token) {
        if (token != address(0)) {
            require(_isTokenAccepted(token), "token not accepted");
        }
        _;
    }

    function _isTokenAccepted(address token) internal view returns (bool) {
        return _acceptedTokens[token];
    }

    function _storeToken(address token, address from, uint256 amount) internal {
        bool success = IERC20(token).transferFrom(from, address(this), amount);
        require(success, "failed to transfer tokens");
    }

    function _sendEther(address payable to, uint256 amount) internal {
        _etherFunds[to] += amount;
        (bool success, ) = to.call{value: amount}("");

        if (success) {
            _etherFunds[to] -= amount;
            emit WithdrawEther(to, amount);
        } else {
            emit WithdrawEtherFailed(to, amount);
        }
    }

    function _sendToken(address token, address to, uint256 amount) internal {
        _tokenFunds[token][to] += amount;
        bool success = IERC20(token).transferFrom(address(this), to, amount);

        if (success) {
            _tokenFunds[token][to] -= amount;
            emit WithdrawToken(token, to, amount);
        } else {
            emit WithdrawTokenFailed(token, to, amount);
        }
    }

    function _getEtherBalance() internal view returns (uint256) {
        return address(this).balance;
    }

    function _getTokenBalance(address token) internal view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    function addToken(address tokenAddress) external onlyOwner {
        _acceptedTokens[tokenAddress] = true;
    }

    function removeToken(address tokenAddress) external onlyOwner {
        _acceptedTokens[tokenAddress] = false;
    }

    function isTokenAccepted(address token) external view returns (bool) {
        return _isTokenAccepted(token);
    }

    function etherFundsOf(address owner) external view returns (uint256) {
        return _etherFunds[owner];
    }

    function tokenFundsOf(
        address token,
        address owner
    ) external view onlyAcceptedToken(token) returns (uint256) {
        return _tokenFunds[token][owner];
    }

    function withdrawEther() external {
        uint256 amount = _etherFunds[msg.sender];
        _etherFunds[msg.sender] = 0;
        _sendEther(payable(msg.sender), amount);
    }

    function withdrawTokens(address token) external onlyAcceptedToken(token) {
        uint256 amount = _tokenFunds[token][msg.sender];
        _tokenFunds[token][msg.sender] = 0;
        _sendToken(token, msg.sender, amount);
    }

    function sendEther(address payable to, uint256 amount) external onlyOwner {
        _sendEther(to, amount);
    }

    function sendToken(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner onlyAcceptedToken(token) {
        _sendToken(token, to, amount);
    }

    function storeToken(
        address token,
        address from,
        uint256 amount
    ) external onlyOwner onlyAcceptedToken(token) {
        _storeToken(token, from, amount);
    }

    function getEtherBalance() external view onlyOwner returns (uint256) {
        return _getEtherBalance();
    }

    function getTokenBalance(
        address token
    ) external view onlyOwner onlyAcceptedToken(token) returns (uint256) {
        return _getTokenBalance(token);
    }
}