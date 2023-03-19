pragma solidity 0.5.17;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../../libs/DecMath.sol";
import "./IMPHIssuanceModel.sol";

contract MPHIssuanceModel01 is Ownable, IMPHIssuanceModel {
    using Address for address;
    using DecMath for uint256;
    using SafeMath for uint256;

    uint256 internal constant PRECISION = 10**18;

    /**
        @notice The multiplier applied when minting MPH for a pool's depositor reward.
                Unit is MPH-wei per depositToken-wei per second. (wei here is the smallest decimal place)
                Scaled by 10^18.
                NOTE: The depositToken's decimals matter! 
     */
    mapping(address => uint256) public poolDepositorRewardMintMultiplier;
    /**
        @notice The multiplier applied when taking back MPH from depositors upon withdrawal.
                No unit, is a proportion between 0 and 1.
                Scaled by 10^18.
     */
    mapping(address => uint256) public poolDepositorRewardTakeBackMultiplier;
    /**
        @notice The multiplier applied when minting MPH for a pool's funder reward.
                Unit is MPH-wei per depositToken-wei per second. (wei here is the smallest decimal place)
                Scaled by 10^18.
                NOTE: The depositToken's decimals matter! 
     */
    mapping(address => uint256) public poolFunderRewardMultiplier;
    /**
        @notice The period over which the depositor reward will be vested, in seconds.
     */
    mapping(address => uint256) public poolDepositorRewardVestPeriod;
    /**
        @notice The period over which the funder reward will be vested, in seconds.
     */
    mapping(address => uint256) public poolFunderRewardVestPeriod;

    /**
        @notice Multiplier used for calculating dev reward
     */
    uint256 public devRewardMultiplier;

    event ESetParamAddress(
        address indexed sender,
        string indexed paramName,
        address newValue
    );
    event ESetParamUint(
        address indexed sender,
        string indexed paramName,
        address indexed pool,
        uint256 newValue
    );

    constructor(uint256 _devRewardMultiplier) public {
        devRewardMultiplier = _devRewardMultiplier;
    }

    /**
        @notice Computes the MPH amount to reward to a depositor upon deposit.
        @param  pool The DInterest pool trying to mint reward
        @param  depositAmount The deposit amount in the pool's stablecoins
        @param  depositPeriodInSeconds The deposit's lock period in seconds
        @param  interestAmount The deposit's fixed-rate interest amount in the pool's stablecoins
        @return depositorReward The MPH amount to mint to the depositor
                devReward The MPH amount to mint to the dev wallet
                govReward The MPH amount to mint to the gov treasury
     */
    function computeDepositorReward(
        address pool,
        uint256 depositAmount,
        uint256 depositPeriodInSeconds,
        uint256 interestAmount
    )
        external
        view
        returns (
            uint256 depositorReward,
            uint256 devReward,
            uint256 govReward
        )
    {
        uint256 mintAmount = depositAmount.mul(depositPeriodInSeconds).decmul(
            poolDepositorRewardMintMultiplier[pool]
        );
        depositorReward = mintAmount;
        devReward = mintAmount.decmul(devRewardMultiplier);
        govReward = 0;
    }

    /**
        @notice Computes the MPH amount to take back from a depositor upon withdrawal.
                If takeBackAmount > devReward + govReward, the extra MPH should be burnt.
        @param  pool The DInterest pool trying to mint reward
        @param  mintMPHAmount The MPH amount originally minted to the depositor as reward
        @param  early True if the deposit is withdrawn early, false if the deposit is mature
        @return takeBackAmount The MPH amount to take back from the depositor
                devReward The MPH amount from takeBackAmount to send to the dev wallet
                govReward The MPH amount from takeBackAmount to send to the gov treasury
     */
    function computeTakeBackDepositorRewardAmount(
        address pool,
        uint256 mintMPHAmount,
        bool early
    )
        external
        view
        returns (
            uint256 takeBackAmount,
            uint256 devReward,
            uint256 govReward
        )
    {
        takeBackAmount = early
            ? mintMPHAmount
            : mintMPHAmount.decmul(poolDepositorRewardTakeBackMultiplier[pool]);
        devReward = 0;
        govReward = early ? 0 : takeBackAmount;
    }

    /**
        @notice Computes the MPH amount to reward to a deficit funder upon withdrawal of an underlying deposit.
        @param  pool The DInterest pool trying to mint reward
        @param  depositAmount The deposit amount in the pool's stablecoins
        @param  fundingCreationTimestamp The timestamp of the funding's creation, in seconds
        @param  maturationTimestamp The maturation timestamp of the deposit, in seconds
        @param  interestPayoutAmount The interest payout amount to the funder, in the pool's stablecoins.
                                     Includes the interest from other funded deposits.
        @param  early True if the deposit is withdrawn early, false if the deposit is mature
        @return funderReward The MPH amount to mint to the funder
                devReward The MPH amount to mint to the dev wallet
                govReward The MPH amount to mint to the gov treasury
     */
    function computeFunderReward(
        address pool,
        uint256 depositAmount,
        uint256 fundingCreationTimestamp,
        uint256 maturationTimestamp,
        uint256 interestPayoutAmount,
        bool early
    )
        external
        view
        returns (
            uint256 funderReward,
            uint256 devReward,
            uint256 govReward
        )
    {
        if (early) {
            return (0, 0, 0);
        }
        funderReward = maturationTimestamp > fundingCreationTimestamp
            ? depositAmount
                .mul(maturationTimestamp.sub(fundingCreationTimestamp))
                .decmul(poolFunderRewardMultiplier[pool])
            : 0;
        devReward = funderReward.decmul(devRewardMultiplier);
        govReward = 0;
    }

    /**
        Param setters
     */

    function setPoolDepositorRewardMintMultiplier(
        address pool,
        uint256 newMultiplier
    ) external onlyOwner {
        require(pool.isContract(), "MPHIssuanceModel: pool not contract");
        poolDepositorRewardMintMultiplier[pool] = newMultiplier;
        emit ESetParamUint(
            msg.sender,
            "poolDepositorRewardMintMultiplier",
            pool,
            newMultiplier
        );
    }

    function setPoolDepositorRewardTakeBackMultiplier(
        address pool,
        uint256 newMultiplier
    ) external onlyOwner {
        require(pool.isContract(), "MPHIssuanceModel: pool not contract");
        require(
            newMultiplier <= PRECISION,
            "MPHIssuanceModel: invalid multiplier"
        );
        poolDepositorRewardTakeBackMultiplier[pool] = newMultiplier;
        emit ESetParamUint(
            msg.sender,
            "poolDepositorRewardTakeBackMultiplier",
            pool,
            newMultiplier
        );
    }

    function setPoolFunderRewardMultiplier(address pool, uint256 newMultiplier)
        external
        onlyOwner
    {
        require(pool.isContract(), "MPHIssuanceModel: pool not contract");
        poolFunderRewardMultiplier[pool] = newMultiplier;
        emit ESetParamUint(
            msg.sender,
            "poolFunderRewardMultiplier",
            pool,
            newMultiplier
        );
    }

    function setPoolDepositorRewardVestPeriod(
        address pool,
        uint256 newVestPeriodInSeconds
    ) external onlyOwner {
        require(pool.isContract(), "MPHIssuanceModel: pool not contract");
        poolDepositorRewardVestPeriod[pool] = newVestPeriodInSeconds;
        emit ESetParamUint(
            msg.sender,
            "poolDepositorRewardVestPeriod",
            pool,
            newVestPeriodInSeconds
        );
    }

    function setPoolFunderRewardVestPeriod(
        address pool,
        uint256 newVestPeriodInSeconds
    ) external onlyOwner {
        require(pool.isContract(), "MPHIssuanceModel: pool not contract");
        poolFunderRewardVestPeriod[pool] = newVestPeriodInSeconds;
        emit ESetParamUint(
            msg.sender,
            "poolFunderRewardVestPeriod",
            pool,
            newVestPeriodInSeconds
        );
    }

    function setDevRewardMultiplier(uint256 newMultiplier) external onlyOwner {
        require(
            newMultiplier <= PRECISION,
            "MPHIssuanceModel: invalid multiplier"
        );
        devRewardMultiplier = newMultiplier;
        emit ESetParamUint(
            msg.sender,
            "devRewardMultiplier",
            address(0),
            newMultiplier
        );
    }
}

pragma solidity 0.5.17;

import "@openzeppelin/contracts/math/SafeMath.sol";

// Decimal math library
library DecMath {
    using SafeMath for uint256;

    uint256 internal constant PRECISION = 10**18;

    function decmul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a.mul(b).div(PRECISION);
    }

    function decdiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return a.mul(PRECISION).div(b);
    }
}

pragma solidity 0.5.17;

interface IMPHIssuanceModel {
    /**
        @notice Computes the MPH amount to reward to a depositor upon deposit.
        @param  pool The DInterest pool trying to mint reward
        @param  depositAmount The deposit amount in the pool's stablecoins
        @param  depositPeriodInSeconds The deposit's lock period in seconds
        @param  interestAmount The deposit's fixed-rate interest amount in the pool's stablecoins
        @return depositorReward The MPH amount to mint to the depositor
                devReward The MPH amount to mint to the dev wallet
                govReward The MPH amount to mint to the gov treasury
     */
    function computeDepositorReward(
        address pool,
        uint256 depositAmount,
        uint256 depositPeriodInSeconds,
        uint256 interestAmount
    )
        external
        view
        returns (
            uint256 depositorReward,
            uint256 devReward,
            uint256 govReward
        );

    /**
        @notice Computes the MPH amount to take back from a depositor upon withdrawal.
                If takeBackAmount > devReward + govReward, the extra MPH should be burnt.
        @param  pool The DInterest pool trying to mint reward
        @param  mintMPHAmount The MPH amount originally minted to the depositor as reward
        @param  early True if the deposit is withdrawn early, false if the deposit is mature
        @return takeBackAmount The MPH amount to take back from the depositor
                devReward The MPH amount from takeBackAmount to send to the dev wallet
                govReward The MPH amount from takeBackAmount to send to the gov treasury
     */
    function computeTakeBackDepositorRewardAmount(
        address pool,
        uint256 mintMPHAmount,
        bool early
    )
        external
        view
        returns (
            uint256 takeBackAmount,
            uint256 devReward,
            uint256 govReward
        );

    /**
        @notice Computes the MPH amount to reward to a deficit funder upon withdrawal of an underlying deposit.
        @param  pool The DInterest pool trying to mint reward
        @param  depositAmount The deposit amount in the pool's stablecoins
        @param  fundingCreationTimestamp The timestamp of the funding's creation, in seconds
        @param  maturationTimestamp The maturation timestamp of the deposit, in seconds
        @param  interestPayoutAmount The interest payout amount to the funder, in the pool's stablecoins.
                                     Includes the interest from other funded deposits.
        @param  early True if the deposit is withdrawn early, false if the deposit is mature
        @return funderReward The MPH amount to mint to the funder
                devReward The MPH amount to mint to the dev wallet
                govReward The MPH amount to mint to the gov treasury
     */
    function computeFunderReward(
        address pool,
        uint256 depositAmount,
        uint256 fundingCreationTimestamp,
        uint256 maturationTimestamp,
        uint256 interestPayoutAmount,
        bool early
    )
        external
        view
        returns (
            uint256 funderReward,
            uint256 devReward,
            uint256 govReward
        );

    /**
        @notice The period over which the depositor reward will be vested, in seconds.
     */
    function poolDepositorRewardVestPeriod(address pool)
        external
        view
        returns (uint256 vestPeriodInSeconds);

    /**
        @notice The period over which the funder reward will be vested, in seconds.
     */
    function poolFunderRewardVestPeriod(address pool)
        external
        view
        returns (uint256 vestPeriodInSeconds);
}

pragma solidity ^0.5.5;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

pragma solidity ^0.5.0;

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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.0;

import "../GSN/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.5.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}