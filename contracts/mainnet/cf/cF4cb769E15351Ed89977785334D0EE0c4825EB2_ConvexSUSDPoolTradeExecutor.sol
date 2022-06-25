//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "../../BaseTradeExecutor.sol";
import {ConvexPositionHandler} from "./ConvexPositionHandler.sol";

/// @title ConvexTradeExecutor
/// @author PradeepSelva
/// @notice A contract to execute strategy's trade, on Convex (sUSD)
contract ConvexSUSDPoolTradeExecutor is
    BaseTradeExecutor,
    ConvexPositionHandler
{
    /// @notice event emitted when harvester is updated
    event UpdatedHarvester(
        address indexed oldHandler,
        address indexed newHandler
    );
    /// @notice event emitted when slippage is updated
    event UpdatedSlippage(
        uint256 indexed oldSlippage,
        uint256 indexed newSlippage
    );

    /// @notice creates a new ConvexTradeExecutor with required state
    /// @param _harvester address of harvester
    /// @param _vault address of vault
    constructor(address _harvester, address _vault) BaseTradeExecutor(_vault) {
        ConvexPositionHandler._configHandler(
            _harvester,
            BaseTradeExecutor.vaultWantToken()
        );
    }

    /*///////////////////////////////////////////////////////////////
                         VIEW FUNCTONS
  //////////////////////////////////////////////////////////////*/
    /// @notice This gives the total funds in the contract in terms of want token
    /// @return totalBalance Total balance of contract in want token
    /// @return blockNumber Current block number
    function totalFunds() public view override returns (uint256, uint256) {
        return ConvexPositionHandler.positionInWantToken();
    }

    /*///////////////////////////////////////////////////////////////
                    STATE MODIFICATION FUNCTIONS
  //////////////////////////////////////////////////////////////*/

    /// @notice Keeper function to set max accepted slippage of swaps
    /// @param _slippage Max accepted slippage during harvesting
    function setSlippage(uint256 _slippage) external onlyGovernance {
        uint256 oldSlippage = ConvexPositionHandler.maxSlippage;

        ConvexPositionHandler._setSlippage(_slippage);
        emit UpdatedSlippage(oldSlippage, _slippage);
    }

    /// @notice Governance function to set how position value should be calculated, i.e using virtual price or calc withdraw
    /// @param _useVirtualPriceForPosValue bool signifying if virtual price should be used to calculate position value
    function setUseVirtualPriceForPosValue(bool _useVirtualPriceForPosValue)
        external
        onlyGovernance
    {
        ConvexPositionHandler._setUseVirtualPriceForPosValue(
            _useVirtualPriceForPosValue
        );
    }

    /// @param _harvester address of harvester
    function setHandler(address _harvester) external onlyGovernance {
        address oldHarvester = address(ConvexPositionHandler.harvester);

        ConvexPositionHandler._configHandler(_harvester, vaultWantToken());
        emit UpdatedHarvester(oldHarvester, _harvester);
    }

    /*///////////////////////////////////////////////////////////////
                    DEPOSIT / WITHDRAW FUNCTIONS
  //////////////////////////////////////////////////////////////*/

    /// @notice To deposit into the Curve Pool
    /// @dev Converts USDC to lp tokens via Curve
    /// @param _data Encoded AmountParams as _data with USDC amount
    function _initateDeposit(bytes calldata _data) internal override {
        ConvexPositionHandler._deposit(_data);
        BaseTradeExecutor.confirmDeposit();
    }

    /// @notice To withdraw from ConvexHandler
    /// @dev  Converts Curve Lp Tokens  back to USDC.
    ///  @param _data Encoded WithdrawParams as _data with USDC token amount
    function _initiateWithdraw(bytes calldata _data) internal override {
        ConvexPositionHandler._withdraw(_data);
        BaseTradeExecutor.confirmWithdraw();
    }

    /// @notice Functionlity to execute after deposit is completed
    /// @dev This is not required in ConvexTradeExecutor, hence empty. This follows the BaseTradeExecutor interface
    function _confirmDeposit() internal override {}

    /// @notice Functionlity to execute after withdraw is completed
    /// @dev This is not required in ConvexTradeExecutor, hence empty. This follows the BaseTradeExecutor interface
    function _confirmWithdraw() internal override {}

    /*///////////////////////////////////////////////////////////////
                    OPEN / CLOSE FUNCTIONS
  //////////////////////////////////////////////////////////////*/

    /// @notice To open staking position in Convex
    /// @dev stakes the specified Curve Lp Tokens into Convex's UST3-Wormhole pool
    /// @param _data Encoded AmountParams as _data with LP Token amount
    function openPosition(bytes calldata _data) public onlyKeeper {
        ConvexPositionHandler._openPosition(_data);
    }

    /// @notice To close Convex Staking Position
    /// @dev Unstakes from Convex position and gives back them as Curve Lp Tokens along with rewards like CRV, CVX.
    /// @param _data Encoded AmountParams as _data with LP token amount
    function closePosition(bytes calldata _data) public onlyKeeper {
        ConvexPositionHandler._closePosition(_data);
    }

    /*///////////////////////////////////////////////////////////////
                    REWARDS FUNCTION
   //////////////////////////////////////////////////////////////*/
    /// @notice To claim rewards from Convex Staking position
    /// @dev Claims Convex Staking position rewards, and converts them to wantToken i.e., USDC.
    /// @param _data is not needed here (empty param, to satisfy interface)
    function claimRewards(bytes calldata _data) public onlyKeeper {
        ConvexPositionHandler._claimRewards(_data);
    }
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/ITradeExecutor.sol";
import "../interfaces/IVault.sol";

abstract contract BaseTradeExecutor is ITradeExecutor {
    uint256 internal constant MAX_INT = type(uint256).max;

    ActionStatus public override depositStatus;
    ActionStatus public override withdrawalStatus;

    address public override vault;

    constructor(address _vault) {
        vault = _vault;
        IERC20(vaultWantToken()).approve(vault, MAX_INT);
    }

    function vaultWantToken() public view returns (address) {
        return IVault(vault).wantToken();
    }

    function governance() public view returns (address) {
        return IVault(vault).governance();
    }

    function keeper() public view returns (address) {
        return IVault(vault).keeper();
    }

    modifier onlyGovernance() {
        require(msg.sender == governance(), "ONLY_GOV");
        _;
    }

    modifier onlyKeeper() {
        require(msg.sender == keeper(), "ONLY_KEEPER");
        _;
    }

    function sweep(address _token) public onlyGovernance {
        IERC20(_token).transfer(
            governance(),
            IERC20(_token).balanceOf(address(this))
        );
    }

    function initiateDeposit(bytes calldata _data) public override onlyKeeper {
        require(!depositStatus.inProcess, "DEPOSIT_IN_PROGRESS");
        depositStatus.inProcess = true;
        _initateDeposit(_data);
    }

    function confirmDeposit() public override onlyKeeper {
        require(depositStatus.inProcess, "DEPOSIT_COMPLETED");
        depositStatus.inProcess = false;
        _confirmDeposit();
    }

    function initiateWithdraw(bytes calldata _data) public override onlyKeeper {
        require(!withdrawalStatus.inProcess, "WITHDRAW_IN_PROGRESS");
        withdrawalStatus.inProcess = true;
        _initiateWithdraw(_data);
    }

    function confirmWithdraw() public override onlyKeeper {
        require(withdrawalStatus.inProcess, "WITHDRAW_COMPLETED");
        withdrawalStatus.inProcess = false;
        _confirmWithdraw();
    }

    /// Internal Funcs

    function _initateDeposit(bytes calldata _data) internal virtual;

    function _confirmDeposit() internal virtual;

    function _initiateWithdraw(bytes calldata _data) internal virtual;

    function _confirmWithdraw() internal virtual;
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
pragma abicoder v2;

import "../../../interfaces/BasePositionHandler.sol";
import "../../../library/Math.sol";

import "../interfaces/IConvexRewards.sol";
import "../interfaces/IConvexBooster.sol";
import "../interfaces/ICurveSwap.sol";
import "../interfaces/ICurveDeposit.sol";
import "../interfaces/ICurveDepositZapper.sol";
import "../interfaces/IHarvester.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title ConvexPositionHandler
/// @author PradeepSelva
/// @notice A Position handler to handle Convex for sUSD Pool
contract ConvexPositionHandler is BasePositionHandler {
    using SafeERC20 for IERC20;

    /*///////////////////////////////////////////////////////////////
                            ENUMS
  //////////////////////////////////////////////////////////////*/
    enum SUSDPoolCoinIndexes {
        DAI,
        USDC,
        USDT,
        SUSD
    }

    /*///////////////////////////////////////////////////////////////
                          STRUCTS FOR DECODING
  //////////////////////////////////////////////////////////////*/
    struct AmountParams {
        uint256 _amount;
    }

    /*///////////////////////////////////////////////////////////////
                          GLOBAL IMMUTABLES
  //////////////////////////////////////////////////////////////*/
    /// @dev the max basis points used as normalizing factor.
    uint256 public immutable MAX_BPS = 10000;
    /// @dev the normalization factor for amounts
    uint256 public constant NORMALIZATION_FACTOR = 1e30;

    /*///////////////////////////////////////////////////////////////
                          GLOBAL MUTABLES
  //////////////////////////////////////////////////////////////*/
    /// @notice the max permitted slippage for swaps
    uint256 public maxSlippage = 30;
    /// @notice the latest amount of rewards claimed and harvested
    uint256 public latestHarvestedRewards;
    /// @notice the total cummulative rewards earned so far
    uint256 public totalCummulativeRewards;
    /// @notice governance handled variable, that tells how to calculate position in want token
    /// @dev this is done to account for cases of depeg
    bool public useVirtualPriceForPosValue = true;

    /*///////////////////////////////////////////////////////////////
                            EXTERNAL CONTRACTS
  //////////////////////////////////////////////////////////////*/
    /// @notice The want token that is deposited and withdrawn
    IERC20 public wantToken;
    /// @notice Curve LP Tokens that are converted and staked on Convex
    IERC20 public lpToken = IERC20(0xC25a3A3b969415c80451098fa907EC722572917F);

    /// @notice Harvester that harvests rewards claimed from Convex
    IHarvester public harvester;

    /// @notice convex sUSD base reward pool
    IConvexRewards public constant baseRewardPool =
        IConvexRewards(0x22eE18aca7F3Ee920D01F25dA85840D12d98E8Ca);
    /// @notice curve's sUSD Pool
    ICurveSwap public constant susdPool =
        ICurveSwap(0xA5407eAE9Ba41422680e2e00537571bcC53efBfD);
    /// @notice curve's sUSD pool deposit
    ICurveDeposit public constant susdDeposit =
        ICurveDeposit(0xFCBa3E75865d2d561BE8D220616520c171F12851);
    /// @notice convex booster
    IConvexBooster public constant convexBooster =
        IConvexBooster(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);

    /*///////////////////////////////////////////////////////////////
                          INITIALIZING
    //////////////////////////////////////////////////////////////*/
    /// @notice configures ConvexPositionHandler with the required state
    /// @param _harvester address of harvester
    /// @param _wantToken address of want token
    function _configHandler(address _harvester, address _wantToken) internal {
        wantToken = IERC20(_wantToken);
        harvester = IHarvester(_harvester);

        // Assign virtual price of susdPool
        prevSharePrice = susdPool.get_virtual_price();

        // Approve max LP tokens to convex booster
        lpToken.approve(address(convexBooster), type(uint256).max);
        // approve max usdc to susd pool
        wantToken.approve(address(susdPool), type(uint256).max);
        // approve max lp tokens to susd deposit
        lpToken.approve(address(susdDeposit), type(uint256).max);
    }

    /*///////////////////////////////////////////////////////////////
                          VIEW FUNCTIONS
  //////////////////////////////////////////////////////////////*/

    /**
   @notice To get the total balances of the contract in want token price
   @return totalBalance Total balance of contract in want token
   @return blockNumber Current block number
   */
    function positionInWantToken()
        public
        view
        override
        returns (uint256, uint256)
    {
        (
            uint256 stakedLpBalance,
            uint256 lpTokenBalance,
            uint256 usdcBalance
        ) = _getTotalBalancesInWantToken(useVirtualPriceForPosValue);

        return (stakedLpBalance + lpTokenBalance + usdcBalance, block.number);
    }

    /*///////////////////////////////////////////////////////////////
                      DEPOSIT / WITHDRAW LOGIC
  //////////////////////////////////////////////////////////////*/

    /**
   @notice To deposit into the Curve Pool
   @dev Converts USDC to lp tokens via Curve
   @param _data Encoded AmountParams as _data with USDC amount
   */
    function _deposit(bytes calldata _data) internal override {
        AmountParams memory depositParams = abi.decode(_data, (AmountParams));
        require(
            depositParams._amount <= wantToken.balanceOf(address(this)),
            "invalid deposit amount"
        );

        _convertUSDCIntoLpToken(depositParams._amount);

        emit Deposit(depositParams._amount);
    }

    /**
   @notice To withdraw from ConvexHandler
   @dev  Converts Curve Lp Tokens  back to USDC.
   @param _data Encoded WithdrawParams as _data with USDC token amount
   */
    function _withdraw(bytes calldata _data) internal override {
        // _amount here is the maxWithdraw
        AmountParams memory withdrawParams = abi.decode(_data, (AmountParams));
        (
            uint256 stakedLpBalance,
            uint256 lpTokenBalance,
            uint256 usdcBalance
        ) = _getTotalBalancesInWantToken(false);
        uint256 totalBalance = (stakedLpBalance + lpTokenBalance + usdcBalance);

        // if _amount is more than balance, then withdraw entire balance
        if (withdrawParams._amount > totalBalance) {
            withdrawParams._amount = totalBalance;
        }

        // calculate maximum amount that can be withdrawn
        uint256 amountToWithdraw = withdrawParams._amount;
        uint256 usdcValueOfLpTokensToConvert = 0;

        // if usdc token balance is insufficient
        if (amountToWithdraw > usdcBalance) {
            usdcValueOfLpTokensToConvert = amountToWithdraw - usdcBalance;

            if (usdcValueOfLpTokensToConvert > lpTokenBalance) {
                uint256 amountToUnstake = usdcValueOfLpTokensToConvert -
                    lpTokenBalance;
                // unstake convex position partially
                // this is min between actual staked balance and calculated amount, to ensure overflow
                uint256 lpTokensToUnstake = Math.min(
                    _USDCValueInLpToken(amountToUnstake),
                    baseRewardPool.balanceOf(address(this))
                );

                require(
                    baseRewardPool.withdrawAndUnwrap(lpTokensToUnstake, true),
                    "could not unstake"
                );
            }
        }

        // usdcValueOfLpTokensToConvert's value converted to Lp Tokens
        // this is min between converted value and lp token balance, to ensure overflow
        uint256 lpTokensToConvert = Math.min(
            _USDCValueInLpToken(usdcValueOfLpTokensToConvert),
            lpToken.balanceOf(address(this))
        );
        // if lp tokens are required to convert, then convert to usdc and update amountToWithdraw
        if (lpTokensToConvert > 0) {
            _convertLpTokenIntoUSDC(lpTokensToConvert);
        }

        emit Withdraw(withdrawParams._amount);
    }

    /*///////////////////////////////////////////////////////////////
                      OPEN / CLOSE LOGIC
  //////////////////////////////////////////////////////////////*/

    /**
   @notice To open staking position in Convex
   @dev stakes the specified Curve Lp Tokens into Convex's sUSD pool
   @param _data Encoded AmountParams as _data with LP Token amount
   */
    function _openPosition(bytes calldata _data) internal override {
        AmountParams memory openPositionParams = abi.decode(
            _data,
            (AmountParams)
        );

        require(
            openPositionParams._amount <= lpToken.balanceOf(address(this)),
            "INSUFFICIENT_BALANCE"
        );

        require(
            convexBooster.deposit(
                baseRewardPool.pid(),
                openPositionParams._amount,
                true
            ),
            "CONVEX_STAKING_FAILED"
        );
    }

    /**
   @notice To close Convex Staking Position
   @dev Unstakes from Convex position and gives back them as Curve Lp Tokens along with rewards like CRV, CVX.
   @param _data Encoded AmountParams as _data with LP token amount
   */
    function _closePosition(bytes calldata _data) internal override {
        AmountParams memory closePositionParams = abi.decode(
            _data,
            (AmountParams)
        );

        require(
            closePositionParams._amount <=
                baseRewardPool.balanceOf(address(this)),
            "AMOUNT_EXCEEDS_BALANCE"
        );

        if (closePositionParams._amount > 0) {
            /// Unstake _amount and claim rewards from convex
            baseRewardPool.withdrawAndUnwrap(closePositionParams._amount, true);
        } else {
            /// Unstake entire balance if closePositionParams._amount is 0
            baseRewardPool.withdrawAllAndUnwrap(true);
        }
    }

    /*///////////////////////////////////////////////////////////////
                      REWARDS LOGIC
  //////////////////////////////////////////////////////////////*/
    /// @notice variable to track previous share price of LP token
    uint256 public prevSharePrice = type(uint256).max;

    /**
   @notice To claim rewards from Convex Staking position
   @dev Claims Convex Staking position rewards, and converts them to wantToken i.e., USDC.
   @param _data is not needed here (empty param, to satisfy interface)
   */
    function _claimRewards(bytes calldata _data) internal override {
        require(baseRewardPool.getReward(), "reward claim failed");

        uint256 initialUSDCBalance = wantToken.balanceOf(address(this));

        // get list of tokens to transfer to harvester
        address[] memory rewardTokens = harvester.rewardTokens();
        //transfer them
        uint256 balance;
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            balance = IERC20(rewardTokens[i]).balanceOf(address(this));

            if (balance > 0) {
                IERC20(rewardTokens[i]).safeTransfer(
                    address(harvester),
                    balance
                );
            }
        }

        // convert all rewards to usdc
        harvester.harvest();

        // get curve lp rewards
        uint256 currentSharePrice = susdPool.get_virtual_price();
        if (currentSharePrice > prevSharePrice) {
            // claim any gain on lp token yields
            uint256 contractLpTokenBalance = lpToken.balanceOf(address(this));
            uint256 totalLpBalance = contractLpTokenBalance +
                baseRewardPool.balanceOf(address(this));
            uint256 yieldEarned = (currentSharePrice - prevSharePrice) *
                totalLpBalance;

            uint256 lpTokenEarned = yieldEarned / currentSharePrice;

            // If lpTokenEarned is more than lpToken balance in contract, unstake the difference
            if (lpTokenEarned > contractLpTokenBalance) {
                baseRewardPool.withdrawAndUnwrap(
                    lpTokenEarned - contractLpTokenBalance,
                    true
                );
            }
            // convert lp token to usdc
            _convertLpTokenIntoUSDC(lpTokenEarned);
        }
        prevSharePrice = currentSharePrice;

        latestHarvestedRewards =
            wantToken.balanceOf(address(this)) -
            initialUSDCBalance;
        totalCummulativeRewards += latestHarvestedRewards;

        emit Claim(latestHarvestedRewards);
    }

    /*///////////////////////////////////////////////////////////////
                          HELPER FUNCTIONS
  //////////////////////////////////////////////////////////////*/

    /// @notice To get total contract balances in terms of want token
    /// @dev Gets lp token balance from contract, staked position on convex, and converts all of them to usdc. And gives balance as want token.
    /// @param useVirtualPrice to check if balances shoudl be based on virtual price
    /// @return stakedLpBalance balance of staked LP tokens in terms of want token
    /// @return lpTokenBalance balance of LP tokens in contract
    /// @return usdcBalance usdc balance in contract
    function _getTotalBalancesInWantToken(bool useVirtualPrice)
        internal
        view
        returns (
            uint256 stakedLpBalance,
            uint256 lpTokenBalance,
            uint256 usdcBalance
        )
    {
        uint256 stakedLpBalanceRaw = baseRewardPool.balanceOf(address(this));
        uint256 lpTokenBalanceRaw = lpToken.balanceOf(address(this));

        uint256 totalLpBalance = stakedLpBalanceRaw + lpTokenBalanceRaw;

        // Here, in order to prevent price manipulation attacks via curve pools,
        // When getting total position value -> its calculated based on virtual price
        // During withdrawal -> calc_withdraw_one_coin() is used to get an actual estimate of USDC received if we were to remove liquidity
        // The following checks account for this
        uint256 totalLpBalanceInUSDC = useVirtualPrice
            ? _lpTokenValueInUSDCfromVirtualPrice(totalLpBalance)
            : _lpTokenValueInUSDC(totalLpBalance);

        lpTokenBalance = useVirtualPrice
            ? _lpTokenValueInUSDCfromVirtualPrice(lpTokenBalanceRaw)
            : _lpTokenValueInUSDC(lpTokenBalanceRaw);

        stakedLpBalance = totalLpBalanceInUSDC - lpTokenBalance;
        usdcBalance = wantToken.balanceOf(address(this));
    }

    /**
   @notice Helper to convert Lp tokens into USDC
   @dev Burns LpTokens on sUSD pool on curve to get USDC
   @param _amount amount of Lp tokens to burn to get USDC
   @return receivedWantTokens amount of want tokens received after converting Lp tokens
   */
    function _convertLpTokenIntoUSDC(uint256 _amount)
        internal
        returns (uint256 receivedWantTokens)
    {
        uint256 initialWantTokens = wantToken.balanceOf(address(this));
        int128 usdcIndexInPool = int128(
            int256(uint256(SUSDPoolCoinIndexes.USDC))
        );

        // estimate amount of USDC received based on stable peg i.e., 1sUSD = 1 3Pool LP Token
        uint256 expectedWantTokensOut = (_amount *
            susdPool.get_virtual_price()) / NORMALIZATION_FACTOR; // 30 = normalizing 18 decimals for virutal price + 18 decimals for LP token - 6 decimals for want token
        // burn Lp tokens to receive USDC with a slippage of `maxSlippage`
        susdDeposit.remove_liquidity_one_coin(
            _amount,
            usdcIndexInPool,
            (expectedWantTokensOut * (MAX_BPS - maxSlippage)) / (MAX_BPS)
        );

        receivedWantTokens =
            wantToken.balanceOf(address(this)) -
            initialWantTokens;
    }

    /**
   @notice Helper to convert USDC into Lp tokens
   @dev Provides USDC liquidity on sUSD pool on curve to get Lp Tokens
   @param _amount amount of USDC to deposit to get Lp Tokens
   @return receivedLpTokens amount of LP tokens received after converting USDC
   */
    function _convertUSDCIntoLpToken(uint256 _amount)
        internal
        returns (uint256 receivedLpTokens)
    {
        uint256 initialLp = lpToken.balanceOf(address(this));
        uint256[4] memory liquidityAmounts = [0, _amount, 0, 0];

        // estimate amount of Lp Tokens based on stable peg i.e., 1sUSD = 1 3Pool LP Token
        uint256 expectedLpOut = (_amount * NORMALIZATION_FACTOR) /
            susdPool.get_virtual_price(); // 30 = normalizing 18 decimals for virutal price + 18 decimals for LP token - 6 decimals for want token
        // Provide USDC liquidity to receive Lp tokens with a slippage of `maxSlippage`
        susdPool.add_liquidity(
            liquidityAmounts,
            (expectedLpOut * (MAX_BPS - maxSlippage)) / (MAX_BPS)
        );

        receivedLpTokens = lpToken.balanceOf(address(this)) - initialLp;
    }

    /**
   @notice to get value of an amount in USDC
   @param _value value to be converted
   @return estimatedLpTokenAmount estimated amount of lp tokens if (_value) amount of USDC is converted
   */
    function _lpTokenValueInUSDC(uint256 _value)
        internal
        view
        returns (uint256)
    {
        if (_value == 0) return 0;

        return
            susdDeposit.calc_withdraw_one_coin(
                _value,
                int128(int256(uint256(SUSDPoolCoinIndexes.USDC)))
            );
    }

    /**
   @notice to get value of an amount in USDC based on virtual price
   @param _value value to be converted
   @return estimatedLpTokenAmount lp tokens value in USDC based on its virtual price 
   */
    function _lpTokenValueInUSDCfromVirtualPrice(uint256 _value)
        internal
        view
        returns (uint256)
    {
        return (susdPool.get_virtual_price() * _value) / NORMALIZATION_FACTOR;
    }

    /**
   @notice to get value of an amount in Lp Tokens
   @param _value value to be converted
   @return estimatedUSDCAmount estimated amount of USDC if (_value) amount of LP Tokens is converted
   */
    function _USDCValueInLpToken(uint256 _value)
        internal
        view
        returns (uint256)
    {
        if (_value == 0) return 0;

        return susdPool.calc_token_amount([0, _value, 0, 0], true);
    }

    /**
   @notice Keeper function to set max accepted slippage of swaps
   @param _slippage Max accepted slippage during harvesting
   */
    function _setSlippage(uint256 _slippage) internal {
        maxSlippage = _slippage;
    }

    /// @notice Governance function to set how position value should be calculated, i.e using virtual price or calc withdraw
    /// @param _useVirtualPriceForPosValue bool signifying if virtual price should be used to calculate position value
    function _setUseVirtualPriceForPosValue(bool _useVirtualPriceForPosValue)
        internal
    {
        useVirtualPriceForPosValue = _useVirtualPriceForPosValue;
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

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

interface ITradeExecutor {
    struct ActionStatus {
        bool inProcess;
        address from;
    }

    function vault() external view returns (address);

    function depositStatus() external returns (bool, address);

    function withdrawalStatus() external returns (bool, address);

    function initiateDeposit(bytes calldata _data) external;

    function confirmDeposit() external;

    function initiateWithdraw(bytes calldata _data) external;

    function confirmWithdraw() external;

    function totalFunds()
        external
        view
        returns (uint256 posValue, uint256 lastUpdatedBlock);
}

/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IVault {
    function keeper() external view returns (address);

    function governance() external view returns (address);

    function wantToken() external view returns (address);

    function deposit(uint256 amountIn, address receiver)
        external
        returns (uint256 shares);

    function withdraw(uint256 sharesIn, address receiver)
        external
        returns (uint256 amountOut);
}

/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

abstract contract BasePositionHandler {
    /// @notice To be emitted when a deposit is made by position handler
    /// @param amount The amount of tokens deposited
    event Deposit(uint256 indexed amount);

    /// @notice To be emitted when a withdraw is made by position handler
    /// @param amount The amount of tokens withdrawn
    event Withdraw(uint256 indexed amount);

    /// @notice To be emitted with rewards are claimed by position handler
    /// @param amount The amount that was withdrawn
    event Claim(uint256 indexed amount);

    /// @notice struct to store data related to position
    /// @param posValue The value of the position in vault wantToken
    /// @param lastUpdatedBlock The block number of last update in position value
    struct Position {
        uint256 posValue;
        uint256 lastUpdatedBlock;
    }

    function positionInWantToken()
        external
        view
        virtual
        returns (uint256, uint256);

    function _openPosition(bytes calldata _data) internal virtual;

    function _closePosition(bytes calldata _data) internal virtual;

    function _deposit(bytes calldata _data) internal virtual;

    function _withdraw(bytes calldata _data) internal virtual;

    function _claimRewards(bytes calldata _data) internal virtual;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

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
}

/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

//sample convex reward contracts interface
interface IConvexRewards {
    // pid of pool
    function pid() external view returns (uint256);

    // earned rewards
    function earned(address account) external view returns (uint256);

    //get balance of an address
    function balanceOf(address _account) external view returns (uint256);

    //withdraw to a convex tokenized deposit
    function withdraw(uint256 _amount, bool _claim) external returns (bool);

    //withdraw directly to curve LP token
    function withdrawAndUnwrap(uint256 _amount, bool _claim)
        external
        returns (bool);

    //claim rewards
    function getReward() external returns (bool);

    //stake a convex tokenized deposit
    function stake(uint256 _amount) external returns (bool);

    //stake a convex tokenized deposit for another address(transfering ownership)
    function stakeFor(address _account, uint256 _amount)
        external
        returns (bool);

    function stakeAll() external returns (bool);

    function withdrawAll(bool claim) external;

    function withdrawAllAndUnwrap(bool claim) external;
}

/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IConvexBooster {
    //deposit into convex, receive a tokenized deposit.  parameter to stake immediately
    function deposit(
        uint256 _pid,
        uint256 _amount,
        bool _stake
    ) external returns (bool);

    //burn a tokenized deposit to receive curve lp tokens back
    function withdraw(uint256 _pid, uint256 _amount) external returns (bool);
}

/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface ICurveSwap {
    function exchange(
        int128 i,
        int128 j,
        uint256 _dx,
        uint256 _min_dy,
        address _receiver
    ) external returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external;

    function add_liquidity(uint256[4] memory amounts, uint256 min_mint_amount)
        external;

    function get_dy(
        int128 i,
        int128 j,
        uint256 _dx
    ) external view returns (uint256);

    function calc_token_amount(uint256[4] memory _amounts, bool _is_deposit)
        external
        view
        returns (uint256);

    function get_virtual_price() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
}

/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface ICurveDeposit {
    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external;

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
}

/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface ICurveDepositZapper {
    function calc_withdraw_one_coin(
        address _pool,
        uint256 _token_amount,
        int128 i
    ) external view returns (uint256);

    function calc_token_amount(
        address _pool,
        uint256[4] memory _amounts,
        bool _is_deposit
    ) external view returns (uint256);

    function remove_liquidity_one_coin(
        address _pool,
        uint256 _burn_amount,
        int128 i,
        uint256 _min_amount
    ) external returns (uint256);

    function add_liquidity(
        address _pool,
        uint256[4] memory _deposit_amounts,
        uint256 _min_mint_amount
    ) external returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;
import "../../../interfaces/IVault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IHarvester {
    function crv() external view returns (IERC20);

    function cvx() external view returns (IERC20);

    function _3crv() external view returns (IERC20);

    function snx() external view returns (IERC20);

    function vault() external view returns (IVault);

    // Swap tokens to wantToken
    function harvest() external;

    function sweep(address _token) external;

    function setSlippage(uint256 _slippage) external;

    function rewardTokens() external view returns (address[] memory);
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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