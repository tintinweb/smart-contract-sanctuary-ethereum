// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./external/@openzeppelin/security/ReentrancyGuardUpgradeable.sol";
import "./external/spool-core/SpoolOwnable.sol";
import "./interfaces/ISpoolStaking.sol";

import "./external/@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "./external/@openzeppelin/utils/SafeCast.sol";
import "./interfaces/IVoSpoolRewards.sol";
import "./interfaces/IVoSPOOL.sol";
import "./interfaces/IRewardDistributor.sol";

/* ========== STRUCTS ========== */

// The reward configuration struct, containing all the necessary data of a typical Synthetix StakingReward contract
struct RewardConfiguration {
	uint32 rewardsDuration;
	uint32 periodFinish;
	uint192 rewardRate; // rewards per second multiplied by accuracy
	uint32 lastUpdateTime;
	uint224 rewardPerTokenStored;
	mapping(address => uint256) userRewardPerTokenPaid;
	mapping(address => uint256) rewards;
}

/**
 * @notice Implementation of the {ISpoolStaking} interface.
 *
 * @dev
 * An adaptation of the Synthetix StakingRewards contract to support multiple tokens:
 *
 * https://github.com/Synthetixio/synthetix/blob/develop/contracts/StakingRewards.sol
 *
 * At stake, gradual voSPOOL (Spool DAO Voting Token) is minted and accumulated every week.
 * At unstake all voSPOOL is burned. The maturing process of voSPOOL restarts.
 */
contract SpoolStaking is ReentrancyGuardUpgradeable, SpoolOwnable, ISpoolStaking {
	using SafeERC20 for IERC20;

	/* ========== CONSTANTS ========== */

	/// @notice Multiplier used when dealing reward calculations
	uint256 private constant REWARD_ACCURACY = 1e18;

	/* ========== STATE VARIABLES ========== */

	/// @notice SPOOL token address
	IERC20 public immutable stakingToken;

	/// @notice voSPOOL token address
	IVoSPOOL public immutable voSpool;

	/// @notice voSPOOL token rewards address
	IVoSpoolRewards public immutable voSpoolRewards;

	/// @notice Spool reward distributor
	IRewardDistributor public immutable rewardDistributor;

	/// @notice Reward token configurations
	mapping(IERC20 => RewardConfiguration) public rewardConfiguration;

	/// @notice Reward tokens
	IERC20[] public rewardTokens;

	/// @notice Blacklisted force-removed tokens
	mapping(IERC20 => bool) public tokenBlacklist;

	/// @notice Total SPOOL staked
	uint256 public totalStaked;

	/// @notice Account SPOOL staked balance
	mapping(address => uint256) public balances;

	/// @notice Whitelist showing if address can stake for another address
	mapping(address => bool) public canStakeFor;

	/// @notice Mapping showing if and what address staked for another address
	/// @dev if address is 0, noone staked for address (or unstaking was permitted)
	mapping(address => address) public stakedBy;

	/* ========== CONSTRUCTOR ========== */

	/**
	 * @notice Sets the immutable values
	 *
	 * @param _stakingToken SPOOL token
	 * @param _voSpool Spool voting token (voSPOOL)
	 * @param _voSpoolRewards voSPOOL rewards contract
	 * @param _rewardDistributor reward distributor contract
	 * @param _spoolOwner Spool DAO owner contract
	 */
	constructor(
		IERC20 _stakingToken,
		IVoSPOOL _voSpool,
		IVoSpoolRewards _voSpoolRewards,
		IRewardDistributor _rewardDistributor,
		ISpoolOwner _spoolOwner
	) SpoolOwnable(_spoolOwner) {
		stakingToken = _stakingToken;
		voSpool = _voSpool;
		voSpoolRewards = _voSpoolRewards;
		rewardDistributor = _rewardDistributor;
	}

	/* ========== INITIALIZER ========== */

	function initialize() external initializer {
		__ReentrancyGuard_init();
	}

	/* ========== VIEWS ========== */

	function lastTimeRewardApplicable(IERC20 token) public view returns (uint32) {
		return uint32(_min(block.timestamp, rewardConfiguration[token].periodFinish));
	}

	function rewardPerToken(IERC20 token) public view returns (uint224) {
		RewardConfiguration storage config = rewardConfiguration[token];

		if (totalStaked == 0) return config.rewardPerTokenStored;

		uint256 timeDelta = lastTimeRewardApplicable(token) - config.lastUpdateTime;

		if (timeDelta == 0) return config.rewardPerTokenStored;

		return SafeCast.toUint224(config.rewardPerTokenStored + ((timeDelta * config.rewardRate) / totalStaked));
	}

	function earned(IERC20 token, address account) public view returns (uint256) {
		RewardConfiguration storage config = rewardConfiguration[token];

		uint256 accountStaked = balances[account];

		if (accountStaked == 0) return config.rewards[account];

		uint256 userRewardPerTokenPaid = config.userRewardPerTokenPaid[account];

		return
			((accountStaked * (rewardPerToken(token) - userRewardPerTokenPaid)) / REWARD_ACCURACY) +
			config.rewards[account];
	}

	function rewardTokensCount() external view returns (uint256) {
		return rewardTokens.length;
	}

	/* ========== MUTATIVE FUNCTIONS ========== */

	function stake(uint256 amount) external nonReentrant updateRewards(msg.sender) {
		_stake(msg.sender, amount);

		stakingToken.safeTransferFrom(msg.sender, address(this), amount);

		emit Staked(msg.sender, amount);
	}

	function _stake(address account, uint256 amount) private {
		require(amount > 0, "SpoolStaking::_stake: Cannot stake 0");

		unchecked {
			totalStaked = totalStaked += amount;
			balances[account] += amount;
		}

		// mint gradual voSPOOL for the account
		voSpool.mintGradual(account, amount);
	}

	function compound(bool doCompoundVoSpoolRewards) external nonReentrant {
		// collect SPOOL earned fom spool rewards and stake them
		uint256 reward = _getRewardForCompound(msg.sender, doCompoundVoSpoolRewards);

		if (reward > 0) {
			// update user rewards before staking
			_updateSpoolRewards(msg.sender);

			// update user voSPOOL based reward before staking
			// skip updating voSPOOL reward if we compounded form it as it's already updated
			if (!doCompoundVoSpoolRewards) {
				_updateVoSpoolReward(msg.sender);
			}

			// stake collected reward
			_stake(msg.sender, reward);
			// move compounded SPOOL reward to this contract
			rewardDistributor.payReward(address(this), stakingToken, reward);
		}
	}

	function unstake(uint256 amount) public nonReentrant notStakedBy updateRewards(msg.sender) {
		require(amount > 0, "SpoolStaking::unstake: Cannot withdraw 0");
		require(amount <= balances[msg.sender], "SpoolStaking::unstake: Cannot unstake more than staked");

		unchecked {
			totalStaked = totalStaked -= amount;
			balances[msg.sender] -= amount;
		}

		stakingToken.safeTransfer(msg.sender, amount);

		// burn gradual voSPOOL for the sender
		if (balances[msg.sender] == 0) {
			voSpool.burnGradual(msg.sender, 0, true);
		} else {
			voSpool.burnGradual(msg.sender, amount, false);
		}

		emit Unstaked(msg.sender, amount);
	}

	function _getRewardForCompound(address account, bool doCompoundVoSpoolRewards)
		internal
		updateReward(stakingToken, account)
		returns (uint256 reward)
	{
		RewardConfiguration storage config = rewardConfiguration[stakingToken];

		reward = config.rewards[account];
		if (reward > 0) {
			config.rewards[account] = 0;
			emit RewardCompounded(msg.sender, reward);
		}

		if (doCompoundVoSpoolRewards) {
			_updateVoSpoolReward(account);
			uint256 voSpoolreward = voSpoolRewards.flushRewards(account);

			if (voSpoolreward > 0) {
				reward += voSpoolreward;
				emit VoRewardCompounded(msg.sender, reward);
			}
		}
	}

	function getRewards(IERC20[] memory tokens, bool doClaimVoSpoolRewards) external nonReentrant notStakedBy {
		for (uint256 i; i < tokens.length; i++) {
			_getReward(tokens[i], msg.sender);
		}

		if (doClaimVoSpoolRewards) {
			_getVoSpoolRewards(msg.sender);
		}
	}

	function getActiveRewards(bool doClaimVoSpoolRewards) external nonReentrant notStakedBy {
		_getActiveRewards(msg.sender);

		if (doClaimVoSpoolRewards) {
			_getVoSpoolRewards(msg.sender);
		}
	}

	function getUpdatedVoSpoolRewardAmount() external returns (uint256 rewards) {
		// update rewards
		rewards = voSpoolRewards.updateRewards(msg.sender);
		// update and store users voSPOOL
		voSpool.updateUserVotingPower(msg.sender);
	}

	function _getActiveRewards(address account) internal {
		uint256 _rewardTokensCount = rewardTokens.length;
		for (uint256 i; i < _rewardTokensCount; i++) {
			_getReward(rewardTokens[i], account);
		}
	}

	function _getReward(IERC20 token, address account) internal updateReward(token, account) {
		RewardConfiguration storage config = rewardConfiguration[token];

		require(config.rewardsDuration != 0, "SpoolStaking::_getReward: Bad reward token");

		uint256 reward = config.rewards[account];
		if (reward > 0) {
			config.rewards[account] = 0;
			rewardDistributor.payReward(account, token, reward);
			emit RewardPaid(token, account, reward);
		}
	}

	function _getVoSpoolRewards(address account) internal {
		_updateVoSpoolReward(account);
		uint256 reward = voSpoolRewards.flushRewards(account);

		if (reward > 0) {
			rewardDistributor.payReward(account, stakingToken, reward);
			emit VoSpoolRewardPaid(stakingToken, account, reward);
		}
	}

	/* ========== RESTRICTED FUNCTIONS ========== */

	function stakeFor(address account, uint256 amount)
		external
		nonReentrant
		canStakeForAddress(account)
		updateRewards(account)
	{
		_stake(account, amount);
		stakingToken.safeTransferFrom(msg.sender, address(this), amount);
		stakedBy[account] = msg.sender;

		emit StakedFor(account, msg.sender, amount);
	}

	/**
	 * @notice Allow unstake for `allowFor` address
	 * @dev
	 *
	 * Requirements:
	 *
	 * - the caller must be the Spool DAO or address that staked for `allowFor` address
	 *
	 * @param allowFor address to allow unstaking for
	 */
	function allowUnstakeFor(address allowFor) external {
		require(
			(canStakeFor[msg.sender] && stakedBy[allowFor] == msg.sender) || isSpoolOwner(),
			"SpoolStaking::allowUnstakeFor: Cannot allow unstaking for address"
		);
		// reset address to 0 to allow unstaking
		stakedBy[allowFor] = address(0);
	}

	/**
	 * @notice Allows a new token to be added to the reward system
	 *
	 * @dev
	 * Emits an {TokenAdded} event indicating the newly added reward token
	 * and configuration
	 *
	 * Requirements:
	 *
	 * - the caller must be the reward Spool DAO
	 * - the reward duration must be non-zero
	 * - the token must not have already been added
	 *
	 */
	function addToken(
		IERC20 token,
		uint32 rewardsDuration,
		uint256 reward
	) external onlyOwner {
		RewardConfiguration storage config = rewardConfiguration[token];

		require(!tokenBlacklist[token], "SpoolStaking::addToken: Cannot add blacklisted token");
		require(rewardsDuration != 0, "SpoolStaking::addToken: Reward duration cannot be 0");
		require(config.lastUpdateTime == 0, "SpoolStaking::addToken: Token already added");

		rewardTokens.push(token);

		config.rewardsDuration = rewardsDuration;

		if (reward > 0) {
			_notifyRewardAmount(token, reward);
		}
	}

	function notifyRewardAmount(
		IERC20 token,
		uint32 _rewardsDuration,
		uint256 reward
	) external onlyOwner {
		RewardConfiguration storage config = rewardConfiguration[token];
		config.rewardsDuration = _rewardsDuration;
		require(
			rewardConfiguration[token].lastUpdateTime != 0,
			"SpoolStaking::notifyRewardAmount: Token not yet added"
		);
		_notifyRewardAmount(token, reward);
	}

	function _notifyRewardAmount(IERC20 token, uint256 reward) private updateReward(token, address(0)) {
		RewardConfiguration storage config = rewardConfiguration[token];

		require(
			config.rewardPerTokenStored + (reward * REWARD_ACCURACY) <= type(uint192).max,
			"SpoolStaking::_notifyRewardAmount: Reward amount too big"
		);

		uint32 newPeriodFinish = uint32(block.timestamp) + config.rewardsDuration;

		if (block.timestamp >= config.periodFinish) {
			config.rewardRate = SafeCast.toUint192((reward * REWARD_ACCURACY) / config.rewardsDuration);
			emit RewardAdded(token, reward, config.rewardsDuration);
		} else {
			uint256 remaining = config.periodFinish - block.timestamp;
			uint256 leftover = remaining * config.rewardRate;
			uint192 newRewardRate = SafeCast.toUint192((reward * REWARD_ACCURACY + leftover) / config.rewardsDuration);

			config.rewardRate = newRewardRate;
			emit RewardUpdated(token, reward, leftover, config.rewardsDuration, newPeriodFinish);
		}

		config.lastUpdateTime = uint32(block.timestamp);
		config.periodFinish = newPeriodFinish;
	}

	// End rewards emission earlier
	function updatePeriodFinish(IERC20 token, uint32 timestamp) external onlyOwner updateReward(token, address(0)) {
		if (rewardConfiguration[token].lastUpdateTime > timestamp) {
			rewardConfiguration[token].periodFinish = rewardConfiguration[token].lastUpdateTime;
		} else {
			rewardConfiguration[token].periodFinish = timestamp;
		}

		emit PeriodFinishUpdated(token, rewardConfiguration[token].periodFinish);
	}

	/**
	 * @notice Remove reward from vault rewards configuration.
	 * @dev
	 * Used to sanitize vault and save on gas, after the reward has ended.
	 * Users will be able to claim rewards
	 *
	 * Requirements:
	 *
	 * - the caller must be the spool owner or Spool DAO
	 * - cannot claim vault underlying token
	 * - cannot only execute if the reward finished
	 *
	 * @param token Token address to remove
	 */
	function removeReward(IERC20 token) external onlyOwner onlyFinished(token) updateReward(token, address(0)) {
		_removeReward(token);
	}

	/**
	 * @notice Allow an address to stake for another address.
	 * @dev
	 * Requirements:
	 *
	 * - the caller must be the distributor
	 *
	 * @param account Address to allow
	 * @param _canStakeFor True to allow, false to remove allowance
	 */
	function setCanStakeFor(address account, bool _canStakeFor) external onlyOwner {
		canStakeFor[account] = _canStakeFor;
		emit CanStakeForSet(account, _canStakeFor);
	}

	function recoverERC20(
		IERC20 tokenAddress,
		uint256 tokenAmount,
		address recoverTo
	) external onlyOwner {
		require(tokenAddress != stakingToken, "SpoolStaking::recoverERC20: Cannot withdraw the staking token");
		tokenAddress.safeTransfer(recoverTo, tokenAmount);
	}

	/* ========== PRIVATE FUNCTIONS ========== */

	/**
	 * @notice Syncs rewards across all tokens of the system
	 *
	 * This function is meant to be invoked every time the instant deposit
	 * of a user changes.
	 */
	function _updateRewards(address account) private {
		// update SPOOL based rewards
		_updateSpoolRewards(account);

		// update voSPOOL based reward
		_updateVoSpoolReward(account);
	}

	function _updateSpoolRewards(address account) private {
		uint256 _rewardTokensCount = rewardTokens.length;

		// update SPOOL based rewards
		for (uint256 i; i < _rewardTokensCount; i++) _updateReward(rewardTokens[i], account);
	}

	function _updateReward(IERC20 token, address account) private {
		RewardConfiguration storage config = rewardConfiguration[token];
		config.rewardPerTokenStored = rewardPerToken(token);
		config.lastUpdateTime = lastTimeRewardApplicable(token);
		if (account != address(0)) {
			config.rewards[account] = earned(token, account);
			config.userRewardPerTokenPaid[account] = config.rewardPerTokenStored;
		}
	}

	/**
	 * @notice Update rewards collected from account voSPOOL
	 * @dev
	 * First we update rewards calling `voSpoolRewards.updateRewards`
	 * - Here we only simulate the reward accumulated over tranches
	 * Then we update and store users power by calling voSPOOL contract
	 * - Here we actually store the udated values.
	 * - If store wouldn't happen, next time we'd simulate the same voSPOOL tranches again
	 */
	function _updateVoSpoolReward(address account) private {
		// update rewards
		voSpoolRewards.updateRewards(account);
		// update and store users voSPOOL
		voSpool.updateUserVotingPower(account);
	}

	function _removeReward(IERC20 token) private {
		uint256 _rewardTokensCount = rewardTokens.length;
		for (uint256 i; i < _rewardTokensCount; i++) {
			if (rewardTokens[i] == token) {
				rewardTokens[i] = rewardTokens[_rewardTokensCount - 1];

				rewardTokens.pop();
				emit RewardRemoved(token);
				break;
			}
		}
	}

	function _onlyFinished(IERC20 token) private view {
		require(
			block.timestamp > rewardConfiguration[token].periodFinish,
			"SpoolStaking::_onlyFinished: Reward not finished"
		);
	}

	function _min(uint256 a, uint256 b) private pure returns (uint256) {
		return a > b ? b : a;
	}

	/* ========== MODIFIERS ========== */

	modifier updateReward(IERC20 token, address account) {
		_updateReward(token, account);
		_;
	}

	modifier updateRewards(address account) {
		_updateRewards(account);
		_;
	}

	modifier canStakeForAddress(address account) {
		// verify sender can stake for
		require(
			canStakeFor[msg.sender] || isSpoolOwner(),
			"SpoolStaking::canStakeForAddress: Cannot stake for other addresses"
		);

		// if address already staked, verify further
		if (balances[account] > 0) {
			// verify address was staked by some other address
			require(stakedBy[account] != address(0), "SpoolStaking::canStakeForAddress: Address already staked");

			// verify address was staked by the sender or sender is the Spool DAO
			require(
				stakedBy[account] == msg.sender || isSpoolOwner(),
				"SpoolStaking::canStakeForAddress: Address staked by another address"
			);
		}
		_;
	}

	modifier notStakedBy() {
		require(stakedBy[msg.sender] == address(0), "SpoolStaking::notStakedBy: Cannot withdraw until allowed");
		_;
	}

	modifier onlyFinished(IERC20 token) {
		_onlyFinished(token);
		_;
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 128 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./interfaces/ISpoolOwner.sol";

abstract contract SpoolOwnable {
    ISpoolOwner internal immutable spoolOwner;
    
    constructor(ISpoolOwner _spoolOwner) {
        require(
            address(_spoolOwner) != address(0),
            "SpoolOwnable::constructor: Spool owner contract address cannot be 0"
        );

        spoolOwner = _spoolOwner;
    }

    function isSpoolOwner() internal view returns(bool) {
        return spoolOwner.isSpoolOwner(msg.sender);
    }

    function _onlyOwner() internal view {
        require(isSpoolOwner(), "SpoolOwnable::onlyOwner: Caller is not the Spool owner");
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface ISpoolOwner {
    function isSpoolOwner(address user) external view returns(bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "../external/@openzeppelin/token/ERC20/IERC20.sol";

interface IRewardDistributor {
	/* ========== FUNCTIONS ========== */

	function payRewards(
		address account,
		IERC20[] memory tokens,
		uint256[] memory amounts
	) external;

	function payReward(
		address account,
		IERC20 token,
		uint256 amount
	) external;

	/* ========== EVENTS ========== */

	event RewardPaid(IERC20 token, address indexed account, uint256 amount);
	event RewardRetrieved(IERC20 token, address indexed account, uint256 amount);
	event DistributorUpdated(address indexed user, bool set);
	event PauserUpdated(address indexed user, bool set);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "../external/@openzeppelin/token/ERC20/IERC20.sol";

interface ISpoolStaking {
	/* ========== EVENTS ========== */

	event Staked(address indexed user, uint256 amount);

	event StakedFor(address indexed stakedFor, address indexed stakedBy, uint256 amount);

	event Unstaked(address indexed user, uint256 amount);
	
	event RewardCompounded(address indexed user, uint256 reward);
	
	event VoRewardCompounded(address indexed user, uint256 reward);

	event RewardPaid(IERC20 token, address indexed user, uint256 reward);

	event VoSpoolRewardPaid(IERC20 token, address indexed user, uint256 reward);

	event RewardAdded(IERC20 indexed token, uint256 amount, uint256 duration);

	event RewardUpdated(IERC20 indexed token, uint256 amount, uint256 leftover, uint256 duration, uint32 periodFinish);

	event RewardRemoved(IERC20 indexed token);

	event PeriodFinishUpdated(IERC20 indexed token, uint32 periodFinish);

	event CanStakeForSet(address indexed account, bool canStakeFor);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

/* ========== STRUCTS ========== */

/**
 * @notice global gradual struct
 * @member totalMaturedVotingPower total fully-matured voting power amount
 * @member totalMaturingAmount total maturing amount (amount of power that is accumulating every week for 1/156 of the amount)
 * @member totalRawUnmaturedVotingPower total raw voting power still maturing every tranche (totalRawUnmaturedVotingPower/156 is its voting power)
 * @member lastUpdatedTrancheIndex last (finished) tranche index global gradual has updated
 */
struct GlobalGradual {
	uint48 totalMaturedVotingPower;
	uint48 totalMaturingAmount;
	uint56 totalRawUnmaturedVotingPower;
	uint16 lastUpdatedTrancheIndex;
}

/**
 * @notice user tranche position struct, pointing at user tranche
 * @dev points at `userTranches` mapping
 * @member arrayIndex points at `userTranches`
 * @member position points at UserTranches position from zero to three (zero, one, two, or three)
 */
struct UserTranchePosition {
	uint16 arrayIndex;
	uint8 position;
}

/**
 * @notice user gradual struct, similar to global gradual holds user gragual voting power values
 * @dev points at `userTranches` mapping
 * @member maturedVotingPower users fully-matured voting power amount
 * @member maturingAmount users maturing amount
 * @member rawUnmaturedVotingPower users raw voting power still maturing every tranche
 * @member oldestTranchePosition UserTranchePosition pointing at the oldest unmatured UserTranche
 * @member latestTranchePosition UserTranchePosition pointing at the latest unmatured UserTranche
 * @member lastUpdatedTrancheIndex last (finished) tranche index user gradual has updated
 */
struct UserGradual {
	uint48 maturedVotingPower; // matured voting amount, power accumulated and older than FULL_POWER_TIME, not accumulating anymore
	uint48 maturingAmount; // total maturing amount (also maximum matured)
	uint56 rawUnmaturedVotingPower; // current user raw unmatured voting power (increases every new tranche), actual unmatured voting power can be calculated as unmaturedVotingPower / FULL_POWER_TRANCHES_COUNT
	UserTranchePosition oldestTranchePosition; // if arrayIndex is 0, user has no tranches (even if `latestTranchePosition` is not empty)
	UserTranchePosition latestTranchePosition; // can only increment, in case of tranche removal, next time user gradually mints we point at tranche at next position
	uint16 lastUpdatedTrancheIndex;
}

/**
 * @title Spool DAO Voting Token interface
 */
interface IVoSPOOL {
	/* ========== FUNCTIONS ========== */

	function mint(address, uint256) external;

	function burn(address, uint256) external;

	function mintGradual(address, uint256) external;

	function burnGradual(
		address,
		uint256,
		bool
	) external;

	function updateVotingPower() external;

	function updateUserVotingPower(address user) external;

	function getTotalGradualVotingPower() external returns (uint256);

	function getUserGradualVotingPower(address user) external returns (uint256);

	function getNotUpdatedUserGradual(address user) external view returns (UserGradual memory);

	function getNotUpdatedGlobalGradual() external view returns (GlobalGradual memory);

	function getCurrentTrancheIndex() external view returns (uint16);

	function getLastFinishedTrancheIndex() external view returns (uint16);

	/* ========== EVENTS ========== */

	event Minted(address indexed recipient, uint256 amount);

	event Burned(address indexed source, uint256 amount);

	event GradualMinted(address indexed recipient, uint256 amount);

	event GradualBurned(address indexed source, uint256 amount, bool burnAll);

	event GlobalGradualUpdated(
		uint16 indexed lastUpdatedTrancheIndex,
		uint48 totalMaturedVotingPower,
		uint48 totalMaturingAmount,
		uint56 totalRawUnmaturedVotingPower
	);

	event UserGradualUpdated(
		address indexed user,
		uint16 indexed lastUpdatedTrancheIndex,
		uint48 maturedVotingPower,
		uint48 maturingAmount,
		uint56 rawUnmaturedVotingPower
	);

	event MinterSet(address indexed minter, bool set);

	event GradualMinterSet(address indexed minter, bool set);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IVoSpoolRewards {
	/* ========== FUNCTIONS ========== */

	function updateRewards(address user) external returns (uint256);

	function flushRewards(address user) external returns (uint256);

	/* ========== EVENTS ========== */

	event RewardRateUpdated(uint8 indexed fromTranche, uint8 indexed toTranche, uint112 rewardPerTranche);

	event RewardEnded(
		uint256 indexed rewardRatesIndex,
		uint8 indexed fromTranche,
		uint8 indexed toTranche,
		uint8 currentTrancheIndex
	);

	event UserRewardUpdated(address indexed user, uint8 lastRewardRateIndex, uint248 earned);
}