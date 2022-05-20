// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/**
 * @notice Mavia Staking Dynamic Pool
 * @dev Version 1.0
 * Each staker has unlimited deposit package with specific locked duration
 * We provide several pool with fixed locked duration with dynamic APY
 * Each time staker collect reward which will be vested in a year (365 days)
 *
 * @author mavia.com, reviewed by King
 *
 * Copyright (c) 2021 Mavia
 */
contract MaviaPoolDynamicAPY is ReentrancyGuardUpgradeable, AccessControlUpgradeable {
  using SafeERC20Upgradeable for IERC20MetadataUpgradeable;

  struct MStaker {
    /// @dev Address of staker
    address sAddress;
    /// @dev Next deposit id, start from 0
    uint256 dNextId;
    /// @dev Next reward id, start from 0
    uint256 rNextId;
    /// @dev Total staked amount
    uint256 tAmount;
    /// @dev Total vesting reward
    uint256 tReward;
    /// @dev It's true if staker already in list
    bool added;
  }

  struct MDeposit {
    /// @dev Deposit id
    uint256 dId;
    /// @dev Token staked amount
    uint256 dAmount;
    /// @dev Locking period - from
    uint256 lkFrom;
    /// @dev Locking period - to
    uint256 lkTo;
    /// @dev Deposit time
    uint256 dTime;
    /// @dev Withdraw time
    uint256 wTime;
    /// @dev Reward Debt
    uint256 rDebt;
  }

  struct MReward {
    /// @dev Reward id
    uint256 rId;
    /// @dev Amount of reward
    uint256 amount;
    /// @dev Locking period - from
    uint256 lkFrom;
    /// @dev Locking period - to
    uint256 lkTo;
    /// @dev Withdraw time
    uint256 wTime;
  }

  struct MLog {
    /// @dev Address of staker
    address lId;
    /// @dev Amount 1
    uint256 logA1;
    /// @dev Amount 2
    uint256 logA2;
    /// @dev 0 = transfer, 1 = unstake, 2 = vest reward, 3 = claim
    uint256 logType;
    /// @dev Timestamp
    uint256 logTime;
  }

  bytes32 public constant EDITOR_ROLE = keccak256("EDITOR_ROLE");
  bytes32 public constant EMERGENCY_ROLE = keccak256("EMERGENCY_ROLE");

  // The precision factor
  uint256 private constant _PRECISION_FACTOR = 1e36;
  /// @dev Percentage nominator: 1% = 100
  uint256 internal constant _RATE_NOMINATOR = 10_000;
  /// @dev Total second in a year
  uint256 internal constant _SECONDS_YEAR = 365 days;

  /// @dev Staker logs
  MLog[] internal _stakerLogs;

  /// @dev The reward token
  IERC20MetadataUpgradeable public rToken;
  /// @dev The staked token
  IERC20MetadataUpgradeable public sToken;

  /// @dev Info of each staker that stakes tokens (sToken)
  mapping(address => MStaker) public stakers;
  /// @dev Staker indexes
  address[] public stakerIds;
  /// @dev Deposits info of against deposit id of the staker
  mapping(address => mapping(uint256 => MDeposit)) public depositLogs;
  /// @dev Rewards info of against reward id of the staker
  mapping(address => mapping(uint256 => MReward)) public rewardLogs;

  /// @dev Congeal start time
  uint256 public congealSTime;
  /// @dev Congeal end time
  uint256 public congealETime;

  /// @dev Pool start time
  uint256 public poolStartTime;
  /// @dev Pool end time
  uint256 public poolEndTime;
  /// @dev Max reward tokens per pool
  uint256 public poolMaxReward;
  /// @dev Claimed reward tokens per pool
  uint256 public poolClaimedReward;
  /// @dev Max staked tokens per pool
  uint256 public poolMaxStakedAmount;
  /// @dev Current staked tokens per pool
  uint256 public poolCurrStakedAmount;

  /// @dev Minimum deposit amount
  uint256 public minDepAmount;
  /// @dev Locked duration in seconds
  uint256 public lockedDuration;
  /// @dev Vested duration in seconds
  uint256 public vestedDuration;
  /// @dev Accrued token per share
  uint256 public accTokenPerShare;
  /// @dev Reward per second.
  uint256 public rewardPerSecond;
  /// @dev Last reward time by second.
  uint256 public lastRewardTime;

  event EDepositLog(address indexed staker, uint256 dId, uint256 amount);
  event EWithdrawLog(address indexed staker, uint256 dId, uint256 amount);
  event EVestedReward(address indexed staker, uint256 dId, uint256 rId, uint256 amount);
  event EClaimReward(address indexed staker, uint256 rId, uint256 amount);

  /**
   * @dev Upgradable initializer
   * @param _pStakedToken Staked token address
   * @param _pRewardToken Reward token address
   * @param _pPoolStartTime Pool start time
   * @param _pPoolEndTime Pool end time
   * @param _pLockedDuration Locked duration in seconds
   * @param _pVestedDuration Vested duration in seconds
   * @param _pRewardPerSecond Reward per seconds
   */
  function MaviaPoolDynamicAPYInit(
    IERC20MetadataUpgradeable _pStakedToken,
    IERC20MetadataUpgradeable _pRewardToken,
    uint256 _pPoolStartTime,
    uint256 _pPoolEndTime,
    uint256 _pLockedDuration,
    uint256 _pVestedDuration,
    uint256 _pRewardPerSecond
  ) external initializer {
    __ReentrancyGuard_init();
    __AccessControl_init();
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(EDITOR_ROLE, _msgSender());

    sToken = _pStakedToken;
    rToken = _pRewardToken;
    poolStartTime = _pPoolStartTime;
    poolEndTime = _pPoolEndTime;
    lockedDuration = _pLockedDuration;
    vestedDuration = _pVestedDuration;
    rewardPerSecond = _pRewardPerSecond;
    lastRewardTime = _pPoolStartTime;
  }

  /**
   * @notice Get remaining reward
   */
  function fGetRemainingReward() external view returns (uint256) {
    if (poolMaxReward > poolClaimedReward) return poolMaxReward - poolClaimedReward;
    return 0;
  }

  /**
   * @notice Staker cannot deposit, withdraw, vest, claim, emergencyWithdraw function
   */
  function fIsCongealed() public view returns (bool) {
    return block.timestamp >= congealSTime && block.timestamp <= congealETime;
  }

  /**
   * @notice View function to see pending reward on frontend.
   * @param _pStaker: Staker address
   * @param _pDepositId: Deposit Id
   * @return Pending reward for a given staker
   */
  function fGetPendingReward(address _pStaker, uint256 _pDepositId) external view returns (uint256) {
    MDeposit storage deposit_ = depositLogs[_pStaker][_pDepositId];
    uint256 adjustedTokenPerShare = accTokenPerShare;
    if (block.timestamp > lastRewardTime && poolCurrStakedAmount != 0) {
      uint256 multiplier = _fGetMultiplier(lastRewardTime, block.timestamp, poolStartTime, poolEndTime);
      uint256 rewardTillNow = multiplier * rewardPerSecond;
      adjustedTokenPerShare = accTokenPerShare + ((rewardTillNow * _PRECISION_FACTOR) / poolCurrStakedAmount);
    }
    return (deposit_.dAmount * adjustedTokenPerShare) / _PRECISION_FACTOR - deposit_.rDebt;
  }

  /**
   * @notice Return length of staker logs
   */
  function fLenMLog() external view returns (uint) {
    return _stakerLogs.length;
  }

  /**
   * @notice View function to get staker logs.
   * @param _pOffset: offset for paging
   * @param _pLimit: limit for paging
   */
  function fGetMLogs(uint _pOffset, uint _pLimit)
    external
    view
    returns (
      MLog[] memory _rStakers,
      uint _rNextOffset,
      uint _rTotal
    )
  {
    uint totalStakers_ = _stakerLogs.length;
    if (_pLimit == 0) {
      _pLimit = 1;
    }

    if (_pLimit > totalStakers_ - _pOffset) {
      _pLimit = totalStakers_ - _pOffset;
    }

    MLog[] memory values_ = new MLog[](_pLimit);
    for (uint i = 0; i < _pLimit; i++) {
      values_[i] = _stakerLogs[_pOffset + i];
    }

    return (values_, _pOffset + _pLimit, totalStakers_);
  }

  /**
   * @notice Return length of staker addresses
   */
  function fLenStakers() external view returns (uint) {
    return stakerIds.length;
  }

  /**
   * @notice View function to get stakers.
   * @param _offset: offset for paging
   * @param _limit: limit for paging
   */
  function fGetStakers(uint _offset, uint _limit)
    external
    view
    returns (
      MStaker[] memory _rStakers,
      uint _rNextOffset,
      uint _rTotal
    )
  {
    uint totalStakers_ = stakerIds.length;
    if (_limit == 0) {
      _limit = 1;
    }

    if (_limit > totalStakers_ - _offset) {
      _limit = totalStakers_ - _offset;
    }

    MStaker[] memory values_ = new MStaker[](_limit);
    for (uint i = 0; i < _limit; i++) {
      values_[i] = stakers[stakerIds[_offset + i]];
    }

    return (values_, _offset + _limit, totalStakers_);
  }

  /**
   * @notice It allows the admin to reward tokens
   * @param _pAmount: Amount of tokens
   * @dev This function is only callable by admin.
   */
  function fAddRewardTokens(uint256 _pAmount) external onlyRole(EDITOR_ROLE) {
    // Check real amount to avoid taxed token
    uint256 previousBalance_ = rToken.balanceOf(address(this));
    rToken.safeTransferFrom(address(msg.sender), address(this), _pAmount);
    uint256 newBalance_ = rToken.balanceOf(address(this));
    uint256 addedAmount_ = newBalance_ - previousBalance_;

    poolMaxReward += addedAmount_;
  }

  /**
   * @notice Stop Congeal
   * @dev Only callable by owner
   */
  function fStopCongeal() external onlyRole(EDITOR_ROLE) {
    congealSTime = 0;
    congealETime = 0;
  }

  /**
   * @notice Update limit staked amount
   * @dev Only callable by owner.
   * @param _pPoolMaxStakedAmount: Max tokens can be staked to this pool
   */
  function fSetPoolMaxStakedAmount(uint256 _pPoolMaxStakedAmount) external onlyRole(EDITOR_ROLE) {
    poolMaxStakedAmount = _pPoolMaxStakedAmount;
  }

  /**
   * @notice Update reward per second
   * @dev Only callable by owner.
   * @param _pRewardPerSecond: Reward per second
   */
  function fSetRewardPerSecond(uint256 _pRewardPerSecond) external onlyRole(EDITOR_ROLE) {
    _fUpdatePool();
    rewardPerSecond = _pRewardPerSecond;
  }

  /**
   * @notice Update pool deposit time
   * @dev Only callable by owner.
   * @param _pPoolStartTime: start time
   * @param _pPoolEndTime: end time
   */
  function fSetPoolDuration(uint256 _pPoolStartTime, uint256 _pPoolEndTime) external onlyRole(EDITOR_ROLE) {
    require(_pPoolStartTime < _pPoolEndTime, "0x1");
    if (poolStartTime > 0) {
      poolStartTime = _pPoolStartTime;
    }
    poolEndTime = _pPoolEndTime;
  }

  /**
   * @notice It allows the admin to update freeze start and end times
   * @dev This function is only callable by owner.
   * @param _pCongealSTime: the new freeze start time
   * @param _pCongealETime: the new freeze end time
   */
  function fSetCongealTimes(uint256 _pCongealSTime, uint256 _pCongealETime) external onlyRole(EDITOR_ROLE) {
    require(_pCongealSTime < _pCongealETime, "0x1");
    require(block.timestamp < _pCongealSTime, "0x2");

    congealSTime = _pCongealSTime;
    congealETime = _pCongealETime;
  }

  /**
   * @notice Update minimum deposit amount
   * @dev This function is only callable by owner.
   * @param _pMinDepAmount: the new minimum deposit amount
   */
  function fSetMinDepAmount(uint256 _pMinDepAmount) external onlyRole(EDITOR_ROLE) {
    minDepAmount = _pMinDepAmount;
  }

  /**
   * @notice Update locked duration
   * @dev This function is only callable by owner.
   * @param _pLockedDuration: Set the locked duration in seconds
   */
  function fSetLockDuration(uint256 _pLockedDuration) external onlyRole(EDITOR_ROLE) {
    lockedDuration = _pLockedDuration;
  }

  /**
   * @dev Emergency withdraw any token
   */
  function fEmcWithdrawToken(
    address _pToken,
    address _pTo,
    uint256 _pAmount
  ) external onlyRole(EMERGENCY_ROLE) {
    IERC20MetadataUpgradeable(_pToken).safeTransfer(_pTo, _pAmount);
  }

  /**
   * @notice Emergency withdraw
   * @dev Only callable by emergency role. Needs to be for emergency.
   * @param _pAmount: Amount of tokens
   */
  function fEmcRewardWithdraw(uint256 _pAmount) external onlyRole(EMERGENCY_ROLE) {
    poolMaxReward -= _pAmount;
    rToken.safeTransfer(address(msg.sender), _pAmount);
  }

  /**
   * @notice Deposit staked tokens and collect reward tokens (if any)
   * @param _pAmount: Amount to withdraw (in rToken)
   */
  function fDeposit(uint256 _pAmount) external nonReentrant {
    require(block.timestamp >= poolStartTime && block.timestamp <= poolEndTime, "0x1");
    require(!fIsCongealed(), "0x2");
    require(_pAmount >= minDepAmount, "0x3");
    if (poolMaxStakedAmount > 0) {
      require((poolCurrStakedAmount + _pAmount) <= poolMaxStakedAmount, "0x4");
    }

    address sender_ = _msgSender();
    MStaker storage staker_ = stakers[sender_];

    // Update share size
    _fUpdatePool();

    if (!staker_.added) {
      stakerIds.push(sender_);
      staker_.sAddress = sender_;
      staker_.tAmount = 0;
      staker_.tReward = 0;
      staker_.dNextId = 0;
      staker_.rNextId = 0;
      staker_.added = true;
    }

    uint256 addedAmount_;
    // Check real amount to avoid taxed token
    uint256 previousBalance_ = sToken.balanceOf(address(this));
    sToken.safeTransferFrom(address(msg.sender), address(this), _pAmount);
    uint256 newBalance_ = sToken.balanceOf(address(this));
    addedAmount_ = newBalance_ - previousBalance_;

    staker_.tAmount += addedAmount_;
    poolCurrStakedAmount += addedAmount_;

    uint256 rewardDebt_ = (addedAmount_ * accTokenPerShare) / _PRECISION_FACTOR;

    depositLogs[sender_][staker_.dNextId] = MDeposit(
      staker_.dNextId,
      addedAmount_,
      block.timestamp,
      block.timestamp + lockedDuration,
      block.timestamp,
      0,
      rewardDebt_
    );
    staker_.dNextId++;

    _fAddMLog(sender_, _pAmount, addedAmount_, 0);
    emit EDepositLog(sender_, staker_.dNextId - 1, _pAmount);
  }

  /**
   * @notice Claimed reward will be vested for 12 months
   * @param _pDepositId: Deposit id of staker investment
   */
  function fVestReward(uint256 _pDepositId) external nonReentrant {
    // Withdraw is frozen
    require(!fIsCongealed(), "0x1");
    _fVestReward(_pDepositId);
  }

  /**
   * @notice Withdraw staked tokens and collect reward tokens
   * @param _pDepositId: Deposit id of staker investment
   */
  function fWithdraw(uint256 _pDepositId) external nonReentrant {
    require(!fIsCongealed(), "0x1");
    address sender_ = _msgSender();
    MDeposit storage deposit_ = depositLogs[sender_][_pDepositId];
    require(deposit_.dAmount > 0, "0x2");

    // Validate staker lock
    require(block.timestamp > deposit_.lkTo, "0x3");

    // Vesting reward
    _fVestReward(_pDepositId);

    // Transfer staked token
    uint256 amount_ = deposit_.dAmount;
    sToken.safeTransfer(sender_, amount_);

    MStaker storage staker_ = stakers[sender_];
    staker_.tAmount -= amount_;

    deposit_.dAmount = 0;
    deposit_.wTime = block.timestamp;
    poolCurrStakedAmount -= amount_;

    _fAddMLog(sender_, staker_.tAmount, amount_, 1);
    emit EWithdrawLog(sender_, _pDepositId, amount_);
  }

  /**
   * @notice Claim reward after vested for 12 months
   * @param _pRewardId: Reward id id of staker investment
   */
  function fClaimReward(uint256 _pRewardId) external nonReentrant {
    require(!fIsCongealed(), "0x1");
    address sender_ = _msgSender();
    MReward storage reward_ = rewardLogs[sender_][_pRewardId];
    uint256 amount_ = reward_.amount;
    require(block.timestamp > reward_.lkTo, "0x2");
    require(amount_ > 0, "0x3");

    // Transfer reward
    poolClaimedReward += amount_;
    rToken.safeTransfer(sender_, amount_);

    MStaker storage staker_ = stakers[sender_];
    staker_.tReward -= amount_;

    reward_.amount = 0;
    reward_.wTime = block.timestamp;

    _fAddMLog(sender_, staker_.tReward, amount_, 3);
    emit EClaimReward(sender_, _pRewardId, amount_);
  }

  /**
   * @notice Private call vest reward
   * @param _pDepositId: Deposit id of staker investment
   */
  function _fVestReward(uint256 _pDepositId) private {
    _fUpdatePool();
    address sender_ = _msgSender();
    MStaker storage staker_ = stakers[sender_];
    MDeposit storage deposit_ = depositLogs[sender_][_pDepositId];
    // Vesting reward
    uint256 maxReward = (deposit_.dAmount * accTokenPerShare) / _PRECISION_FACTOR;
    uint256 pending_ = maxReward - deposit_.rDebt;
    if (pending_ > 0) {
      // Locked in 365 days
      rewardLogs[sender_][staker_.rNextId] = MReward(
        staker_.rNextId,
        pending_,
        block.timestamp,
        block.timestamp + vestedDuration,
        0
      );

      staker_.tReward += pending_;
      staker_.rNextId++;
      deposit_.rDebt = maxReward;

      _fAddMLog(sender_, staker_.tReward, pending_, 2);
      emit EVestedReward(sender_, _pDepositId, staker_.rNextId - 1, pending_);
    }
  }

  /**
   * @notice Return reward multiplier over the given _pFrom to _pTo time.
   * @param _pFrom: Time to start
   * @param _pTo: Time to finish
   * @param _pStartTime: Start time
   * @param _pEndTime: End time
   */
  function _fGetMultiplier(
    uint256 _pFrom,
    uint256 _pTo,
    uint256 _pStartTime,
    uint256 _pEndTime
  ) private pure returns (uint256) {
    if (_pFrom < _pStartTime) _pFrom = _pStartTime;
    if (_pTo > _pEndTime) _pTo = _pEndTime;
    if (_pFrom >= _pTo) return 0;
    return _pTo - _pFrom;
  }

  /**
   * @notice Add staker log
   * @param _pLId Address
   * @param _pLogA1 Amount 1
   * @param _pLogA2 Amount 2
   * @param _pLogType: 0 = transfer, 1 = unstake, 2 = vest reward, 3 = claim
   */
  function _fAddMLog(
    address _pLId,
    uint256 _pLogA1,
    uint256 _pLogA2,
    uint256 _pLogType
  ) private {
    _stakerLogs.push(MLog(_pLId, _pLogA1, _pLogA2, _pLogType, block.timestamp));
  }

  /*
   * @notice Update reward variables of the given pool to be up-to-date.
   */
  function _fUpdatePool() private {
    if (block.timestamp <= lastRewardTime) {
      return;
    }

    if (poolCurrStakedAmount == 0) {
      lastRewardTime = block.timestamp;
      return;
    }

    uint256 multiplier = _fGetMultiplier(lastRewardTime, block.timestamp, poolStartTime, poolEndTime);
    uint256 rewardTillNow = multiplier * rewardPerSecond;
    accTokenPerShare += (rewardTillNow * _PRECISION_FACTOR) / poolCurrStakedAmount;
    lastRewardTime = block.timestamp;
  }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
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

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
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

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
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

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

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
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

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
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}