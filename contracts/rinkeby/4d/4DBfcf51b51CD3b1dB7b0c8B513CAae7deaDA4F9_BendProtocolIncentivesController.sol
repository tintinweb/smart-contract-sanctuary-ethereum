// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;
pragma abicoder v2;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {DistributionTypes} from "./DistributionTypes.sol";

import {DistributionManager} from "./DistributionManager.sol";

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import {IScaledBalanceToken} from "./interfaces/IScaledBalanceToken.sol";
import {IIncentivesController} from "./interfaces/IIncentivesController.sol";

/**
 * @title BendProtocolIncentivesController
 * @notice Distributor contract for rewards to the Bend protocol
 * @author Bend
 **/
contract BendProtocolIncentivesController is
    IIncentivesController,
    DistributionManager
{
    using SafeMath for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IERC20Upgradeable public REWARD_TOKEN;
    address public REWARDS_VAULT;

    mapping(address => uint256) internal usersUnclaimedRewards;
    mapping(address => bool) public authorizedAssets;

    /**
     * @dev initial and configrate contract
     * @param _rewardToken The reward token to incentivize
     * @param _rewardsVault The vault of reward token
     * @param _distributionDuration  Duration of the reward distribution
     */
    function initialize(
        address _rewardToken,
        address _rewardsVault,
        uint128 _distributionDuration
    ) external initializer {
        __DistributionManager_init(_distributionDuration);
        REWARD_TOKEN = IERC20Upgradeable(_rewardToken);
        REWARDS_VAULT = _rewardsVault;
    }

    /**
     * @dev Configure assets for a certain rewards emission
     * @param _assets The assets to incentivize
     * @param _emissionsPerSecond The emission for each asset
     */
    function configureAssets(
        IScaledBalanceToken[] calldata _assets,
        uint256[] calldata _emissionsPerSecond
    ) external override  {
        require(
            _assets.length == _emissionsPerSecond.length,
            "INVALID_CONFIGURATION"
        );

        DistributionTypes.AssetConfigInput[]
            memory assetsConfig = new DistributionTypes.AssetConfigInput[](
                _assets.length
            );

        for (uint256 i = 0; i < _assets.length; i++) {
            authorizedAssets[address(_assets[i])] = true;
            assetsConfig[i].underlyingAsset = address(_assets[i]);
            assetsConfig[i].emissionPerSecond = uint128(_emissionsPerSecond[i]);

            require(
                assetsConfig[i].emissionPerSecond == _emissionsPerSecond[i],
                "INVALID_CONFIGURATION"
            );

            assetsConfig[i].totalStaked = _assets[i].scaledTotalSupply();
        }
        _configureAssets(assetsConfig);
    }

    /**
     * @dev Called by the corresponding asset on any update that affects the rewards distribution
     * @param _user The address of the user
     * @param _totalSupply The total supply of the asset in the lending pool
     * @param _userBalance The balance of the user of the asset in the lending pool
     **/
    function handleAction(
        address _user,
        uint256 _totalSupply,
        uint256 _userBalance
    ) external override {
        require(authorizedAssets[msg.sender], "Asset Unauthorized");
        uint256 accruedRewards = _updateUserAssetInternal(
            _user,
            msg.sender,
            _userBalance,
            _totalSupply
        );
        if (accruedRewards != 0) {
            usersUnclaimedRewards[_user] = usersUnclaimedRewards[_user].add(
                accruedRewards
            );
            emit RewardsAccrued(_user, accruedRewards);
        }
    }

    /**
     * @dev Returns the total of rewards of an user, already accrued + not yet accrued
     * @param _assets The assets to incentivize
     * @param _user The address of the user
     * @return The rewards
     **/
    function getRewardsBalance(
        IScaledBalanceToken[] calldata _assets,
        address _user
    ) external view override returns (uint256) {
        uint256 unclaimedRewards = usersUnclaimedRewards[_user];

        DistributionTypes.UserStakeInput[]
            memory userState = new DistributionTypes.UserStakeInput[](
                _assets.length
            );
        for (uint256 i = 0; i < _assets.length; i++) {
            userState[i].underlyingAsset = address(_assets[i]);
            (
                userState[i].stakedByUser,
                userState[i].totalStaked
            ) = IScaledBalanceToken(_assets[i]).getScaledUserBalanceAndSupply(
                _user
            );
        }
        unclaimedRewards = unclaimedRewards.add(
            _getUnclaimedRewards(_user, userState)
        );
        return unclaimedRewards;
    }

    /**

     * @dev returns the unclaimed rewards of the user
     * @param _user the address of the user
     * @return the unclaimed user rewards
     */
    function getUserUnclaimedRewards(address _user)
        external
        view
        override
        returns (uint256)
    {
        return usersUnclaimedRewards[_user];
    }

    /**
     * @dev Claims reward for an user, on all the assets of the lending pool, accumulating the pending rewards
     * @param _assets The assets to incentivize
     * @param _amount Amount of rewards to claim
     * @return Rewards claimed
     **/
    function claimRewards(
        IScaledBalanceToken[] calldata _assets,
        uint256 _amount
    ) external override returns (uint256) {
        if (_amount == 0) {
            return 0;
        }
        address user = msg.sender;
        uint256 unclaimedRewards = usersUnclaimedRewards[user];

        DistributionTypes.UserStakeInput[]
            memory userState = new DistributionTypes.UserStakeInput[](
                _assets.length
            );
        for (uint256 i = 0; i < _assets.length; i++) {
            require(
                authorizedAssets[address(_assets[i])],
                "Asset Unauthorized"
            );
            userState[i].underlyingAsset = address(_assets[i]);
            (
                userState[i].stakedByUser,
                userState[i].totalStaked
            ) = IScaledBalanceToken(_assets[i]).getScaledUserBalanceAndSupply(
                user
            );
        }

        uint256 accruedRewards = _claimRewards(user, userState);
        if (accruedRewards != 0) {
            unclaimedRewards = unclaimedRewards.add(accruedRewards);
            emit RewardsAccrued(user, accruedRewards);
        }

        if (unclaimedRewards == 0) {
            return 0;
        }

        uint256 amountToClaim = _amount > unclaimedRewards
            ? unclaimedRewards
            : _amount;
        usersUnclaimedRewards[user] = unclaimedRewards - amountToClaim; // Safe due to the previous line

        IERC20Upgradeable(REWARD_TOKEN).safeTransferFrom(
            REWARDS_VAULT,
            msg.sender,
            amountToClaim
        );

        emit RewardsClaimed(msg.sender, amountToClaim);

        return amountToClaim;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;
pragma abicoder v2;

import {IScaledBalanceToken} from "./IScaledBalanceToken.sol";

interface IIncentivesController {
    event RewardsAccrued(address indexed _user, uint256 _amount);

    event RewardsClaimed(address indexed _user, uint256 _amount);

    /**
     * @dev Configure assets for a certain rewards emission
     * @param _assets The assets to incentivize
     * @param _emissionsPerSecond The emission for each asset
     */
    function configureAssets(
        IScaledBalanceToken[] calldata _assets,
        uint256[] calldata _emissionsPerSecond
    ) external;

    /**
     * @dev Called by the corresponding asset on any update that affects the rewards distribution
     * @param _user The address of the user
     * @param _totalSupply The total supply of the asset in the lending pool
     * @param _userBalance The balance of the user of the asset in the lending pool
     **/
    function handleAction(
        address _user,
        uint256 _totalSupply,
        uint256 _userBalance
    ) external;

    /**
     * @dev Returns the total of rewards of an user, already accrued + not yet accrued
     * @param _assets The assets to incentivize
     * @param _user The address of the user
     * @return The rewards
     **/
    function getRewardsBalance(
        IScaledBalanceToken[] calldata _assets,
        address _user
    ) external view returns (uint256);

    /**
     * @dev Claims reward for an user, on all the assets of the lending pool, accumulating the pending rewards
     * @param _assets The assets to incentivize
     * @param _amount Amount of rewards to claim
     * @return Rewards claimed
     **/
    function claimRewards(
        IScaledBalanceToken[] calldata _assets,
        uint256 _amount
    ) external returns (uint256);

    /**
     * @dev returns the unclaimed rewards of the user
     * @param _user the address of the user
     * @return the unclaimed user rewards
     */
    function getUserUnclaimedRewards(address _user)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

interface IScaledBalanceToken {
    /**
     * @dev Returns the scaled balance of the user and the scaled total supply.
     * @param _user The address of the user
     * @return The scaled balance of the user
     * @return The scaled balance and the scaled total supply
     **/
    function getScaledUserBalanceAndSupply(address _user)
        external
        view
        returns (uint256, uint256);

    /**
     * @dev Returns the scaled total supply of the token. Represents sum(debt/index)
     * @return The scaled total supply
     **/
    function scaledTotalSupply() external view returns (uint256);
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;
pragma abicoder v2;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {DistributionTypes} from "./DistributionTypes.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// import "hardhat/console.sol";

/**
 * @title DistributionManager
 * @notice Accounting contract to manage multiple staking distributions
 * @author Bend
 **/
contract DistributionManager is Initializable, OwnableUpgradeable {
    using SafeMath for uint256;

    struct AssetData {
        uint128 emissionPerSecond;
        uint128 lastUpdateTimestamp;
        uint256 index;
        mapping(address => uint256) users;
    }

    uint256 public DISTRIBUTION_END;

    uint8 public constant PRECISION = 18;

    mapping(address => AssetData) public assets;

    event AssetConfigUpdated(
        address indexed _asset,
        uint256 _emissionPerSecond
    );
    event AssetIndexUpdated(address indexed _asset, uint256 _index);
    event DistributionEndUpdated(uint256 newDistributionEnd);

    event UserIndexUpdated(
        address indexed user,
        address indexed asset,
        uint256 index
    );

    function __DistributionManager_init(uint256 _distributionDuration)
        internal
        // initializer
    {
        __Ownable_init();
        DISTRIBUTION_END = block.timestamp.add(_distributionDuration);
    }

    function setDistributionEnd(uint256 _distributionEnd) external onlyOwner {
        DISTRIBUTION_END = _distributionEnd;
        emit DistributionEndUpdated(_distributionEnd);
    }

    function _configureAssets(
        DistributionTypes.AssetConfigInput[] memory _assetsConfigInput
    ) internal {
        for (uint256 i = 0; i < _assetsConfigInput.length; i++) {
            AssetData storage assetConfig = assets[
                _assetsConfigInput[i].underlyingAsset
            ];

            _updateAssetStateInternal(
                _assetsConfigInput[i].underlyingAsset,
                assetConfig,
                _assetsConfigInput[i].totalStaked
            );

            assetConfig.emissionPerSecond = _assetsConfigInput[i]
                .emissionPerSecond;

            emit AssetConfigUpdated(
                _assetsConfigInput[i].underlyingAsset,
                _assetsConfigInput[i].emissionPerSecond
            );
        }
    }

    /**
     * @dev Updates the state of one distribution, mainly rewards index and timestamp
     * @param _underlyingAsset The address used as key in the distribution, for example sBEND or the aTokens addresses on Bend
     * @param _assetConfig Storage pointer to the distribution's config
     * @param _totalStaked Current total of staked assets for this distribution
     * @return The new distribution index
     **/
    function _updateAssetStateInternal(
        address _underlyingAsset,
        AssetData storage _assetConfig,
        uint256 _totalStaked
    ) internal returns (uint256) {
        uint256 oldIndex = _assetConfig.index;
        uint128 lastUpdateTimestamp = _assetConfig.lastUpdateTimestamp;

        if (block.timestamp == lastUpdateTimestamp) {
            return oldIndex;
        }
        uint256 newIndex = _getAssetIndex(
            oldIndex,
            _assetConfig.emissionPerSecond,
            lastUpdateTimestamp,
            _totalStaked
        );

        if (newIndex != oldIndex) {
            _assetConfig.index = newIndex;
            emit AssetIndexUpdated(_underlyingAsset, newIndex);
        }

        _assetConfig.lastUpdateTimestamp = uint128(block.timestamp);

        return newIndex;
    }

    /**
     * @dev Updates the state of an user in a distribution
     * @param _user The user's address
     * @param _asset The address of the reference asset of the distribution
     * @param _stakedByUser Amount of tokens staked by the user in the distribution at the moment
     * @param _totalStaked Total tokens staked in the distribution
     * @return The accrued rewards for the user until the moment
     **/
    function _updateUserAssetInternal(
        address _user,
        address _asset,
        uint256 _stakedByUser,
        uint256 _totalStaked
    ) internal returns (uint256) {
        AssetData storage assetData = assets[_asset];
        uint256 userIndex = assetData.users[_user];
        uint256 accruedRewards = 0;

        uint256 newIndex = _updateAssetStateInternal(
            _asset,
            assetData,
            _totalStaked
        );
        if (userIndex != newIndex) {
            if (_stakedByUser != 0) {
                accruedRewards = _getRewards(
                    _stakedByUser,
                    newIndex,
                    userIndex
                );
            }

            assetData.users[_user] = newIndex;
            emit UserIndexUpdated(_user, _asset, newIndex);
        }
        return accruedRewards;
    }

    /**
     * @dev Used by "frontend" stake contracts to update the data of an user when claiming rewards from there
     * @param _user The address of the user
     * @param _stakes List of structs of the user data related with his stake
     * @return The accrued rewards for the user until the moment
     **/
    function _claimRewards(
        address _user,
        DistributionTypes.UserStakeInput[] memory _stakes
    ) internal returns (uint256) {
        uint256 accruedRewards = 0;

        for (uint256 i = 0; i < _stakes.length; i++) {
            accruedRewards = accruedRewards.add(
                _updateUserAssetInternal(
                    _user,
                    _stakes[i].underlyingAsset,
                    _stakes[i].stakedByUser,
                    _stakes[i].totalStaked
                )
            );
        }

        return accruedRewards;
    }

    /**
     * @dev Return the accrued rewards for an user over a list of distribution
     * @param _user The address of the user
     * @param _stakes List of structs of the user data related with his stake
     * @return The accrued rewards for the user until the moment
     **/
    function _getUnclaimedRewards(
        address _user,
        DistributionTypes.UserStakeInput[] memory _stakes
    ) internal view returns (uint256) {
        uint256 accruedRewards = 0;

        for (uint256 i = 0; i < _stakes.length; i++) {
            AssetData storage assetConfig = assets[_stakes[i].underlyingAsset];
            uint256 assetIndex = _getAssetIndex(
                assetConfig.index,
                assetConfig.emissionPerSecond,
                assetConfig.lastUpdateTimestamp,
                _stakes[i].totalStaked
            );

            accruedRewards = accruedRewards.add(
                _getRewards(
                    _stakes[i].stakedByUser,
                    assetIndex,
                    assetConfig.users[_user]
                )
            );
        }
        return accruedRewards;
    }

    /**
     * @dev Internal function for the calculation of user's rewards on a distribution
     * @param _principalUserBalance Amount staked by the user on a distribution
     * @param _reserveIndex Current index of the distribution
     * @param _userIndex Index stored for the user, representation his staking moment
     * @return The rewards
     **/
    function _getRewards(
        uint256 _principalUserBalance,
        uint256 _reserveIndex,
        uint256 _userIndex
    ) internal pure returns (uint256) {
        return
            _principalUserBalance.mul(_reserveIndex.sub(_userIndex)).div(
                10**uint256(PRECISION)
            );
    }

    /**
     * @dev Calculates the next value of an specific distribution index, with validations
     * @param _currentIndex Current index of the distribution
     * @param _emissionPerSecond Representing the total rewards distributed per second per asset unit, on the distribution
     * @param _lastUpdateTimestamp Last moment this distribution was updated
     * @param _totalBalance of tokens considered for the distribution
     * @return The new index.
     **/
    function _getAssetIndex(
        uint256 _currentIndex,
        uint256 _emissionPerSecond,
        uint128 _lastUpdateTimestamp,
        uint256 _totalBalance
    ) internal view returns (uint256) {
        if (
            _emissionPerSecond == 0 ||
            _totalBalance == 0 ||
            _lastUpdateTimestamp == block.timestamp ||
            _lastUpdateTimestamp >= DISTRIBUTION_END
        ) {
            return _currentIndex;
        }

        uint256 currentTimestamp = block.timestamp > DISTRIBUTION_END
            ? DISTRIBUTION_END
            : block.timestamp;
        uint256 timeDelta = currentTimestamp.sub(_lastUpdateTimestamp);
        return
            _emissionPerSecond
                .mul(timeDelta)
                .mul(10**uint256(PRECISION))
                .div(_totalBalance)
                .add(_currentIndex);
    }

    /**
     * @dev Returns the data of an user on a distribution
     * @param _user Address of the user
     * @param _asset The address of the reference asset of the distribution
     * @return The new index
     **/
    function getUserAssetData(address _user, address _asset)
        public
        view
        returns (uint256)
    {
        return assets[_asset].users[_user];
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;
pragma abicoder v2;

library DistributionTypes {
    struct AssetConfigInput {
        uint128 emissionPerSecond;
        uint256 totalStaked;
        address underlyingAsset;
    }

    struct UserStakeInput {
        address underlyingAsset;
        uint256 stakedByUser;
        uint256 totalStaked;
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

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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