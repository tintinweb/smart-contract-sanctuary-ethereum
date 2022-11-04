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

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error AuctionNotLive();
error ReservePriceNotMet();
error IncrementalPriceNotMet();
error AuctionStillLive();
error WithdrawFailed();
error NotTopBidder();

contract RareAuction is Ownable, ReentrancyGuard {
  struct Bid {
    address bidder;
    uint256 amount;
  }

  event NewBid(address bidder, uint256 value);
  event BidIncreased(address bidder, uint256 oldValue, uint256 newValue);
  event AuctionExtended();

  // The name of the auctioned item
  string public auctionItem;
  // The current winning bid
  Bid public topBid;

  // The minimum amount of time left in an auction after a new bid is created
  uint256 public timeBuffer;
  // The minimum price accepted in an auction
  uint256 public reservePrice;
  // The minimum percentage difference between the last bid amount and the current bid
  uint256 public minBidIncrementPercentage;
  // The start time of the auction
  uint256 public startTime;
  // The end time of the auction
  uint256 public endTime;

  constructor(
    string memory _auctionItem,
    uint256 _timeBuffer,
    uint256 _reservePrice,
    uint256 _minBidIncrementPercentage,
    uint256 _startTime,
    uint256 _endTime
  ) payable {
    auctionItem = _auctionItem;
    timeBuffer = _timeBuffer;
    reservePrice = _reservePrice;
    minBidIncrementPercentage = _minBidIncrementPercentage;
    startTime = _startTime;
    endTime = _endTime;
  }

  /**
   * @notice Record a new bid
   * @dev This function add a new top bid and refunds the current winner
   */
  function bid() public payable nonReentrant {
    if (msg.value < reservePrice) {
      revert ReservePriceNotMet();
    }

    if (block.timestamp < startTime || block.timestamp > endTime) {
      revert AuctionNotLive();
    }

    if (
      msg.value <
      topBid.amount + (topBid.amount * minBidIncrementPercentage) / 100
    ) {
      revert IncrementalPriceNotMet();
    } else {
      // Check if the top bidder exist and refund the top bidder
      if (topBid.amount > 0) {
        _transferETH(topBid.bidder, topBid.amount);
      }
      // Record the new bid
      topBid.bidder = msg.sender;
      topBid.amount = msg.value;
      emit NewBid(topBid.bidder, topBid.amount);

      // Extend the auction if the bid was received within `timeBuffer` of the auction end time
      if (endTime - block.timestamp < timeBuffer) {
        endTime = block.timestamp + timeBuffer;
        emit AuctionExtended();
      }
    }
  }

  /**
   * @notice Increase the bid of the current top bidder
   * @dev This function increases the bid of the current top bidder as long as the auction is still live
   */
  function increaseBid() public payable nonReentrant {
    if (block.timestamp < startTime || block.timestamp > endTime) {
      revert AuctionNotLive();
    }

    if (msg.sender != topBid.bidder) {
      revert NotTopBidder();
    }

    if (msg.value < (topBid.amount * minBidIncrementPercentage) / 100) {
      revert IncrementalPriceNotMet();
    } else {
      topBid.amount += msg.value;
      emit BidIncreased(msg.sender, topBid.amount - msg.value, topBid.amount);
    }
  }

  /**
   * @notice Transfer ETH to a specified address.
   * @dev This function can only be called internally.
   */
  function _transferETH(address to, uint256 value) internal returns (bool) {
    (bool success, ) = to.call{value: value, gas: 30000}(new bytes(0));
    return success;
  }

  /**
   * @notice Withdraw the contract ETH to the owner. 
   * @dev This function is only called by the owner.
   */
  function withdraw() external onlyOwner {
    if (block.timestamp > endTime) {
      bool success = _transferETH(msg.sender, address(this).balance);
      if (!success) {
        revert WithdrawFailed();
      }
    } else {
      revert AuctionStillLive();
    }
  }
}