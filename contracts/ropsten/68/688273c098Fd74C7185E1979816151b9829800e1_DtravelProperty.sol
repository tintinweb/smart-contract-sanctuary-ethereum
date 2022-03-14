// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./DtravelConfig.sol";

struct Booking {
    uint256 id;
    uint256 checkInTimestamp;
    uint256 checkOutTimestamp;
    uint256 paidAmount;
    address guest;
    address token;
    uint8 status; // 0: in_progress, 1: fulfilled, 2: cancelled, 3: emergency cancelled
}

contract DtravelProperty is
    Ownable,
    ReentrancyGuard // The contract deployment will be triggered by the host so owner() will return the host's wallet address.
{
    uint256 public id; // property id
    uint256 public price; // property price
    uint256 public cancelPeriod; // cancellation period
    Booking[] public bookings; // bookings array
    mapping(uint256 => bool) public propertyFilled; // timestamp => bool, false: vacant, true: filled
    DtravelConfig configContract;

    event Fulfilled(
        uint256 bookingId,
        address indexed host,
        address indexed dtravelTreasury,
        uint256 amountForHost,
        uint256 amountForDtravel,
        uint256 fulFilledTime
    );
    event Book(uint256 bookingId, uint256 bookedTimestamp);
    event Cancel(uint256 bookingId, bool isHost, uint256 cancelledTimestamp);
    event EmergencyCancel(uint256 bookingId, uint256 cancelledTimestamp);

    constructor(
        uint256 _id,
        uint256 _price,
        uint256 _cancelPeriod,
        address _config
    ) {
        id = _id;
        price = _price;
        cancelPeriod = _cancelPeriod;
        configContract = DtravelConfig(_config);
    }

    modifier onlyBackend() {
        require(
            msg.sender == configContract.dtravelBackend(),
            "Only Dtravel backend is authorized to call this action"
        );

        _;
    }

    function updatePrice(uint256 _price) external onlyOwner {
        require(_price > 0, "Price must be over 0");
        price = _price;
    }

    function updateCancelPeriod(uint256 _cancelPeriod) external onlyOwner {
        require(_cancelPeriod > 0, "Cancel Period must be over 0");
        cancelPeriod = _cancelPeriod;
    }

    function updatePropertyFilled(uint256[] memory _dates, bool _status) external onlyOwner {
        for (uint256 i = 0; i < _dates.length; i++) {
            propertyFilled[_dates[i]] = _status;
        }
    }

    /* @TODO: Add another method to update propertyFilled with start timestamp and number of days */

    function propertyAvailable(uint256 _checkInTimestamp, uint256 _checkOutTimestamp) public view returns (bool) {
        uint256 time = _checkInTimestamp;
        while (time < _checkOutTimestamp) {
            if (propertyFilled[time] == true) return false;
            time += 1 days;
        }
        return true;
    }

    function book(
        address _token,
        uint256 _checkInTimestamp,
        uint256 _checkOutTimestamp,
        uint256 _bookingAmount
    ) external nonReentrant {
        // Remove onlyBackend modifier for demo
        // ) external nonReentrant onlyBackend {
        require(configContract.supportedTokens(_token) == true, "Token is not whitelisted");
        require(_checkInTimestamp > block.timestamp, "Booking for past date is not allowed");
        require(_checkOutTimestamp >= _checkInTimestamp + 1 days, "Booking period should be at least one night");
        bool isPropertyAvailable = propertyAvailable(_checkInTimestamp, _checkOutTimestamp);
        require(isPropertyAvailable == true, "Property is not available");
        require(IERC20(_token).allowance(msg.sender, address(this)) >= _bookingAmount, "Token allowance too low");
        bool isSuccess = _safeTransferFrom(IERC20(_token), msg.sender, address(this), _bookingAmount);
        require(isSuccess == true, "Payment failed");

        uint256 bookingId = bookings.length;
        bookings.push(Booking(bookingId, _checkInTimestamp, _checkOutTimestamp, _bookingAmount, msg.sender, _token, 0));
        updateBookingStatus(bookingId, 0);

        emit Book(bookingId, block.timestamp);
    }

    function updateBookingStatus(uint256 _bookingId, uint8 _status) internal {
        require(_status <= 3, "Invalid booking status");
        require(_bookingId >= 0 && _bookingId < bookings.length, "Booking not found");

        Booking memory booking = bookings[_bookingId];
        uint256 time = booking.checkInTimestamp;
        uint256 checkoutTimestamp = booking.checkOutTimestamp;
        while (time < checkoutTimestamp) {
            propertyFilled[time] = true;
            time += 1 days;
        }

        bookings[_bookingId].status = _status;
    }

    function cancel(uint256 _bookingId) external nonReentrant {
        require(_bookingId <= bookings.length, "Booking not found");
        Booking memory booking = bookings[_bookingId];
        require(booking.status == 0, "Booking is already cancelled or fulfilled");
        require(
            msg.sender == owner() || msg.sender == booking.guest,
            "Only host or guest is authorized to call this action"
        );
        require(block.timestamp < booking.checkInTimestamp - cancelPeriod, "Cancellation period is over");

        updateBookingStatus(_bookingId, 2);

        // Refund to the guest

        bool isSuccess = IERC20(booking.token).transfer(booking.guest, booking.paidAmount);
        require(isSuccess == true, "Refund failed");

        emit Cancel(_bookingId, msg.sender == owner(), block.timestamp);
    }

    function emergencyCancel(uint256 _bookingId) external onlyBackend nonReentrant {
        require(_bookingId <= bookings.length, "Booking not found");
        Booking memory booking = bookings[_bookingId];
        require(booking.status == 0, "Booking is already cancelled or fulfilled");

        updateBookingStatus(_bookingId, 3);

        // Refund to the guest

        bool isSuccess = IERC20(booking.token).transfer(booking.guest, booking.paidAmount);
        require(isSuccess == true, "Refund failed");

        emit EmergencyCancel(_bookingId, block.timestamp);
    }

    function fulfill(uint256 _bookingId) external nonReentrant {
        require(_bookingId <= bookings.length, "Booking not found");
        Booking memory booking = bookings[_bookingId];
        require(booking.status == 0, "Booking is already cancelled or fulfilled");
        require(block.timestamp >= booking.checkOutTimestamp, "Booking can be fulfilled only after the checkout date");

        updateBookingStatus(_bookingId, 1);

        // Split the payment

        address host = owner();
        address dtravelTreasury = configContract.dtravelTreasury();
        uint256 paidAmount = booking.paidAmount;
        uint256 fee = configContract.fee();
        uint256 amountForHost = (paidAmount * (100 - fee)) / 100;
        uint256 amountForDtravel = paidAmount - amountForHost;

        IERC20(booking.token).transfer(host, amountForHost);
        IERC20(booking.token).transfer(dtravelTreasury, amountForDtravel);

        emit Fulfilled(_bookingId, host, dtravelTreasury, amountForHost, amountForDtravel, block.timestamp);
    }

    function bookingHistory() external view returns (Booking[] memory) {
        return bookings;
    }

    function _safeTransferFrom(
        IERC20 token,
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        bool sent = token.transferFrom(sender, recipient, amount);
        return sent;
    }
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract DtravelConfig is Ownable {
    uint256 public fee; // fee percentage 5% -> 500, 0.1% -> 10
    address public dtravelTreasury;
    address public dtravelBackend;
    mapping(address => bool) public supportedTokens;

    constructor(uint256 _fee, address _vault, address[] memory _tokens) {
        fee = _fee;
        dtravelTreasury = _vault;
        dtravelBackend = msg.sender;
        for(uint i = 0;i < _tokens.length;i++) {
            supportedTokens[_tokens[i]] = true;
        }
    }

    function updateFee(uint256 _fee) public onlyOwner {
        require(_fee >= 0 && _fee <= 10000, "Fee must be between 0 and 10000");
        fee = _fee;
    }

    function addSupportedToken(address _token) public onlyOwner {
        supportedTokens[_token] = true;
    }

    function removeSupportedToken(address _token) public onlyOwner {
        supportedTokens[_token] = false;
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