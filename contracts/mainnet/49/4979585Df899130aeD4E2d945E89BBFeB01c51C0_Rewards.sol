// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./dependencies/@openzeppelin/security/ReentrancyGuard.sol";
import "./dependencies/@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "./dependencies/@openzeppelin/utils/math/Math.sol";
import "./dependencies/@openzeppelin/utils/math/SafeCast.sol";
import "./access/Governable.sol";
import "./storage/RewardsStorage.sol";

/**
 * @title Rewards contract
 */
contract Rewards is ReentrancyGuard, Governable, RewardsStorageV1 {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;

    string public constant VERSION = "1.0.0";
    uint256 public constant REWARD_DURATION = 30 days;

    /// Emitted after reward added
    event RewardAdded(address indexed rewardToken, uint256 reward, uint256 rewardDuration);

    /// Emitted whenever any user claim rewards
    event RewardPaid(address indexed user, address indexed rewardToken, uint256 reward);

    /// Emitted after adding new rewards token into rewardTokens array
    event RewardTokenAdded(address indexed rewardToken, address[] existingRewardTokens);

    /// Emitted when distributor approval is updated
    event RewardDistributorApprovalUpdated(address rewardsToken, address distributor, bool approved);

    function initialize(IESVSP esVSP_) external initializer {
        require(address(esVSP_) != address(0), "esVSP-is-null");

        __Governable_init();

        esVSP = esVSP_;
    }

    /**
     * @notice Get claimable rewards
     * @param account_ The account
     * @return _rewardTokens The addresses of the reward tokens
     * @return _claimableAmounts The claimable amounts
     */
    function claimableRewards(address account_)
        external
        view
        override
        returns (address[] memory _rewardTokens, uint256[] memory _claimableAmounts)
    {
        uint256 _len = rewardTokens.length;

        _rewardTokens = new address[](_len);
        _claimableAmounts = new uint256[](_len);

        uint256 _totalSupply;
        uint256 _userBalance;
        for (uint256 i; i < _len; i++) {
            address _rewardToken = rewardTokens[i];
            (_totalSupply, _userBalance) = _getSupplyAndBalance(_rewardToken, account_);
            _rewardTokens[i] = _rewardToken;
            _claimableAmounts[i] = _claimable(_rewardToken, account_, _totalSupply, _userBalance);
        }
    }

    /**
     * @notice Claim earned rewards
     * @dev This function will claim rewards for all tokens being rewarded
     * @param account_ The account
     */
    function claimRewards(address account_) external override nonReentrant {
        uint256 _len = rewardTokens.length;

        uint256 _totalSupply;
        uint256 _userBalance;
        for (uint256 i; i < _len; i++) {
            address _rewardToken = rewardTokens[i];
            (_totalSupply, _userBalance) = _getSupplyAndBalance(_rewardToken, account_);

            _updateReward(_rewardToken, account_, _totalSupply, _userBalance);

            uint256 _rewardAmount = rewardOf[_rewardToken][account_].claimableRewardsStored;
            if (_rewardAmount > 0) {
                _claimReward(_rewardToken, account_, _rewardAmount);
            }
        }
    }

    /**
     * @notice Drip reward token and extend current reward duration by 30 days
     * User get drip based on their boosted VSP amount
     * @dev Restricted method
     * @param rewardToken_ Reward token address
     * @param rewardAmount_  Reward amount
     */
    function dripRewardAmount(address rewardToken_, uint256 rewardAmount_) external override {
        require(rewards[rewardToken_].lastUpdateTime > 0, "reward-token-not-added");
        require(isRewardDistributor[rewardToken_][_msgSender()], "not-distributor");
        require(rewardAmount_ > 0, "incorrect-reward-amount");
        _dripRewardAmount(rewardToken_, rewardAmount_);
    }

    /**
     * @notice Returns timestamp of last reward update
     * @param _rewardToken The reward token
     * @return The timestamp
     */
    function lastTimeRewardApplicable(address _rewardToken) public view override returns (uint256) {
        return Math.min(block.timestamp, rewards[_rewardToken].periodFinish);
    }

    /**
     * @notice Update reward earning of user
     * @param account_ The account
     */
    function updateReward(address account_) external override {
        uint256 _len = rewardTokens.length;

        uint256 _totalSupply;
        uint256 _userBalance;
        for (uint256 i; i < _len; i++) {
            address _rewardToken = rewardTokens[i];
            (_totalSupply, _userBalance) = _getSupplyAndBalance(_rewardToken, account_);
            _updateReward(_rewardToken, account_, _totalSupply, _userBalance);
        }
    }

    /**
     * @notice Get claimable rewards for a reward token
     * @param rewardToken_ The address of the reward token
     * @param account_ The account
     * @param totalSupply_ The supply of reference (boosted or locked)
     * @param balance_ The balance of reference (boosted or locked)
     * @return The claimable amount
     */
    function _claimable(
        address rewardToken_,
        address account_,
        uint256 totalSupply_,
        uint256 balance_
    ) private view returns (uint256) {
        UserReward memory _userReward = rewardOf[rewardToken_][account_];
        uint256 _rewardPerTokenAvailable = _rewardPerToken(rewardToken_, totalSupply_) - _userReward.rewardPerTokenPaid;
        uint256 _rewardsEarnedSinceLastUpdate = (balance_ * _rewardPerTokenAvailable) / 1e18;
        return _userReward.claimableRewardsStored + _rewardsEarnedSinceLastUpdate;
    }

    /**
     * @notice Transfer claimable reward to user
     * @param rewardToken_ The reward token
     * @param account_ The account
     * @param reward_ The reward amount
     */
    function _claimReward(
        address rewardToken_,
        address account_,
        uint256 reward_
    ) private {
        rewardOf[rewardToken_][account_].claimableRewardsStored = 0;
        IERC20(rewardToken_).safeTransfer(account_, reward_);
        emit RewardPaid(account_, rewardToken_, reward_);
    }

    /**
     * @notice Drip reward token and extend current reward duration by 30 days
     * User get drip based on their boosted VSP amount
     * @param rewardToken_ Reward token address
     * @param rewardAmount_  Reward amount
     */
    function _dripRewardAmount(address rewardToken_, uint256 rewardAmount_) private {
        uint256 _balanceBefore = IERC20(rewardToken_).balanceOf(address(this));
        IERC20(rewardToken_).safeTransferFrom(_msgSender(), address(this), rewardAmount_);
        uint256 _dripAmount = IERC20(rewardToken_).balanceOf(address(this)) - _balanceBefore;

        Reward storage _reward = rewards[rewardToken_];
        uint256 _totalSupply = _reward.isBoosted ? esVSP.totalBoosted() : esVSP.totalLocked();
        _reward.rewardPerTokenStored = _rewardPerToken(rewardToken_, _totalSupply);

        if (block.timestamp >= _reward.periodFinish) {
            _reward.rewardPerSecond = _dripAmount / REWARD_DURATION;
        } else {
            uint256 _remainingPeriod = _reward.periodFinish - block.timestamp;
            uint256 _leftover = _remainingPeriod * _reward.rewardPerSecond;
            _reward.rewardPerSecond = (_dripAmount + _leftover) / REWARD_DURATION;
        }

        // Start new drip time
        _reward.lastUpdateTime = block.timestamp;
        _reward.periodFinish = block.timestamp + REWARD_DURATION;
        emit RewardAdded(rewardToken_, _dripAmount, REWARD_DURATION);
    }

    /**
     * @notice Get supply and balance for reference (i.e. locked or boosted)
     */
    function _getSupplyAndBalance(address rewardToken_, address account_)
        private
        view
        returns (uint256 _totalSupply, uint256 _userBalance)
    {
        if (rewards[rewardToken_].isBoosted) {
            _totalSupply = esVSP.totalBoosted();
            _userBalance = esVSP.boosted(account_);
        } else {
            _totalSupply = esVSP.totalLocked();
            _userBalance = esVSP.locked(account_);
        }
    }

    /**
     * @notice Returns the reward per VSP locked based on time elapsed since last notification multiplied by reward rate
     * @param rewardToken_ The reward token
     * @param totalSupply_ The supply of reference (boosted or locked)
     * @return The reward per VSP
     */
    function _rewardPerToken(address rewardToken_, uint256 totalSupply_) private view returns (uint256) {
        if (totalSupply_ == 0) {
            return rewards[rewardToken_].rewardPerTokenStored;
        }

        uint256 _timeSinceLastUpdate = lastTimeRewardApplicable(rewardToken_) - rewards[rewardToken_].lastUpdateTime;
        uint256 _rewardsSinceLastUpdate = _timeSinceLastUpdate * rewards[rewardToken_].rewardPerSecond;
        uint256 _rewardsPerTokenSinceLastUpdate = (_rewardsSinceLastUpdate * 1e18) / totalSupply_;
        return rewards[rewardToken_].rewardPerTokenStored + _rewardsPerTokenSinceLastUpdate;
    }

    /**
     * @notice Update reward earning of user
     * @param rewardToken_ The address of the reward token
     * @param account_ The account
     * @param totalSupply_ The supply of reference (boosted or locked)
     * @param balance_ The balance of reference (boosted or locked)
     */
    function _updateReward(
        address rewardToken_,
        address account_,
        uint256 totalSupply_,
        uint256 balance_
    ) private {
        uint256 _rewardPerTokenStored = _rewardPerToken(rewardToken_, totalSupply_);
        Reward storage _reward = rewards[rewardToken_];
        _reward.rewardPerTokenStored = _rewardPerTokenStored;
        _reward.lastUpdateTime = lastTimeRewardApplicable(rewardToken_);
        if (account_ != address(0)) {
            rewardOf[rewardToken_][account_] = UserReward({
                claimableRewardsStored: _claimable(rewardToken_, account_, totalSupply_, balance_).toUint128(),
                rewardPerTokenPaid: _rewardPerTokenStored.toUint128()
            });
        }
    }

    /** Governance methods **/

    /**
     * @notice Allow/disallow address as a reward distributor for a given token
     * @param rewardsToken_ The reward token
     * @param distributor_ The distributor address
     * @param approved_ The approved boolean flag
     */
    function setRewardDistributorApproval(
        address rewardsToken_,
        address distributor_,
        bool approved_
    ) external onlyGovernor {
        require(rewards[rewardsToken_].lastUpdateTime > 0, "reward-token-not-added");
        isRewardDistributor[rewardsToken_][distributor_] = approved_;
        emit RewardDistributorApprovalUpdated(rewardsToken_, distributor_, approved_);
    }

    /**
     * @notice add new reward token for distribution
     * @param rewardsToken_ Reward token address
     * @param distributor_  Authorized called to call dripRewardAmount
     * @param isBoosted_ If reward token is boosted than rewards is distributed on boost amount depends on lock period
     */
    function addRewardToken(
        address rewardsToken_,
        address distributor_,
        bool isBoosted_
    ) external onlyGovernor {
        require(rewards[rewardsToken_].lastUpdateTime == 0, "reward-already-added");
        rewards[rewardsToken_] = Reward({
            isBoosted: isBoosted_,
            periodFinish: block.timestamp,
            rewardPerSecond: 0,
            rewardPerTokenStored: 0,
            lastUpdateTime: block.timestamp
        });
        emit RewardTokenAdded(rewardsToken_, rewardTokens);
        rewardTokens.push(rewardsToken_);
        isRewardDistributor[rewardsToken_][distributor_] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/@openzeppelin/utils/Context.sol";
import "../dependencies/@openzeppelin/proxy/utils/Initializable.sol";
import "../interface/IGovernable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (governor) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the governor account will be the one that deploys the contract. This
 * can later be changed with {transferGovernorship}.
 *
 */
abstract contract Governable is IGovernable, Initializable, Context {
    address public governor;
    address public proposedGovernor;

    event UpdatedGovernor(address indexed previousGovernor, address indexed proposedGovernor);

    /**
     * @dev If inheriting child is using proxy then child contract can use
     * __Governable_init() function to initialization this contract
     */
    // solhint-disable-next-line func-name-mixedcase
    function __Governable_init() internal onlyInitializing {
        governor = _msgSender();
        emit UpdatedGovernor(address(0), governor);
    }

    /**
     * @dev Throws if called by any account other than the governor.
     */
    modifier onlyGovernor() {
        require(governor == _msgSender(), "not-governor");
        _;
    }

    /**
     * @dev Transfers governorship of the contract to a new account (`proposedGovernor`).
     * Can only be called by the current owner.
     */
    function transferGovernorship(address _proposedGovernor) external onlyGovernor {
        require(_proposedGovernor != address(0), "proposed-governor-is-zero");
        proposedGovernor = _proposedGovernor;
    }

    /**
     * @dev Allows new governor to accept governorship of the contract.
     */
    function acceptGovernorship() external {
        require(proposedGovernor == _msgSender(), "not-the-proposed-governor");
        emit UpdatedGovernor(governor, proposedGovernor);
        governor = proposedGovernor;
        proposedGovernor = address(0);
    }
}

// SPDX-License-Identifier: MIT

// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/Address.sol";

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
        return !Address.isContract(address(this));
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

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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

// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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

// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT

// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

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

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/@openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";
import "./IRewards.sol";

interface IESVSP is IERC20Metadata {
    function totalLocked() external view returns (uint256);

    function totalBoosted() external view returns (uint256);

    function locked(address _account) external view returns (uint256);

    function boosted(address _account) external view returns (uint256);

    function lock(uint256 amount_, uint256 lockPeriod_) external;

    function lockFor(
        address to_,
        uint256 amount_,
        uint256 lockPeriod_
    ) external;

    function updateExitPenalty(uint256 exitPenalty_) external;

    function unlock(uint256 tokenId_, bool unexpired_) external;

    function kick(uint256 tokenId_) external;

    function kickAllExpiredOf(address account_) external;

    function lockedBalanceOf(address account_) external view returns (uint256);

    function transferPosition(uint256 tokenId_, address to_) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
 * @notice Governable interface
 */
interface IGovernable {
    function governor() external view returns (address _governor);

    function transferGovernorship(address _proposedGovernor) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IRewards {
    function addRewardToken(
        address rewardsToken_,
        address distributor_,
        bool isBoosted_
    ) external;

    function claimRewards(address account_) external;

    function claimableRewards(address account_)
        external
        view
        returns (address[] memory rewardTokens_, uint256[] memory claimableAmounts_);

    function dripRewardAmount(address rewardToken_, uint256 rewardAmount_) external;

    function setRewardDistributorApproval(
        address rewardsToken_,
        address distributor_,
        bool approved_
    ) external;

    function updateReward(address account_) external;

    function lastTimeRewardApplicable(address _rewardToken) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../interface/IESVSP.sol";
import "../interface/IRewards.sol";

abstract contract RewardsStorageV1 is IRewards {
    struct Reward {
        bool isBoosted; // linear distribution if false
        uint256 periodFinish; // end of a drip period
        uint256 rewardPerSecond; // distribution per second (i.e. dripAmount/dripPeriod)
        uint256 lastUpdateTime; // stores last drip time
        uint256 rewardPerTokenStored; // reward per VSP
    }

    struct UserReward {
        uint128 rewardPerTokenPaid; // reward per VSP accumulator
        uint128 claimableRewardsStored; // pending to claim
    }

    /**
     * @notice Locker contract
     */
    IESVSP public esVSP;

    /**
     * @notice Array of reward tokens
     */
    address[] public rewardTokens;

    /**
     * @notice Rewards state per token
     * @dev RewardToken => Reward
     */
    mapping(address => Reward) public rewards;

    /**
     * @notice User's rewards state per token
     * @dev User => RewardToken => UserReward
     */
    mapping(address => mapping(address => UserReward)) public rewardOf;

    /**
     * @notice Reward distributors
     * RewardToken -> distributor -> is approved to drip
     */
    mapping(address => mapping(address => bool)) public isRewardDistributor;
}