pragma solidity ^0.8.13;

import "IERC20.sol";
import "IVault.sol";
import "IAuraLocker.sol";
import "IAuraBalRewardPool.sol";
import {BalancerStablepoolAdapter} from "BalancerStablepoolAdapter.sol";

interface IAuraBooster {
    function depositAll(uint _pid, bool _stake) external;
    function withdraw(uint _pid, uint _amount) external;
    function poolInfo(uint _pid) external returns(address lptoken, address token, address gauge, address crvRewards, address stash, bool shutdown);
}

contract AuraStablepoolFed is BalancerStablepoolAdapter{

    IAuraBalRewardPool public dolaBptRewardPool;
    IAuraBooster public booster;
    IERC20 public bal;
    IERC20 public aura;
    address public chair; // Fed Chair
    address public guardian;
    address public gov;
    uint public dolaSupply;
    uint public constant pid = 122; //Gauge pid, should never change
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
            address booster_,
            address chair_,
            address guardian_,
            address gov_, 
            uint maxLossExpansionBps_,
            uint maxLossWithdrawBps_,
            uint maxLossTakeProfitBps_,
            bytes32 poolId_) 
            BalancerStablepoolAdapter(poolId_, dola_, vault_)
    {
        require(maxLossExpansionBps_ < 10000, "Expansion max loss too high");
        require(maxLossWithdrawBps_ < 10000, "Withdraw max loss too high");
        require(maxLossTakeProfitBps_ < 10000, "TakeProfit max loss too high");
        booster = IAuraBooster(booster_);
        aura = IERC20(aura_);
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

    function setBaseRewardPool() public {
        require(msg.sender == chair, "ONLY CHAIR");
        require(address(dolaBptRewardPool) == address(0), "Already set");
        (,,,address baseRewardPoolAddress,,) = booster.poolInfo(pid);    
        dolaBptRewardPool = IAuraBalRewardPool(baseRewardPoolAddress);
        bal = IERC20(dolaBptRewardPool.rewardToken());
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
        _burnAndPay();
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