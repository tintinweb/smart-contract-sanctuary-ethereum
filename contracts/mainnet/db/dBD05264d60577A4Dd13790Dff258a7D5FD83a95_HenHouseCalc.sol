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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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

    constructor() {
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

// SPDX-License-Identifier: MIT

/*

&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,[email protected]       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at [email protected]
 * Found a broken egg in our contracts? We have a bug bounty program [email protected]
 * Y'all have a nice day

*/

pragma solidity ^0.8.17;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import './interfaces/IEGGToken.sol';
import './interfaces/IFarmAnimals.sol';
import './interfaces/IHenHouse.sol';
import './interfaces/IHenHouseAdvantage.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

contract HenHouseCalc is Ownable, ReentrancyGuard, Pausable {
  using SafeMath for uint256;

  // Events
  event InitializedContract(address thisContract);

  // Interfaces
  IFarmAnimals public farmAnimalsNFT; // ref to the FarmAnimals NFT contract
  IEGGToken public eggToken; // ref to the $EGG contract for minting $EGG earnings
  IHenHouseAdvantage public henHouseAdvantage; // ref to HenHouseAdvantage contract
  IHenHouse public henHouse; // ref to Hen House contract

  mapping(address => bool) private controllers; // address => allowedToCallFunctions

  // Hens
  uint256 public constant DAILY_EGG_RATE = 10000 ether; // Hens earn 10000 $EGG per day
  uint256 public constant DAILY_ROOSTER_EGG_RATE = 1000 ether; // Rooster earn 1000 ether per day on guard duty

  // Recource tracking
  uint256 public constant MAXIMUM_GLOBAL_EGG = 2880000000 ether; // there will only ever be (roughly) 2.88 billion $EGG earned through staking

  /** MODIFIERS */

  modifier requireContractsSet() {
    require(
      address(farmAnimalsNFT) != address(0) &&
        address(eggToken) != address(0) &&
        address(henHouseAdvantage) != address(0) &&
        address(henHouse) != address(0),
      'Contracts not set'
    );
    _;
  }

  /**
   * @dev Modifer to require _msgSender() to be a controller
   */
  modifier onlyController() {
    _isController();
    _;
  }

  // Optimize for bytecode size
  function _isController() internal view {
    require(controllers[_msgSender()], 'Only controllers');
  }

  constructor(
    IEGGToken _eggToken,
    IFarmAnimals _farmAnimalsNFT,
    IHenHouseAdvantage _henHouseAdvantage
  ) {
    eggToken = _eggToken;
    farmAnimalsNFT = _farmAnimalsNFT;
    henHouseAdvantage = _henHouseAdvantage;
    controllers[_msgSender()] = true;

    _pause();
    emit InitializedContract(address(this));
  }

  /**
   * ██ ███    ██ ████████
   * ██ ████   ██    ██
   * ██ ██ ██  ██    ██
   * ██ ██  ██ ██    ██
   * ██ ██   ████    ██
   * This section has internal only functions
   */

  /** ACCOUNTING */

  /** READ ONLY */

  /**
   * @notice Get token kind (chicken, coyote, rooster)
   * @param tokenId the ID of the token to check
   * @return kind
   */
  function _getKind(uint16 tokenId) internal view returns (IFarmAnimals.Kind) {
    return farmAnimalsNFT.getTokenTraits(tokenId).kind;
  }

  /**
   * @notice Gets the rank score for a Coyote
   * @param tokenId the ID of the Coyote to get the rank score for
   * @return the rank score of the Coyote & Rooster(5-8)
   */
  function _rankForCoyoteRooster(uint16 tokenId) internal view returns (uint8) {
    IFarmAnimals.Traits memory s = farmAnimalsNFT.getTokenTraits(tokenId);
    return uint8(s.advantage + 1); // rank index is 0-5
  }

  /**
    @notice Get claim earning amount by tokenId
    @param tokenId the ID of the token to claim earnings from
   */
  function _calcDailyEggRateOfHen(uint16 tokenId) internal view returns (uint256) {
    IFarmAnimals.Traits memory s = farmAnimalsNFT.getTokenTraits(tokenId);
    return (s.advantage * 1000 ether + DAILY_EGG_RATE);
  }

  /**
    @notice Get claim earning amount by tokenId
    @param tokenId the ID of the token to claim earnings from
   */
  function _calcDailyEggRateOfRooster(uint16 tokenId) internal view returns (uint256) {
    IFarmAnimals.Traits memory s = farmAnimalsNFT.getTokenTraits(tokenId);
    return (s.advantage * 100 ether + DAILY_ROOSTER_EGG_RATE);
  }

  /**
   * @notice Calculate Reward $EGG owed to a Hen by tokenID
   * @dev External function
   * @param tokenId the ID of the staked Hen to calculate $EGG reward amount
   * @return owed - the $EGG amount earned
   */

  function calculateRewardsHen(uint16 tokenId, IHenHouse.Stake memory stake)
    external
    view
    onlyController
    returns (uint256 owed)
  {
    owed = _calculateRewardsHen(tokenId, stake);
  }

  /**
   * @notice Calculate Reward $EGG owed to a Hen by tokenID
   * @dev Internal function
   * @param tokenId the ID of the staked Hen to calculate $EGG reward amount
   * @return owed - the $EGG amount earned
   */

  function _calculateRewardsHen(uint16 tokenId, IHenHouse.Stake memory stake) internal view returns (uint256 owed) {
    /**
     * Hen: Daily yeild
     * Hen: Advantage applied to yeild
     * Hen: Pay Tax
     */
    require(stake.owner == tx.origin, 'Caller not owner');
    IHenHouse.HenHouseInfo memory henHouseInfo = henHouse.getHenHouseInfo();
    IHenHouse.GuardHouseInfo memory guardHouseInfo = henHouse.getGuardHouseInfo();
    uint256 globalEgg = henHouseInfo.totalEGGEarnedByHen + guardHouseInfo.totalEGGEarnedByRooster;

    if (globalEgg < MAXIMUM_GLOBAL_EGG) {
      owed = ((block.timestamp - stake.stakedTimestamp) * _calcDailyEggRateOfHen(uint16(tokenId))) / 1 days;
    } else if (stake.stakedTimestamp > henHouseInfo.lastClaimTimestampByHen) {
      owed = 0; // $EGG production stopped already
    } else {
      owed =
        ((henHouseInfo.lastClaimTimestampByHen - stake.stakedTimestamp) * _calcDailyEggRateOfHen(uint16(tokenId))) /
        1 days; // stop earning additional $EGG if it's all been earned
    }
    owed = henHouseAdvantage.calculateAdvantageBonus(tokenId, owed);
  }

  /**
   * @notice Calculate Reward $EGG owed to a Hen by tokenID
   * @dev External function
   * @param tokenId the ID of the staked Hen to calculate $EGG reward amount
   * @return owed - the $EGG amount earned
   */

  function calculateRewardsCoyote(uint16 tokenId, uint8 rank) external view onlyController returns (uint256 owed) {
    owed = _calculateRewardsCoyote(tokenId, rank);
  }

  /**
   * @notice Calculate Reward $EGG owed to a Coyote by tokenID
   * @dev Internal function
   * @param tokenId the ID of the staked Coyote to calculate $EGG reward amount
   * @return owed - the $EGG amount earned
   */

  function _calculateRewardsCoyote(uint16 tokenId, uint8 rank) internal view returns (uint256 owed) {
    /**
     * Coyote: Tax yeild
     * Coyote: Advantage applied to yeild
     */

    IHenHouse.Stake memory stake = henHouse.getStakeInfo(tokenId);
    require(stake.owner == tx.origin, 'Caller not owner');
    IHenHouse.DenInfo memory denInfo = henHouse.getDenInfo();
    owed = (rank) * (denInfo.eggPerCoyoteRank - stake.eggPerRank); // Calculate portion of tokens based on Rank
    owed = henHouseAdvantage.calculateAdvantageBonus(tokenId, owed);
  }

  /**
   * @notice Calculate Reward $EGG owed to a Hen by tokenID
   * @dev External function
   * @param tokenId the ID of the staked Hen to calculate $EGG reward amount
   * @return owed - the $EGG amount earned
   */

  function calculateRewardsRooster(
    uint16 tokenId,
    uint8 rank,
    IHenHouse.Stake memory stake
  ) external view onlyController returns (uint256 owed) {
    owed = _calculateRewardsRooster(tokenId, rank, stake);
  }

  /**
   * @notice Calculate Reward $EGG owed to a Rooster by tokenID
   * @dev Internal function
   * @param tokenId the ID of the staked Rooster to calculate $EGG reward amount
   * @return owed - the $EGG amount earned
   */

  function _calculateRewardsRooster(
    uint16 tokenId,
    uint8 rank,
    IHenHouse.Stake memory stake
  ) internal view returns (uint256 owed) {
    /**
     * Rooster: Daily yeild
     * Rooster: Advantage applied to yeild
     * Rooster: One Off Egg
     * Rooster: Rescue Pool
     * Rooster: Risk pay Coyote
     */
    require(stake.owner == tx.origin, 'Caller not owner');
    IHenHouse.HenHouseInfo memory henHouseInfo = henHouse.getHenHouseInfo();
    IHenHouse.GuardHouseInfo memory guardHouseInfo = henHouse.getGuardHouseInfo();
    uint256 globalEgg = henHouseInfo.totalEGGEarnedByHen + guardHouseInfo.totalEGGEarnedByRooster;
    owed = (rank) * (guardHouseInfo.eggPerRoosterRank - stake.eggPerRank); // Calculate portion of daily EGG tokens based on Rank

    if (globalEgg < MAXIMUM_GLOBAL_EGG) {
      owed += ((block.timestamp.sub(stake.stakedTimestamp)).mul(_calcDailyEggRateOfRooster(tokenId))).div(1 days);
    } else if (stake.stakedTimestamp > guardHouseInfo.lastClaimTimestampByRooster) {
      owed += 0; // $EGG production stopped already
    } else {
      owed += (
        (guardHouseInfo.lastClaimTimestampByRooster.sub(stake.stakedTimestamp)).mul(_calcDailyEggRateOfRooster(tokenId))
      ).div(1 days); // stop earning additional $EGG if it's all been earned
    }
    owed = henHouseAdvantage.calculateAdvantageBonus(tokenId, owed);
    owed += stake.oneOffEgg;
    owed += (rank) * (guardHouseInfo.rescueEggPerRank - stake.rescueEggPerRank); // Calculate portion of rescued EGG tokens based on Rank
  }

  /**
   * @notice Calculate Reward $EGG token amount of token Id
   * @dev Internal function
   * @param tokenId the ID of the staked NFT to calculate $EGG reward amount
   * @return owed - the $EGG amount earned
   */

  function _calculateRewards(uint16 tokenId) internal view returns (uint256 owed) {
    IFarmAnimals.Kind kind = _getKind(tokenId);
    if (kind == IFarmAnimals.Kind.HEN) {
      IHenHouse.Stake memory stake = henHouse.getStakeInfo(tokenId);
      owed = _calculateRewardsHen(tokenId, stake);
    } else if (kind == IFarmAnimals.Kind.COYOTE) {
      uint8 rank = _rankForCoyoteRooster(tokenId);
      owed = _calculateRewardsCoyote(tokenId, rank);
    } else if (kind == IFarmAnimals.Kind.ROOSTER) {
      uint8 rank = _rankForCoyoteRooster(tokenId);
      IHenHouse.Stake memory stake = henHouse.getStakeInfo(tokenId);
      owed = _calculateRewardsRooster(tokenId, rank, stake);
    }
  }

  /**
   * ███████ ██   ██ ████████
   * ██       ██ ██     ██
   * █████     ███      ██
   * ██       ██ ██     ██
   * ███████ ██   ██    ██
   * This section has external functions
   */

  /** STAKING */

  /**
   * @notice Calculate Reward $EGG token amount of token Id
   * @param tokenId the ID of the NFT to calculate $EGG reward amount
   * @return owed - the $EGG amount earned
   */

  function calculateRewards(uint16 tokenId) external view returns (uint256 owed) {
    uint64 lastTokenWrite = farmAnimalsNFT.getTokenWriteBlock(tokenId);
    require(lastTokenWrite < block.number, 'Not allowed');
    owed = _calculateRewards(tokenId);
  }

  /**
   * @notice Calculate Reward $EGG token amount of token Id
   * @param tokenIds Array of the token IDs of the NFT to calculate $EGG reward amount
   * @return owed - the $EGG amount earned
   */

  function calculateAllRewards(uint16[] calldata tokenIds) external view returns (uint256 owed) {
    uint16 tokenId;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];
      uint64 lastTokenWrite = farmAnimalsNFT.getTokenWriteBlock(tokenId);
      require(lastTokenWrite < block.number, 'Not allowed');
      owed = owed.add(_calculateRewards(tokenId));
    }
  }

  /**
   *   ██████  ██     ██ ███    ██ ███████ ██████
   *  ██    ██ ██     ██ ████   ██ ██      ██   ██
   *  ██    ██ ██  █  ██ ██ ██  ██ █████   ██████
   *  ██    ██ ██ ███ ██ ██  ██ ██ ██      ██   ██
   *   ██████   ███ ███  ██   ████ ███████ ██   ██
   * This section will have all the internals set to onlyOwner
   */

  /**
   *  ██████  ██████  ███    ██ ████████ ██████   ██████  ██      ██      ███████ ██████
   * ██      ██    ██ ████   ██    ██    ██   ██ ██    ██ ██      ██      ██      ██   ██
   * ██      ██    ██ ██ ██  ██    ██    ██████  ██    ██ ██      ██      █████   ██████
   * ██      ██    ██ ██  ██ ██    ██    ██   ██ ██    ██ ██      ██      ██      ██   ██
   *  ██████  ██████  ██   ████    ██    ██   ██  ██████  ███████ ███████ ███████ ██   ██
   * This section if for controllers (possibly Owner) only functions
   */

  /**
   * @notice Internal call to enable an address to call controller only functions
   * @param _address the address to enable
   */
  function _addController(address _address) internal {
    controllers[_address] = true;
  }

  /**
   * @notice enables multiple addresses to call controller only functions
   * @dev Only callable by the owner or existing controller
   * @param _addresses array of the address to enable
   */
  function addManyControllers(address[] memory _addresses) external onlyController {
    for (uint256 i = 0; i < _addresses.length; i++) {
      _addController(_addresses[i]);
    }
  }

  /**
   * @notice removes an address from controller list and ability to call controller only functions
   * @dev Only callable by the owner or existing controller
   * @param _address the address to disable
   */
  function removeController(address _address) external onlyController {
    controllers[_address] = false;
  }

  /**
   * @notice Enables owner to pause / unpause contract
   */
  function setPaused(bool _paused) external requireContractsSet onlyController {
    if (_paused) _pause();
    else _unpause();
  }

  /**
   * @notice Set the henHouseAdvantage contract address.
   * @dev Only callable by the owner.
   */
  function setHenHouseAdvantage(address _henHouseAdvantage) external onlyController {
    henHouseAdvantage = IHenHouseAdvantage(_henHouseAdvantage);
  }

  /**
   * @notice Set the henHouse contract address.
   * @dev Only callable by the owner.
   */
  function setHenHouse(address _henHouse) external onlyController {
    henHouse = IHenHouse(_henHouse);
  }
}

// SPDX-License-Identifier: MIT

/*

&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,[email protected]       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at [email protected]
 * Found a broken egg in our contracts? We have a bug bounty program [email protected]
 * Y'all have a nice day

*/

pragma solidity ^0.8.17;

interface IEGGToken {
  function balanceOf(address account) external view returns (uint256);

  function mint(address to, uint256 amount) external;

  function burn(address from, uint256 amount) external;

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  function addLiquidityETH(uint256 tokenAmount, uint256 ethAmount)
    external
    payable
    returns (
      uint256 amountToken,
      uint256 amountETH,
      uint256 liquidity
    );
}

// SPDX-License-Identifier: MIT

/*

&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,[email protected]       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at [email protected]
 * Found a broken egg in our contracts? We have a bug bounty program [email protected]
 * Y'all have a nice day

*/

pragma solidity ^0.8.13;

import 'erc721a/contracts/extensions/IERC721AQueryable.sol';

interface IFarmAnimals is IERC721AQueryable {
  // Kind of Character
  enum Kind {
    HEN,
    COYOTE,
    ROOSTER
  }

  // NFT Traits
  struct Traits {
    Kind kind;
    uint8 advantage;
    uint8[8] traits;
  }

  function burn(uint16 tokenId) external;

  function maxGen0Supply() external view returns (uint16);

  function maxSupply() external view returns (uint256);

  function getTokenTraits(uint16 tokenId) external view returns (Traits memory);

  function getTokenWriteBlock(uint256 tokenId) external view returns (uint64);

  function mint(address recipient, uint256 seed) external returns (uint16[] memory);

  function minted() external view returns (uint16);

  function mintedRoosters() external returns (uint16);

  function specialMint(
    address recipient,
    uint256 seed,
    uint16 specificKind,
    bool twinHen,
    uint16 quantity
  ) external;

  function ownerOf(uint256 tokenId) external view returns (address owner);

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) external;

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function updateAdvantage(
    uint16 tokenId,
    uint8 score,
    bool decrement
  ) external;

  function updateOriginAccess(uint16[] memory tokenIds) external;
}

// SPDX-License-Identifier: MIT

/*

&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,[email protected]       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at [email protected]
 * Found a broken egg in our contracts? We have a bug bounty program [email protected]
 * Y'all have a nice day

*/

pragma solidity ^0.8.17;

interface IHenHouse {
  // struct to store a stake's token, owner, and earning values
  struct Stake {
    uint16 tokenId;
    address owner;
    uint80 eggPerRank; // This is the value of EggPerRank (Coyote/Rooster)
    uint80 rescueEggPerRank; // Value per rank of rescued $EGG
    uint256 oneOffEgg; // One off per staker
    uint256 stakedTimestamp;
    uint256 unstakeTimestamp;
  }

  struct HenHouseInfo {
    uint256 numHensStaked; // Track staked hens
    uint256 totalEGGEarnedByHen; // Amount of $EGG earned so far
    uint256 lastClaimTimestampByHen; // The last time $EGG was claimed
  }

  struct DenInfo {
    uint256 numCoyotesStaked;
    uint256 totalCoyoteRankStaked;
    uint256 eggPerCoyoteRank; // Amount of tax $EGG due per Wily rank point staked
  }

  struct GuardHouseInfo {
    uint256 numRoostersStaked;
    uint256 totalRoosterRankStaked;
    uint256 totalEGGEarnedByRooster;
    uint256 lastClaimTimestampByRooster;
    uint256 eggPerRoosterRank; // Amount of dialy $EGG due per Guard rank point staked
    uint256 rescueEggPerRank; // Amunt of rescued $EGG due per Guard rank staked
  }

  function addManyToHenHouse(address account, uint16[] calldata tokenIds) external;

  function addGenericEggPool(uint256 _amount) external;

  function addRescuedEggPool(uint256 _amount) external;

  function canUnstake(uint16 tokenId) external view returns (bool);

  function claimManyFromHenHouseAndDen(uint16[] calldata tokenIds, bool unstake) external;

  function getDenInfo() external view returns (DenInfo memory);

  function getGuardHouseInfo() external view returns (GuardHouseInfo memory);

  function getHenHouseInfo() external view returns (HenHouseInfo memory);

  function getStakeInfo(uint16 tokenId) external view returns (Stake memory);

  function randomCoyoteOwner(uint256 seed) external view returns (address);

  function randomRoosterOwner(uint256 seed) external view returns (address);

  function rescue(uint16[] calldata tokenIds) external;
}

// SPDX-License-Identifier: MIT

/*

&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,[email protected]       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at [email protected]
 * Found a broken egg in our contracts? We have a bug bounty program [email protected]
 * Y'all have a nice day

*/

pragma solidity ^0.8.17;

interface IHenHouseAdvantage {
  // struct to store the production bonus info of all nfts
  struct AdvantageBonus {
    uint256 tokenId;
    uint256 bonusPercentage;
    uint256 bonusDurationMins;
    uint256 startTime;
  }

  function addAdvantageBonus(
    uint16 tokenId,
    uint256 _durationMins,
    uint16 _percentage
  ) external;

  function removeAdvantageBonus(uint16 tokenId) external;

  function getAdvantageBonus(uint16 tokenId) external view returns (AdvantageBonus memory);

  function updateAdvantageBonus(uint256 tokenId) external;

  function calculateAdvantageBonus(uint256 tokenId, uint256 owed) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '../IERC721A.sol';

/**
 * @dev Interface of ERC721AQueryable.
 */
interface IERC721AQueryable is IERC721A {
    /**
     * Invalid query range (`start` >= `stop`).
     */
    error InvalidQueryRange();

    /**
     * @dev Returns the `TokenOwnership` struct at `tokenId` without reverting.
     *
     * If the `tokenId` is out of bounds:
     *
     * - `addr = address(0)`
     * - `startTimestamp = 0`
     * - `burned = false`
     * - `extraData = 0`
     *
     * If the `tokenId` is burned:
     *
     * - `addr = <Address of owner before token was burned>`
     * - `startTimestamp = <Timestamp when token was burned>`
     * - `burned = true`
     * - `extraData = <Extra data when token was burned>`
     *
     * Otherwise:
     *
     * - `addr = <Address of owner>`
     * - `startTimestamp = <Timestamp of start of ownership>`
     * - `burned = false`
     * - `extraData = <Extra data at start of ownership>`
     */
    function explicitOwnershipOf(uint256 tokenId) external view returns (TokenOwnership memory);

    /**
     * @dev Returns an array of `TokenOwnership` structs at `tokenIds` in order.
     * See {ERC721AQueryable-explicitOwnershipOf}
     */
    function explicitOwnershipsOf(uint256[] memory tokenIds) external view returns (TokenOwnership[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`,
     * in the range [`start`, `stop`)
     * (i.e. `start <= tokenId < stop`).
     *
     * This function allows for tokens to be queried if the collection
     * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
     *
     * Requirements:
     *
     * - `start < stop`
     */
    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view returns (uint256[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(`totalSupply`) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K collections should be fine).
     */
    function tokensOfOwner(address owner) external view returns (uint256[] memory);
}