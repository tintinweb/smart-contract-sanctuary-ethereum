/**
 *Submitted for verification at Etherscan.io on 2022-06-14
*/

/**
 *Submitted for verification at Etherscan.io on 2022-05-29
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: staking.sol

// import "hardhat/console.sol";

pragma solidity ^0.8.0;

contract Staking is Ownable {
    using SafeMath for uint256;

    uint8 public sixMonthAPR = 30;
    uint8 public oneYearAPR = 60;
    uint16 public threeYearAPR = 150;
    uint256 public totalStake;
    uint256 public totalRewards;

    enum StakingPeriod{ SIX_MONTH, ONE_YEAR, THREE_YEAR }

    struct stake {
        uint256 amount;
        StakingPeriod stakePeriod;
        uint timestamp;
    }

    address[] internal stakeholders;

    // mapping(address => stake) internal stakes;
    mapping(address => mapping(StakingPeriod => stake)) public stakes;

    IERC20 public myToken;

    constructor(address _myToken)
    { 
        myToken = IERC20(_myToken);
    }

    // ---------- STAKES ----------

    function createStake(uint256 _stake, StakingPeriod _stakePeriod) public {
        require(_stake > 0, "stake value should not be zero");
        require(myToken.transferFrom(msg.sender, address(this), _stake), "Token Transfer Failed");
        if(stakes[msg.sender][_stakePeriod].amount == 0) {
            addStakeholder(msg.sender);
            stakes[msg.sender][_stakePeriod] = stake(_stake, _stakePeriod, block.timestamp);
            totalStake = totalStake.add(_stake);
        } else {
            stake memory tempStake = stakes[msg.sender][_stakePeriod];
            tempStake.amount = tempStake.amount.add(_stake);
            stakes[msg.sender][_stakePeriod] = tempStake;
            totalStake = totalStake.add(_stake);
        }
    }

    function unStake(uint256 _stake, StakingPeriod _stakePeriod) public {
        require(_stake > 0, "stake value should not be zero");
        stake memory tempStake = stakes[msg.sender][_stakePeriod];
        require(validateStakingPeriod(tempStake), "Staking period is not expired");
        require(_stake <= tempStake.amount, "Invalid Stake Amount");
        uint256 _investorReward = getRewardForUnstake(_stake, tempStake);
        tempStake.amount = tempStake.amount.sub(_stake);
        stakes[msg.sender][_stakePeriod] = tempStake;
        totalStake = totalStake.sub(_stake);
        totalRewards = totalRewards.add(_investorReward);
        //uint256 tokensToBeTransfer = _stake.add(_investorReward);
        if(stakes[msg.sender][_stakePeriod].amount == 0) removeStakeholder(msg.sender);
        myToken.transfer(msg.sender, _stake);
        myToken.transferFrom(owner(), msg.sender, _investorReward);
        
    }

    function getRewardForUnstake(uint256 _unstakeAmount, stake memory _investor) internal view returns (uint256) {
        uint256 total_rewards = getInvestorRewards(_unstakeAmount, _investor);
        uint256 noOfDays = (block.timestamp - _investor.timestamp).div(60).div(60).div(24);
        noOfDays = (noOfDays < 1) ? 1 : noOfDays;
        return total_rewards.div(364).mul(noOfDays);

    }

    function getInvestorRewards(uint256 _unstakeAmount, stake memory _investor) internal view returns (uint256) {
        uint256 investorStakingPeriod = getStakingPeriodInNumbers(_investor);
        uint APY = investorStakingPeriod == 26 weeks ? sixMonthAPR : investorStakingPeriod == 52 weeks ? oneYearAPR : investorStakingPeriod == 156 weeks ? threeYearAPR : 0;
        return _unstakeAmount.div(100).mul(APY);
    } 

    function validateStakingPeriod(stake memory _investor) internal view returns(bool) {
        uint256 stakingTimeStamp = _investor.timestamp + getStakingPeriodInNumbers(_investor);
        return true; // change it to block.timestamp >= stakingTimeStamp; while deploying
    } 

    function getStakingPeriodInNumbers(stake memory _investor) internal pure returns (uint256){
        return _investor.stakePeriod == StakingPeriod.SIX_MONTH ? 26 weeks : _investor.stakePeriod == StakingPeriod.ONE_YEAR ? 52 weeks : _investor.stakePeriod == StakingPeriod.THREE_YEAR ? 156 weeks : 0; 
    }

    function stakeOf(address _stakeholder, StakingPeriod _stakePeriod)
        public
        view
        returns(uint256)
    {
        return stakes[_stakeholder][_stakePeriod].amount;
    }

    function stakingPeriodOf(address _stakeholder, StakingPeriod _stakePeriod) public view returns (StakingPeriod) {
        return stakes[_stakeholder][_stakePeriod].stakePeriod;
    }

    function getDailyRewards(StakingPeriod _stakePeriod) public view returns (uint256) {
        stake memory tempStake = stakes[msg.sender][_stakePeriod];
        uint256 total_rewards = getInvestorRewards(tempStake.amount, tempStake);
        uint256 noOfDays = (block.timestamp - tempStake.timestamp).div(60).div(60).div(24);
        noOfDays = (noOfDays < 1) ? 1 : noOfDays;
       // uint256 stakingPeriodInDays =  getStakingPeriodInNumbers(tempStake).div(60).div(60).div(24);
        return total_rewards.div(364).mul(noOfDays);
    }

    // ---------- STAKEHOLDERS ----------

    function isStakeholder(address _address)
        internal
        view
        returns(bool, uint256)
    {
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            if (_address == stakeholders[s]) return (true, s);
        }
        return (false, 0);
    }

   
    function addStakeholder(address _stakeholder)
        internal
    {
        (bool _isStakeholder, ) = isStakeholder(_stakeholder);
        if(!_isStakeholder) stakeholders.push(_stakeholder);
    }

    
    function removeStakeholder(address _stakeholder)
        internal
    {
        (bool _isStakeholder, uint256 s) = isStakeholder(_stakeholder);
        if(_isStakeholder){
            stakeholders[s] = stakeholders[stakeholders.length - 1];
            stakeholders.pop();
        } 
    }
    // ---------- REWARDS ----------

    
    function getTotalRewards()
        public
        view
        returns(uint256)
    {
        return totalRewards;
    }

    // ---- Staking APY  setters ---- 

    function setSixMonthAPR(uint8 _sixMonthAPR) public onlyOwner {
        sixMonthAPR = _sixMonthAPR;
    }

    function setOneYearAPR(uint8 _oneYearAPR) public onlyOwner {
        oneYearAPR = _oneYearAPR;
    }

    function setThreeYearAPR(uint8 _threeYearAPR) public onlyOwner {
        threeYearAPR = _threeYearAPR;
    }

}