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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.13;

import {DistributionTypes} from "../../lib/DistributionTypes.sol";
import {DistributionManager} from "./DistributionManager.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAaveIncentivesController} from "../../interfaces/IAaveIncentivesController.sol";

/**
 * @title BaseIncentivesController
 * @notice Abstract contract template to build Distributors contracts for ERC20 rewards to protocol participants
 * @author Aave
  */
abstract contract BaseIncentivesController is IAaveIncentivesController, DistributionManager {
    uint256 public constant REVISION = 1;

    address public immutable override REWARD_TOKEN; // solhint-disable-line var-name-mixedcase

    mapping(address => uint256) internal _usersUnclaimedRewards;

    // this mapping allows whitelisted addresses to claim on behalf of others
    // useful for contracts that hold tokens to be rewarded but don't have any native logic to claim Liquidity Mining
    // rewards
    mapping(address => address) internal _authorizedClaimers;

    modifier onlyAuthorizedClaimers(address claimer, address user) {
        if (_authorizedClaimers[user] != claimer) revert ClaimerUnauthorized();

        _;
    }

    error InvalidConfiguration();
    error IndexOverflowAtEmissionsPerSecond();
    error InvalidToAddress();
    error InvalidUserAddress();
    error ClaimerUnauthorized();

    constructor(IERC20 rewardToken, address emissionManager) DistributionManager(emissionManager) {
        REWARD_TOKEN = address(rewardToken);
    }

    /// @inheritdoc IAaveIncentivesController
    function configureAssets(address[] calldata assets, uint256[] calldata emissionsPerSecond)
        external
        override
        onlyEmissionManager
    {
        if (assets.length != emissionsPerSecond.length) revert InvalidConfiguration();

        DistributionTypes.AssetConfigInput[] memory assetsConfig =
            new DistributionTypes.AssetConfigInput[](assets.length);

        for (uint256 i = 0; i < assets.length;) {
            if (uint104(emissionsPerSecond[i]) != emissionsPerSecond[i]) revert IndexOverflowAtEmissionsPerSecond();

            assetsConfig[i].underlyingAsset = assets[i];
            assetsConfig[i].emissionPerSecond = uint104(emissionsPerSecond[i]);
            assetsConfig[i].totalStaked = IERC20(assets[i]).totalSupply();

            unchecked { i++; }
        }

        _configureAssets(assetsConfig);
    }

    /// @inheritdoc IAaveIncentivesController
    function handleAction(
        address user,
        uint256 totalSupply,
        uint256 userBalance
    ) public override {
        uint256 accruedRewards = _updateUserAssetInternal(user, msg.sender, userBalance, totalSupply);

        if (accruedRewards != 0) {
            _usersUnclaimedRewards[user] = _usersUnclaimedRewards[user] + accruedRewards;
            emit RewardsAccrued(user, accruedRewards);
        }
    }

    /// @inheritdoc IAaveIncentivesController
    function getRewardsBalance(address[] calldata assets, address user)
        external
        view
        override
        returns (uint256)
    {
        uint256 unclaimedRewards = _usersUnclaimedRewards[user];

        DistributionTypes.UserStakeInput[] memory userState = new DistributionTypes.UserStakeInput[](assets.length);

        for (uint256 i = 0; i < assets.length;) {
            userState[i].underlyingAsset = assets[i];
            (userState[i].stakedByUser, userState[i].totalStaked) = _getScaledUserBalanceAndSupply(assets[i], user);

            unchecked { i++; }
        }

        unclaimedRewards = unclaimedRewards + _getUnclaimedRewards(user, userState);
        return unclaimedRewards;
    }

    /// @inheritdoc IAaveIncentivesController
    function claimRewards(
        address[] calldata assets,
        uint256 amount,
        address to
    ) external override returns (uint256) {
        if (to == address(0)) revert InvalidToAddress();

        return _claimRewards(assets, amount, msg.sender, msg.sender, to);
    }

    /// @inheritdoc IAaveIncentivesController
    function claimRewardsOnBehalf(
        address[] calldata assets,
        uint256 amount,
        address user,
        address to
    ) external override onlyAuthorizedClaimers(msg.sender, user) returns (uint256) {
        if (user == address(0)) revert InvalidUserAddress();
        if (to == address(0)) revert InvalidToAddress();

        return _claimRewards(assets, amount, msg.sender, user, to);
    }

    /// @inheritdoc IAaveIncentivesController
    function claimRewardsToSelf(address[] calldata assets, uint256 amount)
        external
        override
        returns (uint256)
    {
        return _claimRewards(assets, amount, msg.sender, msg.sender, msg.sender);
    }

    /// @inheritdoc IAaveIncentivesController
    function setClaimer(address user, address caller) external override onlyEmissionManager {
        _authorizedClaimers[user] = caller;
        emit ClaimerSet(user, caller);
    }

    /// @inheritdoc IAaveIncentivesController
    function getClaimer(address user) external view override returns (address) {
        return _authorizedClaimers[user];
    }

    /// @inheritdoc IAaveIncentivesController
    function getUserUnclaimedRewards(address _user) external view override returns (uint256) {
        return _usersUnclaimedRewards[_user];
    }

    /**
     * @dev Claims reward for an user on behalf, on all the assets of the lending pool, accumulating the pending rewards
     * @param amount Amount of rewards to claim
     * @param user Address to check and claim rewards
     * @param to Address that will be receiving the rewards
     * @return Rewards claimed
     */
    function _claimRewards(
        address[] calldata assets,
        uint256 amount,
        address claimer,
        address user,
        address to
    ) internal returns (uint256) {
        if (amount == 0) {
            return 0;
        }

        uint256 unclaimedRewards = _usersUnclaimedRewards[user];

        if (amount > unclaimedRewards) {
            DistributionTypes.UserStakeInput[] memory userState = new DistributionTypes.UserStakeInput[](assets.length);

            for (uint256 i = 0; i < assets.length;) {
                userState[i].underlyingAsset = assets[i];
                (userState[i].stakedByUser, userState[i].totalStaked) = _getScaledUserBalanceAndSupply(assets[i], user);

                unchecked { i++; }
            }

            uint256 accruedRewards = _claimRewards(user, userState);

            if (accruedRewards != 0) {
                unclaimedRewards = unclaimedRewards + accruedRewards;
                emit RewardsAccrued(user, accruedRewards);
            }
        }

        if (unclaimedRewards == 0) {
            return 0;
        }

        uint256 amountToClaim = amount > unclaimedRewards ? unclaimedRewards : amount;
        unchecked { _usersUnclaimedRewards[user] = unclaimedRewards - amountToClaim; } // Safe due to the previous line

        _transferRewards(to, amountToClaim);
        emit RewardsClaimed(user, to, claimer, amountToClaim);

        return amountToClaim;
    }

    /**
     * @dev Abstract function to transfer rewards to the desired account
     * @param to Account address to send the rewards
     * @param amount Amount of rewards to transfer
     */
    function _transferRewards(address to, uint256 amount) internal virtual;

    function _getScaledUserBalanceAndSupply(address _asset, address _user)
        internal
        view
        virtual
        returns (uint256 userBalance, uint256 totalSupply);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.13;

import {IAaveDistributionManager} from "../../interfaces/IAaveDistributionManager.sol";
import {DistributionTypes} from "../../lib/DistributionTypes.sol";

/**
 * @title DistributionManager
 * @notice Accounting contract to manage multiple staking distributions
 * @author Aave
 */
contract DistributionManager is IAaveDistributionManager {
    struct AssetData {
        uint104 emissionPerSecond;
        uint104 index;
        uint40 lastUpdateTimestamp;
        mapping(address => uint256) users;
    }

    address public immutable EMISSION_MANAGER; // solhint-disable-line var-name-mixedcase

    uint8 public constant PRECISION = 18;
    uint256 public constant TEN_POW_PRECISION = 10 ** PRECISION;

    mapping(address => AssetData) public assets;

    uint256 internal _distributionEnd;

    error OnlyEmissionManager();
    error IndexOverflow();

    modifier onlyEmissionManager() {
        if (msg.sender != EMISSION_MANAGER) revert OnlyEmissionManager();

        _;
    }

    constructor(address emissionManager) {
        EMISSION_MANAGER = emissionManager;
    }

    /// @inheritdoc IAaveDistributionManager
    function setDistributionEnd(uint256 distributionEnd) external override onlyEmissionManager {
        _distributionEnd = distributionEnd;
        emit DistributionEndUpdated(distributionEnd);
    }

    /// @inheritdoc IAaveDistributionManager
    function getDistributionEnd() external view override returns (uint256) {
        return _distributionEnd;
    }

    /// @inheritdoc IAaveDistributionManager
    function DISTRIBUTION_END() external view override returns (uint256) { // solhint-disable-line func-name-mixedcase
        return _distributionEnd;
    }

    /// @inheritdoc IAaveDistributionManager
    function getUserAssetData(address user, address asset) public view override returns (uint256) {
        return assets[asset].users[user];
    }

    /// @inheritdoc IAaveDistributionManager
    function getAssetData(address asset) public view override returns (uint256, uint256, uint256) {
        return (assets[asset].index, assets[asset].emissionPerSecond, assets[asset].lastUpdateTimestamp);
    }

    /**
     * @dev Configure the assets for a specific emission
     * @param assetsConfigInput The array of each asset configuration
     */
    function _configureAssets(DistributionTypes.AssetConfigInput[] memory assetsConfigInput) internal {
        for (uint256 i = 0; i < assetsConfigInput.length;) {
            AssetData storage assetConfig = assets[assetsConfigInput[i].underlyingAsset];

            _updateAssetStateInternal(
                assetsConfigInput[i].underlyingAsset,
                assetConfig,
                assetsConfigInput[i].totalStaked
            );

            assetConfig.emissionPerSecond = assetsConfigInput[i].emissionPerSecond;

            emit AssetConfigUpdated(
                assetsConfigInput[i].underlyingAsset,
                assetsConfigInput[i].emissionPerSecond
            );

            unchecked { i++; }
        }
    }

    /**
     * @dev Updates the state of one distribution, mainly rewards index and timestamp
     * @param asset The address of the asset being updated
     * @param assetConfig Storage pointer to the distribution's config
     * @param totalStaked Current total of staked assets for this distribution
     * @return The new distribution index
     */
    function _updateAssetStateInternal(
        address asset,
        AssetData storage assetConfig,
        uint256 totalStaked
    ) internal returns (uint256) {
        uint256 oldIndex = assetConfig.index;
        uint256 emissionPerSecond = assetConfig.emissionPerSecond;
        uint128 lastUpdateTimestamp = assetConfig.lastUpdateTimestamp;

        if (block.timestamp == lastUpdateTimestamp) {
            return oldIndex;
        }

        uint256 newIndex = _getAssetIndex(oldIndex, emissionPerSecond, lastUpdateTimestamp, totalStaked);

        if (newIndex != oldIndex) {
            if (uint104(newIndex) != newIndex) revert IndexOverflow();

            //optimization: storing one after another saves one SSTORE
            assetConfig.index = uint104(newIndex);
            assetConfig.lastUpdateTimestamp = uint40(block.timestamp);
            emit AssetIndexUpdated(asset, newIndex);
        } else {
            assetConfig.lastUpdateTimestamp = uint40(block.timestamp);
        }

        return newIndex;
    }

    /**
     * @dev Updates the state of an user in a distribution
     * @param user The user's address
     * @param asset The address of the reference asset of the distribution
     * @param stakedByUser Amount of tokens staked by the user in the distribution at the moment
     * @param totalStaked Total tokens staked in the distribution
     * @return The accrued rewards for the user until the moment
     */
    function _updateUserAssetInternal(
        address user,
        address asset,
        uint256 stakedByUser,
        uint256 totalStaked
    ) internal returns (uint256) {
        AssetData storage assetData = assets[asset];
        uint256 userIndex = assetData.users[user];
        uint256 accruedRewards = 0;

        uint256 newIndex = _updateAssetStateInternal(asset, assetData, totalStaked);

        if (userIndex != newIndex) {
            if (stakedByUser != 0) {
                accruedRewards = _getRewards(stakedByUser, newIndex, userIndex);
            }

            assetData.users[user] = newIndex;
            emit UserIndexUpdated(user, asset, newIndex);
        }

        return accruedRewards;
    }

    /**
     * @dev Used by "frontend" stake contracts to update the data of an user when claiming rewards from there
     * @param user The address of the user
     * @param stakes List of structs of the user data related with his stake
     * @return The accrued rewards for the user until the moment
     */
    function _claimRewards(address user, DistributionTypes.UserStakeInput[] memory stakes)
        internal
        returns (uint256)
    {
        uint256 accruedRewards = 0;

        for (uint256 i = 0; i < stakes.length;) {
            accruedRewards = accruedRewards + _updateUserAssetInternal(
                    user,
                    stakes[i].underlyingAsset,
                    stakes[i].stakedByUser,
                    stakes[i].totalStaked
                );

            unchecked { i++; }
        }

        return accruedRewards;
    }

    /**
     * @dev Return the accrued rewards for an user over a list of distribution
     * @param user The address of the user
     * @param stakes List of structs of the user data related with his stake
     * @return The accrued rewards for the user until the moment
     */
    function _getUnclaimedRewards(address user, DistributionTypes.UserStakeInput[] memory stakes)
        internal
        view
        returns (uint256)
    {
        uint256 accruedRewards = 0;

        for (uint256 i = 0; i < stakes.length;) {
            AssetData storage assetConfig = assets[stakes[i].underlyingAsset];

            uint256 assetIndex = _getAssetIndex(
                assetConfig.index,
                assetConfig.emissionPerSecond,
                assetConfig.lastUpdateTimestamp,
                stakes[i].totalStaked
            );

            accruedRewards = accruedRewards + _getRewards(stakes[i].stakedByUser, assetIndex, assetConfig.users[user]);

            unchecked { i++; }
        }

        return accruedRewards;
    }

    /**
     * @dev Internal function for the calculation of user's rewards on a distribution
     * @param principalUserBalance Amount staked by the user on a distribution
     * @param reserveIndex Current index of the distribution
     * @param userIndex Index stored for the user, representation his staking moment
     * @return rewards The rewards
     */
    function _getRewards(
        uint256 principalUserBalance,
        uint256 reserveIndex,
        uint256 userIndex
    ) internal pure returns (uint256 rewards) {
        rewards = principalUserBalance * (reserveIndex - userIndex);
        unchecked { rewards /= TEN_POW_PRECISION; }
    }

    /**
     * @dev Calculates the next value of an specific distribution index, with validations
     * @param currentIndex Current index of the distribution
     * @param emissionPerSecond Representing the total rewards distributed per second per asset unit,
     * on the distribution
     * @param lastUpdateTimestamp Last moment this distribution was updated
     * @param totalBalance of tokens considered for the distribution
     * @return newIndex The new index.
     */
    function _getAssetIndex(
        uint256 currentIndex,
        uint256 emissionPerSecond,
        uint128 lastUpdateTimestamp,
        uint256 totalBalance
    ) internal view returns (uint256 newIndex) {
        uint256 distributionEnd = _distributionEnd;

        if (
            emissionPerSecond == 0 ||
            totalBalance == 0 ||
            lastUpdateTimestamp == block.timestamp ||
            lastUpdateTimestamp >= distributionEnd
        ) {
            return currentIndex;
        }

        uint256 currentTimestamp = block.timestamp > distributionEnd ? distributionEnd : block.timestamp;
        uint256 timeDelta = currentTimestamp - lastUpdateTimestamp;

        newIndex = emissionPerSecond * timeDelta * TEN_POW_PRECISION;
        unchecked { newIndex /= totalBalance; }
        newIndex += currentIndex;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.13;

import {DistributionTypes} from "../lib/DistributionTypes.sol";

interface IAaveDistributionManager {
  
    event AssetConfigUpdated(address indexed asset, uint256 emission);
    event AssetIndexUpdated(address indexed asset, uint256 index);
    event UserIndexUpdated(address indexed user, address indexed asset, uint256 index);
    event DistributionEndUpdated(uint256 newDistributionEnd);

    /**
     * @dev Sets the end date for the distribution
     * @param distributionEnd The end date timestamp
     */
    function setDistributionEnd(uint256 distributionEnd) external;

    /**
     * @dev Gets the end date for the distribution
     * @return The end of the distribution
     */
    function getDistributionEnd() external view returns (uint256);

    /**
     * @dev for backwards compatibility with the previous DistributionManager used
     * @return The end of the distribution
     */
    function DISTRIBUTION_END() external view returns(uint256); // solhint-disable-line func-name-mixedcase

    /**
     * @dev Returns the data of an user on a distribution
     * @param user Address of the user
     * @param asset The address of the reference asset of the distribution
     * @return The new index
     */
    function getUserAssetData(address user, address asset) external view returns (uint256);

    /**
     * @dev Returns the configuration of the distribution for a certain asset
     * @param asset The address of the reference asset of the distribution
     * @return The asset index, the emission per second and the last updated timestamp
     */
    function getAssetData(address asset) external view returns (uint256, uint256, uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.13;

import {IAaveDistributionManager} from "../interfaces/IAaveDistributionManager.sol";

interface IAaveIncentivesController is IAaveDistributionManager {
    event RewardsAccrued(address indexed user, uint256 amount);

    event RewardsClaimed(
        address indexed user,
        address indexed to,
        address indexed claimer,
        uint256 amount
    );

    event ClaimerSet(address indexed user, address indexed claimer);

    /**
     * @dev Whitelists an address to claim the rewards on behalf of another address
     * @param user The address of the user
     * @param claimer The address of the claimer
     */
    function setClaimer(address user, address claimer) external;

    /**
     * @dev Configure assets for a certain rewards emission
     * @param assets The assets to incentivize
     * @param emissionsPerSecond The emission for each asset
     */
    function configureAssets(address[] calldata assets, uint256[] calldata emissionsPerSecond) external;

    /**
     * @dev Called by the corresponding asset on any update that affects the rewards distribution
     * @param asset The address of the user
     * @param userBalance The balance of the user of the asset in the lending pool
     * @param totalSupply The total supply of the asset in the lending pool
     */
    function handleAction(
        address asset,
        uint256 userBalance,
        uint256 totalSupply
    ) external;

    /**
     * @dev Claims reward for an user to the desired address, on all the assets of the lending pool,
     * accumulating the pending rewards
     * @param amount Amount of rewards to claim
     * @param to Address that will be receiving the rewards
     * @return Rewards claimed
     */
    function claimRewards(
        address[] calldata assets,
        uint256 amount,
        address to
    ) external returns (uint256);

    /**
     * @dev Claims reward for an user on behalf, on all the assets of the lending pool, accumulating the pending
     * rewards. The caller must be whitelisted via "allowClaimOnBehalf" function by the RewardsAdmin role manager
     * @param amount Amount of rewards to claim
     * @param user Address to check and claim rewards
     * @param to Address that will be receiving the rewards
     * @return Rewards claimed
     */
    function claimRewardsOnBehalf(
        address[] calldata assets,
        uint256 amount,
        address user,
        address to
    ) external returns (uint256);

    /**
     * @dev Claims reward for msg.sender, on all the assets of the lending pool, accumulating the pending rewards
     * @param amount Amount of rewards to claim
     * @return Rewards claimed
     */
    function claimRewardsToSelf(address[] calldata assets, uint256 amount) external returns (uint256);

    /**
     * @dev Returns the whitelisted claimer for a certain address (0x0 if not set)
     * @param user The address of the user
     * @return The claimer address
     */
    function getClaimer(address user) external view returns (address);

    /**
     * @dev Returns the total of rewards of an user, already accrued + not yet accrued
     * @param user The address of the user
     * @return The rewards
     */
    function getRewardsBalance(address[] calldata assets, address user) external view returns (uint256);

    /**
     * @dev returns the unclaimed rewards of the user
     * @param user the address of the user
     * @return the unclaimed user rewards
     */
    function getUserUnclaimedRewards(address user) external view returns (uint256);

    /**
     * @dev for backward compatibility with previous implementation of the Incentives controller
     */
    function REWARD_TOKEN() external view returns (address); // solhint-disable-line func-name-mixedcase
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.13;

library DistributionTypes {
    struct AssetConfigInput {
        uint104 emissionPerSecond;
        uint256 totalStaked;
        address underlyingAsset;
    }

    struct UserStakeInput {
        address underlyingAsset;
        uint256 stakedByUser;
        uint256 totalStaked;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {BaseIncentivesController} from "../external/aave/incentives/base/BaseIncentivesController.sol";
import "../interfaces/INotificationReceiver.sol";


/**
 * @title SiloIncentivesController
 * @notice Distributor contract for rewards to the Aave protocol, using a staked token as rewards asset.
 * The contract stakes the rewards before redistributing them to the Aave protocol participants.
 * The reference staked token implementation is at https://github.com/aave/aave-stake-v2
 * @author Aave
 */
contract SiloIncentivesController is BaseIncentivesController, INotificationReceiver {
    using SafeERC20 for IERC20;

    constructor(IERC20 rewardToken, address emissionManager) BaseIncentivesController(rewardToken, emissionManager) {}

    /**
     * @dev Silo share token event handler
     */
    function onAfterTransfer(address /* _token */, address _from, address _to, uint256 _amount) external {
        if (assets[msg.sender].lastUpdateTimestamp == 0) {
            // optimisation check, if we never configured rewards distribution, then no need for updating any data
            return;
        }

        uint256 totalSupplyBefore = IERC20(msg.sender).totalSupply();

        if (_from == address(0x0)) {
            // we minting tokens, so supply before was less
            // we safe, because this amount came from token, if token handle them we can handle as well
            unchecked { totalSupplyBefore -= _amount; }
        } else if (_to == address(0x0)) {
            // we burning, so supply before was more
            // we safe, because this amount came from token, if token handle them we can handle as well
            unchecked { totalSupplyBefore += _amount; }
        }

        // here user either transferring token to someone else or burning tokens
        // user state will be new, because this event is `onAfterTransfer`
        // we need to recreate status before event in order to automatically calculate rewards
        if (_from != address(0x0)) {
            uint256 balanceBefore;
            // we safe, because this amount came from token, if token handle them we can handle as well
            unchecked { balanceBefore = IERC20(msg.sender).balanceOf(_from) + _amount; }
            handleAction(_from, totalSupplyBefore, balanceBefore);
        }

        // we have to checkout also user `_to`
        if (_to != address(0x0)) {
            uint256 balanceBefore;
            // we safe, because this amount came from token, if token handle them we can handle as well
            unchecked { balanceBefore = IERC20(msg.sender).balanceOf(_to) - _amount; }
            handleAction(_to, totalSupplyBefore, balanceBefore);
        }
    }

    /// @dev it will transfer all balance of reward token to emission manager wallet
    function rescueRewards() external onlyEmissionManager {
        IERC20(REWARD_TOKEN).safeTransfer(msg.sender, IERC20(REWARD_TOKEN).balanceOf(address(this)));
    }

    function notificationReceiverPing() external pure returns (bytes4) {
        return this.notificationReceiverPing.selector;
    }

    function _transferRewards(address to, uint256 amount) internal override {
        IERC20(REWARD_TOKEN).safeTransfer(to, amount);
    }

    /**
     * @dev in Silo, there is no scale, we simply using balance and total supply. Original method name is used here
     * to keep as much of original code.
     */
    function _getScaledUserBalanceAndSupply(address _asset, address _user)
        internal
        virtual
        view
        override
        returns (uint256 userBalance, uint256 totalSupply)
    {
        userBalance = IERC20(_asset).balanceOf(_user);
        totalSupply = IERC20(_asset).totalSupply();
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

/// @title Common interface for Silo Incentive Contract
interface INotificationReceiver {
    /// @dev Informs the contract about token transfer
    /// @param _token address of the token that was transferred
    /// @param _from sender
    /// @param _to receiver
    /// @param _amount amount that was transferred
    function onAfterTransfer(address _token, address _from, address _to, uint256 _amount) external;

    /// @dev Sanity check function
    /// @return always true
    function notificationReceiverPing() external pure returns (bytes4);
}