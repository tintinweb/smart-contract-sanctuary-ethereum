// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

import "ICurve3Pool.sol";
import "ICurveMeta.sol";
import "IStop.sol";
import "IStrategy.sol";
import "IGVault.sol";
import {ERC20} from "ERC20.sol";

// High level Responsibilities:
// - Borrow funds from the vault (1)
// - Invest borrowed funds into an underlying strategy (2)
// - Correctly report PnL to the lender (GVault) (3)
// - Responsibly handle 'borrowed' assets (4)

library StrategyErrors {
    error NotOwner(); // 0x30cd7471
    error NotVault(); // 0x62df0545
    error NotKeeper(); // 0xf512b278
    error ConvexShutdown(); // 0xdbd83f91
    error RewardsTokenMax(); // 0x8f24ac29
    error Stopped(); // 0x7acc84e3
    error SamePid(); // 0x4eb5bc6d
    error BaseAsset(); // 0xaeca768b
    error LpToken(); // 0xaeca768b
    error ConvexToken(); // 0xaeca768b
    error LTMinAmountExpected(); // 0x3d93e699
}

/// Convex booster interface
interface Booster {
    function poolInfo(uint256)
        external
        view
        returns (
            address,
            address,
            address,
            address,
            address,
            bool
        );

    function deposit(
        uint256 _pid,
        uint256 _amount,
        bool _stake
    ) external returns (bool);
}

/// Convex rewards interface
interface Rewards {
    function balanceOf(address account) external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function withdrawAndUnwrap(uint256 amount, bool claim)
        external
        returns (bool);

    function withdrawAllAndUnwrap(bool claim) external;

    function getReward() external returns (bool);

    function extraRewards(uint256 id) external view returns (address);

    function extraRewardsLength() external view returns (uint256);
}

/// GVault Strategy parameters
struct StrategyParams {
    bool active;
    uint256 debtRatio;
    uint256 lastReport;
    uint256 totalDebt;
    uint256 totalGain;
    uint256 totalLoss;
}

/// CRV-ETH and CVX-ETH pool interface
interface ICurveRewards {
    function exchange(
        uint256 from,
        uint256 to,
        uint256 _from_amount,
        uint256 _min_to_amount,
        bool use_eth
    ) external returns (uint256);

    function get_dy(
        uint256 i,
        uint256 j,
        uint256 dx
    ) external view returns (uint256);
}

/// Uniswap v2 router interface
interface IUniV2 {
    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

/// Uniswap v3 router interface
interface IUniV3 {
    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    function exactInput(ExactInputParams calldata params)
        external
        payable
        returns (uint256 amountOut);
}

/// Uniswap v3 pool interface
interface IUniV3_POOL {
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );
}

/** @title StableConvexXPool
 *   @notice Convex strategy based of yearns convex contract that allows usage of one of the 3 pool
 *       stables as want, rather than a metapool lp token. This strategy can swap between meta pool
 *       and convex strategies to optimize yield/risk, and routes all assets through the following flow:
 *           3crv => metaLp => convex.
 */
contract ConvexStrategy {
    /*//////////////////////////////////////////////////////////////
                        CONSTANTS & IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant PERCENTAGE_DECIMAL_FACTOR = 1E4;
    uint256 internal constant DEFAULT_DECIMALS_FACTOR = 1E18;

    address internal constant BOOSTER =
        address(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);

    address internal constant CVX =
        address(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
    address internal constant CRV =
        address(0xD533a949740bb3306d119CC777fa900bA034cd52);
    address internal constant WETH =
        address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    address internal constant USDC =
        address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    address internal constant CRV_3POOL =
        address(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);
    address internal constant CRV_ETH =
        address(0x8301AE4fc9c624d1D396cbDAa1ed877821D7C511);
    address internal constant CVX_ETH =
        address(0xB576491F1E6e5E62f1d8F26062Ee822B40B0E0d4);

    ERC20 internal constant CRV_3POOL_TOKEN =
        ERC20(address(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490));

    address internal constant UNI_V2 =
        address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address internal constant UNI_V3 =
        address(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    address internal constant USDC_ETH_V3 =
        address(0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640);
    uint256 internal constant UNI_V3_FEE = 500;

    // strategy accounting constant
    uint256 internal constant MIN_REWARD_SELL_AMOUNT = 1E18;
    uint256 internal constant MIN_WETH_SELL_AMOUNT = 1E16;
    uint256 internal constant MAX_REPORT_DELAY = 604800;
    uint256 internal constant MIN_REPORT_DELAY = 172800;
    uint256 internal constant INVESTMENT_BUFFER = 10E18;

    // meta pool token layout: [minor stable, 3Crv]
    int128 internal constant CRV3_INDEX = 1;
    uint256 internal constant CRV_ETH_INDEX = 1;

    // Vault and core asset associated with strategy
    IGVault internal immutable VAULT;
    ERC20 internal immutable ASSET;

    // CVX rewards calculation parameters
    uint256 internal constant TOTAL_CLIFFS = 1000;
    uint256 internal constant MAX_SUPPLY = 1E8 * DEFAULT_DECIMALS_FACTOR;
    uint256 internal constant REDUCTION_PER_CLIFF =
        1E5 * DEFAULT_DECIMALS_FACTOR;

    // number of max rewardedTokens set by Curve
    uint256 internal constant MAX_REWARDS = 8;

    /*//////////////////////////////////////////////////////////////
                    STORAGE VARIABLES & TYPES
    //////////////////////////////////////////////////////////////*/

    // Current strategy investment target
    uint256 internal pid; // convex lp token pid
    address internal metaPool; // meta pool
    ERC20 internal lpToken; // meta pool lp token
    address internal rewardContract; // convex reward contract for lp token

    // Potential strategy investment target
    uint256 internal newPid;
    address internal newMetaPool;
    ERC20 internal newLpToken;
    address internal newRewardContract;

    // Additional reward tokens provided by CRV
    address[MAX_REWARDS] public rewardTokens;
    uint256 numberOfRewards;

    // Admin variables
    address public owner; // contract owner
    mapping(address => bool) public keepers;

    uint256 public baseSlippage = 10;
    uint256 public stopLossAttempts;
    address public stopLossLogic;
    bool public emergencyMode;
    bool public stop;

    // Strategy harvest thresholds
    uint256 internal debtThreshold = 20_000 * DEFAULT_DECIMALS_FACTOR;
    uint256 internal profitThreshold = 20_000 * DEFAULT_DECIMALS_FACTOR;
    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event NewKeeper(address indexed keeper);
    event RevokedKeeper(address indexed keeper);
    event LogNewHarvestThresholds(
        uint256 debtThreshold,
        uint256 profitThreshold
    );
    event LogNewStopLoss(address newStopLoss);
    event LogNewBaseSlippage(uint256 baseSlippage);

    event Harvested(
        uint256 profit,
        uint256 loss,
        uint256 debtRepayment,
        uint256 excessDebt
    );

    event EmergencyModeSet(bool mode);

    event LogChangePool(
        uint256 pid,
        address lpToken,
        address reward,
        address metaPool
    );

    event LogSetNewPool(
        uint256 pid,
        address lpToken,
        address reward,
        address metaPool
    );
    event LogAdditionalRewards(address[] rewardTokens);

    event LogStopLossErrorString(uint256 stopLossAttempts, string reason);
    event LogStopLossErrorBytes(uint256 stopLossAttempts, bytes data);

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Strategy constructor
    /// @param _vault Vault that holds the strategy
    /// @param _pid PID of Convex reward pool
    /// @param _metaPool Underlying meta pool
    ///     - used when LP token and Meta pool dont match (older metapools)
    constructor(
        IGVault _vault,
        address _owner,
        uint256 _pid,
        address _metaPool
    ) {
        owner = _owner;
        VAULT = _vault;
        ERC20 _asset = _vault.asset();
        ASSET = _asset;
        _asset.approve(address(_vault), type(uint256).max); // Max approve asset for Vault to save gas

        ERC20(CRV).approve(CRV_ETH, type(uint256).max);
        ERC20(CVX).approve(CVX_ETH, type(uint256).max);
        ERC20(WETH).approve(UNI_V3, type(uint256).max);

        (address lp, , , address reward, , bool shutdown) = Booster(BOOSTER)
            .poolInfo(_pid);
        if (shutdown) revert StrategyErrors.ConvexShutdown();
        pid = _pid;
        metaPool = _metaPool;
        lpToken = ERC20(lp);
        rewardContract = reward;
        ERC20(CRV_3POOL_TOKEN).approve(_metaPool, type(uint256).max);
        ERC20(USDC).approve(CRV_3POOL, type(uint256).max);
        ERC20(lp).approve(BOOSTER, type(uint256).max);
        emit LogChangePool(_pid, lp, reward, _metaPool);
    }

    /*//////////////////////////////////////////////////////////////
                            GETTERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns underlying vault
    function vault() external view returns (address) {
        return address(VAULT);
    }

    /// @notice Returns underlying asset
    function asset() external view returns (address) {
        return address(ASSET);
    }

    /// @notice Get current convex investment path including pid, meta pool, lp token and reward contract
    function getCurrentInvestment()
        external
        view
        returns (
            uint256,
            address,
            address,
            address
        )
    {
        return (pid, metaPool, address(lpToken), rewardContract);
    }

    /// @notice Get current curve meta pool
    function getMetaPool() external view returns (address) {
        return metaPool;
    }

    /// @notice Get new convex investment path including pid, meta pool, lp token and reward contract
    function getPlannedInvestment()
        external
        view
        returns (
            uint256,
            address,
            address,
            address
        )
    {
        return (newPid, newMetaPool, address(newLpToken), newRewardContract);
    }

    /*//////////////////////////////////////////////////////////////
                           SETTERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Change owner of the strategy
    /// @param _owner new strategy owner
    function setOwner(address _owner) external {
        if (msg.sender != owner) revert StrategyErrors.NotOwner();
        address previous_owner = msg.sender;
        owner = _owner;

        emit OwnershipTransferred(previous_owner, _owner);
    }

    /// @notice Add keeper from the strategy
    /// @param _keeper keeper to add
    function setKeeper(address _keeper) external {
        if (msg.sender != owner) revert StrategyErrors.NotOwner();
        keepers[_keeper] = true;

        emit NewKeeper(_keeper);
    }

    /// @notice Remove keeper from the strategy
    /// @param _keeper keeper to remove
    function revokeKeeper(address _keeper) external {
        if (msg.sender != owner) revert StrategyErrors.NotOwner();
        keepers[_keeper] = false;

        emit RevokedKeeper(_keeper);
    }

    /// @notice Add additional rewards provided by the curve pools
    /// @param _tokens list of reward tokens
    function setAdditionalRewards(address[] memory _tokens) external {
        if (msg.sender != owner) revert StrategyErrors.NotOwner();
        if (_tokens.length > MAX_REWARDS)
            revert StrategyErrors.RewardsTokenMax();
        for (uint256 i; i < rewardTokens.length; i++) {
            ERC20(rewardTokens[i]).approve(UNI_V2, 0);
        }
        delete rewardTokens;
        numberOfRewards = _tokens.length;
        for (uint256 i; i < _tokens.length; ++i) {
            address token = _tokens[i];
            rewardTokens[i] = token;
            ERC20(token).approve(UNI_V2, type(uint256).max);
        }
        emit LogAdditionalRewards(_tokens);
    }

    /// @notice Sets emergency mode to enable emergency exit of strategy
    function setEmergencyMode() external {
        if (!keepers[msg.sender]) revert StrategyErrors.NotKeeper();
        emergencyMode = true;

        emit EmergencyModeSet(true);
    }

    /// @notice Set thresholds for when harvest should occur due to profit/loss
    /// @param _debtThreshold Amount of debt/loss the strategy can accumulate before reporting
    /// @param _profitThreshold Amount of profit the strategy can accumulate before reporting
    function setHarvestThresholds(
        uint256 _debtThreshold,
        uint256 _profitThreshold
    ) external {
        if (msg.sender != owner) revert StrategyErrors.NotOwner();
        debtThreshold = _debtThreshold;
        profitThreshold = _profitThreshold;
        emit LogNewHarvestThresholds(_debtThreshold, _profitThreshold);
    }

    /// @notice Restarts strategy after stop-loss has been triggered
    function resume() external {
        if (msg.sender != owner) revert StrategyErrors.NotOwner();
        stop = false;
    }

    /// @notice Set new stop loss logic
    function setStopLossLogic(address _newStopLoss) external {
        if (msg.sender != owner) revert StrategyErrors.NotOwner();
        stopLossLogic = _newStopLoss;
        emit LogNewStopLoss(_newStopLoss);
    }

    /// @notice Set a new base slippage
    function setBaseSlippage(uint256 _baseSlippage) external {
        if (msg.sender != owner) revert StrategyErrors.NotOwner();
        baseSlippage = _baseSlippage;
        emit LogNewBaseSlippage(_baseSlippage);
    }

    /*//////////////////////////////////////////////////////////////
                           STRATEGY ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Get strategies current assets
    function estimatedTotalAssets() external view returns (uint256) {
        (uint256 _assets, , ) = _estimatedTotalAssets(true);
        return _assets;
    }

    /// @notice Internal call of function above
    /// @param _rewards include rewards in return
    function _estimatedTotalAssets(bool _rewards)
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 _balance = ASSET.balanceOf(address(this));
        uint256 _poolAssets = poolAssets();
        uint256 _rewardAmounts;
        if (_rewards) {
            _rewardAmounts = rewards();
        }
        return (
            _balance + _poolAssets + _rewardAmounts,
            _balance,
            _rewardAmounts
        );
    }

    /// @notice Get value of strategy LP position
    function poolAssets() internal view returns (uint256) {
        if (rewardContract == address(0)) return 0;
        uint256 lpAmount = Rewards(rewardContract).balanceOf(address(this));
        if (lpAmount == 0) return 0;
        return
            ICurveMeta(metaPool).calc_withdraw_one_coin(lpAmount, CRV3_INDEX);
    }

    /// @notice Claim and sell off all reward tokens for underlying asset
    function sellAllRewards() internal returns (uint256) {
        Rewards(rewardContract).getReward();
        return _sellRewards();
    }

    /// @notice Return combined value of all reward tokens in underlying asset
    function rewards() public view returns (uint256) {
        return _claimableRewards() + _additionalRewardTokens();
    }

    /// @notice Get price of cvx/crv in eth
    /// @param _pool CVX/CRV pool
    /// @param _amount Amount of rewards to swap
    function getPriceCurve(address _pool, uint256 _amount)
        public
        view
        returns (uint256 price)
    {
        return ICurveRewards(_pool).get_dy(CRV_ETH_INDEX, 0, _amount);
    }

    /// @notice Get Uniswap v2 price of token in base asset
    /// @dev rather than going through the sell path of
    ///     uni v2 => v3 => curve
    ///     we just use univ2 to estimate the value
    /// @param _token Token to swap
    /// @param _amount Amount to swap
    function getPriceV2(address _token, uint256 _amount)
        internal
        view
        returns (uint256 price)
    {
        uint256[] memory crvSwap = IUniV2(UNI_V2).getAmountsOut(
            _amount,
            _getPath(_token, false)
        );
        return crvSwap[crvSwap.length - 1];
    }

    /// @notice Calculate the value of ETH in Base asset, taking the route:
    ///     ETH => USDC => 3Crv
    /// @param _amount Amount of token to swap
    function getPriceV3(uint256 _amount) public view returns (uint256 price) {
        (uint160 sqrtPriceX96, , , , , , ) = IUniV3_POOL(USDC_ETH_V3).slot0();
        price = ((2**192 * DEFAULT_DECIMALS_FACTOR) / uint256(sqrtPriceX96)**2);
        // we assume a dollar price of usdc and divide it by the 3pool
        //  virtual price to get an estimate for the number of tokens we will get
        return
            _amount *
            ((price * 1E12) / ICurve3Pool(CRV_3POOL).get_virtual_price());
    }

    /*//////////////////////////////////////////////////////////////
                           REWARDS LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Value of additional rewards tokens available to claim,
    ///     denoted in base asset
    function _additionalRewardTokens() internal view returns (uint256) {
        uint256 _totalAmount;
        uint256 _tokenAmount;
        address _token;
        for (uint256 i; i < numberOfRewards; ++i) {
            _token = rewardTokens[i];
            if (_token == address(0)) break;
            _tokenAmount = ERC20(_token).balanceOf(address(this));
            if (_tokenAmount > 0)
                _totalAmount += getPriceV2(_token, _tokenAmount);
        }
        return _totalAmount;
    }

    /// @notice Value of CRV/CVX available to claim, denoted in base asset
    function _claimableRewards() internal view returns (uint256) {
        uint256 crv = Rewards(rewardContract).earned(address(this));

        // calculations pulled directly from CVX's contract for minting CVX per CRV claimed
        uint256 supply = ERC20(CVX).totalSupply();
        uint256 cvx;

        uint256 cliff = supply / REDUCTION_PER_CLIFF;
        // mint if below total cliffs
        if (cliff < TOTAL_CLIFFS) {
            // for reduction% take inverse of current cliff
            uint256 reduction = TOTAL_CLIFFS - cliff;
            // reduce
            cvx = (crv * reduction) / TOTAL_CLIFFS;

            // supply cap check
            uint256 amtTillMax = MAX_SUPPLY - supply;
            if (cvx > amtTillMax) {
                cvx = amtTillMax;
            }
        }

        uint256 crvValue;
        if (crv > MIN_REWARD_SELL_AMOUNT) {
            crvValue = getPriceCurve(CRV_ETH, crv);
        }

        uint256 cvxValue;
        if (cvx > MIN_REWARD_SELL_AMOUNT) {
            cvxValue = getPriceCurve(CVX_ETH, cvx);
        }

        if (crvValue + cvxValue > MIN_WETH_SELL_AMOUNT) {
            return getPriceV3(crvValue + cvxValue);
        }
    }

    /// @notice Sell available reward tokens for underlying asset
    /// @return Contracts total amount of base assets
    /// @dev Sell path for CRV/CVX:
    ///     Reward => ETH => USDC => Asset
    ///     <CRV/CVX-ETH pool> => <UNI v3> => 3Pool
    ///      Sell path for addition rewards
    ///     Add. rewards => ETH => USDC => Asset
    ///     <UNI v2> => <UNI v2>
    function _sellRewards() internal returns (uint256) {
        uint256 wethAmount = ERC20(WETH).balanceOf(address(this));
        uint256 _numberOfRewards = numberOfRewards;

        if (_numberOfRewards > 0) {
            wethAmount += _sellAdditionalRewards(_numberOfRewards);
        }

        uint256 cvx = ERC20(CVX).balanceOf(address(this));
        if (cvx > MIN_REWARD_SELL_AMOUNT) {
            wethAmount += ICurveRewards(CVX_ETH).exchange(
                CRV_ETH_INDEX,
                0,
                cvx,
                0,
                false
            );
        }

        uint256 crv = ERC20(CRV).balanceOf(address(this));
        if (crv > MIN_REWARD_SELL_AMOUNT) {
            wethAmount += ICurveRewards(CRV_ETH).exchange(
                CRV_ETH_INDEX,
                0,
                crv,
                0,
                false
            );
        }

        if (wethAmount > MIN_WETH_SELL_AMOUNT) {
            uint256[3] memory _amounts;
            _amounts[1] = IUniV3(UNI_V3).exactInput(
                IUniV3.ExactInputParams(
                    abi.encodePacked(WETH, uint24(UNI_V3_FEE), USDC),
                    address(this),
                    block.timestamp,
                    wethAmount,
                    0
                )
            );
            ICurve3Pool(CRV_3POOL).add_liquidity(_amounts, 0);
            return CRV_3POOL_TOKEN.balanceOf(address(this));
        }
    }

    /// @notice Sell additional rewards for WETH
    /// @param _number_of_rewards number of reward tokens
    function _sellAdditionalRewards(uint256 _number_of_rewards)
        internal
        returns (uint256)
    {
        uint256 wethAmount;
        uint256 reward_amount;
        address reward_token;
        for (uint256 i; i < _number_of_rewards; ++i) {
            reward_token = rewardTokens[i];
            reward_amount = ERC20(reward_token).balanceOf(address(this));
            if (reward_amount > MIN_REWARD_SELL_AMOUNT) {
                uint256[] memory swap = IUniV2(UNI_V2).swapExactTokensForTokens(
                    reward_amount,
                    uint256(0),
                    _getPath(rewardTokens[i], true),
                    address(this),
                    block.timestamp
                );
                wethAmount += swap[swap.length - 1];
            }
        }
        return wethAmount;
    }

    /*//////////////////////////////////////////////////////////////
                           CORE LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Withdraw assets from the strategy to the Vault -
    ///    If the strategy has a loss, this loss will be distributed
    ///     proportionally on the user withdrawing
    /// @param _amount asset quantity needed to be withdrawn by Vault
    /// @return withdrawnAssets amount of assets that were withdrawn from the strategy
    /// @return loss amount of loss that occurred during withdrawal
    function withdraw(uint256 _amount)
        external
        returns (uint256 withdrawnAssets, uint256 loss)
    {
        if (msg.sender != address(VAULT)) revert StrategyErrors.NotVault();
        (uint256 assets, uint256 balance, ) = _estimatedTotalAssets(false);
        uint256 debt = VAULT.getStrategyDebt();
        // not enough assets to withdraw
        if (_amount >= assets && _amount == debt) {
            balance = sellAllRewards();
            balance += divestAll(false);
            if (_amount > balance) {
                loss = _amount - balance;
                withdrawnAssets = balance;
            } else {
                withdrawnAssets = _amount;
            }
        } else {
            // check if there is a loss, and distribute it proportionally
            //  if it exists
            if (debt > assets) {
                loss = ((debt - assets) * _amount) / debt;
                _amount = _amount - loss;
            }
            if (_amount <= balance) {
                withdrawnAssets = _amount;
            } else {
                withdrawnAssets = divest(_amount - balance, false) + balance;
                if (withdrawnAssets <= _amount) {
                    loss += _amount - withdrawnAssets;
                } else {
                    if (loss > withdrawnAssets - _amount) {
                        loss -= withdrawnAssets - _amount;
                    } else {
                        loss = 0;
                    }
                }
            }
        }
        ASSET.transfer(msg.sender, withdrawnAssets);
        return (withdrawnAssets, loss);
    }

    /// @notice Calculated the strategies current PnL and attempts to pay back any excess
    ///     debt the strategy has to the vault.
    /// @param _excessDebt Amount of debt that the strategy should pay back
    /// @param _debtRatio ratio of total vault assets the strategy is entitled to
    function realisePnl(uint256 _excessDebt, uint256 _debtRatio)
        internal
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 profit;
        uint256 loss;
        uint256 debtRepayment;

        uint256 debt = VAULT.getStrategyDebt();

        (
            uint256 assets,
            uint256 balance,
            uint256 _rewards
        ) = _estimatedTotalAssets(true);

        if (_rewards > MIN_REWARD_SELL_AMOUNT) balance = sellAllRewards();
        if (_excessDebt > assets) {
            debtRepayment = balance + divestAll(false);
            loss = debt - debtRepayment;
            balance = debtRepayment;
        } else {
            if (assets > debt) {
                profit = assets - debt;
                if (profit > profitThreshold) {
                    uint256 profitToRepay = (profit *
                        (PERCENTAGE_DECIMAL_FACTOR - _debtRatio)) /
                        PERCENTAGE_DECIMAL_FACTOR;
                    if (profitToRepay + _excessDebt > balance) {
                        balance += divest(
                            profitToRepay + _excessDebt - balance,
                            true
                        );
                        debtRepayment = balance;
                    } else {
                        debtRepayment = profitToRepay + _excessDebt;
                    }
                }
            } else if (assets < debt) {
                loss = debt - assets;
                // here for safety, but should really never be the case
                //  that loss > _excessDebt
                if (loss > _excessDebt) debtRepayment = 0;
                else if (balance < _excessDebt - loss) {
                    balance += divest(_excessDebt - loss - balance, true);
                    debtRepayment = balance;
                } else debtRepayment = _excessDebt - loss;
            }
        }
        return (profit, loss, debtRepayment, balance);
    }

    /// @notice Attempts to remove assets from active Convex position
    /// @param _debt Amount to divest from position
    /// @param _slippage control for when harvest divests
    /// @dev slippage control for users not necessary as they would check for
    ///     user specified minAmount in the vault/zapper
    function divest(uint256 _debt, bool _slippage) internal returns (uint256) {
        uint256 meta_amount = ICurveMeta(metaPool).calc_token_amount(
            [0, _debt],
            false
        );
        if (_slippage) {
            uint256 ratio = curveValue();
            if (
                (meta_amount * ratio) / PERCENTAGE_DECIMAL_FACTOR <
                ((_debt * (PERCENTAGE_DECIMAL_FACTOR - baseSlippage)) /
                    PERCENTAGE_DECIMAL_FACTOR)
            ) {
                revert StrategyErrors.LTMinAmountExpected();
            }
        }
        Rewards(rewardContract).withdrawAndUnwrap(meta_amount, false);
        return
            ICurveMeta(metaPool).remove_liquidity_one_coin(
                meta_amount,
                CRV3_INDEX,
                0
            );
    }

    /// @notice Remove all assets from active Convex position
    /// @param _slippage Slippage control for invest function
    /// @dev slippage control only occurs when large amounts of credits are moved
    ///     out of a meta vault
    function divestAll(bool _slippage) internal returns (uint256) {
        if (Rewards(rewardContract).balanceOf(address(this)) == 0) {
            if (lpToken.balanceOf(address(this)) < 1E18) {
                return 0;
            }
        } else {
            Rewards(rewardContract).withdrawAllAndUnwrap(false);
        }
        uint256 minAmount;
        if (_slippage) {
            uint256 debt = VAULT.getStrategyDebt();
            uint256 slippage = baseSlippage;
            minAmount =
                (debt *
                    (PERCENTAGE_DECIMAL_FACTOR -
                        slippage *
                        (stopLossAttempts + 1))) /
                PERCENTAGE_DECIMAL_FACTOR;
            try
                ICurveMeta(metaPool).remove_liquidity_one_coin(
                    lpToken.balanceOf(address(this)),
                    CRV3_INDEX,
                    minAmount
                )
            returns (uint256 _amount) {
                return _amount;
            } catch Error(string memory reason) {
                emit LogStopLossErrorString(stopLossAttempts, reason);
                return 0;
            } catch (bytes memory lowLevelData) {
                emit LogStopLossErrorBytes(stopLossAttempts, lowLevelData);
                return 0;
            }
        } else {
            uint256 amount = ICurveMeta(metaPool).remove_liquidity_one_coin(
                lpToken.balanceOf(address(this)),
                CRV3_INDEX,
                minAmount
            );
            return amount;
        }
    }

    /// @notice Invest loose assets into current convex position
    /// @param _credit Amount available to invest
    function invest(uint256 _credit) internal returns (uint256) {
        uint256 amount = ICurveMeta(metaPool).add_liquidity([0, _credit], 0);

        uint256 ratio = curveValue();
        if (
            (amount * ratio) / PERCENTAGE_DECIMAL_FACTOR <
            ((_credit * (PERCENTAGE_DECIMAL_FACTOR - baseSlippage)) /
                PERCENTAGE_DECIMAL_FACTOR)
        ) {
            revert StrategyErrors.LTMinAmountExpected();
        }

        Booster(BOOSTER).deposit(pid, amount, true);
        return amount;
    }

    /// @notice Reports back any gains/losses that the strategy has made to the vault
    ///     and gets additional credit/pays back debt depending on credit availability
    function runHarvest() external {
        if (!keepers[msg.sender]) revert StrategyErrors.NotKeeper();
        if (stop) revert StrategyErrors.Stopped();
        (uint256 excessDebt, uint256 debtRatio) = VAULT.excessDebt(
            address(this)
        );
        uint256 profit;
        uint256 loss;
        uint256 debtRepayment;

        uint256 balance;
        bool emergency;

        // separate logic for emergency mode which needs implementation
        if (emergencyMode) {
            sellAllRewards();
            divestAll(false);
            emergency = true;
            debtRepayment = ASSET.balanceOf(address(this));
            uint256 debt = VAULT.getStrategyDebt();
            if (debt > debtRepayment) loss = debt - debtRepayment;
            else profit = debtRepayment - debt;
        } else {
            if (newMetaPool != address(0)) {
                sellAllRewards();
                divestAll(true);
                migratePool();
            }
            (profit, loss, debtRepayment, balance) = realisePnl(
                excessDebt,
                debtRatio
            );
        }
        uint256 credit = VAULT.report(profit, loss, debtRepayment, emergency);

        // invest any free funds in the strategy
        if (balance + credit > debtRepayment + INVESTMENT_BUFFER) {
            invest(balance + credit - debtRepayment);
        }

        emit Harvested(profit, loss, debtRepayment, excessDebt);
    }

    /// @notice Pulls out all funds into strategies base asset and stops
    ///     the strategy from being able to run harvest. Reports back
    ///     any gains/losses from this action to the vault
    function stopLoss() external returns (bool) {
        if (!keepers[msg.sender]) revert StrategyErrors.NotKeeper();
        if (stopLossAttempts == 0) sellAllRewards();
        if (divestAll(true) == 0) {
            stopLossAttempts += 1;
            return false;
        }
        uint256 debt = VAULT.getStrategyDebt();
        uint256 balance = ASSET.balanceOf(address(this));
        uint256 loss;
        uint256 profit;
        // we expect losses, but should account for a situation that
        //     produces gains
        if (debt > balance) {
            loss = debt - balance;
        } else {
            profit = balance - debt;
        }
        // We dont attempt to repay anything - follow up actions need
        //  to be taken to withdraw any assets from the strategy
        VAULT.report(profit, loss, 0, false);
        stop = true;
        stopLossAttempts = 0;
        return true;
    }

    /*//////////////////////////////////////////////////////////////
                           TRIGGERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Checks if the strategy should be harvested
    function canHarvest() external view returns (bool) {
        (bool active, uint256 totalDebt, uint256 lastReport) = VAULT
            .getStrategyData();

        // Should not trigger if strategy is not activated
        if (!active) return false;
        if (stop) return false;

        // Should trigger if hadn't been called in a while
        uint256 timeSinceLastHarvest = block.timestamp - lastReport;
        if (timeSinceLastHarvest > MAX_REPORT_DELAY) return true;

        // Check for profits and losses
        (uint256 assets, , ) = _estimatedTotalAssets(true);
        uint256 debt = totalDebt;
        (uint256 excessDebt, ) = VAULT.excessDebt(address(this));
        uint256 profit;
        if (assets > debt) {
            profit = assets - debt;
        } else {
            excessDebt += debt - assets;
        }
        profit += VAULT.creditAvailable();
        if (excessDebt > debtThreshold) return true;
        if (profit > profitThreshold && timeSinceLastHarvest > MIN_REPORT_DELAY)
            return true;

        return false;
    }

    /// @notice Check if stop loss needs to be triggered
    function canStopLoss() external view returns (bool) {
        if (stop) return false;
        IStop _stopLoss = IStop(stopLossLogic);
        if (address(_stopLoss) == address(0)) return false;
        return _stopLoss.stopLossCheck();
    }

    /*//////////////////////////////////////////////////////////////
                           POOL LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Prepare the strategy for migration to a new convex pool
    /// @param _newPid pid of the convex reward pool
    /// @param _newMetaPool meta pool specified in cased where pool != lp token
    function setPool(uint256 _newPid, address _newMetaPool) external {
        if (msg.sender != owner) revert StrategyErrors.NotOwner();
        if (_newPid == pid) revert StrategyErrors.SamePid();

        // remove old approval
        CRV_3POOL_TOKEN.approve(metaPool, 0);
        lpToken.approve(BOOSTER, 0);

        (address lp, , , address _reward, , bool shutdown) = Booster(BOOSTER)
            .poolInfo(_newPid);
        if (shutdown) revert StrategyErrors.ConvexShutdown();
        ERC20 _newLpToken = ERC20(lp);
        newLpToken = _newLpToken;
        newRewardContract = _reward;
        newPid = _newPid;
        newMetaPool = _newMetaPool;

        // add new approval
        if (CRV_3POOL_TOKEN.allowance(address(this), _newMetaPool) == 0) {
            CRV_3POOL_TOKEN.approve(_newMetaPool, type(uint256).max);
        }
        if (_newLpToken.allowance(address(this), BOOSTER) == 0) {
            _newLpToken.approve(BOOSTER, type(uint256).max);
        }
        emit LogSetNewPool(_newPid, lp, _reward, _newMetaPool);
    }

    /// @notice Migrate investment to a new convex pool
    function migratePool() internal {
        uint256 _newPid = newPid;
        address _newMetaPool = newMetaPool;
        ERC20 _newLpToken = newLpToken;
        address _newReward = newRewardContract;

        pid = _newPid;
        metaPool = _newMetaPool;
        lpToken = _newLpToken;
        rewardContract = _newReward;

        newMetaPool = address(0);
        newPid = 0;
        newLpToken = ERC20(address(0));
        newRewardContract = address(0);

        emit LogChangePool(
            _newPid,
            address(_newLpToken),
            _newReward,
            _newMetaPool
        );
    }

    /*//////////////////////////////////////////////////////////////
                          HELPER FUNCTIONS 
    //////////////////////////////////////////////////////////////*/

    /// @notice Generate paths for swaps
    /// @param _from starting token
    /// @param _base swapping for ETH
    function _getPath(address _from, bool _base)
        internal
        view
        returns (address[] memory)
    {
        address[] memory path;
        if (_base) {
            path = new address[](2);
            path[0] = _from;
            path[1] = WETH;
        } else {
            path = new address[](4);
            path[0] = _from;
            path[1] = WETH;
            path[2] = USDC;
            path[3] = address(ASSET);
        }
        return path;
    }

    /// @notice Get ratio between meta pool tokens
    function curveValue() internal view returns (uint256) {
        uint256 three_pool_vp = ICurve3Pool(CRV_3POOL).get_virtual_price();
        uint256 meta_pool_vp = ICurveMeta(metaPool).get_virtual_price();
        return (meta_pool_vp * PERCENTAGE_DECIMAL_FACTOR) / three_pool_vp;
    }

    /// @notice sweep unwanted tokens from the contract
    /// @param _recipient of the token
    /// @param _token address of
    function sweep(address _recipient, address _token) external {
        if (msg.sender != owner) revert StrategyErrors.NotOwner();
        if (address(ASSET) == _token) revert StrategyErrors.BaseAsset();
        if (address(lpToken) == _token) revert StrategyErrors.LpToken();
        if (address(rewardContract) == _token)
            revert StrategyErrors.ConvexToken();
        uint256 _amount = ERC20(_token).balanceOf(address(this));
        ERC20(_token).transfer(_recipient, _amount);
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

/// Curve 3pool interface
interface ICurve3Pool {
    function get_virtual_price() external view returns (uint256);

    function add_liquidity(
        uint256[3] calldata _deposit_amounts,
        uint256 _min_mint_amount
    ) external;

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external;

    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// Curve metapool interface
interface ICurveMeta {
    function get_virtual_price() external view returns (uint256);

    function calc_withdraw_one_coin(uint256 _tokenAmount, int128 i)
        external
        view
        returns (uint256);

    function calc_token_amount(uint256[2] calldata inAmounts, bool deposit)
        external
        view
        returns (uint256);

    function add_liquidity(
        uint256[2] calldata uamounts,
        uint256 min_mint_amount
    ) external returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _tokenAmount,
        int128 i,
        uint256 min_uamount
    ) external returns (uint256);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

/// Stop loss logic interface
interface IStop {
    function stopLossCheck() external view returns (bool);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

interface IStrategy {
    function asset() external view returns (address);

    function vault() external view returns (address);

    function isActive() external view returns (bool);

    function estimatedTotalAssets() external view returns (uint256);

    function withdraw(uint256 _amount) external returns (uint256, uint256);

    function canHarvest() external view returns (bool);

    function runHarvest() external;

    function canStopLoss() external view returns (bool);

    function stopLoss() external returns (bool);

    function getMetaPool() external view returns (address);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;
import {ERC20} from "ERC20.sol";
import {IStrategy} from "IStrategy.sol";

/// GVault interface
interface IGVault {
    function asset() external view returns (ERC20);

    function excessDebt(address _strategy)
        external
        view
        returns (uint256, uint256);

    function getStrategyDebt() external view returns (uint256);

    function creditAvailable() external view returns (uint256);

    function report(
        uint256 _gain,
        uint256 _loss,
        uint256 _debtRepayment,
        bool _emergency
    ) external returns (uint256);

    function getStrategyData()
        external
        view
        returns (
            bool,
            uint256,
            uint256
        );
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount)
        public
        virtual
        returns (bool)
    {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount)
        public
        virtual
        returns (bool)
    {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max)
            allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            PERMIT_TYPEHASH,
                            owner,
                            spender,
                            value,
                            nonces[owner]++,
                            deadline
                        )
                    )
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

            require(
                recoveredAddress != address(0) && recoveredAddress == owner,
                "INVALID_SIGNER"
            );

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return
            block.chainid == INITIAL_CHAIN_ID
                ? INITIAL_DOMAIN_SEPARATOR
                : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}