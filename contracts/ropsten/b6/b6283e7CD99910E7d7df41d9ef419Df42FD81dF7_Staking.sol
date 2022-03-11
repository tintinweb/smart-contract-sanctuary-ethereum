/*

          88888888                         88888888
       8888    888888                   888888    8888
     888    88  8888888               8888  8888     888
    888        888888888             888888888888     888
   888        88888888888           8888888888888      888
   888      8888888888888           888888888888       888
    888     888888888888             888888888        888
     888     888  88888      _=_      8888888  88    888
       8888    888888      q(-_-)p      888888    8888
          88888888         '_) (_`         88888888
             88            /__/  \            88
             88          _(<_   / )_          88
            8888        (__\_\_|_/__)        8888

 _____ ______   ________  ________   _________  ________  ________          ________  _________  ________  ___  __    ___  ________   ________
|\   _ \  _   \|\   __  \|\   ___  \|\___   ___\\   __  \|\   __  \        |\   ____\|\___   ___\\   __  \|\  \|\  \ |\  \|\   ___  \|\   ____\
\ \  \\\__\ \  \ \  \|\  \ \  \\ \  \|___ \  \_\ \  \|\  \ \  \|\  \       \ \  \___|\|___ \  \_\ \  \|\  \ \  \/  /|\ \  \ \  \\ \  \ \  \___|
 \ \  \\|__| \  \ \   __  \ \  \\ \  \   \ \  \ \ \   _  _\ \   __  \       \ \_____  \   \ \  \ \ \   __  \ \   ___  \ \  \ \  \\ \  \ \  \  ___
  \ \  \    \ \  \ \  \ \  \ \  \\ \  \   \ \  \ \ \  \\  \\ \  \ \  \       \|____|\  \   \ \  \ \ \  \ \  \ \  \\ \  \ \  \ \  \\ \  \ \  \|\  \
   \ \__\    \ \__\ \__\ \__\ \__\\ \__\   \ \__\ \ \__\\ _\\ \__\ \__\        ____\_\  \   \ \__\ \ \__\ \__\ \__\\ \__\ \__\ \__\\ \__\ \_______\
    \|__|     \|__|\|__|\|__|\|__| \|__|    \|__|  \|__|\|__|\|__|\|__|       |\_________\   \|__|  \|__|\|__|\|__| \|__|\|__|\|__| \|__|\|_______|
                                                                              \|_________|
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../SomaNetwork/utils/NetworkAccessUpgradeable.sol";
import "../SecurityTokens/ERC20/utils/ERC20Helper.sol";

contract Staking is ReentrancyGuardUpgradeable, NetworkAccessUpgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using ERC20Helper for IERC20;

    /************************************ Variables ************************************/

    /* Constants */
    bytes32 public constant GLOBAL_ADMIN_ROLE = keccak256('SomaStaking:global-admin-role');
    bytes32 public LOCAL_ADMIN_ROLE;

    /* Tokens utilised in the contract */
    IERC20 public rewardToken;
    IERC20 public stakingToken;

    /* Current strategy index */
    uint256 public currentStrategy;

    /* Accrued tokens per share */
    uint256 public TPS;

    /* Amount of staked tokens globally */
    uint256 public globalStake;

    /* Precision factor for high accuracy */
    uint256 public PRECISION_FACTOR;

    /* Admin claimable amounts for immediate withdrawm/claim % tokens */
    uint256 public adminStakingClaimable;
    uint256 public adminRewardsClaimable;

    /* Early penalties */
    uint256 unstakeTime;
    uint256 claimTime;
    uint256 earlyUnstakePercentage;
    uint256 earlyClaimPercentage;

    /* Strategy type structure */
    struct Strategies {
        uint256 startDate;
        uint256 endDate;
        uint256 rewardsLocked;
        uint256 rewardsUnlocked;
    }

    Strategies[] public strategies;

    /* UserInfo type structure */
    struct UserInfo {
        uint256 stake; // How many tokens the user has staked
        uint256 rewardDebt; // Reward debt the user has accumilated
        uint256 userClaimable; // Rewards claimable by the user
        uint256 unstakeTimestamp; // Time the user has requested to unstake
        uint256 claimTimestamp; // Time the user has requested to claim
    }

    mapping(address => UserInfo) public userInfo; // User info mapping to all addresses

    /************************************ Events ************************************/
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event Claimed(address indexed user, uint256 amount);
    event AdminTokenRecovery(address tokenRecovered, uint256 amount);

    /************************************ Constructor ************************************/
    constructor(address networkAddress) NetworkAccessUpgradeable(networkAddress) {}

    function initialize(
        IERC20 _stakingToken,
        IERC20 _rewardToken
    ) external initializer {
        __ReentrancyGuard_init();
        __NetworkAccess_init();

        LOCAL_ADMIN_ROLE = keccak256(abi.encodePacked(block.timestamp, address(this), msg.sender, 'SomaStaking:local-admin-role'));

        stakingToken = _stakingToken;
        rewardToken = _rewardToken;

        uint256 decimalsRewardToken = rewardToken.tryDecimals();
        require(decimalsRewardToken < 30, "Must be inferior to 30");

        PRECISION_FACTOR = uint256(10**(uint256(30).sub(decimalsRewardToken)));

        currentStrategy = 0;
    }

    /************************************ Getters ************************************/

    function getTPS() public view returns (uint256) {
        uint256 viewTPS = 0;

        if (
            block.timestamp < strategies[currentStrategy].endDate ||
            currentStrategy == strategies.length - 1
        ) {
            viewTPS = _viewTPS(currentStrategy);
        } else {
            uint256 index = currentStrategy;

            while (block.timestamp > strategies[index].endDate) {
                viewTPS = _viewTPS(index);

                if (index == strategies.length - 1) {
                    break;
                }

                index++;
            }
        }

        return viewTPS;
    }

    function _viewTPS(uint256 index) internal view returns (uint256) {
        uint256 rewardsUnlocked = 0;
        uint256 timestamp = block.timestamp;

        if (timestamp >= strategies[index].endDate) {
            timestamp = strategies[index].endDate;
        }

        rewardsUnlocked =
        ((timestamp - strategies[index].startDate) *
        strategies[index].rewardsLocked) /
        (strategies[index].endDate - strategies[index].startDate) -
        strategies[index].rewardsUnlocked;

        if (globalStake == 0) {
            return TPS;
        } else {
            return TPS.add((rewardsUnlocked * PRECISION_FACTOR) / globalStake);
        }
    }

    function getUserDebt(address _account) external view returns (uint256) {
        uint256 localTPS = getTPS();

        return (userInfo[_account].stake.mul(localTPS)).div(PRECISION_FACTOR);
    }

    function getUserClaimable(address _account) external view returns (uint256) {
        uint256 localTPS = getTPS();

        return
        userInfo[_account]
        .userClaimable
        .add((userInfo[_account].stake.mul(localTPS)).div(PRECISION_FACTOR))
        .sub(userInfo[_account].rewardDebt);
    }

    function getUserStake(address _account) external view returns (uint256) {
        return userInfo[_account].stake;
    }

    /************************************ Setters ************************************/

    /** @dev Stakes the users tokens and updates global TPS
   * @param _amount Amount of staking tokens the user would like to stake
   */
    function stake(uint256 _amount) external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(_amount > 0, "Cannot stake 0");

        _updatePool();

        if (user.stake > 0) {
            user.userClaimable = user.userClaimable.add(
                user.stake.mul(TPS).div(PRECISION_FACTOR).sub(user.rewardDebt)
            );
        }

        if (_amount > 0) {
            user.stake = user.stake.add(_amount);
            globalStake = globalStake.add(_amount);

            stakingToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
        }

        user.rewardDebt = user.stake.mul(TPS).div(PRECISION_FACTOR);

        emit Staked(msg.sender, _amount);
    }

    /** @dev Unstakes the users tokens and updates global TPS
   * @param _amount Amount of staking tokens the user would like to stake
   * @notice User has to run this function twice, once to initialise the intention to unstake, the second after the wait period has passed
   */
    function unstake(uint256 _amount) external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(user.stake >= _amount, "Amount to withdraw too high");
        require(_amount > 0, "Cannot unstake 0");

        // If unstakeTimestamp is larger than 0 but less than the current strategy wait time, fail.
        if (
            (user.unstakeTimestamp > 0) &&
            ((block.timestamp - user.unstakeTimestamp) < unstakeTime)
        ) {
            revert("Unstaking time not met");
        }

        if (user.unstakeTimestamp == 0) {
            user.unstakeTimestamp = block.timestamp;
        } else {
            _updatePool();

            if (user.stake > 0) {
                user.userClaimable = user.userClaimable.add(
                    user.stake.mul(TPS).div(PRECISION_FACTOR).sub(user.rewardDebt)
                );
            }

            if (_amount > 0) {
                user.stake = user.stake.sub(_amount);
                globalStake = globalStake.sub(_amount);

                stakingToken.safeTransfer(address(msg.sender), _amount);
            }

            user.rewardDebt = user.stake.mul(TPS).div(PRECISION_FACTOR);

            user.unstakeTimestamp = 0;

            emit Unstaked(msg.sender, _amount);
        }
    }

    /** @dev Unstakes the users tokens and updates global TPS
   * @param _amount Amount of staking tokens the user would like to stake
   * @notice Allows users to immediately unstake, but with a penalty
   */
    function immediateUnstake(uint256 _amount) external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(user.stake >= _amount, "Amount to withdraw too high");
        require(_amount > 0, "Cannot unstake 0");

        _updatePool();

        if (user.stake > 0) {
            user.userClaimable = user.userClaimable.add(
                user.stake.mul(TPS).div(PRECISION_FACTOR).sub(user.rewardDebt)
            );
        }

        if (_amount > 0) {
            user.stake = user.stake.sub(_amount);
            globalStake = globalStake.sub(_amount);

            uint256 adminAmount = (_amount * earlyUnstakePercentage) / 10000;

            adminStakingClaimable = adminStakingClaimable.add(adminAmount);

            stakingToken.safeTransfer(address(msg.sender), _amount - adminAmount);
        }

        user.rewardDebt = user.stake.mul(TPS).div(PRECISION_FACTOR);

        user.unstakeTimestamp = 0;

        emit Unstaked(msg.sender, _amount);
    }

    /** @dev Claims the users reward tokens and updates global TPS
   * @notice User has to run this function twice, once to initialise the intention to claim, the second after the wait period has passed
   */
    function claim() external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(user.stake >= 0, "Amount to withdraw too high");

        // If claimTimestamp is larger than 0 but less than the current strategy wait time, fail.
        if (
            (user.claimTimestamp > 0) &&
            ((block.timestamp - user.claimTimestamp) < claimTime)
        ) {
            revert("Unstaking time not met");
        }

        if (user.claimTimestamp == 0) {
            user.claimTimestamp = block.timestamp;
        } else {
            _updatePool();

            uint256 claimable = user.userClaimable.add(
                user.stake.mul(TPS).div(PRECISION_FACTOR).sub(user.rewardDebt)
            );

            require(user.userClaimable > 0, "Nothing to claim");

            rewardToken.safeTransfer(address(msg.sender), claimable);

            // Reset user claimable to 0
            user.userClaimable = 0;

            user.rewardDebt = user.stake.mul(TPS).div(PRECISION_FACTOR);

            user.claimTimestamp = 0;

            emit Claimed(msg.sender, claimable);
        }
    }

    /** @dev Claims the users reward tokens and updates global TPS
   * @notice Allows users to immediately claim, but with a penalty
   */
    function immediateClaim() external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(user.stake >= 0, "Amount to withdraw too high");

        _updatePool();

        uint256 claimable = user.userClaimable.add(
            user.stake.mul(TPS).div(PRECISION_FACTOR).sub(user.rewardDebt)
        );

        uint256 adminAmount = (claimable * earlyClaimPercentage) / 10000;

        adminRewardsClaimable = adminRewardsClaimable.add(adminAmount);

        require(user.userClaimable > 0, "Nothing to claim");

        rewardToken.safeTransfer(address(msg.sender), claimable - adminAmount);

        // Reset user claimable to 0
        user.userClaimable = 0;

        user.rewardDebt = user.stake.mul(TPS).div(PRECISION_FACTOR);

        user.claimTimestamp = 0;

        emit Claimed(msg.sender, claimable);
    }

    /** @dev Allows the admin to claim any staking tokens left from immediate unstakes
   */
    function claimStakingAdmin(address recipient) external onlyAdmin {
        require(adminStakingClaimable > 0, "Nothing to claim");
        stakingToken.safeTransfer(recipient, adminStakingClaimable);
        adminStakingClaimable = 0;
    }

    /** @dev Allows the admin to claim any staking tokens left from immediate claims
   */
    function claimRewardsAdmin(address recipient) external onlyAdmin {
        require(adminRewardsClaimable > 0, "Nothing to claim");
        rewardToken.safeTransfer(recipient, adminRewardsClaimable);
        adminRewardsClaimable = 0;
    }

    /** @dev Change the penalty parameters
   * @param _unstakeTime Time requirement for unstaking
   * @param _claimTime Time requirement for claiming
   * @param _earlyUnstakePercentage Percentage penalty for early unstake
   * @param _earlyClaimPercentage Percentage penalty for early claim
   */

    function changePenaltyParams(
        uint256 _unstakeTime,
        uint256 _claimTime,
        uint256 _earlyUnstakePercentage,
        uint256 _earlyClaimPercentage
    ) external onlyAdmin {
        unstakeTime = _unstakeTime;
        claimTime = _claimTime;
        earlyUnstakePercentage = _earlyUnstakePercentage;
        earlyClaimPercentage = _earlyClaimPercentage;
    }

    /** @dev Sets a new strategy
   * @param _startDate Start date of the strategy
   * @param _endDate End date of the strategy
   * @param _unstakeTime Time requirement for unstaking
   * @param _claimTime Time requirement for claiming
   * @param _earlyUnstakePercentage Percentage penalty for early unstake
   * @param _earlyClaimPercentage Percentage penalty for early claim
   * @param _rewardsLocked Amount of rewards to lock with the strategy
   */
    function setStrategy(
        uint256 _startDate,
        uint256 _endDate,
        uint256 _unstakeTime,
        uint256 _claimTime,
        uint256 _earlyUnstakePercentage,
        uint256 _earlyClaimPercentage,
        uint256 _rewardsLocked
    ) external onlyAdmin {
        _setStrategy(
            _startDate,
            _endDate,
            _unstakeTime,
            _claimTime,
            _earlyUnstakePercentage,
            _earlyClaimPercentage,
            _rewardsLocked
        );
    }

    function _setStrategy(
        uint256 _startDate,
        uint256 _endDate,
        uint256 _unstakeTime,
        uint256 _claimTime,
        uint256 _earlyUnstakePercentage,
        uint256 _earlyClaimPercentage,
        uint256 _rewardsLocked
    ) internal onlyAdmin {
        Strategies memory tempStategy;

        tempStategy.startDate = _startDate;
        tempStategy.endDate = _endDate;
        tempStategy.rewardsLocked = _rewardsLocked;

        unstakeTime = _unstakeTime;
        claimTime = _claimTime;
        earlyUnstakePercentage = _earlyUnstakePercentage;
        earlyClaimPercentage = _earlyClaimPercentage;

        rewardToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _rewardsLocked
        );

        strategies.push(tempStategy);
    }

    function _updatePool() internal {
        if (
            block.timestamp < strategies[currentStrategy].endDate ||
            currentStrategy == strategies.length - 1
        ) {
            _rewardsUpdate(currentStrategy);
        } else {
            uint256 index = currentStrategy;

            while (block.timestamp > strategies[index].endDate) {
                currentStrategy = index;
                _rewardsUpdate(index);

                if (index == strategies.length - 1) {
                    break;
                }

                index++;
            }
        }
    }

    function _rewardsUpdate(uint256 index) internal {
        if (globalStake != 0) {
            uint256 rewardsUnlocked = 0;
            uint256 timestamp = block.timestamp;

            if (timestamp >= strategies[index].endDate) {
                timestamp = strategies[index].endDate;
            }

            // Calculate the amount of rewards unlocked
            rewardsUnlocked =
            ((timestamp - strategies[index].startDate) *
            strategies[index].rewardsLocked) /
            (strategies[index].endDate - strategies[index].startDate) -
            strategies[index].rewardsUnlocked;

            // Update strategies rewards unlocked

            strategies[index].rewardsUnlocked += rewardsUnlocked;

            // Update TPS
            TPS += (rewardsUnlocked * PRECISION_FACTOR) / globalStake;
        }
    }

    /************************************ Utils ************************************/

    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount)
    external
    onlyAdmin
    {
        require(_tokenAddress != address(stakingToken), "Cannot be staked token");
        require(_tokenAddress != address(rewardToken), "Cannot be reward token");

        IERC20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);

        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }
    /************************************ Modifiers ************************************/

    modifier onlyAdmin {
        require(
            hasRole(LOCAL_ADMIN_ROLE, _msgSender()) || hasRole(GLOBAL_ADMIN_ROLE, _msgSender()),
            'Only the admin is allowed to do this'
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
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
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address sender,
        address recipient,
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

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";

import "../../../utils/security/IPausable.sol";

import "./INetworkAccess.sol";
import "../ISomaNetwork.sol";

abstract contract NetworkAccessUpgradeable is INetworkAccess, ContextUpgradeable, ERC165Upgradeable {
    function __NetworkAccess_init() internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __NetworkAccess_init_unchained();
    }

    function __NetworkAccess_init_unchained() internal onlyInitializing {
    }

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    ISomaNetwork immutable public network;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address networkAddress) {
        // check 0 address
        network = ISomaNetwork(networkAddress);
    }

    modifier whenNotPaused() {
        require(!IPausable(address(network)).paused(), 'NetworkAccess: The network is currently paused.');
        _;
    }

    modifier onlyRole(bytes32 role) {
        require(hasRole(role, _msgSender()), "SomaNetwork: caller does not have the appropriate authority");
        _;
    }

    function NETWORK_KEY() external view virtual override returns (bytes32) {
        return 0;
    }

    function VERSION() external view virtual override returns (bytes32) {
        return bytes32('v1.0.0');
    }

    function REQUIRED_ROLES() external view virtual override returns (bytes32[] memory) {
        return new bytes32[](0);
    }

    function PARENT_ROLES() public view virtual override returns (ParentRole[] memory roles) {
        roles = new ParentRole[](0);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(INetworkAccess).interfaceId ||
        interfaceId == type(IAccessControlUpgradeable).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return IAccessControlUpgradeable(address(network)).getRoleAdmin(role);
    }

    function paused() public view virtual override returns (bool) {
        return IPausable(address(network)).paused();
    }

    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return IAccessControlUpgradeable(address(network)).hasRole(role, account);
    }

    function addedToNetwork() public virtual override {
        // only the actual message sender can call this method (do not allow sender forwarding)
        require(msg.sender == address(network), 'NetworkAccess: only the network can call this hook');
        emit AddedToNetwork();
    }

    function removedFromNetwork() public virtual override {
        // only the actual message sender can call this method (do not allow sender forwarding)
        require(msg.sender == address(network), 'NetworkAccess: only the network can call this hook');
        emit RemovedFromNetwork();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20WithDetails is IERC20 {
    function decimals() external view returns (uint256);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
}

library ERC20Helper {

    function name(IERC20 target) internal view returns (string memory) {
        return name(address(target));
    }

    function name(address target) internal view returns (string memory) {
        return IERC20WithDetails(target).name();
    }

    function tryName(IERC20 target) internal view returns (string memory) {
        return tryName(address(target), "");
    }

    function tryName(address target) internal view returns (string memory) {
        return tryName(target, "");
    }

    function tryName(IERC20 target, string memory defaultName) internal view returns (string memory) {
        return tryName(address(target), defaultName);
    }

    function tryName(address target, string memory defaultName) internal view returns (string memory result) {
        try IERC20WithDetails(target).name() returns (string memory result_) {
            result = result_;
        } catch(bytes memory) {
            result = defaultName;
        }
    }

    function symbol(IERC20 target) internal view returns (string memory) {
        return symbol(address(target));
    }

    function symbol(address target) internal view returns (string memory) {
        return IERC20WithDetails(target).symbol();
    }

    function trySymbol(IERC20 target) internal view returns (string memory) {
        return trySymbol(address(target), "");
    }

    function trySymbol(address target) internal view returns (string memory) {
        return trySymbol(target, "");
    }

    function trySymbol(IERC20 target, string memory defaultSymbol) internal view returns (string memory) {
        return trySymbol(address(target), defaultSymbol);
    }

    function trySymbol(address target, string memory defaultSymbol) internal view returns (string memory result) {
        try IERC20WithDetails(target).symbol() returns (string memory result_) {
            result = result_;
        } catch(bytes memory) {
            result = defaultSymbol;
        }
    }

    function decimals(IERC20 target) internal view returns (uint256) {
        return decimals(address(target));
    }

    function decimals(address target) internal view returns (uint256) {
        return IERC20WithDetails(target).decimals();
    }

    function tryDecimals(IERC20 target) internal view returns (uint256) {
        return tryDecimals(address(target), 18);
    }

    function tryDecimals(address target) internal view returns (uint256) {
        return tryDecimals(target, 18);
    }

    function tryDecimals(IERC20 target, uint256 defaultDecimals) internal view returns (uint256) {
        return tryDecimals(address(target), defaultDecimals);
    }

    function tryDecimals(address target, uint256 defaultDecimals) internal view returns (uint256 result) {
        try IERC20WithDetails(target).decimals() returns (uint256 result_) {
            result = result_;
        } catch(bytes memory) {
            result = defaultDecimals;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0-rc.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0-rc.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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
// OpenZeppelin Contracts (last updated v4.5.0-rc.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IPausable {

    function paused() external view returns (bool);

    function pause() external;

    function unpause() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface INetworkAccess {

    event AddedToNetwork();
    event RemovedFromNetwork();

    struct ParentRole {
        bytes32 parent;
        bytes32[] children;
    }

    function NETWORK_KEY() external view returns (bytes32);
    function VERSION() external view returns (bytes32);
    function REQUIRED_ROLES() external view returns (bytes32[] memory roles);
    function PARENT_ROLES() external view returns (ParentRole[] memory roles);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function paused() external view virtual returns (bool);
    function hasRole(bytes32 role, address account) external view returns (bool);

    function addedToNetwork() external;
    function removedFromNetwork() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface ISomaNetwork {

    function PAUSE_ROLE() external view returns (bytes32);
    function ASSIGN_KEY_ROLE() external view returns (bytes32);
    function BASIC_ROLE_MANAGER() external view returns (bytes32);
    function APPROVE_ACCESS_ROLE() external view returns (bytes32);
    function LOCAL_REVOKE_ACCESS_ROLE() external view returns (bytes32);
    function GLOBAL_REVOKE_ACCESS_ROLE() external view returns (bytes32);

    function add(address account) external;

    function remove(address account) external;
    
    function access(address account) external view returns (bool);

    function get(bytes32 key) external view returns(address);

    function owner() external view returns (address);

    function keyOf(address account) external view returns (bytes32);

    function rolesOf(address account) external view returns (bytes32[] memory);

    function accountsOf(bytes32 role) external view returns (address[] memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}