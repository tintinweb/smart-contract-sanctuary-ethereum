/**
 *Submitted for verification at Etherscan.io on 2022-09-16
*/

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _notEntered will be true
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
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: @openzeppelin/contracts/interfaces/IERC20.sol

// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

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

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol

// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: staking.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract Staking is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeMath for uint16;

    struct User {
        uint256 totalInvested;
        uint256 totalWithdrawn;
        uint256 lastPayout;
        uint256 depositTime;
        uint256 totalClaimed;
    }

    struct Pool {
        uint256 apy;
        uint16 lockPeriodInDays;
        uint256 totalDeposit;
        uint256 startDate;
        uint256 endDate;
        uint256 minContrib;
    }

    IERC20 private token; //Token address

    address public reserveWallet; //Address which receives fee / Pays claim
    uint256 public depositFee;
    uint256 public withdrawFee;
   
    mapping(address => User) public users;
   

    Pool public pool;

    event Stake(address indexed addr, uint256 amount);
    event Claim(address indexed addr, uint256 amount);
    event Reinvest(address indexed addr, uint256 amount, uint256 time);

    constructor(
        address _token
    ) {
        token = IERC20(_token);
        reserveWallet = address(0x123);

        pool.apy = 365; // 1% per day
        pool.lockPeriodInDays = 7;
        pool.startDate = block.timestamp;
        pool.endDate = 1915433738; //Thu Sep 12 2030 08:55:38 GMT+0000
        pool.minContrib = 10000000000; //10 tokens

        depositFee = 10;
        withdrawFee = 10;
    }

    receive() external payable {
        revert("BNB deposit not supported");
    }

    /**
     *
     * @dev update the pool's Info
     *
     */
    function set(
        uint16 _apy,
        uint16 _lockPeriodInDays,
        uint256 _endDate,
        uint256 _minContrib
    ) public onlyOwner {
        pool.apy = _apy;
        pool.lockPeriodInDays = _lockPeriodInDays;
        pool.endDate = _endDate;
        pool.minContrib = _minContrib;
    }

    /**
     *
     * @dev depsoit tokens to staking for  allocation
     *
     * @param {_amount} Amount to be staked
     *
     * @return {bool} Status of stake
     *
     */
    function stake(uint256 _amount) external nonReentrant returns (bool) {
        require(_amount >= pool.minContrib, "Invalid amount!");

        require(
            token.allowance(msg.sender, address(this)) >= _amount,
            "Set allowance first!"
        );

        reinvest();

        bool success = token.transferFrom(msg.sender, address(this), _amount);
        require(success, "Transfer failed");
        
        uint256 fees = _amount.mul(depositFee).div(100);
        if (fees > 0){
            token.transfer(reserveWallet, fees);
        }

        _stake(msg.sender,  _amount.sub(fees));

        return success;
    }

    function reinvest() public  returns (bool) {
        uint256 amount = payout(msg.sender);
        if (amount > 0) {
            _stake(msg.sender, amount);
            emit Reinvest(msg.sender, amount, block.timestamp);
        }

        return true;
    }


    function _stake(address _sender, uint256 _amount) internal {
        User storage user = users[_sender];

        uint256 stopDepo = pool.endDate.sub(pool.lockPeriodInDays.mul(1 days));

        require(
            block.timestamp <= stopDepo,
            "Staking is disabled for this pool"
        );

        user.totalInvested = user.totalInvested.add(_amount);
        pool.totalDeposit = pool.totalDeposit.add(_amount);

        user.lastPayout = block.timestamp;
        user.depositTime = block.timestamp;

        emit Stake(_sender, _amount);
    }

    /**
     *
     * @dev claim accumulated  reward for a single pool
     *
     * @param {0} pool identifier
     *
     * @return {bool} status of claim
     */

    function claim() public nonReentrant returns (bool) {
        _claim(msg.sender);

        return true;
    }

    /**
     *
     * @dev check whether user can unstake or not
     *
     * @param {_addr} address of the user
     *
     * @return {bool} Status of claim
     *
     */

    function canUnstake(address _addr) public view returns (bool) {
        User storage user = users[_addr];

        return (block.timestamp >=
            user.depositTime.add(pool.lockPeriodInDays.mul(1 days)));
    }

    /**
     *
     * @dev withdraw tokens from Staking
     *
     * @param {_amount} amount to be unstaked
     *
     * @return {bool} Status of stake
     *
     */
    function unStake(uint256 _amount) external returns (bool) {
        User storage user = users[msg.sender];

        require(user.totalInvested >= _amount, "You don't have enough funds");

        _claim(msg.sender);

        pool.totalDeposit = pool.totalDeposit.sub(_amount);
        user.totalInvested = user.totalInvested.sub(_amount);

        if (!canUnstake(msg.sender)) {
            uint256 fees = _amount.mul(withdrawFee).div(100);
            if (fees > 0) {
            token.transfer(reserveWallet, fees);
            }
            _amount = _amount.sub(fees);
        }

        token.transfer(msg.sender, _amount);

        return true;
    }

    function _claim(address _addr) internal {
        User storage user = users[_addr];

        uint256 amount = payout(_addr);

        if (amount > 0) {
        
            user.totalWithdrawn = user.totalWithdrawn.add(amount);

            safeTransfer(_addr, amount);

            user.lastPayout = block.timestamp;

            user.totalClaimed = user.totalClaimed.add(amount);
        }

        emit Claim(_addr, amount);
    }

    function payout(address _addr) public view returns (uint256 value) {
        User storage user = users[_addr];

        uint256 from = user.lastPayout > user.depositTime
            ? user.lastPayout
            : user.depositTime;
        uint256 to = block.timestamp > pool.endDate
            ? pool.endDate
            : block.timestamp;

        if (from < to) {
            value = value.add(
                user.totalInvested.mul(to.sub(from)).mul(pool.apy).div(
                    365 days * 100
                )
            );
        }

        return value;
    }

    /**
     *
     * @dev safe transfer function, require to have enough  to transfer
     *
     */
    function safeTransfer(address _to, uint256 _amount) internal {
        uint256 bal = token.balanceOf(reserveWallet);
        if (_amount > bal && bal > 0) {
            token.transferFrom(reserveWallet, _to, bal);
        } else {
            token.transferFrom(reserveWallet, _to, _amount);
        }
    }

    /**
     *
     * @dev update fee values
     *
     */
    function updateFeeAndReserveWallet(uint16 _deposit, uint16 _withdraw, address _reserveWallet)
        public
        onlyOwner
    {
        depositFee = _deposit;
        withdrawFee = _withdraw;
        reserveWallet = _reserveWallet;
    }

}