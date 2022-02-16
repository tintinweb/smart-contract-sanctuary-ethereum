// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.4;

import "../BaseStrategy.sol";
import "../interfaces/IERC20Detailed.sol";
import "../interfaces/ICurve.sol";
import "../interfaces/UniSwap/IUni.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

interface Booster {
    struct PoolInfo {
        address lptoken;
        address token;
        address gauge;
        address crvRewards;
        address stash;
        bool shutdown;
    }

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

    // deposit lp tokens and stake
    function deposit(
        uint256 _pid,
        uint256 _amount,
        bool _stake
    ) external returns (bool);
}

interface Rewards {
    function balanceOf(address account) external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function withdrawAndUnwrap(uint256 amount, bool claim) external returns (bool);

    function withdrawAllAndUnwrap(bool claim) external;

    function getReward() external returns (bool);
}

contract StableConvexXPool is BaseStrategy {
    using SafeERC20 for IERC20;

    address public constant BOOSTER = address(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);

    address public constant CVX = address(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
    address public constant CRV = address(0xD533a949740bb3306d119CC777fa900bA034cd52);
    address public constant WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address public constant DAI = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    address public constant USDC = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address public constant USDT = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);

    address public constant CRV_3POOL = address(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);
    IERC20 public constant CRV_3POOL_TOKEN = IERC20(address(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490));

    address public constant UNISWAP = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public constant SUSHISWAP = address(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);

    int128 public constant CRV3_INDEX = 1;
    uint256 public constant CRV_METAPOOL_LEN = 2;
    uint256 public constant CRV_3POOL_LEN = 3;

    uint256 public constant TO_ETH = 0;
    uint256 public constant TO_WANT = 1;

    int128 public immutable WANT_INDEX;

    address public curve;
    IERC20 public lpToken;
    uint256 public pId;
    address public rewardContract;

    uint256 public newPId;
    address public newCurve;
    IERC20 public newLPToken;
    address public newRewardContract;

    address[] public dex;

    uint256 public slippageRecover = 3;
    uint256 public slippage = 10;

    event LogSetNewPool(uint256 indexed newPId, address newLPToken, address newRewardContract, address newCurve);
    event LogSwitchDex(uint256 indexed id, address newDex);
    event LogSetNewDex(uint256 indexed id, address newDex);
    event LogChangePool(uint256 indexed newPId, address newLPToken, address newRewardContract, address newCurve);
    event LogSetNewSlippageRecover(uint256 slippage);
    event LogSetNewSlippage(uint256 slippage);

    constructor(address _vault, int128 wantIndex) BaseStrategy(_vault) {
        profitFactor = 1000;
        uint8 decimals = IERC20Detailed(address(want)).decimals();
        debtThreshold = 1_00_000 * (uint256(10)**decimals);
        dex = new address[](2);
        // _switchDex(0, UNISWAP);
        // _switchDex(1, SUSHISWAP);

        // require(
        //     (address(want) == DAI && wantIndex == 0) ||
        //         (address(want) == USDC && wantIndex == 1) ||
        //         (address(want) == USDT && wantIndex == 2),
        //     "want and wantIndex does not match"
        // );
        WANT_INDEX = wantIndex;

        // want.safeApprove(CRV_3POOL, type(uint256).max);
    }

    function setNewPool(uint256 _newPId, address _newCurve) external onlyAuthorized {
        require(_newPId != pId, "setMetaPool: same id");
        (address lp, , , address reward, , bool shutdown) = Booster(BOOSTER).poolInfo(_newPId);
        require(!shutdown, "setMetaPool: pool is shutdown");
        IERC20 _newLPToken = IERC20(lp);
        newLPToken = _newLPToken;
        newRewardContract = reward;
        newPId = _newPId;
        newCurve = _newCurve;
        if (CRV_3POOL_TOKEN.allowance(address(this), newCurve) == 0) {
            CRV_3POOL_TOKEN.safeApprove(newCurve, type(uint256).max);
        }
        if (_newLPToken.allowance(address(this), BOOSTER) == 0) {
            _newLPToken.safeApprove(BOOSTER, type(uint256).max);
        }

        emit LogSetNewPool(_newPId, lp, reward, _newCurve);
    }

    function switchDex(uint256 id, address newDex) external onlyAuthorized {
        _switchDex(id, newDex);
        emit LogSetNewDex(id, newDex);
    }

    function setSlippageRecover(uint256 _slippage) external onlyAuthorized {
        slippageRecover = _slippage;
        emit LogSetNewSlippageRecover(_slippage);
    }

    function setSlippage(uint256 _slippage) external onlyAuthorized {
        slippage = _slippage;
        emit LogSetNewSlippage(_slippage);
    }

    function forceWithdraw() external onlyAuthorized {
        _withdrawAll();
    }

    function _switchDex(uint256 id, address newDex) private {
        dex[id] = newDex;

        IERC20 token;
        if (id == 0) {
            token = IERC20(CRV);
        } else {
            token = IERC20(CVX);
        }

        if (token.allowance(address(this), newDex) == 0) {
            token.approve(newDex, type(uint256).max);
        }
        emit LogSwitchDex(id, newDex);
    }

    function name() external pure override returns (string memory) {
        return "StrategyConvexXPool";
    }

    function estimatedTotalAssets() public view override returns (uint256 estimated) {
        estimated = _estimatedTotalAssets(true);
    }

    function _estimatedTotalAssets(bool includeReward) private view returns (uint256 estimated) {
        if (rewardContract != address(0)) {
            uint256 lpAmount = Rewards(rewardContract).balanceOf(address(this));
            if (lpAmount > 0) {
                uint256 crv3Amount = ICurveMetaPool(curve).calc_withdraw_one_coin(lpAmount, CRV3_INDEX);
                estimated = ICurve3Pool(CRV_3POOL).calc_withdraw_one_coin(crv3Amount, WANT_INDEX);
            }
            if (includeReward) {
                estimated += _claimableBasic(TO_WANT);
            }
        }
        estimated += want.balanceOf(address(this));
    }

    uint256 constant totalCliffs = 100;
    uint256 constant maxSupply = 1e8 * 1e18;
    uint256 constant reductionPerCliff = 1e5 * 1e18;

    function _claimableBasic(uint256 toIndex) private view returns (uint256) {
        uint256 crv = Rewards(rewardContract).earned(address(this));

        // calculations pulled directly from CVX's contract for minting CVX per CRV claimed
        uint256 supply = IERC20(CVX).totalSupply();
        uint256 cvx;

        uint256 cliff = supply / reductionPerCliff;
        // mint if below total cliffs
        if (cliff < totalCliffs) {
            // for reduction% take inverse of current cliff
            uint256 reduction = totalCliffs - cliff;
            // reduce
            cvx = (crv * reduction) / totalCliffs;

            // supply cap check
            uint256 amtTillMax = maxSupply - supply;
            if (cvx > amtTillMax) {
                cvx = amtTillMax;
            }
        }

        uint256 crvValue;
        if (crv > 0) {
            uint256[] memory crvSwap = IUni(dex[0]).getAmountsOut(crv, _getPath(CRV, toIndex));
            crvValue = crvSwap[crvSwap.length - 1];
        }

        uint256 cvxValue;
        if (cvx > 0) {
            uint256[] memory cvxSwap = IUni(dex[1]).getAmountsOut(cvx, _getPath(CVX, toIndex));
            cvxValue = cvxSwap[cvxSwap.length - 1];
        }

        return crvValue + cvxValue;
    }

    function _getPath(address from, uint256 toIndex) private view returns (address[] memory path) {
        if (toIndex == TO_ETH) {
            path = new address[](2);
            path[0] = from;
            path[1] = WETH;
        }

        if (toIndex == TO_WANT) {
            path = new address[](3);
            path[0] = from;
            path[1] = WETH;
            path[2] = address(want);
        }
    }

    function adjustPosition(uint256 _debtOutstanding) internal override {
        _debtOutstanding;
        if (emergencyExit) return;
        uint256 wantBal = want.balanceOf(address(this));
        if (wantBal > 0) {
            uint256[CRV_3POOL_LEN] memory amountsCRV3;
            amountsCRV3[uint256(int256(WANT_INDEX))] = wantBal;

            ICurve3Deposit(CRV_3POOL).add_liquidity(amountsCRV3, 0);

            uint256 crv3Bal = CRV_3POOL_TOKEN.balanceOf(address(this));
            if (crv3Bal > 0) {
                uint256[CRV_METAPOOL_LEN] memory amountsMP;
                amountsMP[uint256(int256(CRV3_INDEX))] = crv3Bal;
                ICurveMetaPool _meta = ICurveMetaPool(curve);

                uint256 vp = _meta.get_virtual_price();
                uint256 minAmount = (wantBal * (1E36 / 10**IERC20Detailed(address(want)).decimals())) / vp;

                minAmount = minAmount - (minAmount * slippage) / 10000;
                _meta.add_liquidity(amountsMP, minAmount);

                uint256 lpBal = lpToken.balanceOf(address(this));
                if (lpBal > 0) {
                    Booster(BOOSTER).deposit(pId, lpBal, true);
                }
            }
        }
    }

    function liquidatePosition(uint256 _amountNeeded)
        internal
        override
        returns (uint256 _liquidatedAmount, uint256 _loss)
    {
        uint256 _wantBal = want.balanceOf(address(this));
        if (_wantBal < _amountNeeded) {
            _liquidatedAmount = _withdrawSome(_amountNeeded - _wantBal);
            _liquidatedAmount = _liquidatedAmount + _wantBal;
            _liquidatedAmount = Math.min(_liquidatedAmount, _amountNeeded);
            if (_liquidatedAmount < _amountNeeded) {
                _loss = _amountNeeded - _liquidatedAmount;
            }
        } else {
            _liquidatedAmount = _amountNeeded;
        }
    }

    function _withdrawSome(uint256 _amount) private returns (uint256) {
        uint256 lpAmount = wantToLp(_amount);
        lpAmount = lpAmount + (lpAmount * slippageRecover) / 10000;
        uint256 poolBal = Rewards(rewardContract).balanceOf(address(this));

        if (poolBal < lpAmount) {
            lpAmount = poolBal;
        }

        if (poolBal == 0) return 0;

        uint256 before = want.balanceOf(address(this));

        // withdraw from convex
        Rewards(rewardContract).withdrawAndUnwrap(lpAmount, false);

        // remove liquidity from metapool
        lpAmount = lpToken.balanceOf(address(this));
        ICurveMetaPool(curve).remove_liquidity_one_coin(lpAmount, CRV3_INDEX, 0);

        // remove liquidity from 3pool
        lpAmount = CRV_3POOL_TOKEN.balanceOf(address(this));

        uint256 minAmount = _amount - (_amount * slippage) / 10000;
        ICurve3Deposit(CRV_3POOL).remove_liquidity_one_coin(lpAmount, WANT_INDEX, minAmount);

        return want.balanceOf(address(this)) - before;
    }

    function wantToLp(uint256 amount) private view returns (uint256 lpAmount) {
        uint256[CRV_3POOL_LEN] memory amountsCRV3;
        amountsCRV3[uint256(int256(WANT_INDEX))] = amount;

        uint256 crv3Amount = ICurve3Pool(CRV_3POOL).calc_token_amount(amountsCRV3, false);

        uint256[CRV_METAPOOL_LEN] memory amountsMP;
        amountsMP[uint256(int256(CRV3_INDEX))] = crv3Amount;

        lpAmount = ICurveMetaPool(curve).calc_token_amount(amountsMP, false);
    }

    function prepareReturn(uint256 _debtOutstanding)
        internal
        override
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _debtPayment
        )
    {
        uint256 total;
        uint256 wantBal;
        uint256 beforeTotal;
        uint256 debt = vault.strategies(address(this)).totalDebt;
        if (curve == address(0)) {
            // invest into strategy first time
            _changePool();
            return (0, 0, 0);
        } else if (newCurve != address(0)) {
            beforeTotal = _estimatedTotalAssets(true);
            _withdrawAll();
            _changePool();
            wantBal = want.balanceOf(address(this));
            total = wantBal;

            if (beforeTotal < debt) {
                total = Math.max(beforeTotal, total);
            } else if (beforeTotal > debt && total < debt) {
                total = debt;
            }
        } else {
            Rewards(rewardContract).getReward();
            _sellBasic();
            total = _estimatedTotalAssets(false);
            wantBal = want.balanceOf(address(this));
        }
        _debtPayment = _debtOutstanding;
        if (total > debt) {
            _profit = total - debt;
            uint256 amountToFree = _profit + _debtPayment;
            if (amountToFree > 0 && wantBal < amountToFree) {
                _withdrawSome(amountToFree - wantBal);
                total = _estimatedTotalAssets(false);
                wantBal = want.balanceOf(address(this));
                if (total <= debt) {
                    _profit = 0;
                    _loss = debt - total;
                } else {
                    _profit = total - debt;
                }
                amountToFree = _profit + _debtPayment;
                if (wantBal < amountToFree) {
                    if (_profit > wantBal) {
                        _profit = wantBal;
                        _debtPayment = 0;
                    } else {
                        _debtPayment = Math.min(wantBal - _profit, _debtPayment);
                    }
                }
            }
        } else {
            _loss = debt - total;
            uint256 amountToFree = _debtPayment;
            if (amountToFree > 0 && wantBal < amountToFree) {
                _withdrawSome(amountToFree - wantBal);
                wantBal = want.balanceOf(address(this));
                if (wantBal < amountToFree) {
                    _debtPayment = wantBal;
                }
            }
        }
    }

    function _changePool() private {
        uint256 _newPId = newPId;
        address _newCurve = newCurve;
        IERC20 _newLPToken = newLPToken;
        address _newReward = newRewardContract;

        pId = _newPId;
        curve = _newCurve;
        lpToken = _newLPToken;
        rewardContract = _newReward;

        newCurve = address(0);
        newPId = 0;
        newLPToken = IERC20(address(0));
        newRewardContract = address(0);

        emit LogChangePool(_newPId, address(_newLPToken), _newReward, _newCurve);
    }

    function _sellBasic() private {
        uint256 crv = IERC20(CRV).balanceOf(address(this));
        if (crv > 0) {
            IUni(dex[0]).swapExactTokensForTokens(
                crv,
                uint256(0),
                _getPath(CRV, TO_WANT),
                address(this),
                block.timestamp
            );
        }
        uint256 cvx = IERC20(CVX).balanceOf(address(this));
        if (cvx > 0) {
            IUni(dex[1]).swapExactTokensForTokens(
                cvx,
                uint256(0),
                _getPath(CVX, TO_WANT),
                address(this),
                block.timestamp
            );
        }
    }

    function tendTrigger(uint256 callCost) public pure override returns (bool) {
        callCost;
        return false;
    }

    function prepareMigration(address _newStrategy) internal override {
        _newStrategy;
        _withdrawAll();
    }

    function _withdrawAll() private {
        Rewards(rewardContract).withdrawAllAndUnwrap(true);
        _sellBasic();

        // remove liquidity from metapool
        uint256 lpAmount = lpToken.balanceOf(address(this));
        ICurveMetaPool _meta = ICurveMetaPool(curve);
        uint256 vp = _meta.get_virtual_price();
        _meta.remove_liquidity_one_coin(lpAmount, CRV3_INDEX, 0);

        // calc min amounts
        uint256 minAmount = (lpAmount * vp) / 1E18;
        minAmount =
            (minAmount - (minAmount * slippage) / 10000) /
            (1E18 / 10**IERC20Detailed(address(want)).decimals());

        // remove liquidity from 3pool
        lpAmount = CRV_3POOL_TOKEN.balanceOf(address(this));
        ICurve3Deposit(CRV_3POOL).remove_liquidity_one_coin(lpAmount, WANT_INDEX, minAmount);
    }

    function protectedTokens() internal pure override returns (address[] memory) {
        address[] memory protected = new address[](2);
        protected[0] = CRV;
        protected[1] = CVX;
        return protected;
    }

    function harvestTrigger(uint256 callCost) public view override returns (bool) {
        StrategyParams memory params = vault.strategies(address(this));

        if (params.activation == 0) return false;

        if (block.timestamp - params.lastReport < minReportDelay) return false;

        if (block.timestamp - params.lastReport >= maxReportDelay) return true;

        uint256 outstanding = vault.debtOutstanding();
        if (outstanding > debtThreshold) return true;

        uint256 total = estimatedTotalAssets();
        if (total + debtThreshold < params.totalDebt) return true;

        uint256 profit;
        if (total > params.totalDebt) {
            profit = total - params.totalDebt;
        }

        return (profitFactor * callCost < _wantToETH(profit));
    }

    function _wantToETH(uint256 wantAmount) private view returns (uint256) {
        if (wantAmount > 0) {
            address[] memory path = new address[](2);
            path[0] = address(want);
            path[1] = WETH;
            uint256[] memory amounts = IUni(dex[0]).getAmountsOut(wantAmount, path);
            return amounts[1];
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

struct StrategyParams {
    uint256 activation;
    uint256 debtRatio;
    uint256 minDebtPerHarvest;
    uint256 maxDebtPerHarvest;
    uint256 lastReport;
    uint256 totalDebt;
    uint256 totalGain;
    uint256 totalLoss;
}

interface VaultAPI {
    function decimals() external view returns (uint256);

    function token() external view returns (address);

    function vaultAdapter() external view returns (address);

    function strategies(address _strategy) external view returns (StrategyParams memory);

    /**
     * View how much the Vault would increase this Strategy's borrow limit,
     * based on its present performance (since its last report). Can be used to
     * determine expectedReturn in your Strategy.
     */
    function creditAvailable() external view returns (uint256);

    /**
     * View how much the Vault would like to pull back from the Strategy,
     * based on its present performance (since its last report). Can be used to
     * determine expectedReturn in your Strategy.
     */
    function debtOutstanding() external view returns (uint256);

    /**
     * View how much the Vault expect this Strategy to return at the current
     * block, based on its present performance (since its last report). Can be
     * used to determine expectedReturn in your Strategy.
     */
    function expectedReturn() external view returns (uint256);

    /**
     * This is the main contact point where the Strategy interacts with the
     * Vault. It is critical that this call is handled as intended by the
     * Strategy. Therefore, this function will be called by BaseStrategy to
     * make sure the integration is correct.
     */
    function report(
        uint256 _gain,
        uint256 _loss,
        uint256 _debtPayment
    ) external returns (uint256);

    /**
     * This function should only be used in the scenario where the Strategy is
     * being retired but no migration of the positions are possible, or in the
     * extreme scenario that the Strategy needs to be put into "Emergency Exit"
     * mode in order for it to exit as quickly as possible. The latter scenario
     * could be for any reason that is considered "critical" that the Strategy
     * exits its position as fast as possible, such as a sudden change in
     * market conditions leading to losses, or an imminent failure in an
     * external dependency.
     */
    function revokeStrategy() external;

    function governance() external view returns (address);
}

/**
 * This interface is here for the keeper bot to use.
 */
interface StrategyAPI {
    function name() external view returns (string memory);

    function vault() external view returns (address);

    function want() external view returns (address);

    function keeper() external view returns (address);

    function isActive() external view returns (bool);

    function estimatedTotalAssets() external view returns (uint256);

    function expectedReturn() external view returns (uint256);

    function tendTrigger(uint256 callCost) external view returns (bool);

    function tend() external;

    function harvestTrigger(uint256 callCost) external view returns (bool);

    function harvest() external;

    event Harvested(uint256 profit, uint256 loss, uint256 debtPayment, uint256 debtOutstanding);
}

/**
 * @title Yearn Base Strategy
 * @author yearn.finance
 * @notice
 *  BaseStrategy implements all of the required functionality to interoperate
 *  closely with the Vault contract. This contract should be inherited and the
 *  abstract methods implemented to adapt the Strategy to the particular needs
 *  it has to create a return.
 *
 *  Of special interest is the relationship between `harvest()` and
 *  `vault.report()'. `harvest()` may be called simply because enough time has
 *  elapsed since the last report, and not because any funds need to be moved
 *  or positions adjusted. This is critical so that the Vault may maintain an
 *  accurate picture of the Strategy's performance. See  `vault.report()`,
 *  `harvest()`, and `harvestTrigger()` for further details.
 */
abstract contract BaseStrategy {
    using SafeERC20 for IERC20;

    VaultAPI public vault;
    address public rewards;
    address public keeper;

    IERC20 public want;

    // So indexers can keep track of this
    event Harvested(uint256 profit, uint256 loss, uint256 debtPayment, uint256 debtOutstanding);
    event UpdatedKeeper(address newKeeper);
    event UpdatedRewards(address rewards);
    event UpdatedMinReportDelay(uint256 delay);
    event UpdatedMaxReportDelay(uint256 delay);
    event UpdatedProfitFactor(uint256 profitFactor);
    event UpdatedDebtThreshold(uint256 debtThreshold);
    event EmergencyExitEnabled();

    // The minimum number of seconds between harvest calls. See
    // `setMinReportDelay()` for more details.
    uint256 public minReportDelay;

    // The maximum number of seconds between harvest calls. See
    // `setMaxReportDelay()` for more details.
    uint256 public maxReportDelay;

    // The minimum multiple that `callCost` must be above the credit/profit to
    // be "justifiable". See `setProfitFactor()` for more details.
    uint256 public profitFactor;

    // Use this to adjust the threshold at which running a debt causes a
    // harvest trigger. See `setDebtThreshold()` for more details.
    uint256 public debtThreshold;

    // See note on `setEmergencyExit()`.
    bool public emergencyExit;

    // modifiers
    modifier onlyAuthorized() {
        require(msg.sender == keeper || msg.sender == owner(), "!authorized");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner(), "!authorized");
        _;
    }

    constructor(address _vault) {
        _initialize(_vault, msg.sender, msg.sender);
    }

    function name() external view virtual returns (string memory);

    /**
     * @notice
     *  Initializes the Strategy, this is called only once, when the
     *  contract is deployed.
     * @param _vault The address of the Vault responsible for this Strategy.
     */
    function _initialize(
        address _vault,
        address _rewards,
        address _keeper
    ) internal {
        require(address(want) == address(0), "Strategy already initialized");

        vault = VaultAPI(_vault);
        want = IERC20(vault.token());
        want.safeApprove(_vault, type(uint256).max); // Give Vault unlimited access (might save gas)
        rewards = _rewards;
        keeper = _keeper;

        // initialize variables
        minReportDelay = 0;
        maxReportDelay = 86400;
        profitFactor = 100;
        debtThreshold = 0;
    }

    function setKeeper(address _keeper) external onlyOwner {
        require(_keeper != address(0));
        keeper = _keeper;
        emit UpdatedKeeper(_keeper);
    }

    /**
     * @notice
     *  Used to change `minReportDelay`. `minReportDelay` is the minimum number
     *  of blocks that should pass for `harvest()` to be called.
     *
     *  For external keepers (such as the Keep3r network), this is the minimum
     *  time between jobs to wait. (see `harvestTrigger()`
     *  for more details.)
     *
     * @param _delay The minimum number of seconds to wait between harvests.
     */
    function setMinReportDelay(uint256 _delay) external onlyAuthorized {
        minReportDelay = _delay;
        emit UpdatedMinReportDelay(_delay);
    }

    /**
     * @notice
     *  Used to change `maxReportDelay`. `maxReportDelay` is the maximum number
     *  of blocks that should pass for `harvest()` to be called.
     *
     *  For external keepers (such as the Keep3r network), this is the maximum
     *  time between jobs to wait. (see `harvestTrigger()`
     *  for more details.)
     *
     * @param _delay The maximum number of seconds to wait between harvests.
     */
    function setMaxReportDelay(uint256 _delay) external onlyAuthorized {
        maxReportDelay = _delay;
        emit UpdatedMaxReportDelay(_delay);
    }

    /**
     * @notice
     *  Used to change `profitFactor`. `profitFactor` is used to determine
     *  if it's worthwhile to harvest, given gas costs. (See `harvestTrigger()`
     *  for more details.)
     *
     * @param _profitFactor A ratio to multiply anticipated
     * `harvest()` gas cost against.
     */
    function setProfitFactor(uint256 _profitFactor) external onlyAuthorized {
        profitFactor = _profitFactor;
        emit UpdatedProfitFactor(_profitFactor);
    }

    /**
     * @notice
     *  Sets how far the Strategy can go into loss without a harvest and report
     *  being required.
     *
     *  By default this is 0, meaning any losses would cause a harvest which
     *  will subsequently report the loss to the Vault for tracking. (See
     *  `harvestTrigger()` for more details.)
     *
     * @param _debtThreshold How big of a loss this Strategy may carry without
     * being required to report to the Vault.
     */
    function setDebtThreshold(uint256 _debtThreshold) external onlyAuthorized {
        debtThreshold = _debtThreshold;
        emit UpdatedDebtThreshold(_debtThreshold);
    }

    /**
     * Resolve owner address from Vault contract, used to make assertions
     * on protected functions in the Strategy.
     */
    function owner() internal view returns (address) {
        return vault.governance();
    }

    /**
     * @notice
     *  Provide an accurate estimate for the total amount of assets
     *  (principle + return) that this Strategy is currently managing,
     *  denominated in terms of `want` tokens.
     *
     *  This total should be "realizable" e.g. the total value that could
     *  *actually* be obtained from this Strategy if it were to divest its
     *  entire position based on current on-chain conditions.
     * @dev
     *  Care must be taken in using this function, since it relies on external
     *  systems, which could be manipulated by the attacker to give an inflated
     *  (or reduced) value produced by this function, based on current on-chain
     *  conditions (e.g. this function is possible to influence through
     *  flashloan attacks, oracle manipulations, or other DeFi attack
     *  mechanisms).
     *
     *  It is up to owner to use this function to correctly order this
     *  Strategy relative to its peers in the withdrawal queue to minimize
     *  losses for the Vault based on sudden withdrawals. This value should be
     *  higher than the total debt of the Strategy and higher than its expected
     *  value to be "safe".
     * @return The estimated total assets in this Strategy.
     */
    function estimatedTotalAssets() public view virtual returns (uint256);

    /*
     * @notice
     *  Provide an indication of whether this strategy is currently "active"
     *  in that it is managing an active position, or will manage a position in
     *  the future. This should correlate to `harvest()` activity, so that Harvest
     *  events can be tracked externally by indexing agents.
     * @return True if the strategy is actively managing a position.
     */
    function isActive() public view returns (bool) {
        return vault.strategies(address(this)).debtRatio > 0 || estimatedTotalAssets() > 0;
    }

    /**
     * Perform any Strategy unwinding or other calls necessary to capture the
     * "free return" this Strategy has generated since the last time its core
     * position(s) were adjusted. Examples include unwrapping extra rewards.
     * This call is only used during "normal operation" of a Strategy, and
     * should be optimized to minimize losses as much as possible.
     *
     * This method returns any realized profits and/or realized losses
     * incurred, and should return the total amounts of profits/losses/debt
     * payments (in `want` tokens) for the Vault's accounting (e.g.
     * `want.balanceOf(this) >= _debtPayment + _profit - _loss`).
     *
     * `_debtOutstanding` will be 0 if the Strategy is not past the configured
     * debt limit, otherwise its value will be how far past the debt limit
     * the Strategy is. The Strategy's debt limit is configured in the Vault.
     *
     * NOTE: `_debtPayment` should be less than or equal to `_debtOutstanding`.
     *       It is okay for it to be less than `_debtOutstanding`, as that
     *       should only used as a guide for how much is left to pay back.
     *       Payments should be made to minimize loss from slippage, debt,
     *       withdrawal fees, etc.
     *
     * See `vault.debtOutstanding()`.
     */
    function prepareReturn(uint256 _debtOutstanding)
        internal
        virtual
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _debtPayment
        );

    /**
     * Perform any adjustments to the core position(s) of this Strategy given
     * what change the Vault made in the "investable capital" available to the
     * Strategy. Note that all "free capital" in the Strategy after the report
     * was made is available for reinvestment. Also note that this number
     * could be 0, and you should handle that scenario accordingly.
     *
     * See comments regarding `_debtOutstanding` on `prepareReturn()`.
     */
    function adjustPosition(uint256 _debtOutstanding) internal virtual;

    /**
     * Liquidate up to `_amountNeeded` of `want` of this strategy's positions,
     * irregardless of slippage. Any excess will be re-invested with `adjustPosition()`.
     * This function should return the amount of `want` tokens made available by the
     * liquidation. If there is a difference between them, `_loss` indicates whether the
     * difference is due to a realized loss, or if there is some other sitution at play
     * (e.g. locked funds) where the amount made available is less than what is needed.
     * This function is used during emergency exit instead of `prepareReturn()` to
     * liquidate all of the Strategy's positions back to the Vault.
     *
     * NOTE: The invariant `_liquidatedAmount + _loss <= _amountNeeded` should always be maintained
     */
    function liquidatePosition(uint256 _amountNeeded)
        internal
        virtual
        returns (uint256 _liquidatedAmount, uint256 _loss);

    /**
     * @notice
     *  Provide a signal to the keeper that `tend()` should be called. The
     *  keeper will provide the estimated gas cost that they would pay to call
     *  `tend()`, and this function should use that estimate to make a
     *  determination if calling it is "worth it" for the keeper. This is not
     *  the only consideration into issuing this trigger, for example if the
     *  position would be negatively affected if `tend()` is not called
     *  shortly, then this can return `true` even if the keeper might be
     *  "at a loss" (keepers are always reimbursed by Yearn).
     * @dev
     *  `callCost` must be priced in terms of `want`.
     *
     *  This call and `harvestTrigger()` should never return `true` at the same
     *  time.
     * @param callCost The keeper's estimated cast cost to call `tend()`.
     * @return `true` if `tend()` should be called, `false` otherwise.
     */
    function tendTrigger(uint256 callCost) public view virtual returns (bool);

    /**
     * @notice
     *  Adjust the Strategy's position. The purpose of tending isn't to
     *  realize gains, but to maximize yield by reinvesting any returns.
     *
     *  See comments on `adjustPosition()`.
     *
     */
    function tend() external onlyAuthorized {
        // Don't take profits with this call, but adjust for better gains
        adjustPosition(vault.debtOutstanding());
    }

    /**
     * @notice
     *  Provide a signal to the keeper that `harvest()` should be called. The
     *  keeper will provide the estimated gas cost that they would pay to call
     *  `harvest()`, and this function should use that estimate to make a
     *  determination if calling it is "worth it" for the keeper. This is not
     *  the only consideration into issuing this trigger, for example if the
     *  position would be negatively affected if `harvest()` is not called
     *  shortly, then this can return `true` even if the keeper might be "at a
     *  loss" (keepers are always reimbursed by Yearn).
     * @dev
     *  `callCost` must be priced in terms of `want`.
     *
     *  This call and `tendTrigger` should never return `true` at the
     *  same time.
     *
     *  See `min/maxReportDelay`, `profitFactor`, `debtThreshold`
     *  -controlled parameters that will influence whether this call
     *  returns `true` or not. These parameters will be used in conjunction
     *  with the parameters reported to the Vault (see `params`) to determine
     *  if calling `harvest()` is merited.
     *
     *  It is expected that an external system will check `harvestTrigger()`.
     *  This could be a script run off a desktop or cloud bot (e.g.
     *  https://github.com/iearn-finance/yearn-vaults/blob/master/scripts/keep.py),
     *  or via an integration with the Keep3r network (e.g.
     *  https://github.com/Macarse/GenericKeep3rV2/blob/master/contracts/keep3r/GenericKeep3rV2.sol).
     * @param callCost The keeper's estimated cast cost to call `harvest()`.
     * @return `true` if `harvest()` should be called, `false` otherwise.
     */
    function harvestTrigger(uint256 callCost) public view virtual returns (bool) {
        StrategyParams memory params = vault.strategies(address(this));

        // Should not trigger if Strategy is not activated
        if (params.activation == 0) return false;

        // Should not trigger if we haven't waited long enough since previous harvest
        if (block.timestamp - params.lastReport < minReportDelay) return false;

        // Should trigger if hasn't been called in a while
        if (block.timestamp - params.lastReport >= maxReportDelay) return true;

        // If some amount is owed, pay it back
        // NOTE: Since debt is based on deposits, it makes sense to guard against large
        //       changes to the value from triggering a harvest directly through user
        //       behavior. This should ensure reasonable resistance to manipulation
        //       from user-initiated withdrawals as the outstanding debt fluctuates.
        uint256 outstanding = vault.debtOutstanding();
        if (outstanding > debtThreshold) return true;

        // Check for profits and losses
        uint256 total = estimatedTotalAssets();
        // Trigger if we have a loss to report
        if (total + debtThreshold < params.totalDebt) return true;

        uint256 profit = 0;
        if (total > params.totalDebt) profit = total - params.totalDebt; // We've earned a profit!

        // Otherwise, only trigger if it "makes sense" economically (gas cost
        // is <N% of value moved)
        uint256 credit = vault.creditAvailable();
        return (profitFactor * callCost < credit + profit);
    }

    /**
     * @notice
     *  Harvests the Strategy, recognizing any profits or losses and adjusting
     *  the Strategy's position.
     *
     *  In the rare case the Strategy is in emergency shutdown, this will exit
     *  the Strategy's position.
     *
     * @dev
     *  When `harvest()` is called, the Strategy reports to the Vault (via
     *  `vault.report()`), so in some cases `harvest()` must be called in order
     *  to take in profits, to borrow newly available funds from the Vault, or
     *  otherwise adjust its position. In other cases `harvest()` must be
     *  called to report to the Vault on the Strategy's position, especially if
     *  any losses have occurred.
     */
    function harvest() external {
        require(msg.sender == vault.vaultAdapter(), "harvest: Call from vault");
        uint256 profit = 0;
        uint256 loss = 0;
        uint256 debtOutstanding = vault.debtOutstanding();
        uint256 debtPayment = 0;
        if (emergencyExit) {
            // Free up as much capital as possible
            uint256 totalAssets = estimatedTotalAssets();
            // NOTE: use the larger of total assets or debt outstanding to book losses properly
            (debtPayment, loss) = liquidatePosition(totalAssets > debtOutstanding ? totalAssets : debtOutstanding);
            // NOTE: take up any remainder here as profit
            if (debtPayment > debtOutstanding) {
                profit = debtPayment - debtOutstanding;
                debtPayment = debtOutstanding;
            }
        } else {
            // Free up returns for Vault to pull
            (profit, loss, debtPayment) = prepareReturn(debtOutstanding);
        }
        // Allow Vault to take up to the "harvested" balance of this contract,
        // which is the amount it has earned since the last time it reported to
        // the Vault.
        debtOutstanding = vault.report(profit, loss, debtPayment);

        // Check if free returns are left, and re-invest them
        adjustPosition(debtOutstanding);

        emit Harvested(profit, loss, debtPayment, debtOutstanding);
    }

    /**
     * @notice
     *  Withdraws `_amountNeeded` to `vault`.
     *
     *  This may only be called by the Vault.
     * @param _amountNeeded How much `want` to withdraw.
     * @return _loss Any realized losses
     */
    function withdraw(uint256 _amountNeeded) external returns (uint256 _loss) {
        require(msg.sender == address(vault), "!vault");
        // Liquidate as much as possible to `want`, up to `_amountNeeded`
        uint256 amountFreed;
        (amountFreed, _loss) = liquidatePosition(_amountNeeded);
        // Send it directly back (NOTE: Using `msg.sender` saves some gas here)
        want.safeTransfer(msg.sender, amountFreed);
        // NOTE: Reinvest anything leftover on next `tend`/`harvest`
    }

    /**
     * Do anything necessary to prepare this Strategy for migration, such as
     * transferring any reserve or LP tokens, CDPs, or other tokens or stores of
     * value.
     */
    function prepareMigration(address _newStrategy) internal virtual;

    /**
     * @notice
     *  Transfers all `want` from this Strategy to `_newStrategy`.
     *
     *  This may only be called by owner or the Vault.
     * @dev
     *  The new Strategy's Vault must be the same as this Strategy's Vault.
     * @param _newStrategy The Strategy to migrate to.
     */
    function migrate(address _newStrategy) external {
        require(msg.sender == address(vault));
        require(BaseStrategy(_newStrategy).vault() == vault);
        prepareMigration(_newStrategy);
        want.safeTransfer(_newStrategy, want.balanceOf(address(this)));
    }

    /**
     * @notice
     *  Activates emergency exit. Once activated, the Strategy will exit its
     *  position upon the next harvest, depositing all funds into the Vault as
     *  quickly as is reasonable given on-chain conditions.
     *
     * @dev
     *  See `vault.setEmergencyShutdown()` and `harvest()` for further details.
     */
    function setEmergencyExit() external onlyAuthorized {
        emergencyExit = true;
        vault.revokeStrategy();

        emit EmergencyExitEnabled();
    }

    /**
     * Override this to add all tokens/tokenized positions this contract
     * manages on a *persistent* basis (e.g. not just for swapping back to
     * want ephemerally).
     *
     * NOTE: Do *not* include `want`, already included in `sweep` below.
     *
     * Example:
     *
     *    function protectedTokens() internal override view returns (address[] memory) {
     *      address[] memory protected = new address[](3);
     *      protected[0] = tokenA;
     *      protected[1] = tokenB;
     *      protected[2] = tokenC;
     *      return protected;
     *    }
     */
    function protectedTokens() internal view virtual returns (address[] memory);

    /**
     * @notice
     *  Removes tokens from this Strategy that are not the type of tokens
     *  managed by this Strategy. This may be used in case of accidentally
     *  sending the wrong kind of token to this Strategy.
     *
     *  Tokens will be sent to `owner()`.
     *
     *  This will fail if an attempt is made to sweep `want`, or any tokens
     *  that are protected by this Strategy.
     *
     *  This may only be called by owner.
     * @dev
     *  Implement `protectedTokens()` to specify any additional tokens that
     *  should be protected from sweeping in addition to `want`.
     * @param _token The token to transfer out of this vault.
     */
    function sweep(address _token) external onlyOwner {
        require(_token != address(want), "!want");
        require(_token != address(vault), "!shares");

        address[] memory _protectedTokens = protectedTokens();
        for (uint256 i; i < _protectedTokens.length; i++) require(_token != _protectedTokens[i], "!protected");

        IERC20(_token).safeTransfer(owner(), IERC20(_token).balanceOf(address(this)));
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.4;

interface IERC20Detailed {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.4;

interface ICurve3Pool {
    function coins(uint256 i) external view returns (address);

    function get_virtual_price() external view returns (uint256);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);

    function calc_token_amount(uint256[3] calldata inAmounts, bool deposit) external view returns (uint256);

    function balances(uint256 i) external view returns (uint256);
}

interface ICurve3Deposit {
    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;

    function add_liquidity(uint256[3] calldata uamounts, uint256 min_mint_amount) external;

    function remove_liquidity(uint256 amount, uint256[3] calldata min_uamounts) external;

    function remove_liquidity_imbalance(uint256[3] calldata amounts, uint256 max_burn_amount) external;

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_uamount
    ) external;

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);
}

interface ICurveMetaPool {
    function coins(uint256 i) external view returns (address);

    function get_virtual_price() external view returns (uint256);

    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);

    function calc_token_amount(uint256[2] calldata inAmounts, bool deposit) external view returns (uint256);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;

    function add_liquidity(uint256[2] calldata uamounts, uint256 min_mint_amount) external;

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_uamount
    ) external;
}

interface ICurveZap {
    function add_liquidity(uint256[4] calldata uamounts, uint256 min_mint_amount) external;

    function remove_liquidity(uint256 amount, uint256[4] calldata min_uamounts) external;

    function remove_liquidity_imbalance(uint256[4] calldata amounts, uint256 max_burn_amount) external;

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_uamount
    ) external;

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);

    function calc_token_amount(uint256[4] calldata inAmounts, bool deposit) external view returns (uint256);

    function pool() external view returns (address);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.4;

interface IUni {
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT

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