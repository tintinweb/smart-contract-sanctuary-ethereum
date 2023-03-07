/**
 *Submitted for verification at Etherscan.io on 2023-03-07
*/

// File contracts/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity 0.8.16;

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
}

// File contracts/ERC20/Ownable.sol

/**
 *Submitted for verification at BscScan.com on 2021-09-30
 */


pragma solidity 0.8.16;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is Not owner");
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }
}

// File contracts/ERC20/SafeMath.sol
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity 0.8.16;

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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

// File contracts/Staking.sol
pragma solidity 0.8.16;

abstract contract ReentrancyGuard {
    bool internal locked;
    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }
}

contract Staking is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    IERC20 public ERC20;

    address public stakingReserveAddress;
    uint256 public maxStakePerPool;

    struct PoolInfo {
        uint256 apyPercent;
        uint256 apyDivisor;
        uint256 minStakeAmount; // Minimum stake amount
        uint256 maxStakeAmount; // Maximum stake amount
        uint256 duration; //In Epoch Timestamp
        uint256 startTimestamp; // Pool start time
        uint256 endTimestamp; // Pool end time
        uint256 status; // 0-INACTIVE, 1-ACTIVE
    }

    struct StakeInfo {
        string poolSlug;
        uint256 apyPercent;
        uint256 apyDivisor;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 amount;
        uint256 status; // 0-INACTIVE, 1-ACTIVE
    }

    string[] internal poolSlugs;
    address[] internal stakeholders;

    mapping(string => PoolInfo) public poolDetails;
    mapping(address => mapping(string => StakeInfo)) internal stakers; // Address->_stakeId->StakeInfo
    mapping(address => mapping(string => string[]))
        internal stakePoolIdentifiers; // Address->Pool->UUID[]
    mapping(address => bool) internal stakeholdersIdentifiers; // Address->Pool->_stakeId[]

    // Events
    event PoolCreated(
        address indexed creator,
        string indexed _poolSlug,
        uint256 _apyPercent,
        uint256 _apyDivisor,
        uint256 _minStakeAmount,
        uint256 _maxStakeAmount,
        uint256 _duration,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint256 _status
    );

    event PoolUpdated(
        address indexed creator,
        string indexed _poolSlug,
        uint256 _apyPercent,
        uint256 _apyDivisor,
        uint256 _minStakeAmount,
        uint256 _maxStakeAmount,
        uint256 _duration,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint256 _status
    );

    event StakeCreated(
        string indexed poolSlug,
        string indexed _stakeId,
        address indexed _account,
        uint256 startTimestamp,
        uint256 endTimestamp,
        uint256 _amount
    );

    event StakeRemoved(
        string indexed poolSlug,
        string indexed _stakeId,
        address indexed _account,
        uint256 _amount,
        uint256 _timestamp
    );

    event RewardWithdrawn(
        string indexed poolSlug,
        string indexed _stakeId,
        address indexed _account,
        uint256 _amount
    );

    constructor(
        address _MEMAG_ADDRESS,
        address _STAKING_RESERVE_ADDRESS,
        uint256 _MAX_STAKE_LIMIT_PER_POOL
    ) {
        ERC20 = IERC20(_MEMAG_ADDRESS);
        setMaxStakePerPool(_MAX_STAKE_LIMIT_PER_POOL);
        setStakingReserveAddress(_STAKING_RESERVE_ADDRESS);
    }

    function setStakingReserveAddress(address _reserveAddress)
        public
        onlyOwner
    {
        require(
            _reserveAddress != address(0),
            "Error: Address should be valid!"
        );
        stakingReserveAddress = _reserveAddress;
    }

    function setMaxStakePerPool(uint256 _maxStakeLimit) public onlyOwner {
        require(_maxStakeLimit > 0, "Error: The limit should not be 0!");
        maxStakePerPool = _maxStakeLimit;
    }

    function createPool(
        string memory _slug,
        uint256 _apyPercent,
        uint256 _apyDivisor,
        uint256 _minStakeAmount,
        uint256 _maxStakeAmount,
        uint256 _duration,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint256 _status
    ) external onlyOwner returns (bool) {
        require(
            poolExists(_slug) == false,
            "Error: Pool with this id already exists!"
        );
        require(_apyPercent > 0, "Error: APY percent should be greater than 0");
        require(_apyDivisor > 0, "Error: APY divisor should be greater than 0");
        require(
            _minStakeAmount > 0,
            "Error: Min stake amount should be greater than 0"
        );
        require(
            _maxStakeAmount > _minStakeAmount,
            "Error: Max stake amount should be greater than min stake amount"
        );
        require(_duration > 0, "Error: Duration should be greater than 0");
        require(
            _startTimestamp > 0,
            "Error: Pool start date should be greater than 0"
        );
        require(
            _endTimestamp > _startTimestamp,
            "Error: Pool end date should be greater than start date"
        );
        require(
            _status == 0 || _status == 1,
            "Error: Pool status should be either active or inactive"
        );

        poolSlugs.push(_slug);
        poolDetails[_slug] = PoolInfo(
            _apyPercent,
            _apyDivisor,
            _minStakeAmount,
            _maxStakeAmount,
            _duration,
            _startTimestamp,
            _endTimestamp,
            _status
        );

        emit PoolCreated(
            msg.sender,
            _slug,
            _apyPercent,
            _apyDivisor,
            _minStakeAmount,
            _maxStakeAmount,
            _duration,
            _startTimestamp,
            _endTimestamp,
            _status
        );
        return true;
    }

    function updatePool(
        string memory _poolSlug,
        uint256 _apyPercent,
        uint256 _apyDivisor,
        uint256 _minStakeAmount,
        uint256 _maxStakeAmount,
        uint256 _duration,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint256 _status
    ) external onlyOwner returns (bool) {
        require(
            poolExists(_poolSlug) == true,
            "Error: Pool with this id does not exists!"
        );
        require(
            block.timestamp <= poolDetails[_poolSlug].startTimestamp,
            "Error: Cannot update the running pool!"
        );
        require(_apyPercent > 0, "Error: APY percent should be greater than 0");
        require(_apyDivisor > 0, "Error: APY divisor should be greater than 0");
        require(
            _minStakeAmount > 0,
            "Error: Min stake amount should be greater than 0"
        );
        require(
            _maxStakeAmount > _minStakeAmount,
            "Error: Max stake amount should be greater than min stake amount"
        );
        require(_duration > 0, "Error: Duration should be greater than 0");
        require(
            _startTimestamp > 0,
            "Error: Pool start date should be greater than 0"
        );
        require(
            _endTimestamp > _startTimestamp,
            "Error: Pool end date should be greater than start date"
        );
        require(
            _status == 0 || _status == 1,
            "Error: Pool status should be either active or inactive"
        );

        poolDetails[_poolSlug] = PoolInfo(
            _apyPercent,
            _apyDivisor,
            _minStakeAmount,
            _maxStakeAmount,
            _duration,
            _startTimestamp,
            _endTimestamp,
            _status
        );

        emit PoolUpdated(
            msg.sender,
            _poolSlug,
            _apyPercent,
            _apyDivisor,
            _minStakeAmount,
            _maxStakeAmount,
            _duration,
            _startTimestamp,
            _endTimestamp,
            _status
        );
        return true;
    }

    function createStake(
        string memory _poolSlug,
        string memory _stakeId,
        uint256 _amount
    ) external returns (bool) {
        // Pool checks
        require(
            poolExists(_poolSlug) == true,
            "Error: Pool with this id does not exists!"
        );
        PoolInfo memory poolInfo = poolDetails[_poolSlug];
        require(poolInfo.status == 1, "Error: The pool is inactive");
        require(
            block.timestamp >= poolInfo.startTimestamp,
            "Error: The pool has not started yet!"
        );
        require(
            block.timestamp <= poolInfo.endTimestamp,
            "Error: The pool is expired!"
        );
        require(
            stakePoolIdentifiers[msg.sender][_poolSlug].length <
                maxStakePerPool,
            "Max participation limit for pool reached!"
        );

        // Stake checks
        require(
            stakeExists(msg.sender, _stakeId) == false,
            "Stake already exists"
        );

        // Amount checks
        require(
            _amount >= poolInfo.minStakeAmount,
            "Error: Amount should not be less than minimum stake amount"
        );
        require(
            _amount <= poolInfo.maxStakeAmount,
            "Error: Amount should not be more than maximum stake amount"
        );
        require(
            ERC20.balanceOf(msg.sender) >= _amount,
            "Error: Insufficient MEMAG balance!"
        );

        uint256 _startTS = block.timestamp;
        uint256 _endTS = block.timestamp.add(poolInfo.duration);

        if (stakeholdersIdentifiers[msg.sender] == false) {
            stakeholdersIdentifiers[msg.sender] = true;
            stakeholders.push(msg.sender);
        }

        stakePoolIdentifiers[msg.sender][_poolSlug].push(_stakeId);
        stakers[msg.sender][_stakeId] = StakeInfo(
            _poolSlug,
            poolInfo.apyPercent,
            poolInfo.apyDivisor,
            _startTS,
            _endTS,
            _amount,
            1
        );

        ERC20.transferFrom(msg.sender, address(this), _amount);

        emit StakeCreated(
            _poolSlug,
            _stakeId,
            msg.sender,
            _startTS,
            _endTS,
            _amount
        );
        return true;
    }

    function withdrawStake(string memory _stakeId)
        external
        noReentrant
        returns (bool)
    {
        require(
            stakeExists(msg.sender, _stakeId) == true,
            "Stake does not exists!"
        );
        StakeInfo storage stakeInfo = stakers[msg.sender][_stakeId];
        require(stakeInfo.status == 1, "You have already withdrawn the stake");
        require(
            ERC20.balanceOf(address(this)) >= stakeInfo.amount,
            "Error: Insufficient MEMAG stake funds in liquidity!"
        );

        stakeInfo.status = 0;

        if (block.timestamp >= stakeInfo.endTimestamp) {
            uint256 _rewardAmount = calculateReward(msg.sender, _stakeId);

            require(_rewardAmount > 0, "Error: Insufficient reward generated!");
            require(
                ERC20.balanceOf(stakingReserveAddress) >= _rewardAmount,
                "Error: Insufficient MEMAG reward funds in liquidity!"
            );

            ERC20.transferFrom(
                stakingReserveAddress,
                msg.sender,
                _rewardAmount
            );

            emit RewardWithdrawn(
                stakeInfo.poolSlug,
                _stakeId,
                msg.sender,
                _rewardAmount
            );
        }

        ERC20.transfer(msg.sender, stakeInfo.amount);

        emit StakeRemoved(
            stakeInfo.poolSlug,
            _stakeId,
            msg.sender,
            stakeInfo.amount,
            block.timestamp
        );
        return true;
    }

    function calculateReward(address _account, string memory _stakeId)
        public
        view
        returns (uint256)
    {
        if (stakeExists(_account, _stakeId) == false) {
            return 0;
        }
        StakeInfo memory _stakeDetails = stakers[_account][_stakeId];

        uint256 startTime = _stakeDetails.startTimestamp;
        uint256 endTime = _stakeDetails.endTimestamp;
        uint256 diffTimestamp = endTime.sub(startTime);

        uint256 _finalReward = (
            (
                (
                    _stakeDetails.amount.mul(
                        _stakeDetails.apyPercent.mul(diffTimestamp)
                    )
                ).div(365)
            ).div(86400).div(_stakeDetails.apyDivisor)
        ).div(100);
        return _finalReward;
    }

    function poolExists(string memory _pool) public view returns (bool) {
        return (poolDetails[_pool].duration != 0 &&
            poolDetails[_pool].startTimestamp != 0 &&
            poolDetails[_pool].endTimestamp != 0);
    }

    function stakeExists(address _stakeholder, string memory _stakeId)
        public
        view
        returns (bool)
    {
        if (stakers[_stakeholder][_stakeId].amount != 0) {
            return true;
        }
        return false;
    }

    function stakeOf(address _account, string memory _stakeId)
        external
        view
        returns (
            string memory poolSlug,
            uint256 apyPercent,
            uint256 apyDivisor,
            uint256 startTimestamp,
            uint256 endTimestamp,
            uint256 amount,
            uint256 status
        )
    {
        StakeInfo memory _stakeDetails = stakers[_account][_stakeId];
        return (
            _stakeDetails.poolSlug,
            _stakeDetails.apyPercent,
            _stakeDetails.apyDivisor,
            _stakeDetails.startTimestamp,
            _stakeDetails.endTimestamp,
            _stakeDetails.amount,
            _stakeDetails.status
        );
    }

    function totalPools() external view returns (uint256) {
        return poolSlugs.length;
    }

    function getPoolSlugs() external view returns (string[] memory) {
        return poolSlugs;
    }

    function getStakeHolders() external view returns (address[] memory) {
        return stakeholders;
    }

    function totalStakePools(address _stakeholder, string memory _poolSlug)
        external
        view
        returns (uint256)
    {
        return stakePoolIdentifiers[_stakeholder][_poolSlug].length;
    }
}