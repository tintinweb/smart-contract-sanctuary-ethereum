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

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error AuctionNotInitialized();
error AuctionNotLive();
error ReservePriceNotMet();
error WithdrawFailed();
error BidIncrementTooLow();
error NotEOA();

contract AuctionHouse is Ownable, ReentrancyGuard {
    struct Bid {
        address bidder;
        uint192 amount;
        uint64 bidTime;
    }

    struct BidIndex {
        uint8 index;
        bool isSet;
    }

    event NewBid(address bidder, uint256 value);
    event BidIncreased(address bidder, uint256 oldValue, uint256 increment);
    event AuctionExtended();

    // The max number of top bids the auction will accept
    uint256 public constant MAX_NUM_BIDS = 5;

    // The minimum amount of time left in an auction after a new bid is created
    uint256 public timeBuffer;

    // The minimum price accepted in an auction
    uint256 public reservePrice;

    // The minimum amount a user needs to submit for a stacked bid
    uint256 public minStackedBidIncrement;

    // The start time of the auction
    uint256 public startTime;

    // The end time of the auction
    uint256 public endTime;

    // The current highest bids made in the auction
    Bid[MAX_NUM_BIDS] public activeBids;

    // The mapping between an address and its active bid. The isSet flag differentiates the default
    // uint value 0 from an actual 0 value.
    mapping(address => BidIndex) public bidIndexes;

    constructor(
        uint256 _timeBuffer,
        uint256 _reservePrice,
        uint256 _minStackedBidIncrement,
        uint256 _startTime,
        uint256 _endTime
    ) {
        timeBuffer = _timeBuffer;
        reservePrice = _reservePrice;
        minStackedBidIncrement = _minStackedBidIncrement;
        startTime = _startTime;
        endTime = _endTime;
    }

    modifier onlyEOA() {
        if (tx.origin != msg.sender) {
            revert NotEOA();
        }
        _;
    }

    /**
     * @notice Handle users' bids
     * @dev Bids must be made while the auction is live. Bids must meet a minimum reserve price.
     *
     * The first 8 bids made will be accepted as valid. Subsequent bids must be a percentage
     * higher than the lowest of the 8 active bids. When a low bid is replaced, the ETH will
     * be refunded back to the original bidder.
     *
     * If a valid bid comes in within the last `timeBuffer` seconds, the auction will be extended
     * for another `timeBuffer` seconds. This will continue until no new active bids come in.
     *
     * If a wallet makes a bid while it still has an active bid, the second bid will
     * stack on top of the first bid. If the second bid doesn't meet the `minStackedBidIncrement`
     * threshold, an error will be thrown. A wallet will only have one active bid at at time.
     */
    function bid() public payable nonReentrant onlyEOA {
        if (startTime == 0 || endTime == 0) {
            revert AuctionNotInitialized();
        }
        if (block.timestamp < startTime || block.timestamp > endTime) {
            revert AuctionNotLive();
        }

        BidIndex memory existingIndex = bidIndexes[msg.sender];
        if (existingIndex.isSet) {
            // Case when the user already has an active bid
            if (msg.value < minStackedBidIncrement || msg.value == 0) {
                revert BidIncrementTooLow();
            }

            uint192 oldValue = activeBids[existingIndex.index].amount;
            unchecked {
                activeBids[existingIndex.index].amount =
                    oldValue +
                    uint192(msg.value);
            }
            activeBids[existingIndex.index].bidTime = uint64(block.timestamp);

            emit BidIncreased(msg.sender, oldValue, msg.value);
        } else {
            if (msg.value < reservePrice || msg.value == 0) {
                revert ReservePriceNotMet();
            }

            uint8 lowestBidIndex = getBidIndexToUpdate();
            uint256 lowestBidAmount = activeBids[lowestBidIndex].amount;
            address lowestBidder = activeBids[lowestBidIndex].bidder;

            unchecked {
                if (msg.value < lowestBidAmount + minStackedBidIncrement) {
                    revert BidIncrementTooLow();
                }
            }

            // Refund lowest bidder and remove bidIndexes entry
            if (lowestBidder != address(0)) {
                delete bidIndexes[lowestBidder];
                _transferETH(lowestBidder, lowestBidAmount);
            }

            activeBids[lowestBidIndex] = Bid({
                bidder: msg.sender,
                amount: uint192(msg.value),
                bidTime: uint64(block.timestamp)
            });

            bidIndexes[msg.sender] = BidIndex({
                index: lowestBidIndex,
                isSet: true
            });

            emit NewBid(msg.sender, msg.value);
        }

        // Extend the auction if the bid was received within `timeBuffer` of the auction end time
        if (endTime - block.timestamp < timeBuffer) {
            unchecked {
                endTime = block.timestamp + timeBuffer;
            }
            emit AuctionExtended();
        }
    }

    /**
     * @notice Gets the index of the entry in activeBids to update
     * @dev The index to return will be decided by the following rules:
     * If there are less than MAX_NUM_BIDS bids, the index of the first empty slot is returned.
     * If there are MAX_NUM_BIDS or more bids, the index of the lowest value bid is returned. If
     * there is a tie, the most recent bid with the low amount will be returned. If there is a tie
     * among bidTimes, the highest index is chosen.
     */
    function getBidIndexToUpdate() public view returns (uint8) {
        uint256 minAmount = activeBids[0].amount;
        // If the first value is 0 then we can assume that no bids have been submitted
        if (minAmount == 0) {
            return 0;
        }

        uint8 minIndex = 0;
        uint64 minBidTime = activeBids[0].bidTime;

        for (uint8 i = 1; i < MAX_NUM_BIDS; ) {
            uint256 bidAmount = activeBids[i].amount;
            uint64 bidTime = activeBids[i].bidTime;

            // A zero bidAmount means the slot is empty because we enforce non-zero bid amounts
            if (bidAmount == 0) {
                return i;
            } else if (
                bidAmount < minAmount ||
                (bidAmount == minAmount && bidTime >= minBidTime)
            ) {
                minAmount = bidAmount;
                minIndex = i;
                minBidTime = bidTime;
            }

            unchecked {
                ++i;
            }
        }

        return minIndex;
    }

    /**
     * @notice Get all active bids.
     * @dev Useful for ethers client to get the entire array at once.
     */
    function getAllActiveBids()
        external
        view
        returns (Bid[MAX_NUM_BIDS] memory)
    {
        return activeBids;
    }

    /**
     * @notice Transfers ETH to a specified address.
     * @dev This function can only be called internally.
     */
    function _transferETH(address to, uint256 value) internal returns (bool) {
        (bool success, ) = to.call{value: value, gas: 30000}(new bytes(0));
        return success;
    }

    /**
     * @notice Sets the start and end time of the auction.
     * @dev Only callable by the owner.
     */
    function setAuctionTimes(
        uint256 _startTime,
        uint256 _endTime
    ) external onlyOwner {
        startTime = _startTime;
        endTime = _endTime;
    }

    /**
     * @notice Set the auction time buffer.
     * @dev Only callable by the owner.
     */
    function setTimeBuffer(uint256 _timeBuffer) external onlyOwner {
        timeBuffer = _timeBuffer;
    }

    /**
     * @notice Set the auction reserve price.
     * @dev Only callable by the owner.
     */
    function setReservePrice(uint256 _reservePrice) external onlyOwner {
        reservePrice = _reservePrice;
    }

    /**
     * @notice Set the auction replacing bid buffer amount.
     * @dev Only callable by the owner.
     */
    function setMinReplacementIncrease(
        uint256 _minStackedBidIncrement
    ) external onlyOwner {
        minStackedBidIncrement = _minStackedBidIncrement;
    }

    /**
     * @notice Withdraws the contract value to the owner
     */
    function withdraw() external onlyOwner {
        bool success = _transferETH(msg.sender, address(this).balance);
        if (!success) {
            revert WithdrawFailed();
        }
    }
}