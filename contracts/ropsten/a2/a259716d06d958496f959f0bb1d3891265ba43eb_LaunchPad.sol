/**
 *Submitted for verification at Etherscan.io on 2022-02-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

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


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract LaunchPad is Ownable {
    using SafeMath for uint256;

    IERC20 public token;

    struct Tier{
        uint256 maxDeposit;
        uint256 minDeposit;
    }
    
    struct UserInfo {
        uint256 tier;
        uint256 deposit;
        bool withdawn;
    }

    mapping(uint256 => Tier) public tiers;
    mapping(address => UserInfo) public userInfo;

    uint256 public _TOTAL_SOLD_TOKEN;
    uint256 public _TOTAL_DEPOSIT;
    uint256 public _RATE;

    uint256 public _CAP_SOFT;
    uint256 public _CAP_HARD;

    uint256 public _TIME_START;
    uint256 public _TIME_END;
    uint256 public _TIME_RELEASE;
    
    bool public _PUBLIC_SALE = false;

    receive() external payable {
        deposit();
    }

    function ownerWithdrawETH() public onlyOwner{
        require(block.timestamp > _TIME_END, "Presale haven't finished yet");
        require(_TOTAL_DEPOSIT >= _CAP_SOFT, "Presale didn't hit softcap");
        
        payable(msg.sender).transfer(address(this).balance);
    }

    function ownerWithdrawToken() public onlyOwner{        
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function setTokenForPresale(address _tokenAddress) public onlyOwner{        
        token = IERC20(_tokenAddress);
    }

    function setWhitelist(address[] calldata accounts, uint256 tier) public onlyOwner {
        require(tier < 4);
        for( uint256 i = 0; i < accounts.length; i++){
            userInfo[accounts[i]].tier = tier;
        }
    }

    function setupTier(uint256 tierId, uint256 maxDeposit, uint256 minDeposit) public onlyOwner{        
        require(tierId <=3, "There are 3 tiers");
        tiers[tierId].minDeposit = minDeposit;
        tiers[tierId].maxDeposit = maxDeposit;
    }

    function setupPresale(uint256 start, uint256 end, uint256 release, uint256 rate, uint256 softcap, uint256 hardcap) public onlyOwner{
        _RATE = rate;
        _CAP_SOFT = softcap;
        _CAP_HARD = hardcap;
        _TIME_START = start;
        _TIME_END = end;
        _TIME_RELEASE = release;
    }

    function openSalePubicly(bool opened) public onlyOwner {
        _PUBLIC_SALE = opened;
    }

    function deposit() public payable {
        uint256 tier = userInfo[msg.sender].tier;

        require(block.timestamp >= _TIME_START &&  block.timestamp <= _TIME_END, "Presale is not active this time");
        if(!_PUBLIC_SALE){
            require(tier > 0, "This wallet is not allowed to join the launchpad");
            require(msg.value >= tiers[tier].minDeposit, "Please check minimum amount contribution");
            require(userInfo[msg.sender].deposit.add(msg.value) <= tiers[tier].maxDeposit, "Check max contribution per wallet");
        }else {
            // Open publicly, tier 0
            require(msg.value >= tiers[0].minDeposit, "Please check minimum amount contribution");
            require(userInfo[msg.sender].deposit.add(msg.value) <= tiers[0].maxDeposit, "Check max contribution per wallet");
        }

        require(_TOTAL_DEPOSIT.add(msg.value) <= _CAP_HARD, "Exceed HARD CAP");

        userInfo[msg.sender].deposit = userInfo[msg.sender].deposit.add(msg.value);
        _TOTAL_DEPOSIT = _TOTAL_DEPOSIT.add(msg.value);
        _TOTAL_SOLD_TOKEN = _TOTAL_DEPOSIT.mul(_RATE);
    }

    function withdraw() public {
        require(block.timestamp > _TIME_END, "Presale haven't finished yet");
        require(!userInfo[msg.sender].withdawn, "Already withdawn!");
        if(_TOTAL_DEPOSIT < _CAP_SOFT){
            if(userInfo[msg.sender].deposit > 0){
                payable(msg.sender).transfer(userInfo[msg.sender].deposit);
                userInfo[msg.sender].withdawn = true;
            }
        }else {
            require(block.timestamp > _TIME_RELEASE, "Please check token release time");
            token.transfer(msg.sender, userInfo[msg.sender].deposit.mul(_RATE));
            userInfo[msg.sender].withdawn = true;
        }
    }
}