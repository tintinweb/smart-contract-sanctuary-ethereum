/**
 *Submitted for verification at Etherscan.io on 2022-06-03
*/

// SPDX-License-Identifier: MIT 
// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol


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

// File: contracts/StakingContract.sol


pragma solidity 0.8.9;

interface IBEP20 {
        function balanceOf(address account) external view returns (uint256);
        function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
    }
contract StakingContract {
    using SafeMath for uint256;
    
    IBEP20 public stakingToken;
    IBEP20 public rewardToken;
    struct Stake {
        uint256 stakeTime;
        uint256 withdrawTime;
        uint256 amount;
        uint256 bonus;
        uint256 plan;
        bool withdrawan;
    }
        
    struct User {
        uint256 userTotalStaked;
        uint256 stakeCount;
        uint256 totalRewardTokens;
        mapping(uint256 => Stake) stakerecord;
    }
    address public owner;
    
    uint256 public minimumStake = 2000000000000000000;
    uint256[3] public durations = [1 minutes, 2 minutes, 3 minutes];
    mapping(address => User) public users;
    constructor(address _stakingToken, address _rewardToken) {
       owner = msg.sender;
       stakingToken = IBEP20(_stakingToken);
       rewardToken = IBEP20(_rewardToken);
    }
    
    
    function stake(uint256 amount, uint256 plan) public {
       
        require(plan >= 0 && plan < 3, "put valid plan details");
        require(amount >= minimumStake,"cant deposit need to stake more than minimum amount");
        require(msg.sender != address(0), "User address canot be zero.");
        require(owner != address(0), "Owner address canot be zero.");
        
        User storage user = users[msg.sender];
        user.stakeCount++;
        stakingToken.transferFrom(msg.sender, owner, amount);
        user.userTotalStaked += amount;
        user.stakerecord[user.stakeCount].plan = plan;
        user.stakerecord[user.stakeCount].stakeTime = block.timestamp;
        user.stakerecord[user.stakeCount].amount = amount;
        user.stakerecord[user.stakeCount].withdrawTime = block.timestamp.add(durations[plan]);
        user.stakerecord[user.stakeCount].bonus = rewardCalculate(plan);
    }
    
    function unStakeWithRewards(uint256 count) public {
        
        User storage user = users[msg.sender];
 
        require(user.stakeCount >= count, "Invalid Stake index");
        require(!user.stakerecord[count].withdrawan," withdraw completed ");
        require(msg.sender != address(0), "User address canot be zero.");
        require(owner != address(0), "Owner address canot be zero.");    
        require(block.timestamp >= user.stakerecord[count].withdrawTime,"You can not withdraw amount before time");
        require(rewardToken.balanceOf(owner) >= user.stakerecord[count].amount,"owner doesnt have enough balance");
        
        stakingToken.transferFrom(owner,msg.sender,user.stakerecord[count].amount);
        rewardToken.transferFrom(owner,msg.sender,user.stakerecord[count].bonus);
       
        user.stakerecord[count].withdrawan = true;
        user.totalRewardTokens += user.stakerecord[count].bonus;
    }

    function unStakeWithOutRewards(uint256 count) public {

	// There will be no reward if you unStake Before Time Completion

	    User storage user = users[msg.sender];

	    require(user.stakeCount>=count,"Invalide Stakeindex");
        require(!user.stakerecord[count].withdrawan," withdraw completed ");
	    require(msg.sender != address(0), "User address canot be zero.");
        require(owner != address(0), "Owner address canot be zero.");		
        require(rewardToken.balanceOf(owner) >= user.stakerecord[count].amount,"owner doesnt have enough balance");

        stakingToken.transferFrom(owner,msg.sender,user.stakerecord[count].amount);
        user.stakerecord[count].withdrawan = true;

    }

    function rewardCalculate(uint256 plan) public pure returns(uint256){
        if (plan == 0){
            return 1000000000000000000 ;
        }else if (plan == 1){
            return 5000000000000000000;
        }else{
            return 10000000000000000000;
        }
   }
}