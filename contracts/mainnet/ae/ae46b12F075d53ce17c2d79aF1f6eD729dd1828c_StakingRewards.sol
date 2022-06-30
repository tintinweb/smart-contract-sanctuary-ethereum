/**
 *Submitted for verification at Etherscan.io on 2022-06-29
*/

/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

// SPDX-License-Identifier: MIT

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

// File: contracts/StakingReward.sol


pragma solidity ^0.8.10;



// Staking APY Breakdown
// No lock: 0.02%
// 1 week: 0.17%
// 1 month: 0.68%
// 3 months: 2.2%
// 6 months: 4.5%
// 1 year: 9%
// 2 years: 21%
// 4 years: 41%

// The user will be able to connect/disconnect their wallet, then migrate and swap their PIXUL tokens for xPIXUL.
// The user will be able to stake xPIXUL and receive PIXUL tokens with the APY that is offered on the lock they selected
// User can claim new rewards anytime and can unstake when the timelock has been completed
// user can view the amount of tokens they have locked and the amount of rewards they have accumulated. 

contract StakingRewards {
    using SafeMath for uint256;

    IERC20 public rewardsToken;
    IERC20 public stakingToken;

    uint256 constant year = 60 * 60 * 24 * 365;
    uint256 constant month = 60 * 60 * 24 * 30;
    uint256 constant week = 60 * 60 * 24 * 7;

    /// @dev staking period
    uint256[] stakingPeriod = [0, week, month, 3 * month, 6 * month, year, 2 * year, 4 * year];

    /// APR breakdown
    uint256[] apr = [
        2,      // 0.02%
        17,     // 0.17%
        68,     // 0.68%
        220,    // 2.2%
        450,    // 4.5%
        900,    // 9%
        2100,   // 21%
        4100    // 41%
    ];

    /// @dev current max stakingId
    uint256 public stakingIdPointer;

    struct StakingInfo {
        uint256 stakingId;
        uint256 amount;
        uint256 starttime;
        uint256 claimedAmount;
        uint8 stakingtype;
    }

    mapping(address => uint256) public balances;

    mapping(address => mapping(uint256 => uint256)) _ownedStakings;

    mapping(uint256 => uint256) private _ownedStakingsIndex;
    
    StakingInfo[] _allStakings;

    mapping(uint256 => uint256) _allStakingIndex;

    constructor(address _stakingToken, address _rewardsToken) {
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardsToken);
    }

    function stakingOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < balances[owner], "owner index out of bounds");
        return _ownedStakings[owner][index];
    }

    function totalSupply() public view returns (uint256) {
        return _allStakings.length;
    }

    /// number of stakings
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "balance query for the zero address");
        return balances[owner];
    }

    function stakingByIndex(uint256 index) public view returns (StakingInfo memory) {
        require(index < totalSupply(), "global index out of bounds");
        return _allStakings[index];
    }

    function stakingById(uint256 stakingId) public view returns (StakingInfo memory) {
        require(stakingId <= stakingIdPointer, "staking id is not valid");
        return _allStakings[_allStakingIndex[stakingId]];
    }

    function _addStakingToOwnerEnumeration(address to, uint256 stakingId) private {
        uint256 length = balances[to];
        _ownedStakings[to][length] = stakingId;
        _ownedStakingsIndex[stakingId] = length;
    }

    function _addStakingToAllStakingsEnumeration(StakingInfo memory si) private {
        _allStakingIndex[si.stakingId] = _allStakings.length;
        _allStakings.push(si);
    }

    function _removeStakingFromOwnerEnumeration(address from, uint256 stakingId) private {
        uint256 lastStakingIndex = balances[from] - 1;
        uint256 stakingIndex = _ownedStakingsIndex[stakingId];

        if (stakingIndex != lastStakingIndex) {
            uint256 lastStakingId = _ownedStakings[from][lastStakingIndex];

            _ownedStakings[from][stakingIndex] = lastStakingId;
            _ownedStakingsIndex[lastStakingId] = stakingIndex;
        }

        delete _ownedStakingsIndex[stakingId];
        delete _ownedStakings[from][lastStakingIndex];
    }
    
    function _removeStakingFromAllStakingsEnumeration(uint256 stakingId) private {
        uint256 lastStakingIndex = _allStakings.length - 1;
        uint256 stakingIndex = _allStakingIndex[stakingId];

        StakingInfo memory lastStakingInfo = _allStakings[lastStakingIndex];


        _allStakings[stakingIndex] = lastStakingInfo;
        _allStakingIndex[lastStakingInfo.stakingId] = stakingIndex;

        delete _allStakingIndex[stakingId];
        _allStakings.pop();
    }

    function stake(uint256 amount, uint8 stakingtype) external {
        require(amount > 0, "amount should be not zero");
        require(stakingToken.allowance(msg.sender, address(this)) >= amount, "not enough allowance");

        stakingIdPointer = stakingIdPointer.add(1);
        uint256 stakingId = stakingIdPointer;

        StakingInfo memory si;
        si.stakingId = stakingId;
        si.amount = amount;
        si.starttime = block.timestamp;
        si.stakingtype = stakingtype;
        si.claimedAmount = 0;

        _addStakingToOwnerEnumeration(msg.sender, stakingId);
        _addStakingToAllStakingsEnumeration(si);
        balances[msg.sender]++;

        stakingToken.transferFrom(msg.sender, address(this), amount);
    }

    function unstake(uint256 stakingId) external {
        require(stakingId <= stakingIdPointer, "staking id is not valid");

        StakingInfo memory si = _allStakings[_allStakingIndex[stakingId]];
        require((si.starttime + stakingPeriod[si.stakingtype]) < block.timestamp, "still lock period");

        uint256 fee = apr[si.stakingtype];

        uint256 availableAmount = (si.amount * fee ) *  (block.timestamp - si.starttime) / year / 100 / 100;
        if(availableAmount > si.claimedAmount) {
            getReward(stakingId);
        }

        uint256 amount = si.amount;
        
        _removeStakingFromOwnerEnumeration(msg.sender, stakingId);
        _removeStakingFromAllStakingsEnumeration(stakingId);
        balances[msg.sender]--;

        stakingToken.transfer(msg.sender, amount);
    }

    function getReward(uint256 stakingId) public {
        require(stakingId <= stakingIdPointer, "staking id is not valid");

        StakingInfo memory si = _allStakings[_allStakingIndex[stakingId]];

        uint256 fee = apr[si.stakingtype];

        // uint256 period = (block.timestamp - si.starttime);
        // if((si.stakingtype != 0) && (period > stakingPeriod[si.stakingtype]))
        //     period = stakingPeriod[si.stakingtype];
            
        // uint256 availableAmount = (si.amount * fee / 100) * period / year;

        uint256 availableAmount = (si.amount * fee ) *  (block.timestamp - si.starttime) / year / 100 / 100;   // reward percentage can be (fee / 100)
        require(availableAmount > si.claimedAmount, "no available reward amount");

        _allStakings[_allStakingIndex[stakingId]].claimedAmount = availableAmount;

        rewardsToken.transfer(msg.sender, (availableAmount - si.claimedAmount));
    }

    function getTotalLockedAmount() public view returns (uint256) {
        uint256 amount = 0;
        
        for (uint256 i = 0; i < _allStakings.length; i++) {
            StakingInfo memory si = _allStakings[i];
            amount += si.amount;
        }

        return amount;
    }

    function averageUnlockTime() public view returns (uint256) {
        uint256 time = 0;

        for (uint256 i = 0; i < _allStakings.length; i++) {
            StakingInfo memory si = _allStakings[i];

            if (si.starttime + stakingPeriod[si.stakingtype] > block.timestamp) {
                time += si.starttime + stakingPeriod[si.stakingtype] - block.timestamp;
            }
        }

        return time / _allStakings.length;
    }

    function claimableAmount(uint256 stakingId) external view returns (uint256) {
        require(stakingId <= stakingIdPointer, "staking id is not valid");

        StakingInfo memory si = _allStakings[_allStakingIndex[stakingId]];

        uint256 fee = apr[si.stakingtype];
        uint256 availableAmount = (si.amount * fee ) *  (block.timestamp - si.starttime) / year / 100 / 100;   // reward percentage can be (fee / 100)

        if (availableAmount > si.claimedAmount) {
            return availableAmount - si.claimedAmount;
        } else {
            return 0;
        }
    }

    function averageAPR() public view returns (uint256) {
        uint256 average_apr = 0;

        for (uint256 i = 0; i < _allStakings.length; i++) {
            StakingInfo memory si = _allStakings[i];

            average_apr += apr[si.stakingtype];
        }

        return average_apr / _allStakings.length;
    }

    
}