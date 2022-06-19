// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import {IERC20} from './interfaces/IERC20.sol';
import {SafeERC20} from './libraries/SafeERC20.sol';
import {RewardsController} from './RewardsController.sol';

contract Rewarder is RewardsController {
  using SafeERC20 for IERC20;

  // reward => reward vault
  mapping(address => address) internal _rewardsVault;

  event RewardsVaultUpdated(address indexed vault);

  function setRewardsVault(address vault, address reward) external onlyOwner {
  	_rewardsVault[reward] = vault;
  	emit RewardsVaultUpdated(vault);
  }

  function getRewardsVault(address reward) external view returns (address) {
  	return _rewardsVault[reward];
  }

  function transferRewards(address to, address reward, uint256 amount) internal override returns (bool) {
    IERC20(reward).safeTransferFrom(_rewardsVault[reward], to, amount);
    return true;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 * From https://github.com/OpenZeppelin/openzeppelin-contracts
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
pragma solidity 0.7.5;

import {IERC20} from '../interfaces/IERC20.sol';
import {SafeMath} from './SafeMath.sol';
import {Address} from './Address.sol';

/**
 * @title SafeERC20
 * @dev From https://github.com/OpenZeppelin/openzeppelin-contracts
 * Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  using SafeMath for uint256;
  using Address for address;

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  ) internal {
    callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
  }

  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    require(
      (value == 0) || (token.allowance(address(this), spender) == 0),
      'SafeERC20: approve from non-zero to non-zero allowance'
    );
    callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
  }

  function callOptionalReturn(IERC20 token, bytes memory data) private {
    require(address(token).isContract(), 'SafeERC20: call to non-contract');

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = address(token).call(data);
    require(success, 'SafeERC20: low-level call failed');

    if (returndata.length > 0) {
      // Return data is optional
      // solhint-disable-next-line max-line-length
      require(abi.decode(returndata, (bool)), 'SafeERC20: ERC20 operation did not succeed');
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import {IRewardsController} from './interfaces/IRewardsController.sol';
import {RewardsDistributor} from './RewardsDistributor.sol';
import {IScaledBalanceToken} from './interfaces/IScaledBalanceToken.sol';
import {DistributionTypes} from './libraries/DistributionTypes.sol';

abstract contract RewardsController is RewardsDistributor, IRewardsController {
	// user => authorized claimer
	mapping(address => address) internal _authorizedClaimers;

  modifier onlyAuthorizedClaimers(address claimer, address user) {
    require(_authorizedClaimers[user] == claimer, 'CLAIMER_UNAUTHORIZED');
    _;
  }

  function getClaimer(address user) external view override returns (address) {
    return _authorizedClaimers[user];
  }

  function setClaimer(address user, address caller) external override onlyOwner {
    _authorizedClaimers[user] = caller;
    emit ClaimerSet(user, caller);
  }

  function configureAssets(DistributionTypes.RewardsConfigInput[] memory config)
    external
    override
    onlyOwner
  {
    for (uint256 i = 0; i < config.length; i++) {
      config[i].totalSupply = IScaledBalanceToken(config[i].asset).scaledTotalSupply();
    }
    _configureAssets(config);
  }

  function handleAction(
    address user,
    uint256 totalSupply,
    uint256 userBalance
  ) external override {
    _updateUserRewardsPerAssetInternal(msg.sender, user, userBalance, totalSupply);
  }

	function claimRewards(
    address[] calldata assets,
    uint256 amount,
    address to,
    address reward
  ) external override returns (uint256) {
    require(to != address(0), 'INVALID_TO_ADDRESS');
    return _claimRewards(assets, amount, msg.sender, msg.sender, to, reward);
  }

  function claimRewardsOnBehalf(
    address[] calldata assets,
    uint256 amount,
    address user,
    address to,
    address reward
  ) external override onlyAuthorizedClaimers(msg.sender, user) returns (uint256) {
    require(user != address(0), 'INVALID_USER_ADDRESS');
    require(to != address(0), 'INVALID_TO_ADDRESS');
    return _claimRewards(assets, amount, msg.sender, user, to, reward);
  }

  function claimRewardsToSelf(
    address[] calldata assets,
    uint256 amount,
    address reward
  ) external override returns (uint256) {
    return _claimRewards(assets, amount, msg.sender, msg.sender, msg.sender, reward);
  }

  function claimAllRewards(address[] calldata assets, address to)
    external
    override
    returns (address[] memory rewardTokens, uint256[] memory claimedAmounts)
  {
    require(to != address(0), 'INVALID_TO_ADDRESS');
    return _claimAllRewards(assets, msg.sender, msg.sender, to);
  }

  function claimAllRewardsOnBehalf(
    address[] calldata assets,
    address user,
    address to
  )
    external
    override
    onlyAuthorizedClaimers(msg.sender, user)
    returns (address[] memory rewardTokens, uint256[] memory claimedAmounts)
  {
    require(user != address(0), 'INVALID_USER_ADDRESS');
    require(to != address(0), 'INVALID_TO_ADDRESS');
    return _claimAllRewards(assets, msg.sender, user, to);
  }

  function claimAllRewardsToSelf(address[] calldata assets)
    external
    override
    returns (address[] memory rewardTokens, uint256[] memory claimedAmounts)
  {
    return _claimAllRewards(assets, msg.sender, msg.sender, msg.sender);
  }

  function _getUserStake(address[] calldata assets, address user)
    internal
    view
    override
    returns (DistributionTypes.UserAssetInput[] memory userState)
  {
    userState = new DistributionTypes.UserAssetInput[](assets.length);
    for (uint256 i = 0; i < assets.length; i++) {
      userState[i].underlyingAsset = assets[i];
      (userState[i].userBalance, userState[i].totalSupply) = IScaledBalanceToken(assets[i])
        .getScaledUserBalanceAndSupply(user);
    }
    return userState;
  }

  function _claimRewards(
    address[] calldata assets,
    uint256 amount,
    address claimer,
    address user,
    address to,
    address reward
  ) internal returns (uint256) {
    if (amount == 0) {
      return 0;
    }
    uint256 unclaimedRewards = _usersUnclaimedRewards[user][reward];

    if (amount > unclaimedRewards) {
      _distributeRewards(user, _getUserStake(assets, user));
      unclaimedRewards = _usersUnclaimedRewards[user][reward];
    }

    if (unclaimedRewards == 0) {
      return 0;
    }

    uint256 amountToClaim = amount > unclaimedRewards ? unclaimedRewards : amount;
    _usersUnclaimedRewards[user][reward] = unclaimedRewards - amountToClaim; // Safe due to the previous line

    _transferRewards(to, reward, amountToClaim);
    emit RewardsClaimed(user, reward, to, claimer, amountToClaim);

    return amountToClaim;
  }

  function _claimAllRewards(
    address[] calldata assets,
    address claimer,
    address user,
    address to
  ) internal returns (address[] memory rewardTokens, uint256[] memory claimedAmounts) {
    _distributeRewards(user, _getUserStake(assets, user));

    rewardTokens = new address[](_rewardTokens.length);
    claimedAmounts = new uint256[](_rewardTokens.length);

    for (uint256 i = 0; i < _rewardTokens.length; i++) {
      address reward = _rewardTokens[i];
      uint256 rewardAmount = _usersUnclaimedRewards[user][reward];

      rewardTokens[i] = reward;
      claimedAmounts[i] = rewardAmount;

      if (rewardAmount != 0) {
        _usersUnclaimedRewards[user][reward] = 0;
        _transferRewards(to, reward, rewardAmount);
        emit RewardsClaimed(user, reward, to, claimer, rewardAmount);
      }
    }
    return (rewardTokens, claimedAmounts);
  }

  function _transferRewards(
    address to,
    address reward,
    uint256 amount
  ) internal {
    bool success = transferRewards(to, reward, amount);
    require(success == true, 'TRANSFER_ERROR');
  }

  function transferRewards(address to, address reward, uint256 amount) internal virtual returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.7.5;

/**
 * @dev From https://github.com/OpenZeppelin/openzeppelin-contracts
 * Wrappers over Solidity's arithmetic operations with added overflow
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
    require(c >= a, 'SafeMath: addition overflow');

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
    return sub(a, b, 'SafeMath: subtraction overflow');
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
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
    require(c / a == b, 'SafeMath: multiplication overflow');

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
    return div(a, b, 'SafeMath: division by zero');
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
   */
  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
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
    return mod(a, b, 'SafeMath: modulo by zero');
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
   */
  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

/**
 * @dev Collection of functions related to the address type
 * From https://github.com/OpenZeppelin/openzeppelin-contracts
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
    assembly {
      codehash := extcodehash(account)
    }
    return (codehash != accountHash && codehash != 0x0);
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
    require(address(this).balance >= amount, 'Address: insufficient balance');

    // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    (bool success, ) = recipient.call{value: amount}('');
    require(success, 'Address: unable to send value, recipient may have reverted');
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import {IRewardsDistributor} from './IRewardsDistributor.sol';
import {DistributionTypes} from '../libraries/DistributionTypes.sol';

interface IRewardsController is IRewardsDistributor {
  event RewardsClaimed(
    address indexed user,
    address indexed reward,    
    address indexed to,
    address claimer,
    uint256 amount
  );

  event ClaimerSet(address indexed user, address indexed claimer);

  function setClaimer(address user, address claimer) external;

  function getClaimer(address user) external view returns (address);

  function configureAssets(DistributionTypes.RewardsConfigInput[] memory config) external;

  function handleAction(
    address asset,
    uint256 userBalance,
    uint256 totalSupply
  ) external;

  function claimRewards(
    address[] calldata assets,
    uint256 amount,
    address to,
    address reward
  ) external returns (uint256);

  function claimRewardsOnBehalf(
    address[] calldata assets,
    uint256 amount,
    address user,
    address to,
    address reward
  ) external returns (uint256);


  function claimRewardsToSelf(
    address[] calldata assets,
    uint256 amount,
    address reward
  ) external returns (uint256);

  function claimAllRewards(address[] calldata assets, address to)
    external
    returns (address[] memory rewardsList, uint256[] memory claimedAmounts);

  function claimAllRewardsOnBehalf(
    address[] calldata assets,
    address user,
    address to
  ) external returns (address[] memory rewardsList, uint256[] memory claimedAmounts);

  function claimAllRewardsToSelf(address[] calldata assets)
    external
    returns (address[] memory rewardsList, uint256[] memory claimedAmounts);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import {IRewardsDistributor} from './interfaces/IRewardsDistributor.sol';
import {IERC20Detailed} from './interfaces/IERC20Detailed.sol';
import {DistributionTypes} from './libraries/DistributionTypes.sol';
import {Ownable} from './libraries/Ownable.sol';

abstract contract RewardsDistributor is IRewardsDistributor, Ownable {
	struct RewardData {
		uint88 emissionPerSecond;
		uint104 index;
		uint32 lastUpdateTimestamp;
		uint32 distributionEnd;
		mapping(address => uint256) usersIndex;
	}

	struct AssetData {
		// reward => rewardData
		mapping(address => RewardData) rewards;
		address[] availableRewards;
		uint8 decimals;
	}

	// incentivized asset => AssetData
	mapping(address => AssetData) internal _assets;

	// user => reward => unclaimed rewards
	mapping(address => mapping(address => uint256)) internal _usersUnclaimedRewards;

	// reward => isEnabled
	mapping(address => bool) internal _isRewardEnabled;

	address[] internal _rewardTokens;

  function getRewardsData(address asset, address reward)
    public
    view
    override
    returns (
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    return (
      _assets[asset].rewards[reward].index,
      _assets[asset].rewards[reward].emissionPerSecond,
      _assets[asset].rewards[reward].lastUpdateTimestamp,
      _assets[asset].rewards[reward].distributionEnd
    );
  }

  function getDistributionEnd(address asset, address reward)
    external
    view
    override
    returns (uint256)
  {
    return _assets[asset].rewards[reward].distributionEnd;
  }

  function getRewardsByAsset(address asset) external view override returns (address[] memory) {
    return _assets[asset].availableRewards;
  }

  function getRewardTokens() external view override returns (address[] memory) {
    return _rewardTokens;
  }

  function getUserAssetData(
    address user,
    address asset,
    address reward
  ) public view override returns (uint256) {
    return _assets[asset].rewards[reward].usersIndex[user];
  }

  function getUserUnclaimedRewardsFromStorage(address user, address reward)
    external
    view
    override
    returns (uint256)
  {
    return _usersUnclaimedRewards[user][reward];
  }

  function getUserRewardsBalance(
    address[] calldata assets,
    address user,
    address reward
  ) external view override returns (uint256) {
    return _getUserReward(user, reward, _getUserStake(assets, user));
  }

  function getAllUserRewardsBalance(address[] calldata assets, address user)
    external
    view
    override
    returns (address[] memory rewardTokens, uint256[] memory unclaimedAmounts)
  {
    return _getAllUserRewards(user, _getUserStake(assets, user));
  }

  function setDistributionEnd(
    address asset,
    address reward,
    uint32 distributionEnd
  ) external override onlyOwner {
    _assets[asset].rewards[reward].distributionEnd = distributionEnd;

    emit AssetConfigUpdated(
      asset,
      reward,
      _assets[asset].rewards[reward].emissionPerSecond,
      distributionEnd
    );
  }

  function _configureAssets(DistributionTypes.RewardsConfigInput[] memory rewardsInput)
    internal
  {
    for (uint256 i = 0; i < rewardsInput.length; i++) {
      _assets[rewardsInput[i].asset].decimals = IERC20Detailed(rewardsInput[i].asset).decimals();

      RewardData storage rewardConfig = _assets[rewardsInput[i].asset].rewards[
        rewardsInput[i].reward
      ];

      // Add reward address to asset available rewards if latestUpdateTimestamp is zero
      if (rewardConfig.lastUpdateTimestamp == 0) {
        _assets[rewardsInput[i].asset].availableRewards.push(rewardsInput[i].reward);
      }

      // Add reward address to global rewards list if still not enabled
      if (_isRewardEnabled[rewardsInput[i].reward] == false) {
        _isRewardEnabled[rewardsInput[i].reward] = true;
        _rewardTokens.push(rewardsInput[i].reward);
      }

      // Due emissions is still zero, updates only latestUpdateTimestamp
      _updateAssetStateInternal(
        rewardsInput[i].asset,
        rewardsInput[i].reward,
        rewardConfig,
        rewardsInput[i].totalSupply,
        _assets[rewardsInput[i].asset].decimals
      );

      // Configure emission and distribution end of the reward per asset
      rewardConfig.emissionPerSecond = rewardsInput[i].emissionPerSecond;
      rewardConfig.distributionEnd = rewardsInput[i].distributionEnd;

      emit AssetConfigUpdated(
        rewardsInput[i].asset,
        rewardsInput[i].reward,
        rewardsInput[i].emissionPerSecond,
        rewardsInput[i].distributionEnd
      );
    }
  }

  function _updateAssetStateInternal(
    address asset,
    address reward,
    RewardData storage rewardConfig,
    uint256 totalSupply,
    uint8 decimals
  ) internal returns (uint256) {
    uint256 oldIndex = rewardConfig.index;

    if (block.timestamp == rewardConfig.lastUpdateTimestamp) {
      return oldIndex;
    }

    uint256 newIndex = _getAssetIndex(
      oldIndex,
      rewardConfig.emissionPerSecond,
      rewardConfig.lastUpdateTimestamp,
      rewardConfig.distributionEnd,
      totalSupply,
      decimals
    );

    if (newIndex != oldIndex) {
      require(newIndex <= type(uint104).max, 'Index overflow');
      //optimization: storing one after another saves one SSTORE
      rewardConfig.index = uint104(newIndex);
      rewardConfig.lastUpdateTimestamp = uint32(block.timestamp);
      emit AssetIndexUpdated(asset, reward, newIndex);
    } else {
      rewardConfig.lastUpdateTimestamp = uint32(block.timestamp);
    }

    return newIndex;
  }

  function _updateUserRewardsInternal(
    address user,
    address asset,
    address reward,
    uint256 userBalance,
    uint256 totalSupply
  ) internal returns (uint256) {
    RewardData storage rewardData = _assets[asset].rewards[reward];
    uint256 userIndex = rewardData.usersIndex[user];
    uint256 accruedRewards = 0;

    uint256 newIndex = _updateAssetStateInternal(
      asset,
      reward,
      rewardData,
      totalSupply,
      _assets[asset].decimals
    );

    if (userIndex != newIndex) {
      if (userBalance != 0) {
        accruedRewards = _getRewards(userBalance, newIndex, userIndex, _assets[asset].decimals);
      }

      rewardData.usersIndex[user] = newIndex;
      emit UserIndexUpdated(user, asset, reward, newIndex);
    }

    return accruedRewards;
  }

  function _updateUserRewardsPerAssetInternal(
    address asset,
    address user,
    uint256 userBalance,
    uint256 totalSupply
  ) internal {
    for (uint256 r = 0; r < _assets[asset].availableRewards.length; r++) {
      address reward = _assets[asset].availableRewards[r];
      uint256 accruedRewards = _updateUserRewardsInternal(
        user,
        asset,
        reward,
        userBalance,
        totalSupply
      );
      if (accruedRewards != 0) {
        _usersUnclaimedRewards[user][reward] += accruedRewards;

        emit RewardsAccrued(user, reward, accruedRewards);
      }
    }
  }

  function _distributeRewards(
    address user,
    DistributionTypes.UserAssetInput[] memory userState
  ) internal {
    for (uint256 i = 0; i < userState.length; i++) {
      _updateUserRewardsPerAssetInternal(
        userState[i].underlyingAsset,
        user,
        userState[i].userBalance,
        userState[i].totalSupply
      );
    }
  }

  function _getUserReward(
    address user,
    address reward,
    DistributionTypes.UserAssetInput[] memory userState
  ) internal view returns (uint256 unclaimedRewards) {
    // Add unrealized rewards
    for (uint256 i = 0; i < userState.length; i++) {
      if (userState[i].userBalance == 0) {
        continue;
      }
      unclaimedRewards += _getUnrealizedRewardsFromStake(user, reward, userState[i]);
    }

    // Return unrealized rewards plus stored unclaimed rewardss
    return unclaimedRewards + _usersUnclaimedRewards[user][reward];
  }

  function _getAllUserRewards(
    address user,
    DistributionTypes.UserAssetInput[] memory userState
  ) internal view returns (address[] memory rewardTokens, uint256[] memory unclaimedRewards) {
    rewardTokens = new address[](_rewardTokens.length);
    unclaimedRewards = new uint256[](rewardTokens.length);

    // Add stored rewards from user to unclaimedRewards
    for (uint256 y = 0; y < rewardTokens.length; y++) {
      rewardTokens[y] = _rewardTokens[y];
      unclaimedRewards[y] = _usersUnclaimedRewards[user][rewardTokens[y]];
    }

    // Add unrealized rewards from user to unclaimedRewards
    for (uint256 i = 0; i < userState.length; i++) {
      if (userState[i].userBalance == 0) {
        continue;
      }
      for (uint256 r = 0; r < rewardTokens.length; r++) {
        unclaimedRewards[r] += _getUnrealizedRewardsFromStake(user, rewardTokens[r], userState[i]);
      }
    }
    return (rewardTokens, unclaimedRewards);
  }

  function _getUnrealizedRewardsFromStake(
    address user,
    address reward,
    DistributionTypes.UserAssetInput memory stake
  ) internal view returns (uint256) {
    RewardData storage rewardData = _assets[stake.underlyingAsset].rewards[reward];
    uint8 assetDecimals = _assets[stake.underlyingAsset].decimals;
    uint256 assetIndex = _getAssetIndex(
      rewardData.index,
      rewardData.emissionPerSecond,
      rewardData.lastUpdateTimestamp,
      rewardData.distributionEnd,
      stake.totalSupply,
      assetDecimals
    );

    return _getRewards(stake.userBalance, assetIndex, rewardData.usersIndex[user], assetDecimals);
  }

	function _getRewards(
    uint256 principalUserBalance,
    uint256 reserveIndex,
    uint256 userIndex,
    uint8 decimals
  ) internal pure returns (uint256) {
    return (principalUserBalance * (reserveIndex - userIndex)) / 10**decimals;
  }

  function _getAssetIndex(
    uint256 currentIndex,
    uint256 emissionPerSecond,
    uint128 lastUpdateTimestamp,
    uint256 distributionEnd,
    uint256 totalBalance,
    uint8 decimals
  ) internal view returns (uint256) {
    if (
      emissionPerSecond == 0 ||
      totalBalance == 0 ||
      lastUpdateTimestamp == block.timestamp ||
      lastUpdateTimestamp >= distributionEnd
    ) {
      return currentIndex;
    }

    uint256 currentTimestamp = block.timestamp > distributionEnd
      ? distributionEnd
      : block.timestamp;
    uint256 timeDelta = currentTimestamp - lastUpdateTimestamp;
    return (emissionPerSecond * timeDelta * (10**decimals)) / totalBalance + currentIndex;
  }

  function _getUserStake(address[] calldata assets, address user)
    internal
    view
    virtual
    returns (DistributionTypes.UserAssetInput[] memory userState);

  function getAssetDecimals(address asset) external view override returns (uint8) {
    return _assets[asset].decimals;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;

interface IScaledBalanceToken {
  /**
   * @dev Returns the scaled balance of the user. The scaled balance is the sum of all the
   * updated stored balance divided by the reserve's liquidity index at the moment of the update
   * @param user The user whose balance is calculated
   * @return The scaled balance of the user
   **/
  function scaledBalanceOf(address user) external view returns (uint256);

  /**
   * @dev Returns the scaled balance of the user and the scaled total supply.
   * @param user The address of the user
   * @return The scaled balance of the user
   * @return The scaled balance and the scaled total supply
   **/
  function getScaledUserBalanceAndSupply(address user) external view returns (uint256, uint256);

  /**
   * @dev Returns the scaled total supply of the token. Represents sum(debt/index)
   * @return The scaled total supply
   **/
  function scaledTotalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

library DistributionTypes {
  struct RewardsConfigInput {
    uint88 emissionPerSecond;
    uint256 totalSupply;
    uint32 distributionEnd;
    address asset;
    address reward;
  }

  struct UserAssetInput {
    address underlyingAsset;
    uint256 userBalance;
    uint256 totalSupply;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import {DistributionTypes} from '../libraries/DistributionTypes.sol';

interface IRewardsDistributor {
  event AssetConfigUpdated(
    address indexed asset,
    address indexed reward,
    uint256 emission,
    uint256 distributionEnd
  );
  event AssetIndexUpdated(address indexed asset, address indexed reward, uint256 index);
  event UserIndexUpdated(
    address indexed user,
    address indexed asset,
    address indexed reward,
    uint256 index
  );

  event RewardsAccrued(address indexed user, address indexed reward, uint256 amount);

  function setDistributionEnd(
    address asset,
    address reward,
    uint32 distributionEnd
  ) external;

  function getDistributionEnd(address asset, address reward) external view returns (uint256);

  function getUserAssetData(
    address user,
    address asset,
    address reward
  ) external view returns (uint256);

  function getRewardsData(address asset, address reward)
    external
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256
    );

  function getRewardsByAsset(address asset) external view returns (address[] memory);

  function getRewardTokens() external view returns (address[] memory);

  function getUserUnclaimedRewardsFromStorage(address user, address reward)
    external
    view
    returns (uint256);

  function getUserRewardsBalance(
    address[] calldata assets,
    address user,
    address reward
  ) external view returns (uint256);

  function getAllUserRewardsBalance(address[] calldata assets, address user)
    external
    view
    returns (address[] memory, uint256[] memory);

  function getAssetDecimals(address asset) external view returns (uint8);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;

import {IERC20} from './IERC20.sol';

interface IERC20Detailed is IERC20 {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import './Context.sol';

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
contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
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
    require(_owner == _msgSender(), 'Ownable: caller is not the owner');
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
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

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