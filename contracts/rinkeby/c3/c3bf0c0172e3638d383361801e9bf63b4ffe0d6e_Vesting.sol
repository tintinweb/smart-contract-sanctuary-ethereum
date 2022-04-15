/**
 *Submitted for verification at Etherscan.io on 2022-04-15
*/

/**
 *Submitted for verification at BscScan.com on 2022-03-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

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


contract Vesting is Ownable{
    using SafeMath for uint256;
    address tokenWallet = 0x45f0D298AE77666a483E73F431ee5BF360FD6Aa6;
    IERC20 public lgx = IERC20(0xB7809aDa6ef0CB220886C8A8D997eab72BECBE4d);

    
    address private signatureContract;
    mapping (address => UserInfo) public buyers;
    // mapping (address => uint256) public whitelisted;

    uint256 firstVesting = 1651276801;
    uint256 secondVesting = 1653868801;
    uint256 thirdVesting = 1656547201;
    uint256 fourthVesting = 1659139201;
    uint256 fifthVesting = 1661817601;
    uint256 sixthVesting = 1664496001;
    uint256 seventhVesting = 1667088001;
    uint256 eighthVesting = 1669766401;
    uint256 ninthVesting = 1672358401;

    struct UserInfo{
        address user;
        bool firstVestingClaimed;
        bool secondVestingClaimed;
        bool thirdVestingClaimed;
        bool fourthVestingClaimed;
        bool fifthVestingClaimed;
        bool sixthVestingClaimed;
        bool seventhVestingClaimed;
        bool eighthVestingClaimed;
        bool ninthVestingClaimed;
        uint256 totalClaimed;
    }

    
    // function addToWhitelists(address[] calldata users , uint256[] calldata amounts) public onlyOwner{
    //     for(uint256 i = 0 ; i < users.length ; i++){
    //         whitelisted[users[i]] = amounts[i];
    //     }
    // }

    //  function addToWhitelist(address user , uint256 amount) public onlyOwner{
    //         whitelisted[user] = amount;
    // }

    function claim(uint256 amount , uint256 deadline , uint8 v, bytes32 r, bytes32 s) public {
        // New whitelisting functionality
        require(deadline >= block.timestamp, "deadline passed");
        require(signatureContract == ecrecover(getSignedHash(keccak256(abi.encodePacked(this, msg.sender , deadline , amount))), v, r, s), "owner should sign Transactioon");
        // End
        /* Old whitelisting functionality
        uint256 amount = whitelisted[_msgSender()];
        require(amount > 0 , "Not Whitelisted");
        */
        UserInfo storage user = buyers[_msgSender()];
        require(user.totalClaimed < amount , "Already Claimed");
        if(block.timestamp > firstVesting && !user.firstVestingClaimed){
            uint256 toSend = amount.mul(10).div(100);
            user.totalClaimed = user.totalClaimed.add(toSend);
            user.firstVestingClaimed = true;
            lgx.transferFrom(tokenWallet , _msgSender(), toSend);
        }

         if(block.timestamp > secondVesting && !user.secondVestingClaimed){
            uint256 toSend = amount.mul(1125).div(10000);
            user.totalClaimed = user.totalClaimed.add(toSend);
            user.secondVestingClaimed = true;
            lgx.transferFrom(tokenWallet , _msgSender(), toSend);
        }

          if(block.timestamp > thirdVesting && !user.thirdVestingClaimed){
            uint256 toSend = amount.mul(1125).div(10000);
            user.totalClaimed = user.totalClaimed.add(toSend);
            user.thirdVestingClaimed = true;
            lgx.transferFrom(tokenWallet , _msgSender(), toSend);
        }

        if(block.timestamp > fourthVesting && !user.fourthVestingClaimed){
            uint256 toSend = amount.mul(1125).div(10000);
            user.totalClaimed = user.totalClaimed.add(toSend);
            user.fourthVestingClaimed = true;
            lgx.transferFrom(tokenWallet , _msgSender(), toSend);
        }

        if(block.timestamp > fifthVesting && !user.fifthVestingClaimed){
            uint256 toSend = amount.mul(1125).div(10000);
            user.totalClaimed = user.totalClaimed.add(toSend);
            user.fifthVestingClaimed = true;
            lgx.transferFrom(tokenWallet , _msgSender(), toSend);
        }

         if(block.timestamp > sixthVesting && !user.sixthVestingClaimed){
            uint256 toSend = amount.mul(1125).div(10000);
            user.totalClaimed = user.totalClaimed.add(toSend);
            user.sixthVestingClaimed = true;
            lgx.transferFrom(tokenWallet , _msgSender(), toSend);
        }

         if(block.timestamp > seventhVesting && !user.seventhVestingClaimed){
            uint256 toSend = amount.mul(1125).div(10000);
            user.totalClaimed = user.totalClaimed.add(toSend);
            user.seventhVestingClaimed = true;
            lgx.transferFrom(tokenWallet,_msgSender(),toSend);
        }

         if(block.timestamp > eighthVesting && !user.eighthVestingClaimed){
            uint256 toSend = amount.mul(1125).div(10000);
            user.totalClaimed = user.totalClaimed.add(toSend);
            user.eighthVestingClaimed = true;
            lgx.transferFrom(tokenWallet , _msgSender(), toSend);
        }

         if(block.timestamp > ninthVesting && !user.ninthVestingClaimed){
            uint256 toSend = amount.mul(1125).div(10000);
            user.totalClaimed = user.totalClaimed.add(toSend);
            user.ninthVestingClaimed = true;
            lgx.transferFrom(tokenWallet , _msgSender(), toSend);
        }

    }

    
    function getSignedHash(bytes32 _messageHash) private pure returns(bytes32){
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }
}