pragma solidity ^0.8.13;

import "src/interfaces/IERC20.sol";
import "src/interfaces/balancer/IVault.sol";
import "src/interfaces/aura/IAuraLocker.sol";
import "src/interfaces/aura/IAuraBalRewardPool.sol";
import "src/aura-fed/BalancerAdapter.sol";

interface IAuraBooster {
    function depositAll(uint _pid, bool _stake) external;
    function withdraw(uint _pid, uint _amount) external;
}

contract AuraFed is BalancerComposableStablepoolAdapter{

    IAuraBalRewardPool public dolaBptRewardPool;
    IAuraBooster public booster;
    IERC20 public bal;
    IERC20 public aura;
    address public chair; // Fed Chair
    address public guardian;
    address public gov;
    uint public dolaSupply;
    uint public constant pid = 8; //Gauge pid, should never change
    uint public maxLossExpansionBps;
    uint public maxLossWithdrawBps;
    uint public maxLossTakeProfitBps;
    uint public maxLossSetableByGuardian = 500;

    event Expansion(uint amount);
    event Contraction(uint amount);

    constructor(
            address dola_, 
            address aura_,
            address vault_,
            address dolaBptRewardPool_, 
            address booster_,
            address chair_,
            address guardian_,
            address gov_, 
            uint maxLossExpansionBps_,
            uint maxLossWithdrawBps_,
            uint maxLossTakeProfitBps_,
            bytes32 poolId_) 
            BalancerComposableStablepoolAdapter(poolId_, dola_, vault_)
    {
        require(maxLossExpansionBps_ < 10000, "Expansion max loss too high");
        require(maxLossWithdrawBps_ < 10000, "Withdraw max loss too high");
        require(maxLossTakeProfitBps_ < 10000, "TakeProfit max loss too high");
        dolaBptRewardPool = IAuraBalRewardPool(dolaBptRewardPool_);
        booster = IAuraBooster(booster_);
        aura = IERC20(aura_);
        bal = IERC20(dolaBptRewardPool.rewardToken());
        (address bpt,) = IVault(vault_).getPool(poolId_);
        IERC20(bpt).approve(booster_, type(uint256).max);
        maxLossExpansionBps = maxLossExpansionBps_;
        maxLossWithdrawBps = maxLossWithdrawBps_;
        maxLossTakeProfitBps = maxLossTakeProfitBps_;
        chair = chair_;
        gov = gov_;
        guardian = guardian_;
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
    @notice Method for current chair of the Aura FED to resign
    */
    function resign() public {
        require(msg.sender == chair, "ONLY CHAIR");
        chair = address(0);
    }

    function setMaxLossExpansionBps(uint newMaxLossExpansionBps) public {
        require(msg.sender == gov, "ONLY GOV");
        require(newMaxLossExpansionBps <= 10000, "Can't have max loss above 100%");
        maxLossExpansionBps = newMaxLossExpansionBps;
    }

    function setMaxLossWithdrawBps(uint newMaxLossWithdrawBps) public {
        require(msg.sender == gov || msg.sender == guardian, "ONLY GOV OR CHAIR");
        if(msg.sender == guardian){
            //We limit the max loss a guardian, as we only want governance to be able to set a very high maxloss 
            require(newMaxLossWithdrawBps <= maxLossSetableByGuardian, "Above allowed maxloss for chair");
        }
        require(newMaxLossWithdrawBps <= 10000, "Can't have max loss above 100%");
        maxLossWithdrawBps = newMaxLossWithdrawBps;
    }

    function setMaxLossTakeProfitBps(uint newMaxLossTakeProfitBps) public {
        require(msg.sender == gov, "ONLY GOV");
        require(newMaxLossTakeProfitBps <= 10000, "Can't have max loss above 100%");
        maxLossTakeProfitBps = newMaxLossTakeProfitBps;   
    }

    function setMaxLossSetableByGuardian(uint newMaxLossSetableByGuardian) public {
        require(msg.sender == gov, "ONLY GOV");
        require(newMaxLossSetableByGuardian < 10000);
        maxLossSetableByGuardian = newMaxLossSetableByGuardian;
    }
    /**
    @notice Deposits amount of dola tokens into balancer, before locking with aura
    @param amount Amount of dola token to deposit
    */
    function expansion(uint amount) public {
        require(msg.sender == chair, "ONLY CHAIR");
        dolaSupply += amount;
        IERC20(dola).mint(address(this), amount);
        _deposit(amount, maxLossExpansionBps);
        booster.depositAll(pid, true);
        emit Expansion(amount);
    }
    /**
    @notice Withdraws an amount of dola token to be burnt, contracting DOLA dolaSupply
    @dev Be careful when setting maxLoss parameter. There will almost always be some loss from
    slippage + trading fees that may be incurred when withdrawing from a Balancer pool.
    On the other hand, setting the maxLoss too high, may cause you to be front run by MEV
    sandwhich bots, making sure your entire maxLoss is incurred.
    Recommended to always broadcast withdrawl transactions(contraction & takeProfits)
    through a frontrun protected RPC like Flashbots RPC.
    @param amountDola The amount of dola tokens to withdraw. Note that more tokens may
    be withdrawn than requested, as price is calculated by debts to strategies, but strategies
    may have outperformed price of dola token.
    */
    function contraction(uint amountDola) public {
        require(msg.sender == chair, "ONLY CHAIR");
        //Calculate how many lp tokens are needed to withdraw the dola
        uint bptNeeded = bptNeededForDola(amountDola);
        require(bptNeeded <= bptSupply(), "Not enough BPT tokens");

        //Withdraw BPT tokens from aura, but don't claim rewards
        require(dolaBptRewardPool.withdrawAndUnwrap(bptNeeded, false), "AURA WITHDRAW FAILED");


        //Withdraw DOLA from balancer pool
        uint dolaWithdrawn = _withdraw(amountDola, maxLossWithdrawBps);
        require(dolaWithdrawn > 0, "Must contract");
        _burnAndPay();
        emit Contraction(dolaWithdrawn);
    }

    /**
    @notice Withdraws every remaining balLP token. Can take up to maxLossWithdrawBps in loss, compared to dolaSupply.
    It will still be necessary to call takeProfit to withdraw any potential rewards.
    */
    function contractAll() public {
        require(msg.sender == chair, "ONLY CHAIR");
        //dolaBptRewardPool.withdrawAllAndUnwrap(false);
        require(dolaBptRewardPool.withdrawAndUnwrap(dolaBptRewardPool.balanceOf(address(this)), false), "AURA WITHDRAW FAILED");
        uint dolaWithdrawn = _withdrawAll(maxLossWithdrawBps);
        require(dolaWithdrawn > 0, "Must contract");
        _burnAndPay();
        emit Contraction(dolaWithdrawn);
    }

    /**
    @notice Burns all dola tokens held by the fed up to the dolaSupply, taking any surplus as profit.
    */
    function _burnAndPay() internal {
        uint dolaBal = dola.balanceOf(address(this));
        if(dolaBal > dolaSupply){
            IERC20(dola).transfer(gov, dolaBal - dolaSupply);
            IERC20(dola).burn(dolaSupply);
            dolaSupply = 0;
        } else {
            IERC20(dola).burn(dolaBal);
            dolaSupply -= dolaBal;
        }
    }

    /**
    @notice Withdraws the profit generated by aura staking
    @dev See dev note on Contraction method
    */
    function takeProfit(bool harvestLP) public {
        //This takes balLP at face value, but doesn't take into account slippage or fees
        //Worth considering that the additional transaction fees incurred by withdrawing the small amount of profit generated by tx fees,
        //may not eclipse additional transaction costs. Set harvestLP = false to only withdraw bal and aura rewards.
        uint bptValue = bptSupply() * bpt.getRate() / 10**18;
        if(harvestLP && bptValue > dolaSupply) {
            require(msg.sender == chair, "ONLY CHAIR CAN TAKE BPT PROFIT");
            uint dolaSurplus = bptValue - dolaSupply;
            uint bptToWithdraw = bptNeededForDola(dolaSurplus);
            if(bptToWithdraw > dolaBptRewardPool.balanceOf(address(this))){
                bptToWithdraw = dolaBptRewardPool.balanceOf(address(this));
            }
            require(dolaBptRewardPool.withdrawAndUnwrap(bptToWithdraw, false), "AURA WITHDRAW FAILED");
            uint dolaProfit = _withdraw(dolaSurplus, maxLossTakeProfitBps);
            require(dolaProfit > 0, "NO PROFIT");
            dola.transfer(gov, dolaProfit);
        }

        require(dolaBptRewardPool.getReward(address(this), true), "Getting reward failed");
        bal.transfer(gov, bal.balanceOf(address(this)));
        aura.transfer(gov, aura.balanceOf(address(this)));
    }

    /**
    @notice Burns the remaining dola supply in case the FED has been completely contracted, and still has a negative dola balance.
    */
    function burnRemainingDolaSupply() public {
        dola.transferFrom(msg.sender, address(this), dolaSupply);
        dola.burn(dolaSupply);
        dolaSupply = 0;
    }
    
    /**
    @notice View function for getting bpt tokens in the contract + aura dolaBptRewardPool
    */
    function bptSupply() public view returns(uint){
        return IERC20(bpt).balanceOf(address(this)) + dolaBptRewardPool.balanceOf(address(this));
    }
}

pragma solidity ^0.8.13;

import "src/interfaces/balancer/IVault.sol";
import "src/interfaces/IERC20.sol";

interface IBPT is IERC20{
    function getPoolId() external view returns (bytes32);
    function getRate() external view returns (uint256);
}

contract BalancerComposableStablepoolAdapter {
    
    uint constant BPS = 10_000;
    bytes32 immutable poolId;
    IERC20 immutable dola;
    IBPT immutable bpt = IBPT(0x5b3240B6BE3E7487d61cd1AFdFC7Fe4Fa1D81e64);
    IVault immutable vault;
    IVault.FundManagement fundMan;
    
    constructor(bytes32 poolId_, address dola_, address vault_){
        poolId = poolId_;
        dola = IERC20(dola_);
        vault = IVault(vault_);
        dola.approve(vault_, type(uint).max);
        bpt.approve(vault_, type(uint).max);
        fundMan.sender = address(this);
        fundMan.fromInternalBalance = false;
        fundMan.recipient = payable(address(this));
        fundMan.toInternalBalance = false;
    }
    
    /**
    @notice Swaps exact amount of assetIn for asseetOut through a balancer pool. Output must be higher than minOut
    @dev Due to the unique design of Balancer ComposableStablePools, where BPT are part of the swappable balance, we can just swap DOLA directly for BPT
    @param assetIn Address of the asset to trade an exact amount in
    @param assetOut Address of the asset to trade for
    @param amount Amount of assetIn to trade
    @param minOut minimum amount of assetOut to receive
    */
    function swapExactIn(address assetIn, address assetOut, uint amount, uint minOut) internal {
        IVault.SingleSwap memory swapStruct;

        //Populate Single Swap struct
        swapStruct.poolId = poolId;
        swapStruct.kind = IVault.SwapKind.GIVEN_IN;
        swapStruct.assetIn = IAsset(assetIn);
        swapStruct.assetOut = IAsset(assetOut);
        swapStruct.amount = amount;
        //swapStruct.userData: User data can be left empty

        vault.swap(swapStruct, fundMan, minOut, block.timestamp+1);
    }

    /**
    @notice Deposit an amount of dola into balancer, getting balancer pool tokens in return
    @param dolaAmount Amount of dola to buy BPTs for
    @param maxSlippage Maximum amount of value that can be lost in basis points, assuming DOLA = 1$
    */
    function _deposit(uint dolaAmount, uint maxSlippage) internal returns(uint){
        uint init = bpt.balanceOf(address(this));
        uint bptWanted = bptNeededForDola(dolaAmount);
        uint minBptOut = bptWanted - bptWanted * maxSlippage / BPS;
        swapExactIn(address(dola), address(bpt), dolaAmount, minBptOut);
        uint bptOut =  bpt.balanceOf(address(this)) - init;
        return bptOut;
    }
    
    /**
    @notice Withdraws an amount of value close to dolaAmount
    @dev Will rarely withdraw an amount equal to dolaAmount, due to slippage.
    @param dolaAmount Amount of dola the withdrawer wants to withdraw
    @param maxSlippage Maximum amount of value that can be lost in basis points, assuming DOLA = 1$
    */
    function _withdraw(uint dolaAmount, uint maxSlippage) internal returns(uint){
        uint init = dola.balanceOf(address(this));
        uint bptNeeded = bptNeededForDola(dolaAmount);
        uint minDolaOut = dolaAmount - dolaAmount * maxSlippage / BPS;
        swapExactIn(address(bpt), address(dola), bptNeeded, minDolaOut);
        uint dolaOut = dola.balanceOf(address(this)) - init;
        return dolaOut;
    }

    /**
    @notice Withdraws all BPT in the contract
    @dev Will rarely withdraw an amount equal to dolaAmount, due to slippage.
    @param maxSlippage Maximum amount of value that can be lost in basis points, assuming DOLA = 1$
    */
    function _withdrawAll(uint maxSlippage) internal returns(uint){
        uint bptBal = bpt.balanceOf(address(this));
        uint expectedDolaOut = bptBal * bpt.getRate() / 10**18;
        uint minDolaOut = expectedDolaOut - expectedDolaOut * maxSlippage / BPS;
        swapExactIn(address(bpt), address(dola), bptBal, minDolaOut);
        return dola.balanceOf(address(this));
    }

    /**
    @notice Get amount of BPT equal to the value of dolaAmount, assuming Dola = 1$
    @dev Uses the getRate() function of the balancer pool to calculate the value of the dolaAmount
    @param dolaAmount Amount of DOLA to get the equal value in BPT.
    @return Uint representing the amount of BPT the dolaAmount should be worth.
    */
    function bptNeededForDola(uint dolaAmount) public view returns(uint) {
        return dolaAmount * 10**18 / bpt.getRate();
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
pragma solidity 0.8.13;

import "./IAuraLocker.sol";

interface IAuraBalRewardPool {
    function auraLocker() external view returns (IAuraLocker);

    function rewardToken() external view returns (address);
    
    function stakingToken() external view returns (address);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function stake(uint256 _amount) external returns (bool);

    function stakeAll() external returns (bool);

    function stakeFor(address _for, uint256 _amount) external  returns (bool);

    function withdrawAndUnwrap(uint256 amount, bool claim) external returns (bool);
    
    function withdrawAllAndUnwrap(bool claim) external returns (bool);

    /**
     * @dev Gives a staker their rewards
     * @param _lock Lock the rewards? If false, takes a 20% haircut
     */
    function getReward(bool _lock) external returns (bool);

    function getReward(address _addr, bool _claimExtra) external returns (bool);

    /**
     * @dev Forwards to the penalty forwarder for distro to Aura Lockers
     */
    function forwardPenalty() external;

    function periodFinish() external returns (uint);
}

pragma solidity ^0.8.13;

interface IAuraLocker {
    function delegate(address _newDelegate) external;

    function lock(address _account, uint256 _amount) external;

    function lockedBalances(address _account) view external returns (uint);

    function checkpointEpoch() external;

    function epochCount() external view returns (uint256);

    function balanceAtEpochOf(uint256 _epoch, address _user) external view returns (uint256 amount);

    function totalSupplyAtEpoch(uint256 _epoch) external view returns (uint256 supply);

    function queueNewRewards(address _rewardsToken, uint256 reward) external;

    function getReward(address _account, bool _stake) external;

    function getReward(address _account) external;

    function balanceOf(address _user) external view returns (uint256);

    function rewardTokens() external view returns (address[] memory);
}

pragma solidity ^0.8.13;

import "src/interfaces/IERC20.sol";
interface IAsset {}

interface IVault {
    
    function getInternalBalance(address user, IERC20[] memory tokens) external view returns (uint256[] memory);
    
    enum PoolSpecialization { GENERAL, MINIMAL_SWAP_INFO, TWO_TOKEN }

    function getPool(bytes32 poolId) external view returns (address, PoolSpecialization);
    
    function getPoolTokenInfo(bytes32 poolId, IERC20 token)
        external
        view
        returns (
            uint256 cash,
            uint256 managed,
            uint256 lastChangeBlock,
            address assetManager
    );

    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (
            address[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
    );

    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable;

    struct JoinPoolRequest {
        IAsset[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest memory request
    ) external;

    struct ExitPoolRequest {
        IAsset[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    enum SwapKind { GIVEN_IN, GIVEN_OUT }

    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);
}