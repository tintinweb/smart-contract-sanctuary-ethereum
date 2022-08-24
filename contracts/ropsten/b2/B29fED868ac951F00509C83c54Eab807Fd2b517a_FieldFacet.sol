/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

import "./BeanDibbler.sol";
import "../../../libraries/LibClaim.sol";

/**
 * @author Publius
 * @title Field sows Beans.
 **/
contract FieldFacet is BeanDibbler {
    using Decimal for Decimal.D256;

    /**
     * Sow
     **/

    // Claim and Sow Beans

    /// @notice Performs a claim, then transfers allocates the beans to the user wallet, then sows the desired number of beans ()
    /// @param amount  	amount of beans to sow
    /// @param claim parameters struct for claiming tokens withdrawn from the silo
    /// @return pods amount of pods that were received
    function claimAndSowBeans(uint256 amount, LibClaim.Claim calldata claim) external nonReentrant returns (uint256 pods) {
        return _claimAndSowBeansWithMin(amount, amount, claim);
    }

    function claimAndSowBeansWithMin(
        uint256 amount,
        uint256 minAmount,
        LibClaim.Claim calldata claim
    ) external nonReentrant returns (uint256 pods) {
        return _claimAndSowBeansWithMin(amount, minAmount, claim);
    }

    function _claimAndSowBeansWithMin(
        uint256 amount,
        uint256 minAmount,
        LibClaim.Claim calldata claim
    ) private returns (uint256 pods) {
        amount = getSowAmount(amount, minAmount);
        allocateBeans(claim, amount);
        pods = _sowBeans(amount, false);
        LibMarket.claimRefund(claim);
    }

    // Claim, Buy and Sow Beans

    /// @notice Performs a claim, then transfers allocates the beans to the user wallet. Subsequently, it buys the specified number of beans and immediately deposits those beans in the silo, then sows the desired number of beans
    /// @param amount amount of beans to sow
    /// @param buyAmount amount of beans to buy
    /// @param claim parameters struct for claiming tokens withdrawn from the silo
    /// @return pods amount of pods that were received
    function claimBuyAndSowBeans(
        uint256 amount,
        uint256 buyAmount,
        LibClaim.Claim calldata claim
    ) external payable nonReentrant returns (uint256 pods) {
        return _claimBuyAndSowBeansWithMin(amount, buyAmount, amount + buyAmount, claim);
    }

    function claimBuyAndSowBeansWithMin(
        uint256 amount,
        uint256 buyAmount,
        uint256 minAmount,
        LibClaim.Claim calldata claim
    ) external payable nonReentrant returns (uint256 pods) {
        return _claimBuyAndSowBeansWithMin(amount, buyAmount, minAmount, claim);
    }

    function _claimBuyAndSowBeansWithMin(
        uint256 amount,
        uint256 buyAmount,
        uint256 minAmount,
        LibClaim.Claim calldata claim
    ) private returns (uint256 pods) {
        uint256 ethAmount;
        (amount, buyAmount, ethAmount) = getBuyAndSowAmount(amount, buyAmount, minAmount, msg.value);
        allocateBeans(claim, amount);
        uint256 boughtAmount = LibMarket.buyAndSow(buyAmount, ethAmount);
        pods = _sowBeans(boughtAmount + amount, false);
        LibMarket.refund();
    }

    // Sow Beans

    /// @notice Sows the specified number of beans
    /// @param amount amount of beans to sow
    /// @return uint256 amount of pods that were received
    function sowBeans(uint256 amount) external returns (uint256) {
        return sowBeansWithMin(amount, amount);
    }

    function sowBeansWithMin(uint256 amount, uint256 minAmount) public returns (uint256) {
        amount = getSowAmount(amount, minAmount);
        return _sowBeans(amount, true);
    }

    // Buy and Sow Beans

    /// @notice Buys the specified number of beans and immediately deposits those beans in the silo, then sows the desired number of beans.
    /// @param amount amount of beans to sow
    /// @param buyAmount amount of beans to buy
    /// @return pods amount of pods that were received
    function buyAndSowBeans(uint256 amount, uint256 buyAmount) external payable nonReentrant returns (uint256 pods) {
        return _buyAndSowBeansWithMin(amount, buyAmount, amount + buyAmount);
    }

    function buyAndSowBeansWithMin(
        uint256 amount,
        uint256 buyAmount,
        uint256 minAmount
    ) external payable nonReentrant returns (uint256 pods) {
        return _buyAndSowBeansWithMin(amount, buyAmount, minAmount);
    }

    function _buyAndSowBeansWithMin(
        uint256 amount,
        uint256 buyAmount,
        uint256 minAmount
    ) private returns (uint256 pods) {
        uint256 ethAmount;
        (amount, buyAmount, ethAmount) = getBuyAndSowAmount(amount, buyAmount, minAmount, msg.value);
        uint256 boughtAmount = LibMarket.buyAndSow(buyAmount, ethAmount);
        if (amount > 0) bean().transferFrom(msg.sender, address(this), amount);
        pods = _sowBeans(boughtAmount + amount, false);
        LibMarket.refund();
    }

    // Helpers

    /// @notice Performs a claim. It then allocates the desired number of beans to the users wallet.
    /// @param c parameters struct for claiming tokens withdrawn from the silo
    /// @param transferBeans number of beans to allocate to the user wallet
    function allocateBeans(LibClaim.Claim calldata c, uint256 transferBeans) private {
        LibClaim.claim(c);
        LibMarket.allocateBeans(transferBeans);
    }

    function getSowAmount(uint256 amount, uint256 minAmount) private view returns (uint256 maxSowAmount) {
        maxSowAmount = s.f.soil;
        require(maxSowAmount >= minAmount && amount >= minAmount && minAmount > 0, "Field: Sowing below min or 0 pods.");
        if (amount < maxSowAmount) return amount;
    }

    function getBuyAndSowAmount(
        uint256 amount,
        uint256 buyAmount,
        uint256 minAmount,
        uint256 ethAmount
    )
        private
        view
        returns (
            uint256 maxSowAmount,
            uint256 sowBuyAmount,
            uint256 sowEthAmount
        )
    {
        maxSowAmount = s.f.soil;
        require(maxSowAmount >= minAmount && amount + buyAmount >= minAmount && minAmount > 0, "Field: Sowing below min or 0 pods.");
        if (amount + buyAmount <= maxSowAmount) return (amount, buyAmount, ethAmount);
        if (amount < maxSowAmount) {
            sowBuyAmount = maxSowAmount - amount;
            sowEthAmount = ((ethAmount - 1) * sowBuyAmount) / buyAmount + 1;
            return (amount, sowBuyAmount, sowEthAmount);
        }
    }
}

/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

import "../../../interfaces/IBean.sol";
import "../../../libraries/LibDibbler.sol";
import "../../ReentrancyGuard.sol";

/**
 * @author Publius
 * @title Dibbler
 **/
contract BeanDibbler is ReentrancyGuard {
    using Decimal for Decimal.D256;

    event Sow(address indexed account, uint256 index, uint256 beans, uint256 pods);

    /**
     * Getters
     **/

    /// @notice Getter for the net total number of pods excluding the number of harvested pods (несобранные стручки)
    /// @return uint256 net total number of pods excluding the number of harvested pods
    function totalPods() public view returns (uint256) {
        return s.f.pods - s.f.harvested;
    }

    /// @notice Getter for the current index of the pods (все стручки)
    /// @return uint256 the current index of the pods
    function podIndex() public view returns (uint256) {
        return s.f.pods;
    }

    /// @notice Getter for the current index of the harvestable pods (созревшие стручки)
    /// @return uint256 the current index of the harvestable pods
    function harvestableIndex() public view returns (uint256) {
        return s.f.harvestable;
    }

    /// @notice Getter for the current index of the harvested pods (собранные стручки)
    /// @return uint256 the current index of the harvested pods
    function harvestedIndex() public view returns (uint256) {
        return s.f.harvested;
    }

    /// @notice Getter for the number of total harvestable pods (созревшие несобранные стручки)
    /// @return uint256 he number of total harvestable pods
    function totalHarvestable() public view returns (uint256) {
        return s.f.harvestable - s.f.harvested;
    }

    /// @notice Getter for the number of total unripened pods (несозревшие стручки)
    /// @return uint256 the number of total unripened pods
    function totalUnripenedPods() public view returns (uint256) {
        return s.f.pods - s.f.harvestable;
    }

    /// @notice Getter for the current number of pods at a particular plot id for a particular account ()
    /// @param account address of the account to retrieve number of pods
    /// @param plotId plot id to retrieve number of pods from
    /// @return uint256 the current number of pods at a particular plot id for a particular account
    function plot(address account, uint256 plotId) public view returns (uint256) {
        return s.a[account].field.plots[plotId];
    }

    /// @notice Getter for the total amount of soil currently (вся почва)
    /// @return uint256 the total amount of soil currently
    function totalSoil() public view returns (uint256) {
        return s.f.soil;
    }

    /**
     * Internal
     **/

    /// @notice Internal Function for sowing a specified amount of beans and returns the amount of pods received (посев бобов и получение стручков)
    /// @param amount amount of beans to sow
    /// @param fromWallet ()
    /// @return pods the amount of pods received
    function _sowBeans(uint256 amount, bool fromWallet) internal returns (uint256 pods) {
        pods = LibDibbler.sow(amount, msg.sender);
        if (fromWallet) bean().burnFrom(msg.sender, amount);
        else bean().burn(amount);
        LibCheck.beanBalanceCheck();
    }

    /// @notice Internal Function for retrieving the IBean object for the bean token ()
    /// @return IBean the IBean object for the bean token
    function bean() internal view returns (IBean) {
        return IBean(s.c.bean);
    }
}

/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

import "./LibCheck.sol";
import "./LibInternal.sol";
import "./LibMarket.sol";
import "./LibAppStorage.sol";
import "../interfaces/IWETH.sol";

/**
 * @author Publius
 * @title Claim Library handles claiming Popcorn and LP withdrawals, harvesting plots and claiming Ether.
 **/
library LibClaim {
    event BeanClaim(address indexed account, uint32[] withdrawals, uint256 beans);
    event LPClaim(address indexed account, uint32[] withdrawals, uint256 lp);
    event BnbClaim(address indexed account, uint256 bnb);
    event Harvest(address indexed account, uint256[] plots, uint256 beans);
    event PodListingCancelled(address indexed account, uint256 indexed index);

    struct Claim {
        uint32[] beanWithdrawals;
        uint32[] lpWithdrawals;
        uint256[] plots;
        bool claimBnb;
        bool convertLP;
        uint256 minBeanAmount;
        uint256 minEthAmount;
        bool toWallet;
    }

    function claim(Claim calldata c) public returns (uint256 beansClaimed) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (c.beanWithdrawals.length > 0) beansClaimed = beansClaimed + claimBeans(c.beanWithdrawals);
        if (c.plots.length > 0) beansClaimed = beansClaimed + harvest(c.plots);
        if (c.lpWithdrawals.length > 0) {
            if (c.convertLP) {
                if (!c.toWallet) beansClaimed = beansClaimed + removeClaimLPAndWrapBeans(c.lpWithdrawals, c.minBeanAmount, c.minEthAmount);
                else removeAndClaimLP(c.lpWithdrawals, c.minBeanAmount, c.minEthAmount);
            } else claimLP(c.lpWithdrawals);
        }
        if (c.claimBnb) claimBnb();

        if (beansClaimed > 0) {
            if (c.toWallet) IBean(s.c.bean).transfer(msg.sender, beansClaimed);
            else s.a[msg.sender].wrappedBeans = s.a[msg.sender].wrappedBeans + beansClaimed;
        }
    }

    // Claim Beans

    function claimBeans(uint32[] calldata withdrawals) public returns (uint256 beansClaimed) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        for (uint256 i; i < withdrawals.length; i++) {
            require(withdrawals[i] <= s.season.current, "Claim: Withdrawal not recievable.");
            beansClaimed = beansClaimed + claimBeanWithdrawal(msg.sender, withdrawals[i]);
        }
        emit BeanClaim(msg.sender, withdrawals, beansClaimed);
    }

    function claimBeanWithdrawal(address account, uint32 _s) private returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 amount = s.a[account].bean.withdrawals[_s];
        require(amount > 0, "Claim: Popcorn withdrawal is empty.");
        delete s.a[account].bean.withdrawals[_s];
        s.bean.withdrawn = s.bean.withdrawn - amount;
        return amount;
    }

    // Claim LP

    function claimLP(uint32[] calldata withdrawals) public {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 lpClaimed = _claimLP(withdrawals);
        IPancakePair(s.c.pair).transfer(msg.sender, lpClaimed);
    }

    function removeAndClaimLP(
        uint32[] calldata withdrawals,
        uint256 minBeanAmount,
        uint256 minEthAmount
    ) public returns (uint256 beans) {
        uint256 lpClaimd = _claimLP(withdrawals);
        (beans, ) = LibMarket.removeLiquidity(lpClaimd, minBeanAmount, minEthAmount);
    }

    function removeClaimLPAndWrapBeans(
        uint32[] calldata withdrawals,
        uint256 minBeanAmount,
        uint256 minEthAmount
    ) private returns (uint256 beans) {
        uint256 lpClaimd = _claimLP(withdrawals);
        (beans, ) = LibMarket.removeLiquidityWithBeanAllocation(lpClaimd, minBeanAmount, minEthAmount);
    }

    function _claimLP(uint32[] calldata withdrawals) private returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 lpClaimd = 0;
        for (uint256 i; i < withdrawals.length; i++) {
            require(withdrawals[i] <= s.season.current, "Claim: Withdrawal not recievable.");
            lpClaimd = lpClaimd + claimLPWithdrawal(msg.sender, withdrawals[i]);
        }
        emit LPClaim(msg.sender, withdrawals, lpClaimd);
        return lpClaimd;
    }

    function claimLPWithdrawal(address account, uint32 _s) private returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 amount = s.a[account].lp.withdrawals[_s];
        require(amount > 0, "Claim: LP withdrawal is empty.");
        delete s.a[account].lp.withdrawals[_s];
        s.lp.withdrawn = s.lp.withdrawn - amount;
        return amount;
    }

    // Season of Plenty

    function claimBnb() public {
        LibInternal.updateSilo(msg.sender);
        uint256 bnb = claimPlenty(msg.sender);
        emit BnbClaim(msg.sender, bnb);
    }

    function claimPlenty(address account) private returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (s.sop.base == 0) return 0;
        uint256 eth = (s.a[account].sop.base * s.sop.weth) / s.sop.base;
        s.sop.weth = s.sop.weth - eth;
        s.sop.base = s.sop.base - s.a[account].sop.base;
        s.a[account].sop.base = 0;
        IWETH(s.c.weth).withdraw(eth);
        (bool success, ) = account.call{value: eth}("");
        require(success, "WETH: BNB transfer failed");
        return eth;
    }

    // Harvest

    function harvest(uint256[] calldata plots) public returns (uint256 beansHarvested) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        for (uint256 i; i < plots.length; i++) {
            require(plots[i] < s.f.harvestable, "Claim: Plot not harvestable.");
            require(s.a[msg.sender].field.plots[plots[i]] > 0, "Claim: Plot not harvestable.");
            uint256 harvested = harvestPlot(msg.sender, plots[i]);
            beansHarvested = beansHarvested + harvested;
        }
        require(s.f.harvestable - s.f.harvested >= beansHarvested, "Claim: Not enough Harvestable.");
        s.f.harvested = s.f.harvested + beansHarvested;
        emit Harvest(msg.sender, plots, beansHarvested);
    }

    function harvestPlot(address account, uint256 plotId) private returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 pods = s.a[account].field.plots[plotId];
        require(pods > 0, "Claim: Plot is empty.");
        uint256 harvestablePods = s.f.harvestable - plotId;
        delete s.a[account].field.plots[plotId];
        if (s.podListings[plotId] > 0) {
            cancelPodListing(plotId);
        }
        if (harvestablePods >= pods) return pods;
        s.a[account].field.plots[plotId + harvestablePods] = pods - harvestablePods;
        return harvestablePods;
    }

    function cancelPodListing(uint256 index) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        delete s.podListings[index];
        emit PodListingCancelled(msg.sender, index);
    }
}

/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @author Publius
 * @title Popcorn Interface
 **/
abstract contract IBean is IERC20 {
    function burn(uint256 amount) public virtual;

    function burnFrom(address account, uint256 amount) public virtual;

    function mint(address account, uint256 amount) public virtual returns (bool);
}

/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

import "../C.sol";
import "../interfaces/IBean.sol";
import "./Decimal.sol";
import "./LibCheck.sol";
import "./LibAppStorage.sol";

/**
 * @author Publius
 * @title Dibbler
 **/
library LibDibbler {
    using Decimal for Decimal.D256;

    event Sow(address indexed account, uint256 index, uint256 beans, uint256 pods);

    /**
     * Shed
     **/

    function sow(uint256 amount, address account) internal returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        // We can assume amount <= soil from getSowAmount
        s.f.soil = s.f.soil - amount;
        return sowNoSoil(amount, account);
    }

    function sowNoSoil(uint256 amount, address account) internal returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 pods = beansToPods(amount, s.w.yield);
        require(pods > 0, "Field: Must receive non-zero Pods.");
        sowPlot(account, amount, pods);
        s.f.pods = s.f.pods + pods;
        saveSowTime();
        return pods;
    }

    function sowPlot(
        address account,
        uint256 beans,
        uint256 pods
    ) private {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.a[account].field.plots[s.f.pods] = pods;
        emit Sow(account, s.f.pods, beans, pods);
    }

    function beansToPods(uint256 beanstalks, uint256 y) private pure returns (uint256) {
        Decimal.D256 memory rate = Decimal.ratio(y, 100).add(Decimal.one());
        return Decimal.from(beanstalks).mul(rate).asUint256();
    }

    function saveSowTime() private {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (s.f.soil > 1e18 || s.w.nextSowTime < type(uint32).max) return;
        s.w.nextSowTime = uint32(block.timestamp - s.season.timestamp);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;
import "../libraries/LibInternal.sol";
import "./AppStorage.sol";

/**
 * @author Farmer Farms
 * @title Variation of Oepn Zeppelins reentrant guard to include Silo Update
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts%2Fsecurity%2FReentrancyGuard.sol
 **/
abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    AppStorage internal s;

    modifier updateSilo() {
        LibInternal.updateSilo(msg.sender);
        _;
    }
    
    modifier updateSiloNonReentrant() {
        require(s.reentrantStatus != _ENTERED, "ReentrancyGuard: reentrant call");
        s.reentrantStatus = _ENTERED;
        LibInternal.updateSilo(msg.sender);
        _;
        s.reentrantStatus = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(s.reentrantStatus != _ENTERED, "ReentrancyGuard: reentrant call");
        s.reentrantStatus = _ENTERED;
        _;
        s.reentrantStatus = _NOT_ENTERED;
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

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

import "./interfaces/pancake/IPancakePair.sol";
import "./interfaces/IBean.sol";
import "./libraries/Decimal.sol";

/**
 * @author Publius
 * @title C holds the contracts for Farmer.
 **/
library C {
    using Decimal for Decimal.D256;

    // Constants
    uint256 private constant PERCENT_BASE = 1e18; // BSC

    // Chain
    uint256 private constant CHAIN_ID = 56; // BSC

    // Season
    uint256 private constant CURRENT_SEASON_PERIOD = 3600; // 1 hour
    uint256 private constant REWARD_MULTIPLIER = 1;
    uint256 private constant MAX_TIME_MULTIPLIER = 300; // seconds

    // Sun
    uint256 private constant HARVESET_PERCENTAGE = 0.5e18; // 50%

    // Weather
    uint256 private constant POD_RATE_LOWER_BOUND = 0.05e18; // 5%
    uint256 private constant OPTIMAL_POD_RATE = 0.15e18; // 15%
    uint256 private constant POD_RATE_UPPER_BOUND = 0.25e18; // 25%

    uint256 private constant DELTA_POD_DEMAND_LOWER_BOUND = 0.95e18; // 95%
    uint256 private constant DELTA_POD_DEMAND_UPPER_BOUND = 1.05e18; // 105%

    uint32 private constant STEADY_SOW_TIME = 60; // 1 minute
    uint256 private constant RAIN_TIME = 24; // 24 seasons = 1 day

    // Governance
    uint32 private constant GOVERNANCE_PERIOD = 168; // 168 seasons = 7 days
    uint32 private constant GOVERNANCE_EMERGENCY_PERIOD = 86400; // 1 day
    uint256 private constant GOVERNANCE_PASS_THRESHOLD = 5e17; // 1/2
    uint256 private constant GOVERNANCE_EMERGENCY_THRESHOLD_NUMERATOR = 2; // 2/3
    uint256 private constant GOVERNANCE_EMERGENCY_THRESHOLD_DEMONINATOR = 3; // 2/3
    uint32 private constant GOVERNANCE_EXPIRATION = 24; // 24 seasons = 1 day
    uint256 private constant GOVERNANCE_PROPOSAL_THRESHOLD = 0.001e18; // 0.1%
    uint256 private constant BASE_COMMIT_INCENTIVE = 100e6; // 100 beans
    uint256 private constant MAX_PROPOSITIONS = 5;

    // Silo
    uint256 private constant BASE_ADVANCE_INCENTIVE = 100e6; // 100 beans
    uint32 private constant WITHDRAW_TIME = 25; // 24 + 1 seasons
    uint256 private constant SEEDS_PER_BEAN = 2;
    uint256 private constant SEEDS_PER_LP_BEAN = 4;
    uint256 private constant STALK_PER_BEAN = 10000;
    uint256 private constant ROOTS_BASE = 1e12;

    // Field
    uint256 private constant MAX_SOIL_DENOMINATOR = 4; // 25%
    uint256 private constant COMPLEX_WEATHER_DENOMINATOR = 1000; // 0.1%

    // Bsc contracts
    address private constant FACTORY = address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    address private constant ROUTER = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address private constant PEG_PAIR = address(0x8CAd25b511cEeFF2F20FeA5825A6993113Aa8211);
    address private constant BUSD_TOKEN = address(0xf76D4a441E4ba86A923ce32B89AFF89dBccAA075);

    /**
     * Getters
     **/

    function getSeasonPeriod() internal pure returns (uint256) {
        return CURRENT_SEASON_PERIOD;
    }

    function getGovernancePeriod() internal pure returns (uint32) {
        return GOVERNANCE_PERIOD;
    }

    function getGovernanceEmergencyPeriod() internal pure returns (uint32) {
        return GOVERNANCE_EMERGENCY_PERIOD;
    }

    function getGovernanceExpiration() internal pure returns (uint32) {
        return GOVERNANCE_EXPIRATION;
    }

    function getGovernancePassThreshold() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: GOVERNANCE_PASS_THRESHOLD});
    }

    function getGovernanceEmergencyThreshold() internal pure returns (Decimal.D256 memory) {
        return Decimal.ratio(GOVERNANCE_EMERGENCY_THRESHOLD_NUMERATOR, GOVERNANCE_EMERGENCY_THRESHOLD_DEMONINATOR);
    }

    function getGovernanceProposalThreshold() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: GOVERNANCE_PROPOSAL_THRESHOLD});
    }

    function getAdvanceIncentive() internal pure returns (uint256) {
        return BASE_ADVANCE_INCENTIVE;
    }

    function getCommitIncentive() internal pure returns (uint256) {
        return BASE_COMMIT_INCENTIVE;
    }

    function getSiloWithdrawSeasons() internal pure returns (uint32) {
        return WITHDRAW_TIME;
    }

    function getComplexWeatherDenominator() internal pure returns (uint256) {
        return COMPLEX_WEATHER_DENOMINATOR;
    }

    function getMaxSoilDenominator() internal pure returns (uint256) {
        return MAX_SOIL_DENOMINATOR;
    }

    function getHarvestPercentage() internal pure returns (uint256) {
        return HARVESET_PERCENTAGE;
    }

    function getChainId() internal pure returns (uint256) {
        return CHAIN_ID;
    }

    function getOptimalPodRate() internal pure returns (Decimal.D256 memory) {
        return Decimal.ratio(OPTIMAL_POD_RATE, PERCENT_BASE);
    }

    function getUpperBoundPodRate() internal pure returns (Decimal.D256 memory) {
        return Decimal.ratio(POD_RATE_UPPER_BOUND, PERCENT_BASE);
    }

    function getLowerBoundPodRate() internal pure returns (Decimal.D256 memory) {
        return Decimal.ratio(POD_RATE_LOWER_BOUND, PERCENT_BASE);
    }

    function getUpperBoundDPD() internal pure returns (Decimal.D256 memory) {
        return Decimal.ratio(DELTA_POD_DEMAND_UPPER_BOUND, PERCENT_BASE);
    }

    function getLowerBoundDPD() internal pure returns (Decimal.D256 memory) {
        return Decimal.ratio(DELTA_POD_DEMAND_LOWER_BOUND, PERCENT_BASE);
    }

    function getSteadySowTime() internal pure returns (uint32) {
        return STEADY_SOW_TIME;
    }

    function getRainTime() internal pure returns (uint256) {
        return RAIN_TIME;
    }

    function getMaxPropositions() internal pure returns (uint256) {
        return MAX_PROPOSITIONS;
    }

    function getSeedsPerBean() internal pure returns (uint256) {
        return SEEDS_PER_BEAN;
    }

    function getSeedsPerLPBean() internal pure returns (uint256) {
        return SEEDS_PER_LP_BEAN;
    }

    function getStalkPerBean() internal pure returns (uint256) {
        return STALK_PER_BEAN;
    }

    function getStalkPerLPSeed() internal pure returns (uint256) {
        return STALK_PER_BEAN / SEEDS_PER_LP_BEAN;
    }

    function getRootsBase() internal pure returns (uint256) {
        return ROOTS_BASE;
    }

    function getFactory() internal pure returns (address) {
        return FACTORY;
    }

    function getRouter() internal pure returns (address) {
        return ROUTER;
    }

    function getPegPair() internal pure returns (address) {
        return PEG_PAIR;
    }

    function getRewardMultiplier() internal pure returns (uint256) {
        return REWARD_MULTIPLIER;
    }

    function getMaxTimeMultiplier() internal pure returns (uint256) {
        return MAX_TIME_MULTIPLIER;
    }

    function getBUSD() internal pure returns (address) {
        return BUSD_TOKEN;
    }
}

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

/**
 * @title Decimal
 * @author dYdX
 *
 * Library that defines a fixed-point number with 18 decimal places.
 */
library Decimal {
    // ============ Constants ============

    uint256 constant BASE = 10**18;

    // ============ Structs ============

    struct D256 {
        uint256 value;
    }

    // ============ Static Functions ============

    function zero() internal pure returns (D256 memory) {
        return D256({value: 0});
    }

    function one() internal pure returns (D256 memory) {
        return D256({value: BASE});
    }

    function from(uint256 a) internal pure returns (D256 memory) {
        return D256({value: a * (BASE)});
    }

    function ratio(uint256 a, uint256 b) internal pure returns (D256 memory) {
        return D256({value: getPartial(a, BASE, b)});
    }

    // ============ Self Functions ============

    function add(D256 memory self, uint256 b) internal pure returns (D256 memory) {
        return D256({value: self.value + (b * (BASE))});
    }

    function sub(D256 memory self, uint256 b) internal pure returns (D256 memory) {
        return D256({value: self.value - (b * (BASE))});
    }

    function sub(
        D256 memory self,
        uint256 b,
        string memory reason
    ) internal pure returns (D256 memory) {
        require(self.value >= b * BASE, reason);
        return D256({value: self.value - (b * (BASE))});
    }

    function mul(D256 memory self, uint256 b) internal pure returns (D256 memory) {
        return D256({value: self.value * (b)});
    }

    function div(D256 memory self, uint256 b) internal pure returns (D256 memory) {
        return D256({value: self.value / (b)});
    }

    function pow(D256 memory self, uint256 b) internal pure returns (D256 memory) {
        if (b == 0) {
            return one();
        }

        D256 memory temp = D256({value: self.value});
        for (uint256 i = 1; i < b; i++) {
            temp = mul(temp, self);
        }

        return temp;
    }

    function add(D256 memory self, D256 memory b) internal pure returns (D256 memory) {
        return D256({value: self.value + (b.value)});
    }

    function sub(D256 memory self, D256 memory b) internal pure returns (D256 memory) {
        return D256({value: self.value - (b.value)});
    }

    function sub(
        D256 memory self,
        D256 memory b,
        string memory reason
    ) internal pure returns (D256 memory) {
        require(self.value >= b.value, reason);
        return D256({value: self.value - (b.value)});
    }

    function mul(D256 memory self, D256 memory b) internal pure returns (D256 memory) {
        return D256({value: getPartial(self.value, b.value, BASE)});
    }

    function div(D256 memory self, D256 memory b) internal pure returns (D256 memory) {
        return D256({value: getPartial(self.value, BASE, b.value)});
    }

    function equals(D256 memory self, D256 memory b) internal pure returns (bool) {
        return self.value == b.value;
    }

    function greaterThan(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) == 2;
    }

    function lessThan(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) == 0;
    }

    function greaterThanOrEqualTo(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) > 0;
    }

    function lessThanOrEqualTo(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) < 2;
    }

    function isZero(D256 memory self) internal pure returns (bool) {
        return self.value == 0;
    }

    function asUint256(D256 memory self) internal pure returns (uint256) {
        return self.value / (BASE);
    }

    // ============ Core Methods ============

    function getPartial(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    ) private pure returns (uint256) {
        return (target * (numerator)) / (denominator);
    }

    function compareTo(D256 memory a, D256 memory b) private pure returns (uint256) {
        if (a.value == b.value) {
            return 1;
        }
        return a.value > b.value ? 2 : 0;
    }
}

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

import "../interfaces/pancake/IPancakePair.sol";
import "./LibAppStorage.sol";
import "../interfaces/IBean.sol";

/**
 * @author Publius
 * @title Check Library verifies Farmer's balances are correct.
 **/
library LibCheck {
    function beanBalanceCheck() internal view {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(IBean(s.c.bean).balanceOf(address(this)) >= s.f.harvestable - s.f.harvested + s.bean.deposited + s.bean.withdrawn, "Check: Popcorn balance fail.");
    }

    function lpBalanceCheck() internal view {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(IPancakePair(s.c.pair).balanceOf(address(this)) >= s.lp.deposited + s.lp.withdrawn, "Check: LP balance fail.");
    }

    function balanceCheck() internal view {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(IBean(s.c.bean).balanceOf(address(this)) >= s.f.harvestable - s.f.harvested + s.bean.deposited + s.bean.withdrawn, "Check: Popcorn balance fail.");
        require(IPancakePair(s.c.pair).balanceOf(address(this)) >= s.lp.deposited + s.lp.withdrawn, "Check: LP balance fail.");
    }
}

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

import "../farm/AppStorage.sol";

/**
 * @author Publius
 * @title App Storage Library allows libaries to access Farmer's state.
 **/
library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;

/**
 * @author Stanislav
 * @title Pancake Pair Interface
 **/
interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

import "../interfaces/IDiamondCut.sol";

/**
 * @author Publius
 * @title App Storage defines the state object for Farmer.
 **/
contract Account {
    // Field stores a Farmer's Plots and Pod allowances.
    struct Field {
        mapping(uint256 => uint256) plots; // A Farmer's Plots. Maps from Plot index to Pod amount.
        mapping(address => uint256) podAllowances; // An allowance mapping for Pods similar to that of the ERC-20 standard. Maps from spender address to allowance amount.
    }

    // Asset Silo is a struct that stores Deposits and Seeds per Deposit, and formerly stored Withdrawals.
    // Asset Silo currently stores Unripe Bean and Unripe LP Deposits.
    struct AssetSilo {
        mapping(uint32 => uint256) withdrawals;
        mapping(uint32 => uint256) deposits;
        mapping(uint32 => uint256) depositSeeds;
    }

    // Deposit represents a Deposit in the Silo of a given Token at a given Season.
    // Stored as two uint128 state variables to save gas.
    struct Deposit {
        uint128 amount;
        uint128 bdv;
    }

    // Silo stores Silo-related balances
    struct Silo {
        uint256 stalk; // Balance of the Farmer's normal Stalk.
        uint256 seeds; // Balance of the Farmer's normal Seeds.
    }

    // Season Of Plenty stores Season of Plenty (SOP) related balances
    struct SeasonOfPlenty {
        uint256 base;
        uint256 roots; // The number of Roots a Farmer had when it started Raining.
        uint256 basePerRoot;
    }

    // The Account level State stores all of the Farmer's balances in the contract.
    struct State {
        Field field; // A Farmer's Field storage.
        AssetSilo bean;
        AssetSilo lp;
        Silo s; // A Farmer's Silo storage.
        uint32 votedUntil; // Delete on second deploy
        uint32 lastUpdate; // The Season in which the Farmer last updated their Silo.
        uint32 lastSop; // The last Season that a SOP occured at the time the Farmer last updated their Silo.
        uint32 lastRain; // The last Season that it started Raining at the time the Farmer last updated their Silo.
        uint32 lastSIs;
        uint32 proposedUntil; // Delete on second deploy
        SeasonOfPlenty sop; // A Farmer's Season Of Plenty storage.
        uint256 roots; // A Farmer's Root balance.
        uint256 wrappedBeans;
        mapping(address => mapping(uint32 => Deposit)) deposits;  // A Farmer's Silo Deposits stored as a map from Token address to Season of Deposit to Deposit.
        mapping(address => mapping(uint32 => uint256)) withdrawals;  // A Farmer's Withdrawals from the Silo stored as a map from Token address to Season the Withdrawal becomes Claimable to Withdrawn amount of Tokens.
    }
}

contract Storage {
    // Contracts stored the contract addresses of various important contracts to Beanstalk.
    struct Contracts {
        address bean;
        address pair;
        address pegPair;
        address weth;
    }

    // Field stores global Field balances.
    struct Field {
        uint256 soil; // The number of Soil currently available.
        uint256 pods; // The pod index; the total number of Pods ever minted.
        uint256 harvested; // The harvested index; the total number of Pods that have ever been Harvested.
        uint256 harvestable; // The harvestable index; the total number of Pods that have ever been Harvestable. Included previously Harvested Beans.
    }

    // Governance
    // Delete on second deploy
    struct Bip {
        address proposer;
        uint32 start;
        uint32 period;
        bool executed;
        int256 pauseOrUnpause;
        uint128 timestamp;
        uint256 roots;
        uint256 endTotalRoots;
    }

    struct DiamondCut {
        IDiamondCut.FacetCut[] diamondCut;
        address initAddress;
        bytes initData;
    }

    struct Governance {
        uint32[] activeBips;
        uint32 bipIndex;
        mapping(uint32 => DiamondCut) diamondCuts;
        mapping(uint32 => mapping(address => bool)) voted;
        mapping(uint32 => Bip) bips;
    }

    // Silo
    struct AssetSilo {
        uint256 deposited; // The total number of a given Token currently Deposited in the Silo.
        uint256 withdrawn; // The total number of a given Token currently Withdrawn From the Silo but not Claimed.
    }

    struct IncreaseSilo {
        uint256 beans;
    }

    struct V1IncreaseSilo {
        uint256 beans;
        uint256 stalk;
        uint256 roots;
    }

    struct SeasonOfPlenty {
        uint256 weth;
        uint256 base;
        uint32 last;
    }

    struct Silo {
        uint256 stalk;
        uint256 seeds;
        uint256 roots;
    }

    // Oracle stores global level Oracle balances.
    // Currently the oracle refers to the time weighted average price calculated from the Bean:weth - usdc:weth.
    struct Oracle {
        bool initialized;  // True if the Oracle has been initialzed. It needs to be initialized on Deployment and re-initialized each Unpause.
        uint256 cumulative;
        uint256 pegCumulative;
        uint32 timestamp;  // The timestamp of the start of the current Season.
        uint32 pegTimestamp;
    }

    // Rain stores global level Rain balances. (Rain is when P > 1, Pod rate Excessively Low).
    struct Rain {
        uint32 start;
        bool raining;
        uint256 pods; // The number of Pods when it last started Raining.
        uint256 roots; // The number of Roots when it last started Raining.
    }

    // Sesaon stores global level Season balances.
    struct Season {
        // The first storage slot in Season is filled with a variety of somewhat unrelated storage variables.
        // Given that they are all smaller numbers, they are stored together for gas efficient read/write operations. 
        // Apologies if this makes it confusing :(
        uint32 current; // The current Season in Beanstalk.
        uint32 sis;
        uint8 withdrawSeasons; // The number of seasons required to Withdraw a Deposit.
        uint256 start; // The timestamp of the Beanstalk deployment rounded down to the nearest hour.
        uint256 period; // The length of each season in Beanstalk.
        uint256 timestamp; // The timestamp of the start of the current Season.
        uint256 rewardMultiplier;
        uint256 maxTimeMultiplier;
        uint256 costSunrice;
    }

    // Weather stores global level Weather balances.
    struct Weather {
        uint256 startSoil; // The number of Soil at the start of the current Season.
        uint256 lastDSoil; // Delta Soil; the number of Soil purchased last Season.
        uint32 lastSowTime; // The number of seconds it took for all but at most 1 Soil to sell out last Season.
        uint32 nextSowTime; // The number of seconds it took for all but at most 1 Soil to sell out this Season
        uint32 yield; // Weather; the interest rate for sowing Beans in Soil.
    }

    // Fundraiser stores Fundraiser data for a given Fundraiser.
    struct Fundraiser {
        address payee; // The address to be paid after the Fundraiser has been fully funded.
        address token; // The token address that used to raise funds for the Fundraiser.
        uint256 total; // The total number of Tokens that need to be raised to complete the Fundraiser.
        uint256 remaining; // The remaining number of Tokens that need to to complete the Fundraiser.
        uint256 start; // The timestamp at which the Fundraiser started (Fundraisers cannot be started and funded in the same block).
    }

    // SiloSettings stores the settings for each Token that has been Whitelisted into the Silo.
    // A Token is considered whitelisted in the Silo if there exists a non-zero SiloSettings selector.
    struct SiloSettings {
        bytes4 selector; // The encoded BDV function selector for the Token.
        uint32 seeds; // The Seeds Per BDV that the Silo mints in exchange for Depositing this Token.
        uint32 stalk; // The Stalk Per BDV that the Silo mints in exchange for Depositing this Token.
    }
}

struct AppStorage {
    uint8 index; // The index of the Bean token in the Bean:Eth Uniswap v2 pool
    int8[32] cases; // The 24 Weather cases (array has 32 items, but caseId = 3 (mod 4) are not cases).
    bool paused; // True if Beanstalk is Paused.
    uint128 pausedAt; // The timestamp at which Beanstalk was last paused. 
    Storage.Season season; // The Season storage struct found above.
    Storage.Contracts c;
    Storage.Field f; // The Field storage struct found above.
    Storage.Governance g; // The Governance storage struct found above.
    Storage.Oracle o; // The Oracle storage struct found above.
    Storage.Rain r; // The Rain storage struct found above.
    Storage.Silo s; // The Silo storage struct found above.
    uint256 reentrantStatus; // An intra-transaction state variable to protect against reentrance
    Storage.Weather w; // The Weather storage struct found above.
    Storage.AssetSilo bean;
    Storage.AssetSilo lp;
    Storage.IncreaseSilo si;
    Storage.SeasonOfPlenty sop;
    Storage.V1IncreaseSilo v1SI;
    uint256 unclaimedRoots;
    uint256 v2SIBeans;
    mapping(uint32 => uint256) sops; // A mapping from Season to Plenty Per Root (PPR) in that Season. Plenty Per Root is 0 if a Season of Plenty did not occur.
    mapping(address => Account.State) a; // A mapping from Farmer address to Account state.
    uint32 bip0Start;
    uint32 hotFix3Start;
    mapping(uint32 => Storage.Fundraiser) fundraisers; // A mapping from Fundraiser Id to Fundraiser storage.
    uint32 fundraiserIndex; // The number of Fundraisers that have occured.
    mapping(uint256 => bytes32) podListings; // A mapping from Plot Index to the hash of the Pod Listing.
    mapping(bytes32 => uint256) podOrders; // A mapping from the hash of a Pod Order to the amount of Pods that the Pod Order is still willing to buy.
    mapping(address => Storage.AssetSilo) siloBalances; // A mapping from Token address to Silo Balance storage (amount deposited and withdrawn).
    mapping(address => Storage.SiloSettings) ss;  // A mapping from Token address to Silo Settings for each Whitelisted Token. If a non-zero storage exists, a Token is whitelisted.
    // These refund variables are intra-transaction state varables use to store refund amounts
    uint256 refundStatus;
    uint256 beanRefundAmount;
    uint256 ethRefundAmount;
    uint8 pegIndex; // The index of the BUSD token in the BUSD:BNB PancakeSwap v2 pool
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

/**
 * @author Publius
 * @title Internal Library handles gas efficient function calls between facets.
 **/

interface ISiloUpdate {
    function updateSilo(address account) external payable;
}

library LibInternal {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint16 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint16 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        address[] facetAddresses;
        mapping(bytes4 => bool) supportedInterfaces;
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function updateSilo(address account) internal {
        DiamondStorage storage ds = diamondStorage();
        address facet = ds.selectorToFacetAndPosition[ISiloUpdate.updateSilo.selector].facetAddress;
        bytes memory myFunctionCall = abi.encodeWithSelector(ISiloUpdate.updateSilo.selector, account);
        (bool success, ) = address(facet).delegatecall(myFunctionCall);
        require(success, "Silo: updateSilo failed.");
    }
}

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

import "../interfaces/pancake/IPancakeRouter02.sol";
import "../interfaces/IBean.sol";
import "../interfaces/IWETH.sol";
import "./LibAppStorage.sol";
import "./LibClaim.sol";

/**
 * @author Publius
 * @title Market Library handles swapping, addinga and removing LP on Pancake for Farmer.
 **/
library LibMarket {
    event BeanAllocation(address indexed account, uint256 beans);

    struct DiamondStorage {
        address bean;
        address weth;
        address router;
    }

    struct AddLiquidity {
        uint256 beanAmount;
        uint256 minBeanAmount;
        uint256 minEthAmount;
    }

    bytes32 private constant MARKET_STORAGE_POSITION = keccak256("diamond.standard.market.storage");

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = MARKET_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function initMarket(
        address bean,
        address weth,
        address router
    ) internal {
        DiamondStorage storage ds = diamondStorage();
        ds.bean = bean;
        ds.weth = weth;
        ds.router = router;
    }

    /**
     * Swap
     **/

    function buy(uint256 buyBeanAmount) internal returns (uint256 amount) {
        (, amount) = _buy(buyBeanAmount, msg.value, msg.sender);
    }

    function buyAndDeposit(uint256 buyBeanAmount) internal returns (uint256 amount) {
        (, amount) = _buy(buyBeanAmount, msg.value, address(this));
    }

    function buyExactTokensToWallet(
        uint256 buyBeanAmount,
        address to,
        bool toWallet
    ) internal returns (uint256 amount) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (toWallet) amount = buyExactTokens(buyBeanAmount, to);
        else {
            amount = buyExactTokens(buyBeanAmount, address(this));
            s.a[to].wrappedBeans = s.a[to].wrappedBeans + amount;
        }
    }

    function buyExactTokens(uint256 buyBeanAmount, address to) internal returns (uint256 amount) {
        (uint256 ethAmount, uint256 beanAmount) = _buyExactTokens(buyBeanAmount, msg.value, to);
        allocateEthRefund(msg.value, ethAmount, false);
        return beanAmount;
    }

    function buyAndSow(uint256 buyBeanAmount, uint256 buyEthAmount) internal returns (uint256 amount) {
        if (buyBeanAmount == 0) {
            allocateEthRefund(msg.value, 0, false);
            return 0;
        }
        (uint256 ethAmount, uint256 beanAmount) = _buyExactTokensWETH(buyBeanAmount, buyEthAmount, address(this));
        allocateEthRefund(msg.value, ethAmount, false);
        amount = beanAmount;
    }

    function sellToWETH(uint256 sellBeanAmount, uint256 minBuyEthAmount) internal returns (uint256 amount) {
        (, uint256 outAmount) = _sell(sellBeanAmount, minBuyEthAmount, address(this));
        return outAmount;
    }

    /**
     *  Liquidity
     **/

    function removeLiquidity(
        uint256 liqudity,
        uint256 minBeanAmount,
        uint256 minEthAmount
    ) internal returns (uint256 beanAmount, uint256 ethAmount) {
        DiamondStorage storage ds = diamondStorage();
        return IPancakeRouter02(ds.router).removeLiquidityETH(ds.bean, liqudity, minBeanAmount, minEthAmount, msg.sender, block.timestamp);
    }

    function removeLiquidityWithBeanAllocation(
        uint256 liqudity,
        uint256 minBeanAmount,
        uint256 minEthAmount
    ) internal returns (uint256 beanAmount, uint256 ethAmount) {
        DiamondStorage storage ds = diamondStorage();
        (beanAmount, ethAmount) = IPancakeRouter02(ds.router).removeLiquidity(ds.bean, ds.weth, liqudity, minBeanAmount, minEthAmount, address(this), block.timestamp);
        allocateEthRefund(ethAmount, 0, true);
    }

    function addAndDepositLiquidity(AddLiquidity calldata al) internal returns (uint256) {
        allocateBeans(al.beanAmount);
        (, uint256 liquidity) = addLiquidity(al);
        return liquidity;
    }

    function addLiquidity(AddLiquidity calldata al) internal returns (uint256, uint256) {
        (uint256 beansDeposited, uint256 ethDeposited, uint256 liquidity) = _addLiquidity(msg.value, al.beanAmount, al.minEthAmount, al.minBeanAmount);
        allocateEthRefund(msg.value, ethDeposited, false);
        allocateBeanRefund(al.beanAmount, beansDeposited);
        return (beansDeposited, liquidity);
    }

    function swapAndAddLiquidity(
        uint256 buyBeanAmount,
        uint256 buyEthAmount,
        LibMarket.AddLiquidity calldata al
    ) internal returns (uint256) {
        uint256 boughtLP;
        if (buyBeanAmount > 0) boughtLP = LibMarket.buyBeansAndAddLiquidity(buyBeanAmount, al);
        else if (buyEthAmount > 0) boughtLP = LibMarket.buyEthAndAddLiquidity(buyEthAmount, al);
        else boughtLP = LibMarket.addAndDepositLiquidity(al);
        return boughtLP;
    }

    // al.buyBeanAmount is the amount of beans the user wants to add to LP
    // buyBeanAmount is the amount of beans the person bought to contribute to LP. Note that
    // buyBean amount will AT BEST be equal to al.buyBeanAmount because of slippage.
    // Otherwise, it will almost always be less than al.buyBean amount
    function buyBeansAndAddLiquidity(uint256 buyBeanAmount, AddLiquidity calldata al) internal returns (uint256 liquidity) {
        DiamondStorage storage ds = diamondStorage();
        IWETH(ds.weth).deposit{value: msg.value}();

        address[] memory path = new address[](2);
        path[0] = ds.weth;
        path[1] = ds.bean;
        uint256[] memory amounts = IPancakeRouter02(ds.router).getAmountsIn(buyBeanAmount, path);
        (uint256 ethSold, uint256 beans) = _buyWithWETH(buyBeanAmount, amounts[0], address(this));

        // If beans bought does not cover the amount of money to move to LP
        if (al.beanAmount > buyBeanAmount) {
            uint256 newBeanAmount = al.beanAmount - buyBeanAmount;
            allocateBeans(newBeanAmount);
            beans = beans + newBeanAmount;
        }
        uint256 ethAdded;
        (beans, ethAdded, liquidity) = _addLiquidityWETH(msg.value - ethSold, beans, al.minEthAmount, al.minBeanAmount);

        allocateBeanRefund(al.beanAmount, beans);
        allocateEthRefund(msg.value, ethAdded + ethSold, true);
        return liquidity;
    }

    // This function is called when user sends more value of POPCORN than BNB to LP.
    // Value of POPCORN is converted to equivalent value of BNB.
    function buyEthAndAddLiquidity(uint256 buyWethAmount, AddLiquidity calldata al) internal returns (uint256) {
        DiamondStorage storage ds = diamondStorage();
        uint256 sellBeans = _amountIn(buyWethAmount);
        allocateBeans(al.beanAmount + sellBeans);
        (uint256 beansSold, uint256 wethBought) = _sell(sellBeans, buyWethAmount, address(this));
        if (msg.value > 0) IWETH(ds.weth).deposit{value: msg.value}();
        (uint256 beans, uint256 ethAdded, uint256 liquidity) = _addLiquidityWETH(msg.value + wethBought, al.beanAmount, al.minEthAmount, al.minBeanAmount);

        allocateBeanRefund(al.beanAmount + sellBeans, beans + beansSold);
        allocateEthRefund(msg.value + wethBought, ethAdded, true);
        return liquidity;
    }

    /**
     *  Shed
     **/

    function _sell(
        uint256 sellBeanAmount,
        uint256 minBuyEthAmount,
        address to
    ) internal returns (uint256 inAmount, uint256 outAmount) {
        DiamondStorage storage ds = diamondStorage();
        address[] memory path = new address[](2);
        path[0] = ds.bean;
        path[1] = ds.weth;
        uint256[] memory amounts = IPancakeRouter02(ds.router).swapExactTokensForTokens(sellBeanAmount, minBuyEthAmount, path, to, block.timestamp);
        return (amounts[0], amounts[1]);
    }

    function _buy(
        uint256 beanAmount,
        uint256 ethAmount,
        address to
    ) private returns (uint256 inAmount, uint256 outAmount) {
        DiamondStorage storage ds = diamondStorage();
        address[] memory path = new address[](2);
        path[0] = ds.weth;
        path[1] = ds.bean;

        uint256[] memory amounts = IPancakeRouter02(ds.router).swapExactETHForTokens{value: ethAmount}(beanAmount, path, to, block.timestamp);
        return (amounts[0], amounts[1]);
    }

    function _buyExactTokens(
        uint256 beanAmount,
        uint256 ethAmount,
        address to
    ) private returns (uint256 inAmount, uint256 outAmount) {
        DiamondStorage storage ds = diamondStorage();
        address[] memory path = new address[](2);
        path[0] = ds.weth;
        path[1] = ds.bean;

        uint256[] memory amounts = IPancakeRouter02(ds.router).swapETHForExactTokens{value: ethAmount}(beanAmount, path, to, block.timestamp);
        return (amounts[0], amounts[1]);
    }

    function _buyExactTokensWETH(
        uint256 beanAmount,
        uint256 ethAmount,
        address to
    ) private returns (uint256 inAmount, uint256 outAmount) {
        DiamondStorage storage ds = diamondStorage();
        address[] memory path = new address[](2);
        path[0] = ds.weth;
        path[1] = ds.bean;
        IWETH(ds.weth).deposit{value: ethAmount}();
        uint256[] memory amounts = IPancakeRouter02(ds.router).swapTokensForExactTokens(beanAmount, ethAmount, path, to, block.timestamp);
        IWETH(ds.weth).withdraw(ethAmount - amounts[0]);
        return (amounts[0], amounts[1]);
    }

    function _buyWithWETH(
        uint256 beanAmount,
        uint256 ethAmount,
        address to
    ) internal returns (uint256 inAmount, uint256 outAmount) {
        DiamondStorage storage ds = diamondStorage();
        address[] memory path = new address[](2);
        path[0] = ds.weth;
        path[1] = ds.bean;

        uint256[] memory amounts = IPancakeRouter02(ds.router).swapExactTokensForTokens(ethAmount, beanAmount, path, to, block.timestamp);
        return (amounts[0], amounts[1]);
    }

    function _addLiquidity(
        uint256 ethAmount,
        uint256 beanAmount,
        uint256 minEthAmount,
        uint256 minBeanAmount
    )
        private
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        DiamondStorage storage ds = diamondStorage();
        return IPancakeRouter02(ds.router).addLiquidityETH{value: ethAmount}(ds.bean, beanAmount, minBeanAmount, minEthAmount, address(this), block.timestamp);
    }

    function _addLiquidityWETH(
        uint256 wethAmount,
        uint256 beanAmount,
        uint256 minWethAmount,
        uint256 minBeanAmount
    )
        internal
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        DiamondStorage storage ds = diamondStorage();
        return IPancakeRouter02(ds.router).addLiquidity(ds.bean, ds.weth, beanAmount, wethAmount, minBeanAmount, minWethAmount, address(this), block.timestamp);
    }

    function _amountIn(uint256 buyWethAmount) internal view returns (uint256) {
        DiamondStorage storage ds = diamondStorage();
        address[] memory path = new address[](2);
        path[0] = ds.bean;
        path[1] = ds.weth;
        uint256[] memory amounts = IPancakeRouter02(ds.router).getAmountsIn(buyWethAmount, path);
        return amounts[0];
    }

    function allocateBeansToWallet(
        uint256 amount,
        address to,
        bool toWallet
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (toWallet) LibMarket.allocateBeansTo(amount, to);
        else {
            LibMarket.allocateBeansTo(amount, address(this));
            s.a[to].wrappedBeans = s.a[to].wrappedBeans + amount;
        }
    }

    function transferBeans(
        address to,
        uint256 amount,
        bool toWallet
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (toWallet) IBean(s.c.bean).transferFrom(msg.sender, to, amount);
        else {
            IBean(s.c.bean).transferFrom(msg.sender, address(this), amount);
            s.a[to].wrappedBeans = s.a[to].wrappedBeans + amount;
        }
    }

    function allocateBeans(uint256 amount) internal {
        allocateBeansTo(amount, address(this));
    }

    function allocateBeansTo(uint256 amount, address to) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 wrappedBeans = s.a[msg.sender].wrappedBeans;
        uint256 remainingBeans = amount;
        if (wrappedBeans > 0) {
            if (remainingBeans > wrappedBeans) {
                s.a[msg.sender].wrappedBeans = 0;
                remainingBeans = remainingBeans - wrappedBeans;
            } else {
                s.a[msg.sender].wrappedBeans = wrappedBeans - remainingBeans;
                remainingBeans = 0;
            }
            uint256 fromWrappedBeans = amount - remainingBeans;
            emit BeanAllocation(msg.sender, fromWrappedBeans);
            if (to != address(this)) IBean(s.c.bean).transfer(to, fromWrappedBeans);
        }
        if (remainingBeans > 0) IBean(s.c.bean).transferFrom(msg.sender, to, remainingBeans);
    }

    // Allocate Popcorn Refund stores the Popcorn refund amount in the state to be refunded at the end of the transaction.
    function allocateBeanRefund(uint256 inputAmount, uint256 amount) internal {
        if (inputAmount > amount) {
            AppStorage storage s = LibAppStorage.diamondStorage();
            if (s.refundStatus % 2 == 1) {
                s.refundStatus += 1;
                s.beanRefundAmount = inputAmount - amount;
            } else s.beanRefundAmount = s.beanRefundAmount + (inputAmount - amount);
        }
    }

    // Allocate BNB Refund stores the BNB refund amount in the state to be refunded at the end of the transaction.
    function allocateEthRefund(
        uint256 inputAmount,
        uint256 amount,
        bool weth
    ) internal {
        if (inputAmount > amount) {
            AppStorage storage s = LibAppStorage.diamondStorage();
            if (weth) IWETH(s.c.weth).withdraw(inputAmount - amount);
            if (s.refundStatus < 3) {
                s.refundStatus += 2;
                s.ethRefundAmount = inputAmount - amount;
            } else s.ethRefundAmount = s.ethRefundAmount + (inputAmount - amount);
        }
    }

    function claimRefund(LibClaim.Claim calldata c) internal {
        // The only case that a Claim triggers an BNB refund is
        // if the farmer claims LP, removes the LP and wraps the underlying Beans
        if (c.convertLP && !c.toWallet && c.lpWithdrawals.length > 0) refund();
    }

    function refund() internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        // If Refund state = 1 -> No refund
        // If Refund state is even -> Refund Beans
        // if Refund state > 2 -> Refund BNB

        uint256 rs = s.refundStatus;
        if (rs > 1) {
            if (rs > 2) {
                (bool success, ) = msg.sender.call{value: s.ethRefundAmount}("");
                require(success, "Market: Refund failed.");
                rs -= 2;
                s.ethRefundAmount = 1;
            }
            if (rs == 2) {
                IBean(s.c.bean).transfer(msg.sender, s.beanRefundAmount);
                s.beanRefundAmount = 1;
            }
            s.refundStatus = 1;
        }
    }
}

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @author Publius
 * @title WETH Interface
 **/
interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

import { IPancakeRouter01 } from "./IPancakeRouter01.sol";

/**
 * @author Stanislav
 * @title Pancake Router02 Interface
 **/
interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

/**
 * @author Stanislav
 * @title Pancake Router01 Interface
 **/
interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}