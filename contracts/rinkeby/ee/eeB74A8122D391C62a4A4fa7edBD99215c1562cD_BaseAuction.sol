// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BaseAuction is Ownable, Pausable {
  uint256 public immutable increaseByBid;
  uint256 public immutable minIncreaseBid;
  uint256 public immutable minStartingBid;

  uint32 public endTime;
  address payable private beneficiary;

  event StartAuctionEvent();
  event CloseAuctionEvent();
  event SubmitBidEvent(address indexed bidder, uint256 newBidPrice);
  event RefundEvent(address indexed bidder, uint256 bidRefund);
  event WithdrawEvent(uint256 amount);
  event EndTimeEvent(uint32 endTime);
  event BeneficiaryEvent(address beneficiary);

  error InvalidState(State state);
  error TooLate(uint32 time);
  error TooEarly(uint32 time);

  enum State { Inactive, Active, Closed }

  State public state = State.Inactive;

  modifier inState(State _state) {
    if (state != _state) revert InvalidState(state);
    _;
  }

  modifier onlyBefore(uint32 _time) {
    if (block.timestamp >= _time) revert TooLate(_time);
    _;
  }

  modifier onlyAfter(uint32 _time) {
    if (block.timestamp < _time) revert TooEarly(_time);
    _;
  }

  mapping(address => uint256) private bids;

  /**
  * @param _beneficiary beneficiary address
  * @param _minStartingBid the minimum to start a bid
  * @param _minIncreaseBid the minimumin to increase a bid
  * @param _increaseByBid the requirement to increase a bid by
  * @param _endTime time to end auction
  */
  constructor(
    address payable _beneficiary,
    uint256 _minStartingBid,
    uint256 _minIncreaseBid,
    uint256 _increaseByBid,
    uint32 _endTime
  ) {
    require(_beneficiary != address(0), "Invalid address for beneficiary");
    require(_minStartingBid % _increaseByBid == 0, "_minStartingBid isn't a multiple of _increaseByBid");
    require(_minIncreaseBid % _increaseByBid == 0, "_minIncreaseBid isn't a multiple of _increaseByBid");
    require(block.timestamp < _endTime, "Can't set endtime in the past");

    beneficiary = _beneficiary;
    minStartingBid = _minStartingBid;
    minIncreaseBid = _minIncreaseBid;
    increaseByBid = _increaseByBid;
    endTime = _endTime;
  }

  /**
  * @dev See {Pausable-pause}.
  */
  function pause() public onlyOwner {
    _pause();
  }

  /**
  * @dev See {Pausable-unpause}.
  */
  function unpause() public onlyOwner {
    _unpause();
  }

  /**
  * @dev Sets the auction's end time
  * @param _endTime time to end auction
  */
  function setEndTime(uint32 _endTime) external onlyOwner {
    require(block.timestamp < _endTime, "Can't set endtime in the past");
    endTime = _endTime;

    emit EndTimeEvent(_endTime);
  }

  /**
  * @dev Sets the auction's beneficiary address
  * @param _beneficiary beneficiary of auction
  */
  function setBeneficiary(address payable _beneficiary) external onlyOwner {
    require(_beneficiary != address(0), "Invalid address for beneficiary");
    beneficiary = _beneficiary;

    emit BeneficiaryEvent(_beneficiary);
  }

  /// @dev Start auction
  function startAuction() external onlyOwner inState(State.Inactive) onlyBefore(endTime) {
    state = State.Active;
    emit StartAuctionEvent();
  }

  /// @dev Close auction
  function closeAuction() external onlyOwner inState(State.Active) onlyAfter(endTime) {
    state = State.Closed;
    emit CloseAuctionEvent();
  }

  /**
  * @notice Get bidder's current bid amount
  * @param _bidder the bidder's address
  */
  function getBid(address _bidder) external view returns (uint256) {
    return bids[_bidder];
  }

  /// @notice Submit bid
  function submitBid() external payable whenNotPaused inState(State.Active) {
    require(msg.value >= minIncreaseBid, "Bid has to be higher than minimum increase");
    uint256 currBidPrice = bids[msg.sender];
    uint256 newBidPrice = currBidPrice + msg.value;

    require(newBidPrice >= minStartingBid, "Bid doesn't meet minimum requirement");
    require(newBidPrice % increaseByBid == 0, "Bid doesn't meet increase requirement");
    require(newBidPrice > currBidPrice, "New bid shouldn't be equal to the current bid");

    bids[msg.sender] = newBidPrice;

    emit SubmitBidEvent(msg.sender, newBidPrice);
  }

  /**
  * @dev Refund bidders that did not place on leaderboard
  * @param _bidders list of addresses to refund
  */
  function refund(address payable[] calldata _bidders) external onlyOwner inState(State.Closed) {
    for (uint256 i = 0; i < _bidders.length; i++) {
      address payable bidder = _bidders[i];
      uint256 bidRefund = bids[bidder];
      require(bidRefund > 0, "Bidder doesn't have refund");
      bids[bidder] = 0;

      (bool success, ) = bidder.call{value: bidRefund}("");
      require(success, "Refund has failed");
      emit RefundEvent(bidder, bidRefund);
    }
  }

  /// @dev contract receives ether
  receive() external payable {
    require(msg.sender == owner() || msg.sender == beneficiary, "Must be owner or beneficiary");
  }

  /// @dev beneficiary can withdraw balance
  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    (bool success,) = beneficiary.call{value: balance}("");
    require(success, "Failed to withdraw ether");
    emit WithdrawEvent(balance);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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