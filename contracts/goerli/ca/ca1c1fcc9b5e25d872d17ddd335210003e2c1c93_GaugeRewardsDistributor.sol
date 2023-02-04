// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.15;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ================== GaugeRewardsDistributor ==================
// ====================================================================
// Looks at the gauge controller contract and pushes out IQ rewards once
// a week to the gauges (farms)

// Everipedia: https://github.com/EveripediaNetwork
// Frax Finance: https://github.com/FraxFinance

// Primary Author(s)
// Travis Moore: https://github.com/FortisFortuna

// Reviewer(s) / Contributor(s)
// Jason Huan: https://github.com/jasonhuan
// Sam Kazemian: https://github.com/samkazemian
// Cesar Rodriguez: https://github.com/kesar

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IGaugeController.sol";
import "../Utils/TransferHelper.sol";

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IMiddlemanGauge {
    function pullAndBridge(uint256 reward_amount) external;
}

contract GaugeRewardsDistributor is Ownable {
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    // Instances and addresses
    address public reward_token_address;
    IGaugeController public gauge_controller;

    // Admin addresses
    address public curator_address;

    // Constants
    uint256 private constant MULTIPLIER_PRECISION = 1e18;
    uint256 private constant ONE_WEEK = 7 days;

    // Gauge controller related
    mapping(address => bool) public gauge_whitelist;
    mapping(address => bool) public is_middleman; // For cross-chain farms, use a middleman contract to push to a bridge
    mapping(address => uint256) public last_time_gauge_paid;

    // Booleans
    bool public distributionsOn;

    /* ========== MODIFIERS ========== */

    modifier onlyByOwnerOrCurator() {
        require(msg.sender == owner() || msg.sender == curator_address, "Not owner or curator");
        _;
    }

    modifier isDistributing() {
        require(distributionsOn == true, "Distributions are off");
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _owner,
        address _curator_address,
        address _reward_token_address,
        address _gauge_controller_address
    )
        Ownable()
    {
        curator_address = _curator_address;
        _transferOwnership(_owner);

        reward_token_address = _reward_token_address;
        gauge_controller = IGaugeController(_gauge_controller_address);

        distributionsOn = true;
    }

    /* ========== VIEWS ========== */

    // Current weekly reward amount
    function currentReward(address gauge_address) public view returns (uint256 reward_amount) {
        uint256 rel_weight = gauge_controller.gauge_relative_weight(gauge_address, block.timestamp);
        uint256 rwd_rate = (gauge_controller.global_emission_rate() * rel_weight) / MULTIPLIER_PRECISION;
        reward_amount = rwd_rate * ONE_WEEK;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    // Callable by anyone
    function distributeReward(address gauge_address)
        public
        isDistributing
        returns (uint256 weeks_elapsed, uint256 reward_tally)
    {
        require(gauge_whitelist[gauge_address], "Gauge not whitelisted");

        // Calculate the elapsed time in weeks.
        uint256 last_time_paid = last_time_gauge_paid[gauge_address];

        // Edge case for first reward for this gauge
        if (last_time_paid == 0) {
            weeks_elapsed = 1;
        } else {
            // Truncation desired
            weeks_elapsed = (block.timestamp).sub(last_time_paid) / ONE_WEEK;

            // Return early here for 0 weeks instead of throwing, as it could have bad effects in other contracts
            if (weeks_elapsed == 0) {
                return (0, 0);
            }
        }

        // NOTE: This will always use the current global_emission_rate()
        reward_tally = 0;
        uint256 this_weeks_elapsed = weeks_elapsed;
        for (uint256 i = 0; i < this_weeks_elapsed; i++) {
            uint256 rel_weight_at_week;
            if (i == 0) {
                // Mutative, for the current week. Makes sure the weight is checkpointed. Also returns the weight.
                rel_weight_at_week = gauge_controller.gauge_relative_weight_write(gauge_address, block.timestamp);
            } else {
                // View
                rel_weight_at_week =
                    gauge_controller.gauge_relative_weight(gauge_address, (block.timestamp).sub(ONE_WEEK * i));
            }
            uint256 rwd_rate_at_week = (gauge_controller.global_emission_rate()).mul(rel_weight_at_week).div(1e18);
            reward_tally = reward_tally.add(rwd_rate_at_week.mul(ONE_WEEK));
        }

        // Update the last time paid
        last_time_gauge_paid[gauge_address] = block.timestamp;

        if (is_middleman[gauge_address]) {
            IERC20(reward_token_address).approve(gauge_address, reward_tally);
            IMiddlemanGauge(gauge_address).pullAndBridge(reward_tally);
        } else {
            TransferHelper.safeTransfer(reward_token_address, gauge_address, reward_tally);
        }

        emit RewardDistributed(gauge_address, reward_tally);
    }

    /* ========== RESTRICTED FUNCTIONS - Curator / migrator callable ========== */

    function toggleDistributions() external onlyByOwnerOrCurator {
        distributionsOn = !distributionsOn;

        emit DistributionsToggled(distributionsOn);
    }

    /* ========== RESTRICTED FUNCTIONS - Owner only ========== */

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        TransferHelper.safeTransfer(tokenAddress, owner(), tokenAmount);
        emit RecoveredERC20(tokenAddress, tokenAmount);
    }

    function setGaugeState(address _gauge_address, bool _is_middleman, bool _is_active) external onlyOwner {
        is_middleman[_gauge_address] = _is_middleman;
        gauge_whitelist[_gauge_address] = _is_active;

        emit GaugeStateChanged(_gauge_address, _is_middleman, _is_active);
    }

    function setCurator(address _new_curator_address) external onlyOwner {
        curator_address = _new_curator_address;
    }

    function setGaugeController(address _gauge_controller_address) external onlyOwner {
        gauge_controller = IGaugeController(_gauge_controller_address);
    }

    /* ========== EVENTS ========== */

    event RewardDistributed(address indexed gauge_address, uint256 reward_amount);
    event RecoveredERC20(address token, uint256 amount);
    event GaugeStateChanged(address gauge_address, bool is_middleman, bool is_active);
    event DistributionsToggled(bool distibutions_state);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.15;

// https://github.com/swervefi/swerve/edit/master/packages/swerve-contracts/interfaces/IGaugeController.sol

interface IGaugeController {
    function time_total() external view returns (uint256);

    function gauge_relative_weight(address) external view returns (uint256);

    function get_admin() external view returns (address);

    function gauge_relative_weight(address, uint256) external view returns (uint256);

    function global_emission_rate() external view returns (uint256);

    function get_total_weight() external view returns (uint256);

    function gauge_relative_weight_write(address, uint256) external returns (uint256);

    function add_type(string calldata, uint256) external;

    function add_gauge(address, int128, uint256) external;

    function change_global_emission_rate(uint256) external;

    function vote_for_gauge_weights(address, uint256) external;

    function checkpoint_gauge(address) external;

    function commit_transfer_ownership(address) external;

    function apply_transfer_ownership() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeTransfer(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FAILED");
    }
}