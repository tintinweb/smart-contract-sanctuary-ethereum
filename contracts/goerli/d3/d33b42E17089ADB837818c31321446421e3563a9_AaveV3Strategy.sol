// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

import "../abstracts/OpsReady.sol";
import "../interfaces/IController.sol";
import "../interfaces/IOwnership.sol";
import "../interfaces/IVault.sol";
import "../interfaces/IAaveV3Pool.sol";
import "../interfaces/IAaveV3Reward.sol";
import "../interfaces/IExchangeLogic.sol";
import "../errors/CommonError.sol";

/**
 * @title AaveV3Strategy
 * @author @InsureDAO
 * @notice This contract pulls a vault fund then utilize for various strategies.
 * @dev This strategy also has Controller functionality because currently the controller
 *      has 1 strategy and the strategy is not complicated. In the future, Strategy methods
 *      will be generalized as interface and separated from Controller.
 */
contract AaveV3Strategy is IController, OpsReady {
    using SafeERC20 for IERC20;

    IOwnership public immutable ownership;
    IVault public immutable vault;
    IAaveV3Pool public immutable aave;
    IAaveV3Reward public immutable aaveReward;
    IExchangeLogic public exchangeLogic;

    /// @inheritdoc IController
    uint256 public maxManagingRatio;

    /// @notice We use usdc as vault asset
    IERC20 public immutable usdc;

    /// @dev Supplying USDC to Aave pool, aUSDC is minted as your position.
    IERC20 public immutable ausdc;

    /// @dev Current supplying assets array used to claim reward. This should be a*** token.
    address[] public supplyingAssets;

    /// @dev This variable is significant to avoid locking asset in Aave pool.
    uint256 public aaveMaxOccupancyRatio;

    /// @dev What minimum reward a compound should be triggered by check() function.
    uint256 public minOpsTrigger;

    /// @dev internal multiplication scale 1e6 to reduce decimal truncation
    uint256 private constant MAGIC_SCALE_1E6 = 1e6; //

    modifier onlyOwner() {
        if (ownership.owner() != msg.sender) revert OnlyOwner();
        _;
    }

    modifier onlyVault() {
        if (msg.sender != address(vault)) revert OnlyVault();
        _;
    }

    modifier withinValidRatio(uint256 _ratio) {
        if (_ratio > MAGIC_SCALE_1E6) revert RatioOutOfRange();
        _;
    }

    event FundPulled(address indexed _vault, uint256 _amount);
    event FundReturned(address indexed _vault, uint256 _amount);
    event FundEmigrated(address indexed _to, uint256 _amount);
    event FundImmigrated(address indexed _from, uint256 _amount);
    event EmergencyExit(address indexed _destination, uint256 _withdrawnAmount);
    event SupplyIncreased(address indexed _token, uint256 _amount);
    event SupplyDecreased(address indexed _token, uint256 _amount);
    event MaxManagingRatioSet(uint256 _ratio);
    event MaxOccupancyRatioSet(uint256 _ratio);
    event ExchangeLogicSet(address _logic);
    event RewardTokenSet(address _token);
    event RewardClaimed(address _token, uint256 _amount);
    event SwapSucceeded(address indexed _tokenIn, address indexed _tokenOut, uint256 _amountIn, uint256 _amountOut);

    constructor(
        IOwnership _ownership,
        IVault _vault,
        IExchangeLogic _exchangeLogic,
        IAaveV3Pool _aave,
        IAaveV3Reward _aaveReward,
        IERC20 _usdc,
        IERC20 _ausdc,
        address _ops
    ) {
        ownership = _ownership;
        vault = _vault;
        exchangeLogic = _exchangeLogic;
        aave = _aave;
        aaveReward = _aaveReward;
        usdc = _usdc;
        ausdc = _ausdc;
        ops = _ops;
        supplyingAssets.push(address(_ausdc));

        maxManagingRatio = MAGIC_SCALE_1E6;
        aaveMaxOccupancyRatio = (MAGIC_SCALE_1E6 * 10) / 100;
        minOpsTrigger = 100e6;
    }

    /**
     * Controller methods
     */

    /// @inheritdoc IController
    function managingFund() public view returns (uint256) {
        return ausdc.balanceOf(address(this));
    }

    /// @inheritdoc IController
    function adjustFund() external {
        uint256 expectUtilizeAmount = (totalValueAll() * maxManagingRatio) / MAGIC_SCALE_1E6;
        if (expectUtilizeAmount > managingFund()) {
            unchecked {
                uint256 _shortage = expectUtilizeAmount - managingFund();
                _pullFund(_shortage);
            }
        }
    }

    /// @inheritdoc IController
    function returnFund(uint256 _amount) external onlyVault {
        _unutilize(_amount);
        usdc.safeTransfer(address(vault), _amount);

        emit FundReturned(address(vault), _amount);
    }

    /// @inheritdoc IController
    function setMaxManagingRatio(uint256 _ratio) external onlyOwner withinValidRatio(_ratio) {
        maxManagingRatio = _ratio;
        emit MaxManagingRatioSet(_ratio);
    }

    /// @inheritdoc IController
    function emigrate(address _to) external onlyVault {
        if (_to == address(0)) revert ZeroAddress();

        // liquidate all positions
        _withdrawAllReward();
        uint256 _underlying = managingFund();
        if (_underlying != 0) {
            aave.withdraw(address(usdc), _underlying, address(this));
        }

        // approve to pull all balance
        usdc.safeApprove(_to, type(uint256).max);

        uint256 _migrateAmount = usdc.balanceOf(address(this));

        IController(_to).immigrate(address(this));

        emit FundEmigrated(_to, _migrateAmount);
    }

    /// @inheritdoc IController
    function immigrate(address _from) external {
        if (_from == address(0)) revert ZeroAddress();
        if (_from == address(this)) revert MigrateToSelf();
        if (managingFund() != 0) revert AlreadyInUse();

        uint256 _amount = usdc.balanceOf(_from);

        usdc.safeTransferFrom(_from, address(this), _amount);

        emit FundImmigrated(_from, _amount);

        _utilize(_amount);
    }

    /// @inheritdoc IController
    function emergencyExit(address _to) external onlyOwner {
        if (_to == address(0)) revert ZeroAddress();

        uint256 _transferAmount = managingFund();
        IERC20(ausdc).safeTransfer(_to, _transferAmount);

        emit EmergencyExit(_to, _transferAmount);
    }

    /// @inheritdoc IController
    function currentManagingRatio() public view returns (uint256) {
        return _calcManagingRatio(managingFund());
    }

    /// @dev Internal function to pull fund from a vault. This is called only in adjustFund().
    function _pullFund(uint256 _amount) internal {
        if (_calcManagingRatio(managingFund() + _amount) > maxManagingRatio) revert ExceedManagingRatio();

        // receive usdc from the vault
        vault.utilize(_amount);
        emit FundPulled(address(vault), _amount);

        // directly utilize all amount
        _utilize(_amount);
    }

    /// @notice Returns sum of vault available asset and controller managing fund.
    function totalValueAll() public view returns (uint256) {
        return vault.available() + managingFund();
    }

    /// @dev Calculate what percentage of a vault fund to be utilized from amount given.
    function _calcManagingRatio(uint256 _amount) internal view returns (uint256 _managingRatio) {
        unchecked {
            _managingRatio = (_amount * MAGIC_SCALE_1E6) / totalValueAll();
        }
    }

    /**
     * Strategy methods
     */

    /**
     * @notice Claims all reward token, then compounds it automatically.
     * @param _token token address to be swapped
     * @param _amount what amount of the token to be swapped
     * @param _minAmountOut minimum amount of USDC caller expects to receive.
     *                      This prevent MEV attacks.
     */
    function compound(
        address _token,
        uint256 _amount,
        uint256 _minAmountOut
    ) external onlyOps {
        if (_token == address(0)) revert ZeroAddress();
        if (_amount == 0) revert AmountZero();
        if (_minAmountOut == 0) revert AmountZero();
        uint256 _reward = aaveReward.claimRewards(supplyingAssets, _amount, address(this), _token);
        IERC20(_token).safeIncreaseAllowance(exchangeLogic.swapper(), _reward);
        uint256 _swapped = _swap(_token, address(usdc), _reward, _minAmountOut);
        _utilize(_swapped);
    }

    /**
     * @inheritdoc OpsReady
     * @notice Check the rewards can be compounded. If the contract has sufficient reward,
     *         returns compound() function payload to execute.
     */
    function check() external override returns (bool _canExec, bytes memory _execPayload) {
        // default payload is the error message
        _execPayload = bytes("No enough reward to withdraw");
        // all token addresse and reward amount list
        (address[] memory _tokens, uint256[] memory _rewards) = getUnclaimedRewards();

        // check if any reward is eligible for compound
        uint256 _rewardsLength = _tokens.length;
        for (uint256 i = 0; i < _rewardsLength; ) {
            address _token = _tokens[i];
            uint256 _reward = _rewards[i];
            uint256 _estimatedOutUsdc = _reward != 0
                ? exchangeLogic.estimateAmountOut(_token, address(usdc), _reward)
                : 0;
            uint256 _minAmountOut = (_estimatedOutUsdc * exchangeLogic.slippageTolerance()) / MAGIC_SCALE_1E6;
            _canExec = _minAmountOut >= minOpsTrigger;
            // unclaimed reward is larger than trigger, compound will be executed
            if (_canExec) {
                _execPayload = abi.encodeWithSelector(this.compound.selector, _token, _reward, _minAmountOut);
                break;
            }

            unchecked {
                ++i;
            }
        }
    }

    function setOps(address _ops) external onlyOwner {
        if (_ops == address(0)) revert ZeroAddress();
        ops = _ops;
    }

    function setMinOpsTrigger(uint256 _min) external onlyOwner {
        if (_min == 0) revert AmountZero();
        minOpsTrigger = _min;
    }

    /**
     * @notice Sets aaveMaxOccupancyRatio
     * @param _ratio The portion of the aave total supply
     */
    function setAaveMaxOccupancyRatio(uint256 _ratio) external onlyOwner withinValidRatio(_ratio) {
        aaveMaxOccupancyRatio = _ratio;
        emit MaxOccupancyRatioSet(_ratio);
    }

    /**
     * @notice Sets exchangeLogic contract for the strategy
     * @param _exchangeLogic ExchangeLogic contract
     */
    function setExchangeLogic(IExchangeLogic _exchangeLogic) public onlyOwner {
        _setExchangeLogic(_exchangeLogic);
    }

    /**
     * @notice Gets amount of unclaimed reward token from Aave.
     */
    function getUnclaimedRewards() public view returns (address[] memory _tokens, uint256[] memory _rewards) {
        (_tokens, _rewards) = aaveReward.getAllUserRewards(supplyingAssets, address(this));
    }

    function currenRewardTokens() external view returns (address[] memory _tokens) {
        (_tokens, ) = aaveReward.getAllUserRewards(supplyingAssets, address(this));
    }

    /**
     * @notice this function called when migration is being executed.
     */
    function _withdrawAllReward() internal {
        (address[] memory _rewards, uint256[] memory _gotRewards) = aaveReward.claimAllRewards(
            supplyingAssets,
            address(this)
        );

        // compound each reward tokens got
        uint256 _rewardsCount = _rewards.length;
        for (uint256 i = 0; i < _rewardsCount; ) {
            address _rewardToken = _rewards[i];
            uint256 _amount = _gotRewards[i];
            if (_amount > 0) {
                IERC20(_rewardToken).safeIncreaseAllowance(exchangeLogic.swapper(), _amount);
                // execute swap regardless any slippage
                _swap(_rewardToken, address(usdc), _amount, 1);
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Supplies given amount of USDC to Aave pool. If all supplying asset of this contract exceeds
     *      Aave total supply, transaction failed to be revereted.
     * @param _amount The amount of USDC to supply
     */
    function _utilize(uint256 _amount) internal {
        if (_amount == 0) revert AmountZero();
        if (managingFund() + _amount > _calcAaveNewSupplyCap()) revert AaveSupplyCapExceeded();

        // supply utilized assets into aave pool
        usdc.approve(address(aave), _amount);
        aave.supply(address(usdc), _amount, address(this), 0);
        emit SupplyIncreased(address(usdc), _amount);
    }

    /**
     * @dev Withdraws given amount of supplying USDC from Aave pool.
     * @param _amount The amount of USDC to withdraw
     */
    function _unutilize(uint256 _amount) internal {
        if (_amount == 0) revert AmountZero();
        if (_amount > managingFund()) revert InsufficientManagingFund();

        aave.withdraw(address(usdc), _amount, address(this));
        emit SupplyDecreased(address(usdc), _amount);
    }

    /**
     * @dev Calculates the amount limit of aUSDC token to be supplied.
     */
    function _calcAaveNewSupplyCap() internal view returns (uint256 _available) {
        uint256 _reserve = ausdc.totalSupply();

        unchecked {
            _available = (_reserve * aaveMaxOccupancyRatio) / MAGIC_SCALE_1E6;
        }
    }

    /**
     * @dev Internal function that actually set exchange logic to the contract.
     */
    function _setExchangeLogic(IExchangeLogic _exchangeLogic) private {
        if (address(_exchangeLogic) == address(0)) revert ZeroAddress();
        if (address(_exchangeLogic) == address(exchangeLogic)) revert SameAddressUsed();
        // check the given address is valid
        assert(_exchangeLogic.swapper() != address(0));

        address _oldSwapper = exchangeLogic.swapper();
        address[] memory _rewards = aaveReward.getRewardsByAsset(address(ausdc));
        uint256 _rewardsCount = _rewards.length;
        //revoke allowance of current swapper
        for (uint256 i = 0; i < _rewardsCount; ) {
            IERC20(_rewards[i]).safeApprove(_oldSwapper, 0);

            unchecked {
                ++i;
            }
        }

        //update, and approve to new swapper
        exchangeLogic = _exchangeLogic;
        emit ExchangeLogicSet(address(_exchangeLogic));
    }

    /**
     * @dev Swap function to be used reward token conversion.
     *      You can see more details in the IExchangeLogic interface.
     */
    function _swap(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _minAmountOut
    ) internal returns (uint256) {
        address _swapper = exchangeLogic.swapper();
        (bool _success, bytes memory _res) = _swapper.call(
            exchangeLogic.abiEncodeSwap(_tokenIn, _tokenOut, _amountIn, _minAmountOut, address(this))
        );

        if (!_success) revert NoRewardClaimable();

        uint256 _swapped = abi.decode(_res, (uint256));
        emit SwapSucceeded(_tokenIn, _tokenOut, _amountIn, _swapped);

        return _swapped;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

abstract contract OpsReady {
    /// @dev The address execute routine task. In this case, claiming reward.
    address public ops;

    modifier onlyOps() {
        if (msg.sender != ops) revert OnlyOps();
        _;
    }

    /**
     * @dev Checks the function is executable, and returns some data for executing the function.
     *      This function needs for Gelato. See more details below
     *      https://docs.gelato.network/developer-products/gelato-ops-smart-contract-automation-hub/guides/writing-a-resolver/smart-contract-resolver
     */
    function check() external virtual returns (bool _canExec, bytes memory _execPayload);
}

error OnlyOps();

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

/**
 * @title IController
 * @author @InsureDAO
 * @dev Defines the basic interface for an InsureDAO Controller.
 * @notice Controller invests market deposited tokens on behalf of Vault contract.
 *         This contract gets utilized a vault assets then invests these assets via
 *         Strategy contract. To Avoid unnecessary complexity, sometimes the controller
 *         includes the functionality of a strategy.
 */
interface IController {
    /**
     * @notice Utilizes a vault fund to strategies, which invest fund to
     *         various protocols. Vault fund is utilized up to maxManagingRatio
     *         determined by the owner.
     * @dev You **should move all pulled fund to strategies** in this function
     *      to avoid unnecessary complexity of asset management.
     *      Controller exists to route vault fund to strategies safely.
     */
    function adjustFund() external;

    /**
     * @notice Returns utilized fund to a vault. If the amount exceeds all
     *         assets the controller manages, transaction should be reverted.
     * @param _amount the amount to be returned to a vault
     */
    function returnFund(uint256 _amount) external;

    /**
     * @notice Returns all assets this controller manages. Value is denominated
     *         in USDC token amount. (e.g. If the controller utilizes 100 USDC
     *         for strategies, valueAll() returns 100,000,000(100 * 1e6)) .
     */
    function managingFund() external view returns (uint256);

    /**
     * @notice The proportion of a vault fund to be utilized. 1e6 regarded as 100%.
     */
    function maxManagingRatio() external view returns (uint256);

    /**
     * @notice Changes maxManagingRatio which
     * @param _ratio maxManagingRatio to be set. See maxManagingRatio() for more detail
     */
    function setMaxManagingRatio(uint256 _ratio) external;

    /**
     * @notice Returns the proportion of a vault fund managed by the controller.
     */
    function currentManagingRatio() external view returns (uint256);

    /**
     * @notice Moves managing asset to new controller. Only vault should call
     *         this method for safety.
     * @param _to the destination of migration. this address should be a
     *            controller address as this method expected call immigrate() internally.
     */
    function emigrate(address _to) external;

    /**
     * @notice Receives the asset from old controller. New controller should call this method.
     * @param _from The address that fund received from. the address should be a controller address.
     */
    function immigrate(address _from) external;

    /**
     * @notice Sends managing fund to any address. This method should be called in case that
     *         managing fund cannot be moved by the controller (e.g. A protocol contract is
     *         temporary unavailable so the controller cannot withdraw managing fund directly,
     *         where emergencyExit() should move to the right to take reward like aUSDC on Aave).
     * @param _to The address that fund will be sent.
     */
    function emergencyExit(address _to) external;
}

error RatioOutOfRange();
error ExceedManagingRatio();
error AlreadyInUse();
error AaveSupplyCapExceeded();
error InsufficientManagingFund();
error InsufficientRewardToWithdraw();
error NoRewardClaimable();
error MigrateToSelf();
error SameAddressUsed();

pragma solidity 0.8.12;

//SPDX-License-Identifier: MIT

interface IOwnership {
    function owner() external view returns (address);

    function futureOwner() external view returns (address);

    function commitTransferOwnership(address newOwner) external;

    function acceptTransferOwnership() external;
}

pragma solidity 0.8.12;

interface IVault {
    function addValueBatch(
        uint256 _amount,
        address _from,
        address[2] memory _beneficiaries,
        uint256[2] memory _shares
    ) external returns (uint256[2] memory _allocations);

    function addValue(
        uint256 _amount,
        address _from,
        address _attribution
    ) external returns (uint256 _attributions);

    function withdrawValue(uint256 _amount, address _to) external returns (uint256 _attributions);

    function transferValue(uint256 _amount, address _destination) external returns (uint256 _attributions);

    function withdrawAttribution(uint256 _attribution, address _to) external returns (uint256 _retVal);

    function withdrawAllAttribution(address _to) external returns (uint256 _retVal);

    function transferAttribution(uint256 _amount, address _destination) external;

    function attributionOf(address _target) external view returns (uint256);

    function underlyingValue(address _target) external view returns (uint256);

    function attributionValue(uint256 _attribution) external view returns (uint256);

    function utilize(uint256 _amount) external returns (uint256);

    function valueAll() external view returns (uint256);

    function token() external returns (address);

    function balance() external view returns (uint256);

    function available() external view returns (uint256);

    function borrowValue(uint256 _amount, address _to) external;

    /*
    function borrowAndTransfer(uint256 _amount, address _to)
        external
        returns (uint256 _attributions);
    */

    function offsetDebt(uint256 _amount, address _target) external returns (uint256 _attributions);

    function repayDebt(uint256 _amount, address _target) external;

    function debts(address _debtor) external view returns (uint256);

    function transferDebt(uint256 _amount) external;

    //onlyOwner
    function withdrawRedundant(address _token, address _to) external;

    function setController(address _controller) external;
}

// SPDX-License-Identifier: agpl-3.0
// Forked and minimized from https://github.com/aave/aave-v3-periphery/blob/master/contracts/rewards/interfaces/IRewardsDistributor.sol
pragma solidity ^0.8.0;

interface IAaveV3Reward {
    /**
     * @dev Sets the end date for the distribution
     * @param asset The asset to incentivize
     * @param reward The reward token that incentives the asset
     * @param newDistributionEnd The end date of the incentivization, in unix time format
     **/
    function setDistributionEnd(
        address asset,
        address reward,
        uint32 newDistributionEnd
    ) external;

    /**
     * @dev Sets the emission per second of a set of reward distributions
     * @param asset The asset is being incentivized
     * @param rewards List of reward addresses are being distributed
     * @param newEmissionsPerSecond List of new reward emissions per second
     */
    function setEmissionPerSecond(
        address asset,
        address[] calldata rewards,
        uint88[] calldata newEmissionsPerSecond
    ) external;

    /**
     * @dev Gets the end date for the distribution
     * @param asset The incentivized asset
     * @param reward The reward token of the incentivized asset
     * @return The timestamp with the end of the distribution, in unix time format
     **/
    function getDistributionEnd(address asset, address reward) external view returns (uint256);

    /**
     * @dev Returns the index of a user on a reward distribution
     * @param user Address of the user
     * @param asset The incentivized asset
     * @param reward The reward token of the incentivized asset
     * @return The current user asset index, not including new distributions
     **/
    function getUserAssetIndex(
        address user,
        address asset,
        address reward
    ) external view returns (uint256);

    /**
     * @dev Returns the configuration of the distribution reward for a certain asset
     * @param asset The incentivized asset
     * @param reward The reward token of the incentivized asset
     * @return The index of the asset distribution
     * @return The emission per second of the reward distribution
     * @return The timestamp of the last update of the index
     * @return The timestamp of the distribution end
     **/
    function getRewardsData(address asset, address reward)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    /**
     * @dev Returns the list of available reward token addresses of an incentivized asset
     * @param asset The incentivized asset
     * @return List of rewards addresses of the input asset
     **/
    function getRewardsByAsset(address asset) external view returns (address[] memory);

    /**
     * @dev Returns the list of available reward addresses
     * @return List of rewards supported in this contract
     **/
    function getRewardsList() external view returns (address[] memory);

    /**
     * @dev Returns the accrued rewards balance of a user, not including virtually accrued rewards since last distribution.
     * @param user The address of the user
     * @param reward The address of the reward token
     * @return Unclaimed rewards, not including new distributions
     **/
    function getUserAccruedRewards(address user, address reward) external view returns (uint256);

    /**
     * @dev Returns a single rewards balance of a user, including virtually accrued and unrealized claimable rewards.
     * @param assets List of incentivized assets to check eligible distributions
     * @param user The address of the user
     * @param reward The address of the reward token
     * @return The rewards amount
     **/
    function getUserRewards(
        address[] calldata assets,
        address user,
        address reward
    ) external view returns (uint256);

    /**
     * @dev Returns a list all rewards of a user, including already accrued and unrealized claimable rewards
     * @param assets List of incentivized assets to check eligible distributions
     * @param user The address of the user
     * @return The list of reward addresses
     * @return The list of unclaimed amount of rewards
     **/
    function getAllUserRewards(address[] calldata assets, address user)
        external
        view
        returns (address[] memory, uint256[] memory);

    /**
     * @dev Returns the decimals of an asset to calculate the distribution delta
     * @param asset The address to retrieve decimals
     * @return The decimals of an underlying asset
     */
    function getAssetDecimals(address asset) external view returns (uint8);

    /**
     * @dev Returns the address of the emission manager
     * @return The address of the EmissionManager
     */
    function getEmissionManager() external view returns (address);

    /**
     * @dev Updates the address of the emission manager
     * @param emissionManager The address of the new EmissionManager
     */
    function setEmissionManager(address emissionManager) external;

    /**
     * @dev Whitelists an address to claim the rewards on behalf of another address
     * @param user The address of the user
     * @param claimer The address of the claimer
     */
    function setClaimer(address user, address claimer) external;

    /**
     * @dev Sets a TransferStrategy logic contract that determines the logic of the rewards transfer
     * @param reward The address of the reward token
     * @param transferStrategy The address of the TransferStrategy logic contract
     */
    // function setTransferStrategy(address reward, ITransferStrategyBase transferStrategy) external;

    /**
     * @dev Sets an Aave Oracle contract to enforce rewards with a source of value.
     * @notice At the moment of reward configuration, the Incentives Controller performs
     * a check to see if the reward asset oracle is compatible with IEACAggregator proxy.
     * This check is enforced for integrators to be able to show incentives at
     * the current Aave UI without the need to setup an external price registry
     * @param reward The address of the reward to set the price aggregator
     * @param rewardOracle The address of price aggregator that follows IEACAggregatorProxy interface
     */
    // function setRewardOracle(address reward, IEACAggregatorProxy rewardOracle) external;

    /**
     * @dev Get the price aggregator oracle address
     * @param reward The address of the reward
     * @return The price oracle of the reward
     */
    function getRewardOracle(address reward) external view returns (address);

    /**
     * @dev Returns the whitelisted claimer for a certain address (0x0 if not set)
     * @param user The address of the user
     * @return The claimer address
     */
    function getClaimer(address user) external view returns (address);

    /**
     * @dev Returns the Transfer Strategy implementation contract address being used for a reward address
     * @param reward The address of the reward
     * @return The address of the TransferStrategy contract
     */
    function getTransferStrategy(address reward) external view returns (address);

    /**
     * @dev Configure assets to incentivize with an emission of rewards per second until the end of distribution.
     * @param config The assets configuration input, the list of structs contains the following fields:
     *   uint104 emissionPerSecond: The emission per second following rewards unit decimals.
     *   uint256 totalSupply: The total supply of the asset to incentivize
     *   uint40 distributionEnd: The end of the distribution of the incentives for an asset
     *   address asset: The asset address to incentivize
     *   address reward: The reward token address
     *   ITransferStrategy transferStrategy: The TransferStrategy address with the install hook and claim logic.
     *   IEACAggregatorProxy rewardOracle: The Price Oracle of a reward to visualize the incentives at the UI Frontend.
     *                                     Must follow Chainlink Aggregator IEACAggregatorProxy interface to be compatible.
     */
    // function configureAssets(RewardsDataTypes.RewardsConfigInput[] memory config) external;

    /**
     * @dev Called by the corresponding asset on any update that affects the rewards distribution
     * @param user The address of the user
     * @param userBalance The user balance of the asset
     * @param totalSupply The total supply of the asset
     **/
    function handleAction(
        address user,
        uint256 userBalance,
        uint256 totalSupply
    ) external;

    /**
     * @dev Claims reward for a user to the desired address, on all the assets of the pool, accumulating the pending rewards
     * @param assets List of assets to check eligible distributions before claiming rewards
     * @param amount The amount of rewards to claim
     * @param to The address that will be receiving the rewards
     * @param reward The address of the reward token
     * @return The amount of rewards claimed
     **/
    function claimRewards(
        address[] calldata assets,
        uint256 amount,
        address to,
        address reward
    ) external returns (uint256);

    /**
     * @dev Claims reward for a user on behalf, on all the assets of the pool, accumulating the pending rewards. The
     * caller must be whitelisted via "allowClaimOnBehalf" function by the RewardsAdmin role manager
     * @param assets The list of assets to check eligible distributions before claiming rewards
     * @param amount The amount of rewards to claim
     * @param user The address to check and claim rewards
     * @param to The address that will be receiving the rewards
     * @param reward The address of the reward token
     * @return The amount of rewards claimed
     **/
    function claimRewardsOnBehalf(
        address[] calldata assets,
        uint256 amount,
        address user,
        address to,
        address reward
    ) external returns (uint256);

    /**
     * @dev Claims reward for msg.sender, on all the assets of the pool, accumulating the pending rewards
     * @param assets The list of assets to check eligible distributions before claiming rewards
     * @param amount The amount of rewards to claim
     * @param reward The address of the reward token
     * @return The amount of rewards claimed
     **/
    function claimRewardsToSelf(
        address[] calldata assets,
        uint256 amount,
        address reward
    ) external returns (uint256);

    /**
     * @dev Claims all rewards for a user to the desired address, on all the assets of the pool, accumulating the pending rewards
     * @param assets The list of assets to check eligible distributions before claiming rewards
     * @param to The address that will be receiving the rewards
     * @return rewardsList List of addresses of the reward tokens
     * @return claimedAmounts List that contains the claimed amount per reward, following same order as "rewardList"
     **/
    function claimAllRewards(address[] calldata assets, address to)
        external
        returns (address[] memory rewardsList, uint256[] memory claimedAmounts);

    /**
     * @dev Claims all rewards for a user on behalf, on all the assets of the pool, accumulating the pending rewards. The caller must
     * be whitelisted via "allowClaimOnBehalf" function by the RewardsAdmin role manager
     * @param assets The list of assets to check eligible distributions before claiming rewards
     * @param user The address to check and claim rewards
     * @param to The address that will be receiving the rewards
     * @return rewardsList List of addresses of the reward tokens
     * @return claimedAmounts List that contains the claimed amount per reward, following same order as "rewardsList"
     **/
    function claimAllRewardsOnBehalf(
        address[] calldata assets,
        address user,
        address to
    ) external returns (address[] memory rewardsList, uint256[] memory claimedAmounts);

    /**
     * @dev Claims all reward for msg.sender, on all the assets of the pool, accumulating the pending rewards
     * @param assets The list of assets to check eligible distributions before claiming rewards
     * @return rewardsList List of addresses of the reward tokens
     * @return claimedAmounts List that contains the claimed amount per reward, following same order as "rewardsList"
     **/
    function claimAllRewardsToSelf(address[] calldata assets)
        external
        returns (address[] memory rewardsList, uint256[] memory claimedAmounts);
}

// SPDX-License-Identifier: AGPL-3.0
// Forked and minimized from https://github.com/aave/aave-v3-core/blob/master/contracts/interfaces/IPool.sol
pragma solidity ^0.8.0;

/**
 * @title IPool
 * @author Aave
 * @notice Defines the basic interface for an Aave Pool.
 **/
interface IAaveV3Pool {
    /**
     * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
     * @param asset The address of the underlying asset to supply
     * @param amount The amount to be supplied
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @notice Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
     * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
     * @param to The address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     **/
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    /**
     * @notice Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
     * already supplied enough collateral, or he was given enough allowance by a credit delegator on the
     * corresponding debt token (StableDebtToken or VariableDebtToken)
     * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
     *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
     * @param asset The address of the underlying asset to borrow
     * @param amount The amount to be borrowed
     * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
     * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     * @param onBehalfOf The address of the user who will receive the debt. Should be the address of the borrower itself
     * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
     * if he has been given credit delegation allowance
     **/
    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    /**
     * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
     * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
     * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
     * @param onBehalfOf The address of the user who will get his debt reduced/removed. Should be the address of the
     * user calling the function if he wants to reduce/remove his own debt, or the address of any other
     * other borrower whose debt should be removed
     * @return The final amount repaid
     **/
    function repay(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        address onBehalfOf
    ) external returns (uint256);

    /**
     * @notice Allows a user to use the protocol in eMode
     * @param categoryId The id of the category
     */
    function setUserEMode(uint8 categoryId) external;

    /**
     * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
     * @dev Deprecated: Use the `supply` function instead
     * @param asset The address of the underlying asset to supply
     * @param amount The amount to be supplied
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

error ZeroAddress();
error AmountZero();
error OnlyOwner();
error OnlyVault();

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

/**
 * @title IExchangeLogic
 * @author @InsureDAO
 * @notice Defines the basic interface for an InsureDAO Exchange Logic.
 **/
interface IExchangeLogic {
    /**
     * @dev Returns swap function abi, which enables to perform interchangeability of various swap specs.
     *      Caller exactly execute low level function call with abi.
     * @param _tokenIn The token address to be swapped.
     * @param _tokenOut The token address a caller receives.
     * @param _amountIn The amount of token to be swapped.
     * @param _amountOutMin The minimum amount the caller should receive.
     */
    function abiEncodeSwap(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _to
    ) external view returns (bytes memory);

    /**
     * @dev Returns the contract address providing swap feature.
     */
    function swapper() external returns (address);

    /**
     * @dev Returns the token amount to receive
     */
    function estimateAmountOut(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn
    ) external returns (uint256);

    /**
     * @dev Returns the token amount a caller need to provide for given amount.
     */
    function estimateAmountIn(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountMinOut
    ) external returns (uint256);

    /**
     * @dev Returns what portion of tokens to be lost from swap operation.
     */
    function slippageTolerance() external view returns (uint256);
}

error ZeroSlippageTolerance();
error SlippageToleranceOutOfRange();

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}