// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "./DtravelConfig.sol";

struct Booking {
  uint256 id;
  uint256 checkInTimestamp;
  uint256 checkOutTimestamp;
  uint256 paidAmount;
  address guest;
  address token;
}

contract DtravelProperty is Ownable {
  uint256 public id; // property id
  uint256 public price; // property price
  uint256 public cancelPeriod; // cancellation period
  Booking[] public bookings; // bookings array
  mapping(uint256 => bool) public filled; // timestamp => bool
  mapping(uint256 => uint8) public bookingStatus; // booking id => 0, 1, 2

  constructor(uint256 _id, uint256 _price, uint256 _cancelPeriod) {
    id = _id;
    price = _price;
    cancelPeriod = _cancelPeriod;
  }

  function updatePrice(uint256 _price) onlyOwner external {
    require(_price > 0, "Price must be over 0");
    price = _price;
  }

  function updateCancelPeriod(uint256 _cancelPeriod) onlyOwner external {
    require(_cancelPeriod > 0, "Cancel Period must be over 0");
    cancelPeriod = _cancelPeriod;
  }

  function propertyAvailable(uint256 _checkInTimestamp, uint256 _checkOutTimestamp ) view public returns(bool) {
    uint256 time = _checkInTimestamp;
    while (time < _checkOutTimestamp) {
      if (filled[time] == true)
        return false;
      time += 60 * 60 * 24;
    }
    return true;
  }

  function book(address _token, uint256 _checkInTimestamp, uint256 _checkOutTimestamp) external returns(bool, uint256) {
    require(_checkInTimestamp > block.timestamp, "Booking for past date is not allowed");
    require(_checkOutTimestamp > _checkInTimestamp + 60 * 60 * 24, "Booking period should be at least one night");
    bool isPropertyAvailable = propertyAvailable(_checkInTimestamp, _checkOutTimestamp);
    require(isPropertyAvailable == true, "Property is not available");
    uint256 bookingAmount = price * (_checkOutTimestamp - _checkInTimestamp) / (60 * 60 * 24);
    require(
          IERC20(_token).allowance(msg.sender, address(this)) >= bookingAmount,
          "Token allowance too low"
      );
    bool isSuccess = _safeTransferFrom(IERC20(_token), msg.sender, address(this), bookingAmount);
    require(isSuccess == true, "Payment failed");
    
    uint256 bookingId = bookings.length;
    uint256 time = _checkInTimestamp;
    while (time < _checkOutTimestamp) {
      filled[time] = true;
      time += 60 * 60 * 24;
    }
    bookingStatus[bookingId] = 0;
    bookings.push(Booking(bookingId, _checkInTimestamp, _checkOutTimestamp, bookingAmount, msg.sender, _token));

    return (isSuccess, bookingAmount);
  }

  function cancel(uint256 _bookingId, uint8 _cancelType) external returns(bool) {
    require(_bookingId <= bookings.length, "Booking not found");
    require(bookingStatus[_bookingId] == 0, "Booking is already cancelled or fulfilled");
    Booking memory booking = bookings[_bookingId];
    require(block.timestamp < booking.checkInTimestamp + cancelPeriod, "Booking has already expired the cancellation period");
    require(msg.sender == owner() || msg.sender == booking.guest, "You are not authorized to cancel this booking");
    
    bookingStatus[_bookingId] = _cancelType;

    uint256 time = booking.checkInTimestamp;
    uint256 checkOutTimestamp = booking.checkOutTimestamp;
    while (time < checkOutTimestamp) {
      filled[time] = false;
      time += 60 * 60 * 24;
    }

    // Refund to the guest

    bool isSuccess = _safeTransferFrom(IERC20(booking.token), address(this), booking.guest, booking.paidAmount);
    require(isSuccess == true, "Refund failed");

    return (isSuccess);
  }

  function bookingHistory() external view returns(Booking[] memory) {
    return bookings;
  }

  function _safeTransferFrom(
      IERC20 token,
      address sender,
      address recipient,
      uint amount
  ) internal returns(bool){
      bool sent = token.transferFrom(sender, recipient, amount);
      return sent;
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract DtravelConfig is Ownable {
    uint256 fee;
    mapping(address => bool) public supportedTokens;

    constructor(uint256 _fee, address[] memory _tokens) {
        fee = _fee;
        for(uint i = 0;i < _tokens.length;i++) {
            supportedTokens[_tokens[i]] = true;
        }
    }

    function updateFee(uint256 _fee) public onlyOwner {
        fee = _fee;
    }

    function addSupportedToken(address _token) public onlyOwner {
        supportedTokens[_token] = true;
    }

    function removeSupportedToken(address _token) public onlyOwner {
        supportedTokens[_token] = false;
    }
}

// struct Booking {
//     address customer;
//     uint256 checkInDate;
//     uint256 checkOutDate;   
// }

// contract Property {
//     address owner;
//     address host;
//     uint256 id;
//     uint256 price;
//     uint256 cancelPeriod;
//     uint8 status;
//     Booking[] bookings;

//     constructor(uint256 _id, uint256 _price, uint256 _cancelPeriod) {
//         owner = msg.sender;
//         id = _id;
//         price = _price;
//         cancelPeriod = _cancelPeriod;
//         status = 0;
//     }

//     function book(address _token, uint256 _amount) external returns (bool) {
//         // Transfer tokens from msg.sender to this contract
//         IERC20(_token).transferFrom(msg.sender, address(this), _amount);
//         status = 1; // Filled
//         return true; // success
//     }

//     function split() public view {
//         require(msg.sender == escrow, 'Unauthorized');

//         // Split the payment
//     }

//     function cancel() public view {
//         require(msg.sender == owner || msg.sender == customer, 'Unauthorized');

//         // Refund the money to msg.sender
//     }
// }

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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