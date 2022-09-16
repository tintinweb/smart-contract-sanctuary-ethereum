pragma solidity ^0.8.13;

import "src/interfaces/IERC20.sol";
import "src/interfaces/curve/IMetaPool.sol";
import "src/interfaces/convex/IConvexBooster.sol";
import "src/interfaces/convex/IConvexBaseRewardPool.sol";
import "src/convex-fed/CurvePoolAdapter.sol";

contract ConvexFed is CurvePoolAdapter{

    uint public immutable poolId;
    IConvexBooster public booster;
    IConvexBaseRewardPool public baseRewardPool;
    IERC20 public crv;
    IERC20 public CVX;
    address public chair; // Fed Chair
    address public gov;
    uint public dolaSupply;
    uint public maxLossExpansionBps;
    uint public maxLossWithdrawBps;
    uint public maxLossTakeProfitBps;

    event Expansion(uint amount);
    event Contraction(uint amount);

    constructor(
            address dola_, 
            address CVX_,
            address crvPoolAddr,
            address booster_, 
            address baseRewardPool_, 
            address chair_,
            address gov_, 
            uint maxLossExpansionBps_,
            uint maxLossWithdrawBps_,
            uint maxLossTakeProfitBps_)
            CurvePoolAdapter(dola_, crvPoolAddr)
    {
        booster = IConvexBooster(booster_);
        baseRewardPool = IConvexBaseRewardPool(baseRewardPool_);
        crv = IERC20(baseRewardPool.rewardToken());
        CVX = IERC20(CVX_);
        poolId = baseRewardPool.pid();
        IERC20(crvPoolAddr).approve(booster_, type(uint256).max);
        IERC20(crvPoolAddr).approve(baseRewardPool_, type(uint256).max);
        maxLossExpansionBps = maxLossExpansionBps_;
        maxLossWithdrawBps = maxLossWithdrawBps_;
        maxLossTakeProfitBps = maxLossTakeProfitBps_;
        chair = chair_;
        gov = gov_;
    }

    /**
    @notice Method for gov to change gov address
    */
    function changeGov(address newGov_) public {
        require(msg.sender == gov, "ONLY GOV");
        gov = newGov_;
    }

    /**
    @notice Method for gov to change the chair
    */
    function changeChair(address newChair_) public {
        require(msg.sender == gov, "ONLY GOV");
        chair = newChair_;
    }

    /**
    @notice Method for current chair of the Yearn FED to resign
    */
    function resign() public {
        require(msg.sender == chair, "ONLY CHAIR");
        chair = address(0);
    }

    /**
    @notice Set the maximum acceptable loss when expanding dola supply. Only callable by gov.
    @param newMaxLossExpansionBps The maximum loss allowed by basis points 1 = 0.01%
    */
    function setMaxLossExpansionBps(uint newMaxLossExpansionBps) public {
        require(msg.sender == gov, "ONLY GOV");
        require(newMaxLossExpansionBps <= 10000, "Can't have max loss above 100%");
        maxLossExpansionBps = newMaxLossExpansionBps;
    }

    /**
    @notice Set the maximum acceptable loss when withdrawing dola supply. Only callable by gov.
    @param newMaxLossWithdrawBps The maximum loss allowed by basis points 1 = 0.01%
    */
    function setMaxLossWithdrawBps(uint newMaxLossWithdrawBps) public {
        require(msg.sender == gov, "ONLY GOV");
        require(newMaxLossWithdrawBps <= 10000, "Can't have max loss above 100%");
        maxLossWithdrawBps = newMaxLossWithdrawBps;
    }

    /**
    @notice Set the maximum acceptable loss when Taking Profit from LP tokens. Only callable by gov.
    @param newMaxLossTakeProfitBps The maximum loss allowed by basis points 1 = 0.01%
    */
    function setMaxLossTakeProfitBps(uint newMaxLossTakeProfitBps) public {
        require(msg.sender == gov, "ONLY GOV");
        require(newMaxLossTakeProfitBps <= 10000, "Can't have max loss above 100%");
        maxLossTakeProfitBps = newMaxLossTakeProfitBps;   
    }
    /**
    @notice Deposits amount of dola tokens into yEarn vault

    @param amount Amount of dola token to deposit into yEarn vault
    */
    function expansion(uint amount) public {
        require(msg.sender == chair, "ONLY CHAIR");
        dolaSupply += amount;
        dola.mint(address(this), amount);
        metapoolDeposit(amount, maxLossExpansionBps);
        require(booster.depositAll(poolId, true), 'Failed Deposit');
        emit Expansion(amount);
    }

    /**
    @notice Withdraws an amount of dola token to be burnt, contracting DOLA dolaSupply
    @dev Be careful when setting maxLoss parameter. There will almost always be some slippage when trading.
    For example, slippage + trading fees may be incurred when withdrawing from a Curve pool.
    On the other hand, setting the maxLoss too high, may cause you to be front run by MEV
    sandwhich bots, making sure your entire maxLoss is incurred.
    Recommended to always broadcast withdrawl transactions(contraction & takeProfits)
    through a frontrun protected RPC like Flashbots RPC.
    @param amountDola The amount of dola tokens to withdraw. Note that more tokens may
    be withdrawn than requested.
    */
    function contraction(uint amountDola) public {
        require(msg.sender == chair, "ONLY CHAIR");
        //Calculate how many lp tokens are needed to withdraw the dola
        uint crvLpNeeded = lpForDola(amountDola);
        require(crvLpNeeded <= crvLpSupply(), "Not enough crvLP tokens");

        //Withdraw and unwrap curveLP tokens from convex, but don't claim rewards
        require(baseRewardPool.withdrawAndUnwrap(crvLpNeeded, false), "CONVEX WITHDRAW FAILED");

        //Withdraw DOLA from curve pool
        uint dolaWithdrawn = metapoolWithdraw(amountDola, maxLossWithdrawBps);
        require(dolaWithdrawn > 0, "Must contract");
        if(dolaWithdrawn > dolaSupply){
            dola.transfer(gov, dolaWithdrawn - dolaSupply);
            dola.burn(dolaSupply);
            dolaSupply = 0;
        } else {
            dola.burn(dolaWithdrawn);
            dolaSupply = dolaSupply - dolaWithdrawn;
        }
        emit Contraction(dolaWithdrawn);
    }

    /**
    @notice Withdraws every remaining crvLP token. Can take up to maxLossWithdrawBps in loss, compared to dolaSupply.
    It will still be necessary to call takeProfit to withdraw any potential rewards.
    */
    function contractAll() public {
        require(msg.sender == chair, "ONLY CHAIR");
        baseRewardPool.withdrawAllAndUnwrap(false);
        uint dolaMinOut = dolaSupply * (10_000 - maxLossWithdrawBps) / 10_000;
        uint dolaOut = crvMetapool.remove_liquidity_one_coin(crvLpSupply(), 0, dolaMinOut);
        if(dolaOut > dolaSupply){
            dola.transfer(gov, dolaOut - dolaSupply);
            dola.burn(dolaSupply);
            dolaSupply = 0;
        } else {
            dola.burn(dolaOut);
            dolaSupply -= dolaOut;
        }
        emit Contraction(dolaOut);
    }


    /**
    @notice Withdraws the profit generated by convex staking
    @dev See dev note on Contraction method
    */
    function takeProfit(bool harvestLP) public {
        //This takes crvLP at face value, but doesn't take into account slippage or fees
        //Worth considering that the additional transaction fees incurred by withdrawing the small amount of profit generated by tx fees,
        //may not eclipse additional transaction costs. Set harvestLP = false to only withdraw crv and cvx rewards.
        uint crvLpValue = crvMetapool.get_virtual_price()*crvLpSupply() / 10**18;
        if(harvestLP && crvLpValue > dolaSupply) {
            require(msg.sender == chair, "ONLY CHAIR CAN TAKE CRV LP PROFIT");
            uint dolaSurplus = crvLpValue - dolaSupply;
            uint crvLpToWithdraw = lpForDola(dolaSurplus);
            require(baseRewardPool.withdrawAndUnwrap(crvLpToWithdraw, false), "CONVEX WITHDRAW FAILED");
            uint dolaProfit = metapoolWithdraw(dolaSurplus, maxLossTakeProfitBps);
            require(dolaProfit > 0, "NO PROFIT");
            dola.transfer(gov, dolaProfit);
        }
        require(baseRewardPool.getReward());
        crv.transfer(gov, crv.balanceOf(address(this)));
        CVX.transfer(gov, CVX.balanceOf(address(this)));
    }
    
    /**
    @notice View function for getting crvLP tokens in the contract + convex baseRewardPool
    */
    function crvLpSupply() public view returns(uint){
        return crvMetapool.balanceOf(address(this)) + baseRewardPool.balanceOf(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

     * @dev Returns the decimal points used by the token.
     */
    function decimals() external view returns (uint8);

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
    
    /**
     * @dev Burns `amount` of token, shringking total supply
     */
    function burn(uint amount) external;

    /**
     * @dev Mints `amount` of token to address `to` increasing total supply
     */
    function mint(address to, uint amount) external;

    //For testing
    function addMinter(address minter_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

interface IMetaPool {

	// Deployment
	function __init__() external;
	function initialize(string memory _name, string memory _symbol, address _coin, uint _decimals, uint _A, uint _fee, address _admin) external;

	// ERC20 Standard
	function decimals() external view returns (uint);
	function transfer(address _to, uint _value) external returns (uint256);
	function transferFrom(address _from, address _to, uint _value) external returns (bool);
	function approve(address _spender, uint _value) external returns (bool);
	function balanceOf(address _owner) external view returns (uint256);
	function totalSupply() external view returns (uint256);


	// StableSwap Functionality
	function get_previous_balances() external view returns (uint[2] memory);
	function get_twap_balances(uint[2] memory _first_balances, uint[2] memory _last_balances, uint _time_elapsed) external view returns (uint[2] memory);
	function get_price_cumulative_last() external view returns (uint[2] memory);
	function admin_fee() external view returns (uint);
	function A() external view returns (uint);
	function A_precise() external view returns (uint);
	function get_virtual_price() external view returns (uint);
	function calc_token_amount(uint[2] memory _amounts, bool _is_deposit) external view returns (uint);
	function calc_token_amount(uint[2] memory _amounts, bool _is_deposit, bool _previous) external view returns (uint);
	function add_liquidity(uint[2] memory _amounts, uint _min_mint_amount) external returns (uint);
	function add_liquidity(uint[2] memory _amounts, uint _min_mint_amount, address _receiver) external returns (uint);
	function get_dy(int128 i, int128 j, uint256 dx) external view returns (uint256);
	function get_dy(int128 i, int128 j, uint256 dx, uint256[2] memory _balances) external view returns (uint256);
	function get_dy_underlying(int128 i, int128 j, uint256 dx) external view returns (uint256);
	function get_dy_underlying(int128 i, int128 j, uint256 dx, uint256[2] memory _balances) external view returns (uint256);
	function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns (uint256);
	function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy, address _receiver) external returns (uint256);
	function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns (uint256);
	function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy, address _receiver) external returns (uint256);
	function remove_liquidity(uint256 _burn_amount, uint256[2] memory _min_amounts) external returns (uint256[2] memory);
	function remove_liquidity(uint256 _burn_amount, uint256[2] memory _min_amounts, address _receiver) external returns (uint256[2] memory);
	function remove_liquidity_imbalance(uint256[2] memory _amounts, uint256 _max_burn_amount) external returns (uint256);
	function remove_liquidity_imbalance(uint256[2] memory _amounts, uint256 _max_burn_amount, address _receiver) external returns (uint256);
	function calc_withdraw_one_coin(uint256 _burn_amount, int128 i) external view returns (uint256);
	function calc_withdraw_one_coin(uint256 _burn_amount, int128 i, bool _previous) external view returns (uint256);
	function remove_liquidity_one_coin(uint256 _burn_amount, int128 i, uint256 _min_received) external returns (uint256);
	function remove_liquidity_one_coin(uint256 _burn_amount, int128 i, uint256 _min_received, address _receiver) external returns (uint256);
	function ramp_A(uint256 _future_A, uint256 _future_time) external;
	function stop_ramp_A() external;
	function admin_balances(uint256 i) external view returns (uint256);
	function withdraw_admin_fees() external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.11;

interface IConvexBooster {
  function FEE_DENOMINATOR() external view returns (uint256);
  function MaxFees() external view returns (uint256);
  function addPool(address _lptoken, address _gauge, uint256 _stashVersion) external returns (bool);
  function claimRewards(uint256 _pid, address _gauge) external returns (bool);
  function crv() external view returns (address);
  function deposit(uint256 _pid, uint256 _amount, bool _stake) external returns (bool);
  function depositAll(uint256 _pid, bool _stake) external returns (bool);
  function distributionAddressId() external view returns (uint256);
  function earmarkFees() external returns (bool);
  function earmarkIncentive() external view returns (uint256);
  function earmarkRewards(uint256 _pid) external returns (bool);
  function feeDistro() external view returns (address);
  function feeManager() external view returns (address);
  function feeToken() external view returns (address);
  function gaugeMap(address) external view returns (bool);
  function isShutdown() external view returns (bool);
  function lockFees() external view returns (address);
  function lockIncentive() external view returns (uint256);
  function lockRewards() external view returns (address);
  function minter() external view returns (address);
  function owner() external view returns (address);
  function platformFee() external view returns (uint256);
  function poolInfo(uint256) external view returns (address lptoken, address token, address gauge, address crvRewards, address stash, bool shutdown);
  function poolLength() external view returns (uint256);
  function poolManager() external view returns (address);
  function registry() external view returns (address);
  function rewardArbitrator() external view returns (address);
  function rewardClaimed(uint256 _pid, address _address, uint256 _amount) external returns (bool);
  function rewardFactory() external view returns (address);
  function setArbitrator(address _arb) external;
  function setFactories(address _rfactory, address _sfactory, address _tfactory) external;
  function setFeeInfo() external;
  function setFeeManager(address _feeM) external;
  function setFees(uint256 _lockFees, uint256 _stakerFees, uint256 _callerFees, uint256 _platform) external;
  function setGaugeRedirect(uint256 _pid) external returns (bool);
  function setOwner(address _owner) external;
  function setPoolManager(address _poolM) external;
  function setRewardContracts(address _rewards, address _stakerRewards) external;
  function setTreasury(address _treasury) external;
  function setVoteDelegate(address _voteDelegate) external;
  function shutdownPool(uint256 _pid) external returns (bool);
  function shutdownSystem() external;
  function staker() external view returns (address);
  function stakerIncentive() external view returns (uint256);
  function stakerRewards() external view returns (address);
  function stashFactory() external view returns (address);
  function tokenFactory() external view returns (address);
  function treasury() external view returns (address);
  function vote(uint256 _voteId, address _votingAddress, bool _support) external returns (bool);
  function voteDelegate() external view returns (address);
  function voteGaugeWeight(address[] memory _gauge, uint256[] memory _weight) external returns (bool);
  function voteOwnership() external view returns (address);
  function voteParameter() external view returns (address);
  function withdraw(uint256 _pid, uint256 _amount) external returns (bool);
  function withdrawAll(uint256 _pid) external returns (bool);
  function withdrawTo(uint256 _pid, uint256 _amount, address _to) external returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.11;

interface IConvexBaseRewardPool {
  function addExtraReward(address _reward) external returns (bool);
  function balanceOf(address account) external view returns (uint256);
  function clearExtraRewards() external;
  function currentRewards() external view returns (uint256);
  function donate(uint256 _amount) external returns (bool);
  function duration() external view returns (uint256);
  function earned(address account) external view returns (uint256);
  function extraRewards(uint256) external view returns (address);
  function extraRewardsLength() external view returns (uint256);
  function getReward() external returns (bool);
  function getReward(address _account, bool _claimExtras) external returns (bool);
  function historicalRewards() external view returns (uint256);
  function lastTimeRewardApplicable() external view returns (uint256);
  function lastUpdateTime() external view returns (uint256);
  function newRewardRatio() external view returns (uint256);
  function operator() external view returns (address);
  function periodFinish() external view returns (uint256);
  function pid() external view returns (uint256);
  function queueNewRewards(uint256 _rewards) external returns (bool);
  function queuedRewards() external view returns (uint256);
  function rewardManager() external view returns (address);
  function rewardPerToken() external view returns (uint256);
  function rewardPerTokenStored() external view returns (uint256);
  function rewardRate() external view returns (uint256);
  function rewardToken() external view returns (address);
  function rewards(address) external view returns (uint256);
  function stake(uint256 _amount) external returns (bool);
  function stakeAll() external returns (bool);
  function stakeFor(address _for, uint256 _amount) external returns (bool);
  function stakingToken() external view returns (address);
  function totalSupply() external view returns (uint256);
  function userRewardPerTokenPaid(address) external view returns (uint256);
  function withdraw(uint256 amount, bool claim) external returns (bool);
  function withdrawAll(bool claim) external;
  function withdrawAllAndUnwrap(bool claim) external;
  function withdrawAndUnwrap(uint256 amount, bool claim) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "src/interfaces/IERC20.sol";
import "src/interfaces/curve/IMetaPool.sol";
import "src/interfaces/curve/IZapDepositor3pool.sol";

abstract contract CurvePoolAdapter {

    IERC20 public dola;
    IMetaPool public crvMetapool;
    uint public constant PRECISION = 10_000;
    uint public immutable CRVPRECISION = 10**18;

    constructor(address dola_, address crvMetapool_){
        dola = IERC20(dola_);
        crvMetapool = IMetaPool(crvMetapool_);
        //Approve max uint256 spend for crvMetapool, from this address
        dola.approve(crvMetapool_, type(uint256).max);
        IERC20(crvMetapool_).approve(crvMetapool_, type(uint256).max);
    }
    /**
    @notice Function for depositing into curve metapool.

    @param amountDola Amount of dola to be deposited into metapool

    @param allowedSlippage Max allowed slippage. 1 = 0.01%

    @return Amount of Dola-3CRV tokens bought
    */
    function metapoolDeposit(uint256 amountDola, uint allowedSlippage) internal returns(uint256){
        //TODO: Should this be corrected for 3CRV virtual price?
        uint[2] memory amounts = [amountDola, 0];
        uint minCrvLPOut = amountDola * CRVPRECISION / crvMetapool.get_virtual_price() * (PRECISION - allowedSlippage) / PRECISION;
        return crvMetapool.add_liquidity(amounts, minCrvLPOut);
    }

    /**
    @notice Function for depositing into curve metapool.

    @param amountDola Amount of dola to be withdrawn from the metapool

    @param allowedSlippage Max allowed slippage. 1 = 0.01%

    @return Amount of Dola tokens received
    */
    function metapoolWithdraw(uint amountDola, uint allowedSlippage) internal returns(uint256){
        uint[2] memory amounts = [amountDola, 0];
        uint amountCrvLp = crvMetapool.calc_token_amount( amounts, false);
        uint expectedCrvLp = amountDola * CRVPRECISION / crvMetapool.get_virtual_price();
        //The expectedCrvLp must be higher or equal than the crvLp amount we supply - the allowed slippage
        require(expectedCrvLp >= applySlippage(amountCrvLp, allowedSlippage), "LOSS EXCEED WITHDRAW MAX LOSS");
        uint dolaMinOut = applySlippage(amountDola, allowedSlippage);
        return crvMetapool.remove_liquidity_one_coin(amountCrvLp, 0, dolaMinOut);
    }

    function applySlippage(uint amount, uint allowedSlippage) internal pure returns(uint256){
        return amount * (PRECISION - allowedSlippage) / PRECISION;
    }

    function lpForDola(uint amountDola) internal view returns(uint256){
        uint[2] memory amounts = [amountDola, 0];
        return crvMetapool.calc_token_amount(amounts, false);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;


interface IZapDepositor3pool {
  function add_liquidity(address _pool, uint256[4] memory _deposit_amounts, uint256 _min_mint_amount) external returns (uint256);
  function add_liquidity(address _pool, uint256[4] memory _deposit_amounts, uint256 _min_mint_amount, address _receiver) external returns (uint256);
  function add_liquidity(address _pool, uint256[4] memory _deposit_amounts, uint256 _min_mint_amount, address _receiver, bool _use_underlying) external returns (uint256);
  function remove_liquidity(address _pool, uint256 _burn_amount, uint256[4] memory _min_amounts) external returns (uint256[4] memory);
  function remove_liquidity(address _pool, uint256 _burn_amount, uint256[4] memory _min_amounts, address _receiver) external returns (uint256[4] memory);
  function remove_liquidity(address _pool, uint256 _burn_amount, uint256[4] memory _min_amounts, address _receiver, bool _use_underlying) external returns (uint256[4] memory);
  function remove_liquidity_one_coin(address _pool, uint256 _burn_amount, int128 i, uint256 _min_amount) external returns (uint256);
  function remove_liquidity_one_coin(address _pool, uint256 _burn_amount, int128 i, uint256 _min_amount, address _receiver) external returns (uint256);
  function remove_liquidity_one_coin(address _pool, uint256 _burn_amount, int128 i, uint256 _min_amount, address _receiver, bool _use_underlying) external returns (uint256);
  function remove_liquidity_imbalance(address _pool, uint256[4] memory _amounts, uint256 _max_burn_amount) external returns (uint256);
  function remove_liquidity_imbalance(address _pool, uint256[4] memory _amounts, uint256 _max_burn_amount, address _receiver) external returns (uint256);
  function remove_liquidity_imbalance(address _pool, uint256[4] memory _amounts, uint256 _max_burn_amount, address _receiver, bool _use_underlying) external returns (uint256);
  function calc_withdraw_one_coin(address _pool, uint256 _token_amount, int128 i) external view returns (uint256);
  function calc_token_amount(address _pool, uint256[4] memory _amounts, bool _is_deposit) external view returns (uint256);
  function exchange_underlying(address _pool, int128 _i, int128 _j, uint256 _dx, uint256 _min_dy) external returns (uint256);
  function exchange_underlying(address _pool, int128 _i, int128 _j, uint256 _dx, uint256 _min_dy, address _receiver) external returns (uint256);
  function exchange_underlying(address _pool, int128 _i, int128 _j, uint256 _dx, uint256 _min_dy, address _receiver, bool _use_underlying) external returns (uint256);
}