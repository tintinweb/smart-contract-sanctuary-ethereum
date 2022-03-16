// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IReserve.sol";
import "./Farm.sol";

contract FarmFactory is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // The MONEY TOKEN!
    address public money;
    // Deposit Fee address
    address public feeAddress;
    // Reserve address
    address public reserve;
    // total farms
    uint256 private farmId;

    // Farm address for each LP token address.
    mapping(uint256 => address) public farms;
    mapping(address => address) public farmAddresses; // farm => farm lp token

    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;

    //round id to reward array
    uint256[] public rewards;
    uint256 public globalRoundId;

    //only after this time, rewards will be fetched and ditributed to the users from last date
    uint256 public lastReserveDistributionTimestamp;
    uint256 public reserveDistributionSchedule;
    uint256 public depositPeriod;

    event NewPool(
        address indexed farm,
        IERC20 lpToken,
        uint256 allocPoint,
        uint16 depositFeeBP
    );
    event UpdatePool(
        address indexed farm,
        uint256 allocPoint,
        uint16 depositFeeBP
    );
    event SetFeeAddress(address indexed user, address indexed newAddress);
    event UpdatedReserveDistributionSchedule(
        uint256 _reserveDistributionSchedule
    );
    event SetReserveAddress(address _reserve);
    event RewardsAccumulated();

    modifier onlyFarm() {
        require(farmAddresses[msg.sender] != address(0), "NOT_FARM");
        _;
    }

    constructor(
        address _money,
        address _feeAddress,
        address _reserve,
        uint256 _reserveDistributionSchedule,
        uint256 _depositPeriod
    ) public {
        require(
            _money != address(0),
            "FarmFactory:constructor:: ERR_ZERO_ADDRESS_MONEY"
        );
        require(
            _feeAddress != address(0),
            "FarmFactory:constructor:: ERR_ZERO_ADDRESS_FEE_ADDRESS"
        );
        require(
            _reserve != address(0),
            "FarmFactory:constructor:: ERR_ZERO_ADDRESS_RESERVE"
        );

        money = _money;
        feeAddress = _feeAddress;
        reserve = _reserve;

        reserveDistributionSchedule = _reserveDistributionSchedule; // 30 days;
        depositPeriod = _depositPeriod; // 24 hours;
    }

    function poolLength() external view returns (uint256) {
        return farmId != 0 ? farmId - 1 : 0;
    }

    function getMoneyPerShare(uint256 _farmId, uint256 _round)
        external
        view
        returns (uint256)
    {
        return Farm(farms[_farmId]).getMoneyPerShare(_round);
    }

    function getPoolDeposits(uint256 _farmId, uint256 _round)
        external
        view
        returns (uint256)
    {
        return Farm(farms[_farmId]).getPoolDeposits(_round);
    }

    // Add a new farm. Can only be called by the owner.
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        uint16 _depositFeeBP
    ) public onlyOwner {
        require(
            _depositFeeBP <= 10000,
            "FarmFactory:add:: INVALID_FEE_BASIS_POINTS"
        );
        require(_allocPoint != 0, "FarmFactory:add:: INVALID_ALLOC_POINTS");
        require(
            address(_lpToken) != address(0),
            "FarmFactory:add:: INVALID_LP_TOKEN"
        );

        if (totalAllocPoint == 0) {
            lastReserveDistributionTimestamp = depositPeriod.add(
                block.timestamp
            );
        }

        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        farmId = farmId + 1;

        Farm farm = new Farm(
            money,
            _allocPoint,
            _lpToken,
            _depositFeeBP,
            globalRoundId,
            farmId,
            depositPeriod
        );

        farms[farmId] = address(farm);
        farmAddresses[address(farm)] = address(_lpToken);

        emit NewPool(address(farm), _lpToken, _allocPoint, _depositFeeBP);
    }

    // Update the given pool's MONEY allocation point and deposit fee. Can only be called by the owner.
    function set(
        uint256 _farmId,
        uint256 _allocPoint,
        uint16 _depositFeeBP
    ) public onlyOwner {
        require(
            _depositFeeBP <= 10000,
            "FarmFactory:set:: INVALID_FEE_BASIS_POINTS"
        );
        require(
            _farmId < farmId || farmId != 0,
            "FarmFactory:set:: INVALID_POOL_ID"
        );

        Farm farm = Farm(farms[_farmId]);
        totalAllocPoint = totalAllocPoint.sub(farm.allocPoint()).add(
            _allocPoint
        );
        farm.set(_allocPoint, _depositFeeBP);

        emit UpdatePool(farms[_farmId], _allocPoint, _depositFeeBP);
    }

    function getCurrentRoundId(uint256 _farmId)
        public
        view
        returns (uint256 depositForRound)
    {
        return Farm(farms[_farmId]).getCurrentRoundId();
    }

    function pendingMoney(uint256 _farmId, address _user)
        public
        view
        returns (uint256 pending)
    {
        return Farm(farms[_farmId]).pendingMoney(_user);
    }

    // Deposit LP tokens to MoneyFarm for MONEY allocation.
    function deposit(uint256 _farmId, uint256 _amount) public {
        Farm(farms[_farmId]).depositFor(msg.sender, _amount);
    }

    // Withdraw LP tokens from MoneyFarm.
    function withdraw(uint256 _farmId, uint256 _amount) public {
        Farm(farms[_farmId]).withdrawFor(msg.sender, _amount);
    }

    function pullRewards() public returns (uint256 rewardAccumulated) {
        require(
            lastReserveDistributionTimestamp.add(reserveDistributionSchedule) <=
                block.timestamp,
            "FarmFactory:pullRewards:: REWARDS_NOT_AVAILABLE_YET"
        );

        rewardAccumulated = IReserve(reserve).withdrawRewards();
        if (rewardAccumulated == 0) return rewardAccumulated;

        rewards.push(rewardAccumulated);
        globalRoundId = rewards.length.sub(1);

        lastReserveDistributionTimestamp = block.timestamp;

        emit RewardsAccumulated();
    }

    // Update reward variables of the given pool to be up-to-date.
    // call pull rewards before this (if not executed for the current round already)
    function getRewards(uint256 _round) external view returns (uint256) {
        return rewards[_round];
    }

    // Safe money transfer function, just in case if rounding error causes pool to not have enough MONEY Tokens.
    function safeMoneyTransfer(address _to, uint256 _amount) external onlyFarm {
        uint256 moneyBal = IERC20(money).balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > moneyBal) {
            transferSuccess = IERC20(money).transfer(_to, moneyBal);
        } else {
            transferSuccess = IERC20(money).transfer(_to, _amount);
        }
        require(
            transferSuccess,
            "FarmFactory:safeMoneyTransfer:: TRANSFER_FAILED"
        );
    }

    function setFeeAddress(address _feeAddress) public onlyOwner {
        feeAddress = _feeAddress;
        emit SetFeeAddress(msg.sender, _feeAddress);
    }

    function setReserveAddress(address _reserveAddress) public onlyOwner {
        reserve = _reserveAddress;
        emit SetReserveAddress(_reserveAddress);
    }

    function updateReserveDistributionSchedule(
        uint256 _reserveDistributionSchedule
    ) external onlyOwner {
        reserveDistributionSchedule = _reserveDistributionSchedule;
        emit UpdatedReserveDistributionSchedule(_reserveDistributionSchedule);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IReserve {
    struct Withdrawer {
        bool isEligible;
        uint256 proportion;
        uint256 amountWithdrawn;
    }

    function money() external view returns (address);

    function moneyBalance() external view returns (uint256);

    function totalMoneyCollected() external view returns (uint256);

    function totalProportions() external view returns (uint256);

    function withdrawers(address withdrawer)
        external
        view
        returns (
            bool isEligible,
            uint256 proportion,
            uint256 amountWithdrawn
        );

    function updateBuyback(address _newAddress) external;

    function updateMoney(address _newAddress) external;

    function updateWithdrawer(address _oldWithdrawer, address _newWithdrawer)
        external;

    function deposit(uint256 _deposit) external;

    function withdrawRewards() external returns (uint256);

    function canWithdraw() external view returns (bool);

    function inCaseTokensGetStuck(address _token, address payable _to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IReserve.sol";
import "../interfaces/IFarmFactory.sol";

contract Farm is ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // Info of each user.
    struct UserInfo {
        uint256 amount;
        uint256 entryFarmRound;
    }

    IERC20 public lpToken; // Address of LP token contract.
    uint16 public depositFeeBP; // Deposit fee in basis points

    uint256 public allocPoint; // How many allocation points assigned to this pool.
    uint256 public poolStartTime; // timestamp when the owner add a farm
    uint256 public globalRoundId;
    uint256 public availableRewards;
    uint256 public farmId;

    //only after this time, rewards will be fetched and ditributed to the users from last date
    uint256 public lastReserveDistributionTimestamp;
    uint256 public depositPeriod; // 24 hours;
    uint256 public constant REWARD_PRECISION = 10**12;

    uint256[] cumulativeMoneyPerShare;
    uint256[] deposits;

    // The MONEY TOKEN!
    address public money;
    // Factory address
    address public factory;

    // Info of each user that stakes LP tokens.
    mapping(address => UserInfo) public userInfo;

    event Deposit(
        address indexed user,
        uint256 roundId,
        uint256 amount,
        uint256 rewards
    );
    event Withdraw(
        address indexed user,
        uint256 roundId,
        uint256 amount,
        uint256 rewards
    );
    event PoolUpdated();

    constructor(
        address _money,
        uint256 _allocPoint,
        IERC20 _lpToken,
        uint16 _depositFeeBP,
        uint256 _globalRoundId,
        uint256 _farmId,
        uint256 _depositPeriod
    ) public {
        require(
            _money != address(0),
            "Farm:constructor:: ERR_ZERO_ADDRESS_MONEY"
        );

        money = _money;
        factory = msg.sender;
        allocPoint = _allocPoint;
        lpToken = _lpToken;
        depositFeeBP = _depositFeeBP;
        lastReserveDistributionTimestamp = depositPeriod.add(block.timestamp);
        poolStartTime = block.timestamp;
        globalRoundId = _globalRoundId;
        farmId = _farmId;

        depositPeriod = _depositPeriod;
    }

    modifier onlyFactory() {
        require(factory == msg.sender, "Farm: caller is not the factory");
        _;
    }

    // Update the given pool's MONEY allocation point and deposit fee. Can only be called by the owner.
    function set(uint256 _allocPoint, uint16 _depositFeeBP) public onlyFactory {
        allocPoint = _allocPoint;
        depositFeeBP = _depositFeeBP;
    }

    /**
        roundId:
        if (startTime - block.timestamp) < depositPeriod => 0
        else
        (startTime + depositPeriod - block.timestamp) < 30 days => 1
        else
        (startTime + depositPeriod - block.timestamp)/ 30 days => roundId

        Example:
        startTime 100
        currentTime 500
        depositPeriod 10
        reserveDistributionSchedule 50

        109 = 0  (109 - 100) = (9 < 10) hence 0
        159 = 1  (159 - 100+10) = (49 < 40) hence 1
        209 = 2  (209 - 110) = 99/50 = 1+1 = 2
        259 = 3  (259 - 110) = 149/50 = 2+1 = 3
        309 = 4  (259 - 110) = 149/50 = 2+1 = 4
     */
    function getCurrentRoundId() public view returns (uint256 depositForRound) {
        // zero indexed round ids
        uint256 timeDiff = block.timestamp.sub(poolStartTime);

        uint256 reserveDistributionSchedule = getReserveDistributionSchedule();
        if (timeDiff < depositPeriod) {
            return 0;
        } else if (timeDiff.sub(depositPeriod) < reserveDistributionSchedule) {
            depositForRound = 1;
        } else {
            depositForRound = (timeDiff.sub(depositPeriod)).div(
                reserveDistributionSchedule
            );

            depositForRound++;
        }

        if (
            depositForRound != deposits.length.sub(1) &&
            depositForRound != deposits.length
        ) {
            depositForRound = deposits.length;
        }
    }

    function getMoneyPerShare(uint256 _round) external view returns (uint256) {
        if (cumulativeMoneyPerShare.length <= _round) return 0;
        if (cumulativeMoneyPerShare.length == 1)
            return cumulativeMoneyPerShare[_round];
        return
            cumulativeMoneyPerShare[_round].sub(
                cumulativeMoneyPerShare[_round.sub(1)]
            );
    }

    function getPoolDeposits(uint256 _round) external view returns (uint256) {
        if (deposits.length <= _round) return 0;
        return deposits[_round];
    }

    function getReserveDistributionSchedule() public view returns (uint256) {
        return IFarmFactory(factory).reserveDistributionSchedule();
    }

    function _updateRewards() internal {
        if (
            lastReserveDistributionTimestamp.add(
                getReserveDistributionSchedule()
            ) <= block.timestamp
        ) {
            updatePool();
        }
    }

    function updatePool() public {
        uint256 lastPoolRoundUpdated = cumulativeMoneyPerShare.length;
        if (lastPoolRoundUpdated != 0) lastPoolRoundUpdated--;

        uint256 rewardIndex = globalRoundId.add(lastPoolRoundUpdated);
        uint256 totalRounds = IFarmFactory(factory)
            .globalRoundId()
            .sub(rewardIndex)
            .add(1);

        uint256 totalAllocPoint = IFarmFactory(factory).totalAllocPoint();

        for (uint256 round = 1; round <= totalRounds; round++) {
            uint256 reward = IFarmFactory(factory).getRewards(
                rewardIndex + round - 1
            );

            uint256 roundRewards = (reward.mul(allocPoint))
                .div(totalAllocPoint)
                .mul(REWARD_PRECISION);

            uint256 share = roundRewards.div(deposits[round - 1]);

            //to initialise 0th round
            if (cumulativeMoneyPerShare.length != 0)
                share = share.add(cumulativeMoneyPerShare[round.sub(2)]);

            cumulativeMoneyPerShare.push(share);
            availableRewards = availableRewards.add(roundRewards);
        }

        lastReserveDistributionTimestamp = block.timestamp;

        emit PoolUpdated();
    }

    function pendingMoney(address _user) public view returns (uint256 pending) {
        UserInfo memory user = userInfo[_user];
        if (user.amount == 0) return 0;

        if (cumulativeMoneyPerShare.length == 0) return 0;

        uint256 start = user.entryFarmRound;
        uint256 end = cumulativeMoneyPerShare.length - 1;

        if (end < start) return 0;

        uint256 totalRewardPerShare;

        if (start == end) {
            totalRewardPerShare = cumulativeMoneyPerShare[start];
            if (start != 0) {
                totalRewardPerShare = totalRewardPerShare.sub(
                    cumulativeMoneyPerShare[start.sub(1)]
                );
            }
        } else {
            totalRewardPerShare = cumulativeMoneyPerShare[end].sub(
                cumulativeMoneyPerShare[start]
            );
        }

        pending = user.amount.mul(totalRewardPerShare).div(REWARD_PRECISION);
    }

    // Deposit LP tokens to MoneyFarm for MONEY allocation.
    function deposit(uint256 _amount) public {
        depositFor(msg.sender, _amount);
    }

    function depositFor(address _user, uint256 _amount) public nonReentrant {
        UserInfo storage user = userInfo[_user];

        uint256 currentRound = getCurrentRoundId();
        uint256 farmAmount = _amount;

        if (farmAmount != 0) {
            lpToken.safeTransferFrom(_user, address(this), farmAmount);

            if (depositFeeBP > 0) {
                uint256 depositFee = farmAmount.mul(depositFeeBP).div(10000);
                address feeAddress = IFarmFactory(factory).feeAddress();
                lpToken.safeTransfer(feeAddress, depositFee);
                farmAmount = farmAmount.sub(depositFee);
            }

            _updateDeposits(farmAmount, currentRound);
        }

        uint256 pendingRewards = pendingMoney(_user);
        if (pendingRewards != 0) {
            availableRewards = availableRewards.sub(pendingRewards);
            IFarmFactory(factory).safeMoneyTransfer(_user, pendingRewards);
        }

        user.entryFarmRound = currentRound;
        user.amount = user.amount.add(farmAmount);

        emit Deposit(_user, currentRound, _amount, pendingRewards);
    }

    // Withdraw LP tokens from MoneyFarm.
    function withdraw(uint256 _amount) public {
        withdrawFor(msg.sender, _amount);
    }

    function withdrawFor(address _user, uint256 _amount) public nonReentrant {
        UserInfo storage user = userInfo[_user];

        require(user.amount >= _amount, "Farm:withdraw:: INVALID_AMOUNT");

        _updateRewards();

        uint256 pendingRewards = pendingMoney(_user);

        if (pendingRewards > 0) {
            availableRewards = availableRewards.sub(pendingRewards);
            IFarmFactory(factory).safeMoneyTransfer(_user, pendingRewards);
        }

        uint256 currentRound = getCurrentRoundId();

        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);

            uint256 withdrawRound = deposits.length.sub(1);

            user.entryFarmRound = currentRound;

            uint256 finalAmount = deposits[withdrawRound].sub(_amount);
            if (currentRound == withdrawRound) {
                deposits[withdrawRound] = finalAmount;
            } else {
                _updateDeposits(finalAmount, currentRound);
            }

            lpToken.safeTransfer(address(_user), _amount);
        }

        emit Withdraw(_user, currentRound, _amount, pendingRewards);
    }

    function _updateDeposits(uint256 farmAmount, uint256 currentRound)
        internal
    {
        if (deposits.length == 0) {
            deposits.push(farmAmount);
        } else if (currentRound == deposits.length) {
            deposits.push(farmAmount.add(deposits[currentRound.sub(1)]));
        } else {
            require(currentRound == deposits.length.sub(1), "ERR!");
            deposits[currentRound] = deposits[currentRound].add(farmAmount);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IFarmFactory {
    // The MONEY TOKEN!
    function money() external view returns (address);

    // Deposit Fee address
    function feeAddress() external view returns (address);

    // Reserve address
    function reserve() external view returns (address);

    // Total allocation points. Must be the sum of all allocation points in all pools.
    function totalAllocPoint() external view returns (uint256);

    //round id to reward array
    function rewards() external view returns (uint256[] memory);

    function globalRoundId() external view returns (uint256);

    // Farm address for each LP token address.
    function farms(uint256) external view returns (address);

    // farm => farm lp token
    function farmAddresses(address) external view returns (address);

    function reserveDistributionSchedule() external view returns (uint256);

    function lastReserveDistributionTimestamp() external view returns (uint256);

    function depositPeriod() external view returns (uint256);

    function poolLength() external view returns (uint256);

    function getMoneyPerShare(uint256 _farmId, uint256 _round)
        external
        view
        returns (uint256);

    function getPoolDeposits(uint256 _farmId, uint256 _round)
        external
        view
        returns (uint256);

    function getCurrentRoundId(uint256 _farmId)
        external
        view
        returns (uint256 depositForRound);

    function pendingMoney(uint256 _farmId, address _user)
        external
        view
        returns (uint256 pending);

    function deposit(uint256 _farmId, uint256 _amount) external;

    function withdraw(uint256 _farmId, uint256 _amount) external;

    function pullRewards() external returns (uint256 rewardAccumulated);

    function getRewards(uint256 _round) external view returns (uint256);

    function safeMoneyTransfer(address _to, uint256 _amount) external;
}