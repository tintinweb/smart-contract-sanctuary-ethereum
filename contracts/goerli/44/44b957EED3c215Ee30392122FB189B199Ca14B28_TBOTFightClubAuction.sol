// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// import "hardhat/console.sol";

contract TBOTFightClubAuction is Ownable, Pausable, ReentrancyGuard {
  event Bid(address indexed account, uint256 amount);

  /// @dev Compiler will pack this into a single 256bit word.
  struct BidderInfo {
    // bidValue . max bidValue is 2^224 (2.69e49) ether is enough for reality
    uint224 bidValue;
    // index of bidder in _bidderArr . 4e9 bidder is enough for reality
    uint32 bidderArrIndex;
  }

  string public constant VERSION = "1.0.0";

  uint256 public startPrice;

  uint64 public decimals;

  address payable public tkxWallet;

  /// @notice startAuctionTime unit second
  /// @return startAuctionTime unit second
  uint64 public startAuctionTime;
  /// @notice endAuctionTime unit second
  /// @return endAuctionTime unit second
  uint64 public endAuctionTime;

  mapping(address => BidderInfo) private _bidByAddressMapping;

  /// @notice max length allow is 2^32 (4e9). coz we process index as uint32
  address[] private _bidderArr;

  /// @notice 2^32 (4e9) bidder is enough for reality .
  ///         value type(uint32).max as empty slot (because index value start from 0)
  uint32[4] private _topBidderIndexArr;

  /// @notice constructor
  /// @dev Explain to a developer any extra details
  /// @param startPrice_ : start price for auction
  /// @param decimals_ : decimals allow for bid value
  /// @param tkxWallet_ : wallet that will be receiver every bid amount
  /// @param startAuctionTime_  : time to start auction
  /// @param endAuctionTime_ : time to end auction
  constructor(
    uint256 startPrice_,
    uint64 decimals_,
    address payable tkxWallet_,
    uint64 startAuctionTime_,
    uint64 endAuctionTime_
  ) {
    require(tkxWallet_ != address(0));

    startPrice = startPrice_;
    decimals = decimals_;
    tkxWallet = tkxWallet_;
    startAuctionTime = startAuctionTime_;
    endAuctionTime = endAuctionTime_;
    // init _topBidderIndexArr
    _topBidderIndexArr[0] = type(uint32).max;
    _topBidderIndexArr[1] = type(uint32).max;
    _topBidderIndexArr[2] = type(uint32).max;
    _topBidderIndexArr[3] = type(uint32).max;
  }

  modifier whenAuctionActive() {
    require(block.timestamp >= startAuctionTime && block.timestamp <= endAuctionTime, "Auction is not active");
    _;
  }

  /************************
   * @dev for pause
   */

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  /********************
   *
   */

  function setTime(uint64 startAuctionTime_, uint64 endAuctionTime_) external onlyOwner {
    startAuctionTime = startAuctionTime_;
    endAuctionTime = endAuctionTime_;
  }

  function setStartPrice(uint256 startPrice_, uint64 decimals_) external onlyOwner {
    startPrice = startPrice_;
    decimals = decimals_;
  }

  function setTkxWallet(address payable tkxWallet_) external onlyOwner {
    tkxWallet = tkxWallet_;
  }

  /***********************
   * @dev for bid function
   */

  /// @notice Get bidValue of bidder address
  /// @param bidder : bidder address
  /// @return bidValue : bidValue of bidder
  function getBidOfAddress(address bidder) external view returns (uint256) {
    return _bidByAddressMapping[bidder].bidValue;
  }

  /// @notice Use to get all top 4 bidder belong with bidValue
  /// @return bidderArr : array of bidder address
  /// @return bidValueArr : array of bidValue belong with bidderArr
  function getTopBidder() external view returns (address[4] memory bidderArr, uint256[4] memory bidValueArr) {
    for (uint256 index = 0; index < _topBidderIndexArr.length; index++) {
      if (_topBidderIndexArr[index] == type(uint32).max) {
        bidderArr[index] = address(0);
        bidValueArr[index] = 0;
      } else {
        bidderArr[index] = _bidderArr[_topBidderIndexArr[index]];
        bidValueArr[index] = _bidByAddressMapping[bidderArr[index]].bidValue;
      }
    }
  }

  /// @notice Use to get all bidder and bidValue
  /// @param skip : skip number of bidder
  /// @param limit : limit number of bidder return
  /// @return bidderArr : array of bidder address
  /// @return bidValueArr : array of bidValue belong with bidderArr
  function getBidders(uint32 skip, uint32 limit) external view returns (address[] memory, uint256[] memory) {
    uint256 endIndex = _bidderArr.length;
    if (limit > 0 && (skip + limit) < endIndex) {
      endIndex = skip + limit;
    }

    address[] memory bidderArr = new address[](endIndex - skip);
    uint256[] memory bidValueArr = new uint256[](endIndex - skip);

    for (uint256 index = skip; index < endIndex; index++) {
      bidderArr[index - skip] = _bidderArr[index];
      bidValueArr[index - skip] = _bidByAddressMapping[_bidderArr[index]].bidValue;
    }

    return (bidderArr, bidValueArr);
  }

  /// @notice getTotalBidder
  /// @return totalBidder total bidder
  function getTotalBidder() external view returns (uint256 totalBidder) {
    return _bidderArr.length;
  }

  /// @notice
  /// @dev
  function bid() external payable nonReentrant whenNotPaused whenAuctionActive {
    if (_bidByAddressMapping[msg.sender].bidValue == 0) {
      require(msg.value >= startPrice, "Bid value must lagger start price");
    }
    require((msg.value % (10**(18 - decimals))) == 0, "Not correct decimals");
    require(msg.value <= type(uint224).max, "You bid too much money");
    require(_bidderArr.length < type(uint32).max, "Can not bid anymore");

    //
    // update bid info
    //
    if (_bidByAddressMapping[msg.sender].bidValue == 0) {
      _bidByAddressMapping[msg.sender].bidderArrIndex = uint32(_bidderArr.length);
      _bidderArr.push(msg.sender);
    }

    // overflow bidValue 2^224 is not reality
    _bidByAddressMapping[msg.sender].bidValue += uint224(msg.value);

    //
    // process top bid
    //

    uint32 currentBidderIndex = _bidByAddressMapping[msg.sender].bidderArrIndex;
    uint224 currentBidValue = _bidByAddressMapping[msg.sender].bidValue;

    for (uint256 index = 0; index < _topBidderIndexArr.length; index++) {
      uint32 currentTopIndex = _topBidderIndexArr[index];
      if (currentTopIndex == type(uint32).max) {
        // empty slot => record current bidder is top and break
        _topBidderIndexArr[index] = currentBidderIndex;
        break;
      }

      if (
        currentBidValue > _bidByAddressMapping[_bidderArr[currentTopIndex]].bidValue &&
        _topBidderIndexArr[index] != currentBidderIndex
      ) {
        // current bidder lagger than current top => insert current bidder in here and shift right other top bidder
        uint32 tmpIndex = _topBidderIndexArr[index];
        _topBidderIndexArr[index] = currentBidderIndex;

        // clear current position in _topBidderIndexArr of currentBidderIndex
        for (
          uint256 indexClearDuplicated = index + 1;
          indexClearDuplicated < _topBidderIndexArr.length;
          indexClearDuplicated++
        ) {
          if (currentBidderIndex == _topBidderIndexArr[indexClearDuplicated]) {
            _topBidderIndexArr[indexClearDuplicated] = type(uint32).max;
            break;
          }
        }

        currentBidderIndex = tmpIndex;
        currentBidValue = _bidByAddressMapping[_bidderArr[currentBidderIndex]].bidValue;
      } else if (_topBidderIndexArr[index] == currentBidderIndex) {
        // if currentBidder is existed in top list at correct position => break;
        break;
      }
    }

    emit Bid(msg.sender, _bidByAddressMapping[msg.sender].bidValue);

    // transfer balance to tkxWallet
    payable(tkxWallet).transfer(msg.value);
  }
}

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