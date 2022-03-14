pragma solidity ^0.8.10;

import "../interfaces/IAllocator.sol";
import "./interfaces/ISwapRouter.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/LiquityInterfaces.sol";
import "../types/BaseAllocator.sol";

error LUSDAllocator_InputTooLarge();
error LUSDAllocator_TreasuryAddressZero();

/**
 *  Contract deploys LUSD from treasury into the liquity stabilty pool. Each update, rewards are harvested.
 *  The allocator stakes the LQTY rewards and sells part of the ETH rewards to stack more LUSD.
 *  This contract inherits BaseAllocator is and meant to be used with Treasury extender.
 */
contract LUSDAllocatorV2 is BaseAllocator {
    using SafeERC20 for IERC20;

    /* ======== STATE VARIABLES ======== */
    IStabilityPool public immutable lusdStabilityPool = IStabilityPool(0x66017D22b0f8556afDd19FC67041899Eb65a21bb);
    ILQTYStaking public immutable lqtyStaking = ILQTYStaking(0x4f9Fbb3f1E99B56e0Fe2892e623Ed36A76Fc605d);
    ISwapRouter public immutable swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    address public treasuryAddress;
    address public immutable wethAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public immutable lqtyTokenAddress = 0x6DEA81C8171D0bA574754EF6F8b412F2Ed88c54D;
    address public hopTokenAddress = 0x6B175474E89094C44Da98b954EedeAC495271d0F; // Dai. Could be something else.

    uint256 public constant FEE_PRECISION = 1e6;
    uint256 public constant POOL_FEE_MAX = 10000;
    /**
     * @notice The target percent of eth to swap to LUSD at uniswap.  divide by 1e6 to get actual value.
     * Examples:
     * 500000 => 500000 / 1e6 = 0.50 = 50%
     * 330000 => 330000 / 1e6 = 0.33 = 33%
     */
    uint256 public ethToLUSDRatio = 330000; // 33% of ETH to LUSD
    /**
     * @notice poolFee parameter for uniswap swaprouter, divide by 1e6 to get the actual value.  See https://docs.uniswap.org/protocol/guides/swaps/multihop-swaps#calling-the-function-1
     * Maximum allowed value is 10000 (1%)
     * Examples:
     * poolFee =  3000 =>  3000 / 1e6 = 0.003 = 0.3%
     * poolFee = 10000 => 10000 / 1e6 =  0.01 = 1.0%
     */
    uint24 public poolFee = 3000; // Init the uniswap pool fee to 0.3%
    uint256 public minETHLUSDRate; // minimum amount of LUSD we are willing to swap WETH for.

    /**
     * @notice tokens in AllocatorInitData should be [LUSD Address]
     * LUSD Address (0x5f98805A4E8be255a32880FDeC7F6728C6568bA0)
     */
    constructor(
        AllocatorInitData memory data,
        address _treasuryAddress,
        uint256 _minETHLUSDRate
    ) BaseAllocator(data) {
        treasuryAddress = _treasuryAddress;
        minETHLUSDRate = _minETHLUSDRate;

        IERC20(wethAddress).safeApprove(treasuryAddress, type(uint256).max);
        IERC20(wethAddress).safeApprove(address(swapRouter), type(uint256).max);
        data.tokens[0].safeApprove(address(lusdStabilityPool), type(uint256).max);
        data.tokens[0].safeApprove(treasuryAddress, type(uint256).max);
        IERC20(lqtyTokenAddress).safeApprove(treasuryAddress, type(uint256).max);
    }

    /**
     *  @notice Need this because StabilityPool::withdrawFromSP() and LQTYStaking::stake() will send ETH here
     */
    receive() external payable {}

    /* ======== CONFIGURE FUNCTIONS for Guardian only ======== */
    /**
     *  @notice Set the target percent of eth from yield to swap to LUSD at uniswap. The rest is sent to treasury.
     *  @param _ethToLUSDRatio uint256 number between 0 and 100000. 100000 being 100%. Default is 33000 which is 33%.
     */
    function setEthToLUSDRatio(uint256 _ethToLUSDRatio) external {
        _onlyGuardian();
        if (_ethToLUSDRatio > FEE_PRECISION) revert LUSDAllocator_InputTooLarge();
        ethToLUSDRatio = _ethToLUSDRatio;
    }

    /**
     *  @notice set poolFee parameter for uniswap swaprouter
     *  @param _poolFee uint256 number between 0 and 10000. 10000 being 1%
     */
    function setPoolFee(uint24 _poolFee) external {
        _onlyGuardian();
        if (_poolFee > POOL_FEE_MAX) revert LUSDAllocator_InputTooLarge();
        poolFee = _poolFee;
    }

    /**
     *  @notice set the address of the hop token. Token to swap weth to before LUSD
     *  @param _hopTokenAddress address
     */
    function setHopTokenAddress(address _hopTokenAddress) external {
        _onlyGuardian();
        hopTokenAddress = _hopTokenAddress;
    }

    /**
     *  @notice sets minETHLUSDRate for swapping ETH for LUSD
     *  @param _rate uint
     */
    function setMinETHLUSDRate(uint256 _rate) external {
        _onlyGuardian();
        minETHLUSDRate = _rate;
    }

    /**
     *  @notice Updates address of treasury to authority.vault()
     */
    function updateTreasury() public {
        _onlyGuardian();
        if (authority.vault() == address(0)) revert LUSDAllocator_TreasuryAddressZero();
        treasuryAddress = address(authority.vault());
    }

    /* ======== INTERNAL FUNCTIONS ======== */

    /**
     *  @notice claims LQTY & ETH Rewards. minETHLUSDRate minimum rate of when swapping ETH->LUSD.  e.g. 3500 means we swap at a rate of 1 ETH for a minimum 3500 LUSD
     
        1.  Harvest from LUSD StabilityPool to get ETH+LQTY rewards
        2.  Stake LQTY rewards from #1.
        3.  If we have eth, convert to weth, then swap a percentage of it to LUSD.  If swap successul then send all remaining WETH to treasury
        4.  Deposit all LUSD in balance to into StabilityPool.
     */
    function _update(uint256 id) internal override returns (uint128 gain, uint128 loss) {
        if (getETHRewards() > 0 || getLQTYRewards() > 0) {
            // 1.  Harvest from LUSD StabilityPool to get ETH+LQTY rewards
            lusdStabilityPool.withdrawFromSP(0); //Passing 0 b/c we don't want to withdraw from the pool but harvest - see https://discord.com/channels/700620821198143498/818895484956835912/908031137010581594
        }

        // 2.  Stake LQTY rewards from #1 and any other LQTY in wallet.
        uint256 balanceLqty = IERC20(lqtyTokenAddress).balanceOf(address(this));
        if (balanceLqty > 0) {
            lqtyStaking.stake(balanceLqty); //Stake LQTY, also receives any prior ETH+LUSD rewards from prior staking
        }

        // 3.  If we have eth, convert to weth, then swap a percentage of it to LUSD.
        uint256 ethBalance = address(this).balance; // Use total balance in case we have leftover from a prior failed attempt
        bool swappedLUSDSuccessfully;
        if (ethBalance > 0) {
            // Wrap ETH to WETH
            IWETH(wethAddress).deposit{value: ethBalance}();

            if (ethToLUSDRatio > 0) {
                uint256 wethBalance = IWETH(wethAddress).balanceOf(address(this)); //Base off of WETH balance in case we have leftover from a prior failed attempt
                uint256 amountWethToSwap = (wethBalance * ethToLUSDRatio) / FEE_PRECISION;
                uint256 amountLUSDMin = amountWethToSwap * minETHLUSDRate; //WETH and LUSD is 18 decimals

                // From https://docs.uniswap.org/protocol/guides/swaps/multihop-swaps#calling-the-function-1
                // Multiple pool swaps are encoded through bytes called a `path`. A path is a sequence of token addresses and poolFees that define the pools used in the swaps.
                // The format for pool encoding is (tokenIn, fee, tokenOut/tokenIn, fee, tokenOut) where tokenIn/tokenOut parameter is the shared token across the pools.
                // Since we are swapping WETH to DAI and then DAI to LUSD the path encoding is (WETH, 0.3%, DAI, 0.3%, LUSD).
                ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
                    path: abi.encodePacked(wethAddress, poolFee, hopTokenAddress, poolFee, address(_tokens[0])),
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: amountWethToSwap,
                    amountOutMinimum: amountLUSDMin
                });

                // Executes the swap
                if (swapRouter.exactInput(params) > 0) {
                    swappedLUSDSuccessfully = true;
                }
            }
        }

        // If swap was successful (or if percent to swap is 0), send the remaining WETH to the treasury.  Crucial check otherwise we'd send all our WETH to the treasury and not respect our desired percentage
        if (ethToLUSDRatio == 0 || swappedLUSDSuccessfully) {
            uint256 wethBalance = IWETH(wethAddress).balanceOf(address(this));
            if (wethBalance > 0) {
                IERC20(wethAddress).safeTransfer(treasuryAddress, wethBalance);
            }
        }

        // 4.  Deposit all LUSD in balance to into StabilityPool.
        uint256 lusdBalance = _tokens[0].balanceOf(address(this));
        if (lusdBalance > 0) {
            lusdStabilityPool.provideToSP(lusdBalance, address(0));

            uint128 total = uint128(lusdStabilityPool.getCompoundedLUSDDeposit(address(this)));
            uint128 last = extender.getAllocatorPerformance(id).gain + uint128(extender.getAllocatorAllocated(id));
            if (total >= last) gain = total - last;
            else loss = last - total;
        }
    }

    function deallocate(uint256[] memory amounts) public override {
        _onlyGuardian();
        if (amounts[0] > 0) lusdStabilityPool.withdrawFromSP(amounts[0]);
        if (amounts[1] > 0) lqtyStaking.unstake(amounts[1]);
    }

    function _deactivate(bool panic) internal override {
        if (panic) {
            // If panic unstake everything
            _withdrawEverything();
        }
    }

    function _prepareMigration() internal override {
        _withdrawEverything();

        // Could have leftover eth from unstaking unclaimed yield.
        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            IWETH(wethAddress).deposit{value: ethBalance}();
        }

        // Don't need to transfer WETH since its a utility token it will be migrated
    }

    /**
     *  @notice Withdraws LUSD and LQTY from pools. This also may result in some ETH being sent to wallet due to unclaimed yield after withdrawing.
     */
    function _withdrawEverything() internal {
        // Will throw exception if nothing to unstake
        if (lqtyStaking.stakes(address(this)) > 0) {
            // If unstake amount > amount available to unstake will unstake everything. So max int ensures unstake max amount.
            lqtyStaking.unstake(type(uint256).max);
        }

        if (lusdStabilityPool.getCompoundedLUSDDeposit(address(this)) > 0) {
            lusdStabilityPool.withdrawFromSP(type(uint256).max);
        }
    }

    /* ======== VIEW FUNCTIONS ======== */

    /**
     * @notice This returns the amount of LUSD allocated to the pool. Does not return how much LUSD deposited since that number is increasing and compounding.
     */
    function amountAllocated(uint256 id) public view override returns (uint256) {
        if (tokenIds[id] == 0) {
            return lusdStabilityPool.getTotalLUSDDeposits();
        }
        return 0;
    }

    function rewardTokens() public view override returns (IERC20[] memory) {
        IERC20[] memory rewards = new IERC20[](1);
        rewards[0] = IERC20(lqtyTokenAddress);
        return rewards;
    }

    function utilityTokens() public view override returns (IERC20[] memory) {
        IERC20[] memory utility = new IERC20[](2);
        utility[0] = IERC20(lqtyTokenAddress);
        utility[1] = IERC20(wethAddress);
        return utility;
    }

    function name() external view override returns (string memory) {
        return "LUSD Allocator";
    }

    /**
     *  @notice get ETH rewards from SP
     *  @return uint
     */
    function getETHRewards() public view returns (uint256) {
        return lusdStabilityPool.getDepositorETHGain(address(this));
    }

    /**
     *  @notice get LQTY rewards from SP
     *  @return uint
     */
    function getLQTYRewards() public view returns (uint256) {
        return lusdStabilityPool.getDepositorLQTYGain(address(this));
    }
}

pragma solidity >=0.8.0;

// interfaces
import "./IERC20.sol";
import "./ITreasuryExtender.sol";
import "./IOlympusAuthority.sol";

enum AllocatorStatus {
    OFFLINE,
    ACTIVATED,
    MIGRATING
}

struct AllocatorInitData {
    IOlympusAuthority authority;
    ITreasuryExtender extender;
    IERC20[] tokens;
}

/**
 * @title Interface for the BaseAllocator
 * @dev
 *  These are the standard functions that an Allocator should implement. A subset of these functions
 *  is implemented in the `BaseAllocator`. Similar to those implemented, if for some reason the developer
 *  decides to implement a dedicated base contract, or not at all and rather a dedicated Allocator contract
 *  without base, imitate the functionalities implemented in it.
 */
interface IAllocator {
    /**
     * @notice
     *  Emitted when the Allocator is deployed.
     */
    event AllocatorDeployed(address authority, address extender);

    /**
     * @notice
     *  Emitted when the Allocator is activated.
     */
    event AllocatorActivated();

    /**
     * @notice
     *  Emitted when the Allocator is deactivated.
     */
    event AllocatorDeactivated(bool panic);

    /**
     * @notice
     *  Emitted when the Allocators loss limit is violated.
     */
    event LossLimitViolated(uint128 lastLoss, uint128 dloss, uint256 estimatedTotalAllocated);

    /**
     * @notice
     *  Emitted when a Migration is executed.
     * @dev
     *  After this also `AllocatorDeactivated` should follow.
     */
    event MigrationExecuted(address allocator);

    /**
     * @notice
     *  Emitted when Ether is received by the contract.
     * @dev
     *  Only the Guardian is able to send the ether.
     */
    event EtherReceived(uint256 amount);

    function update(uint256 id) external;

    function deallocate(uint256[] memory amounts) external;

    function prepareMigration() external;

    function migrate() external;

    function activate() external;

    function deactivate(bool panic) external;

    function addId(uint256 id) external;

    function name() external view returns (string memory);

    function ids() external view returns (uint256[] memory);

    function tokenIds(uint256 id) external view returns (uint256);

    function version() external view returns (string memory);

    function status() external view returns (AllocatorStatus);

    function tokens() external view returns (IERC20[] memory);

    function utilityTokens() external view returns (IERC20[] memory);

    function rewardTokens() external view returns (IERC20[] memory);

    function amountAllocated(uint256 id) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

import "../../interfaces/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}

//https://etherscan.io/address/0x66017D22b0f8556afDd19FC67041899Eb65a21bb
/*
 * The Stability Pool holds LUSD tokens deposited by Stability Pool depositors.
 *
 * When a trove is liquidated, then depending on system conditions, some of its LUSD debt gets offset with
 * LUSD in the Stability Pool:  that is, the offset debt evaporates, and an equal amount of LUSD tokens in the Stability Pool is burned.
 *
 * Thus, a liquidation causes each depositor to receive a LUSD loss, in proportion to their deposit as a share of total deposits.
 * They also receive an ETH gain, as the ETH collateral of the liquidated trove is distributed among Stability depositors,
 * in the same proportion.
 *
 * When a liquidation occurs, it depletes every deposit by the same fraction: for example, a liquidation that depletes 40%
 * of the total LUSD in the Stability Pool, depletes 40% of each deposit.
 *
 * A deposit that has experienced a series of liquidations is termed a "compounded deposit": each liquidation depletes the deposit,
 * multiplying it by some factor in range ]0,1[
 *
 * Please see the implementation spec in the proof document, which closely follows on from the compounded deposit / ETH gain derivations:
 * https://github.com/liquity/liquity/blob/master/papers/Scalable_Reward_Distribution_with_Compounding_Stakes.pdf
 *
 * --- LQTY ISSUANCE TO STABILITY POOL DEPOSITORS ---
 *
 * An LQTY issuance event occurs at every deposit operation, and every liquidation.
 *
 * Each deposit is tagged with the address of the front end through which it was made.
 *
 * All deposits earn a share of the issued LQTY in proportion to the deposit as a share of total deposits. The LQTY earned
 * by a given deposit, is split between the depositor and the front end through which the deposit was made, based on the front end's kickbackRate.
 *
 * Please see the system Readme for an overview:
 * https://github.com/liquity/dev/blob/main/README.md#lqty-issuance-to-stability-providers
 */
interface IStabilityPool {
    // --- Functions ---
    /*
     * Initial checks:
     * - Frontend is registered or zero address
     * - Sender is not a registered frontend
     * - _amount is not zero
     * ---
     * - Triggers a LQTY issuance, based on time passed since the last issuance. The LQTY issuance is shared between *all* depositors and front ends
     * - Tags the deposit with the provided front end tag param, if it's a new deposit
     * - Sends depositor's accumulated gains (LQTY, ETH) to depositor
     * - Sends the tagged front end's accumulated LQTY gains to the tagged front end
     * - Increases deposit and tagged front end's stake, and takes new snapshots for each.
     */
    function provideToSP(uint256 _amount, address _frontEndTag) external;

    /*
     * Initial checks:
     * - _amount is zero or there are no under collateralized troves left in the system
     * - User has a non zero deposit
     * ---
     * - Triggers a LQTY issuance, based on time passed since the last issuance. The LQTY issuance is shared between *all* depositors and front ends
     * - Removes the deposit's front end tag if it is a full withdrawal
     * - Sends all depositor's accumulated gains (LQTY, ETH) to depositor
     * - Sends the tagged front end's accumulated LQTY gains to the tagged front end
     * - Decreases deposit and tagged front end's stake, and takes new snapshots for each.
     *
     * If _amount > userDeposit, the user withdraws all of their compounded deposit.
     */
    function withdrawFromSP(uint256 _amount) external;

    /*
     * Initial checks:
     * - User has a non zero deposit
     * - User has an open trove
     * - User has some ETH gain
     * ---
     * - Triggers a LQTY issuance, based on time passed since the last issuance. The LQTY issuance is shared between *all* depositors and front ends
     * - Sends all depositor's LQTY gain to  depositor
     * - Sends all tagged front end's LQTY gain to the tagged front end
     * - Transfers the depositor's entire ETH gain from the Stability Pool to the caller's trove
     * - Leaves their compounded deposit in the Stability Pool
     * - Updates snapshots for deposit and tagged front end stake
     */
    function withdrawETHGainToTrove(address _upperHint, address _lowerHint) external;

    /*
     * Initial checks:
     * - Frontend (sender) not already registered
     * - User (sender) has no deposit
     * - _kickbackRate is in the range [0, 100%]
     * ---
     * Front end makes a one-time selection of kickback rate upon registering
     */
    function registerFrontEnd(uint256 _kickbackRate) external;

    /*
     * Initial checks:
     * - Caller is TroveManager
     * ---
     * Cancels out the specified debt against the LUSD contained in the Stability Pool (as far as possible)
     * and transfers the Trove's ETH collateral from ActivePool to StabilityPool.
     * Only called by liquidation functions in the TroveManager.
     */
    function offset(uint256 _debt, uint256 _coll) external;

    /*
     * Returns the total amount of ETH held by the pool, accounted in an internal variable instead of `balance`,
     * to exclude edge cases like ETH received from a self-destruct.
     */
    function getETH() external view returns (uint256);

    /*
     * Returns LUSD held in the pool. Changes when users deposit/withdraw, and when Trove debt is offset.
     */
    function getTotalLUSDDeposits() external view returns (uint256);

    /*
     * Calculates the ETH gain earned by the deposit since its last snapshots were taken.
     */
    function getDepositorETHGain(address _depositor) external view returns (uint256);

    /*
     * Calculate the LQTY gain earned by a deposit since its last snapshots were taken.
     * If not tagged with a front end, the depositor gets a 100% cut of what their deposit earned.
     * Otherwise, their cut of the deposit's earnings is equal to the kickbackRate, set by the front end through
     * which they made their deposit.
     */
    function getDepositorLQTYGain(address _depositor) external view returns (uint256);

    /*
     * Return the LQTY gain earned by the front end.
     */
    function getFrontEndLQTYGain(address _frontEnd) external view returns (uint256);

    /*
     * Return the user's compounded deposit.
     */
    function getCompoundedLUSDDeposit(address _depositor) external view returns (uint256);

    /*
     * Return the front end's compounded stake.
     *
     * The front end's compounded stake is equal to the sum of its depositors' compounded deposits.
     */
    function getCompoundedFrontEndStake(address _frontEnd) external view returns (uint256);
}

//
interface ILQTYStaking {
    /*
        sends _LQTYAmount from the caller to the staking contract, and increases their stake.
        If the caller already has a non-zero stake, it pays out their accumulated ETH and LUSD gains from staking.
    */
    function stake(uint256 _LQTYamount) external;

    /**
        reduces the caller’s stake by _LQTYamount, up to a maximum of their entire stake. 
        It pays out their accumulated ETH and LUSD gains from staking.
    */
    function unstake(uint256 _LQTYamount) external;

    function getPendingETHGain(address _user) external view returns (uint256);

    function getPendingLUSDGain(address _user) external view returns (uint256);

    function stakes(address _user) external view returns (uint256);
}

pragma solidity ^0.8.10;

// interfaces
import "../interfaces/IAllocator.sol";
import "../interfaces/ITreasury.sol";

// types
import "../types/OlympusAccessControlledV2.sol";

// libraries
import "../libraries/SafeERC20.sol";

error BaseAllocator_AllocatorNotActivated();
error BaseAllocator_AllocatorNotOffline();
error BaseAllocator_Migrating();
error BaseAllocator_NotMigrating();
error BaseAllocator_OnlyExtender(address sender);

/**
 * @title BaseAllocator
 * @notice
 *  This abstract contract serves as a template for writing new Olympus Allocators.
 *  Many of the functionalities regarding handling of Treasury funds by the Guardian have
 *  been delegated to the `TreasuryExtender` contract, and thus an explanation for them can be found
 *  in `TreasuryExtender.sol`.
 *
 *  The main purpose of this abstract contract and the `IAllocator` interface is to provide
 *  a unified framework for how an Allocator should behave. Below an explanation of how
 *  we expect an Allocator to behave in general, mentioning the most important points.
 *
 *  Activation:
 *   - An Allocator is first deployed with all necessary arguments.
 *     Thereafter, each deposit is registered with the `TreasuryExtender`.
 *     This assigns a unique id for each deposit (set of allocations) in an Allocator.
 *   - Next, the Allocators allocation and loss limits are set via the extender function.
 *   - Finally, the Allocator is activated by calling `activate`.
 *
 *  Runtime:
 *   The Allocator is in communication with the Extender, it must inform the Extender
 *   what the status of the tokens is which were allocated. We only care about noting down
 *   their status in the Extender. A quick summary of the important functions on this topic:
 *
 *   - `update(uint256 id)` is the main function that deals with state reporting, where
 *     `_update(uint256 id)` is the internal function to implement, which should update Allocator
 *     internal state. `update(uint256 id)` then continues to report the Allocators state via `report`
 *     to the extender. `_update(uint256 id)` should handle _investment_ of funds present in Contract.
 *
 *   - `deallocate` should handle allocated token withdrawal, preparing the tokens to be withdrawn
 *     by the Extender. It is not necessary to handle approvals for this token, because it is automatically
 *     approved in the constructor. For other token withdrawals, it is assumed that reward tokens will
 *     either be sold into underlying (allocated) or that they will simply rest in the Contract, being reward tokens.
 *     Please also check function documentation.
 *
 *   - `rewardTokens` and `utilityTokens` should return the above mentioned simple reward tokens for the former case,
 *     while utility tokens should be those tokens which are continously reinvested or otherwise used by the contract
 *     in order to accrue more rewards. A reward token can also be a utility token, but then one must prepare them
 *     separately for withdrawal if they are to be returned to the treasury.
 *
 *  Migration & Deactivation:
 *   - `prepareMigration()` together with the virtual `_prepareMigration()` sets the state of the Allocator into
 *     MIGRATING, disabling further token deposits, enabling only withdrawals, and preparing all funds for withdrawal.
 *
 *   - `migrate` then executes the migration and also deactivates the Allocator.
 *
 *   - `deactivate` sets `status` to OFFLINE, meaning it simply deactivates the Allocator. It can be passed
 *     a panic boolean, meaning it handles deactivation logic in `deactivate`. The Allocator panic deactivates if
 *     this state if the loss limit is reached via `update`. The Allocator can otherwise also simply be deactivated
 *     and funds transferred back to the Treasury.
 *
 *  This was a short summary of the Allocator lifecycle.
 */
abstract contract BaseAllocator is OlympusAccessControlledV2, IAllocator {
    using SafeERC20 for IERC20;

    // Indices which represent the ids of the deposits in the `TreasuryExtender`
    uint256[] internal _ids;

    // The allocated (underlying) tokens of the Allocator
    IERC20[] internal _tokens;

    // From deposit id to the token's id
    mapping(uint256 => uint256) public tokenIds;

    // Allocator status: OFFLINE, ACTIVATED, MIGRATING
    AllocatorStatus public status;

    // The extender with which the Allocator communicates.
    ITreasuryExtender public immutable extender;

    constructor(AllocatorInitData memory data) OlympusAccessControlledV2(data.authority) {
        _tokens = data.tokens;
        extender = data.extender;

        for (uint256 i; i < data.tokens.length; i++) {
            data.tokens[i].approve(address(data.extender), type(uint256).max);
        }

        emit AllocatorDeployed(address(data.authority), address(data.extender));
    }

    /////// MODIFIERS

    modifier onlyExtender {
	_onlyExtender(msg.sender);
	_;
    }

    modifier onlyActivated {
	_onlyActivated(status);
	_;
    }

    modifier onlyOffline {
	_onlyOffline(status);
	_;
    }

    modifier notMigrating {
	_notMigrating(status);
	_;
    }

    modifier isMigrating {
	_isMigrating(status);
	_;
    }

    /////// VIRTUAL FUNCTIONS WHICH NEED TO BE IMPLEMENTED
    /////// SORTED BY EXPECTED COMPLEXITY AND DEPENDENCY

    /**
     * @notice
     *  Updates an Allocators state.
     * @dev
     *  This function should be implemented by the developer of the Allocator.
     *  This function should fulfill the following purposes:
     *   - invest token specified by deposit id
     *   - handle rebalancing / harvesting for token as needed
     *   - calculate gain / loss for token and return those values
     *   - handle any other necessary runtime calculations, such as fees etc.
     *
     *  In essence, this function should update the main runtime state of the Allocator
     *  so that everything is properly invested, harvested, accounted for.
     * @param id the id of the deposit in the `TreasuryExtender`
     */
    function _update(uint256 id) internal virtual returns (uint128 gain, uint128 loss);

    /**
     * @notice
     *  Deallocates tokens, prepares tokens for return to the Treasury.
     * @dev
     *  This function should deallocate (withdraw) `amounts` of each token so that they may be withdrawn
     *  by the TreasuryExtender. Otherwise, this function may also prepare the withdraw if it is time-bound.
     * @param amounts is the amount of each of token from `_tokens` to withdraw
     */
    function deallocate(uint256[] memory amounts) public virtual;

    /**
     * @notice
     *  Handles deactivation logic for the Allocator.
     */
    function _deactivate(bool panic) internal virtual;

    /**
     * @notice
     *  Handles migration preparatory logic.
     * @dev
     *  Within this function, the developer should arrange the withdrawal of all assets for migration.
     *  A useful function, say, to be passed into this could be `deallocate` with all of the amounts,
     *  so with n places for n-1 utility tokens + 1 allocated token, maxed out.
     */
    function _prepareMigration() internal virtual;

    /**
     * @notice
     *  Should estimate total amount of Allocated tokens
     * @dev
     *  The difference between this and `treasury.getAllocatorAllocated`, is that the latter is a static
     *  value recorded during reporting, but no data is available on _new_ amounts after reporting.
     *  Thus, this should take into consideration the new amounts. This can be used for say aTokens.
     * @param id the id of the deposit in `TreasuryExtender`
     */
    function amountAllocated(uint256 id) public view virtual returns (uint256);

    /**
     * @notice
     *  Should return all reward token addresses
     */
    function rewardTokens() public view virtual returns (IERC20[] memory);

    /**
     * @notice
     *  Should return all utility token addresses
     */
    function utilityTokens() public view virtual returns (IERC20[] memory);

    /**
     * @notice
     *  Should return the Allocator name
     */
    function name() external view virtual returns (string memory);

    /////// IMPLEMENTATION OPTIONAL

    /**
     * @notice
     *  Should handle activation logic
     * @dev
     *  If there is a need to handle any logic during activation, this is the function you should implement it into
     */
    function _activate() internal virtual {}

    /////// FUNCTIONS

    /**
     * @notice
     *  Updates an Allocators state and reports to `TreasuryExtender` if necessary.
     * @dev
     *  Can only be called by the Guardian.
     *  Can only be called while the Allocator is activated.
     *
     *  This function should update the Allocators internal state via `_update`, which should in turn
     *  return the `gain` and `loss` the Allocator has sustained in underlying allocated `token` from `_tokens`
     *  decided by the `id`.
     *  Please check the docs on `_update` to see what its function should be.
     *
     *  `_lossLimitViolated` checks if the Allocators is above its loss limit and deactivates it in case
     *  of serious losses. The loss limit should be set to some value which is unnacceptable to be lost
     *  in the case of normal runtime and thus require a panic shutdown, whatever it is defined to be.
     *
     *  Lastly, the Allocator reports its state to the Extender, which handles gain, loss, allocated logic.
     *  The documentation on this can be found in `TreasuryExtender.sol`.
     * @param id the id of the deposit in `TreasuryExtender`
     */
    function update(uint256 id) external override onlyGuardian onlyActivated {
        // effects
        // handle depositing, harvesting, compounding logic inside of _update()
        // if gain is in allocated then gain > 0 otherwise gain == 0
        // we only use so we know initia
        // loss always in allocated
        (uint128 gain, uint128 loss) = _update(id);

        if (_lossLimitViolated(id, loss)) {
            deactivate(true);
            return;
        }

        // interactions
        // there is no interactions happening inside of report
        // so allocator has no state changes to make after it
        if (gain + loss > 0) extender.report(id, gain, loss);
    }

    /**
     * @notice
     *  Prepares the Allocator for token migration.
     * @dev
     *  This function prepares the Allocator for token migration by calling the to-be-implemented
     *  `_prepareMigration`, which should logically withdraw ALL allocated (1) + utility AND reward tokens
     *  from the contract. The ALLOCATED token and THE UTILITY TOKEN is going to be migrated, while the REWARD
     *  tokens can be withdrawn by the Extender to the Treasury.
     */
    function prepareMigration() external override onlyGuardian notMigrating {
        // effects
        _prepareMigration();

        status = AllocatorStatus.MIGRATING;
    }

    /**
     * @notice
     *  Migrates the allocated and all utility tokens to the next Allocator.
     * @dev
     *  The allocated token and the utility tokens will be migrated by this function, while it is
     *  assumed that the reward tokens are either simply kept or already harvested into the underlying
     *  essentially being the edge case of this contract. This contract is also going to report to the
     *  Extender that a migration happened and as such it is important to follow the proper sequence of
     *  migrating.
     *
     *  Steps to migrate:
     *   - FIRST call `_prepareMigration()` to prepare funds for migration.
     *   - THEN deploy the new Allocator and activate it according to the normal procedure.
     *     NOTE: This is to be done RIGHT BEFORE migration as to avoid allocating to the wrong allocator.
     *   - FINALLY call migrate. This is going to migrate the funds to the LAST allocator registered.
     *   - Check if everything went fine.
     *
     *  End state should be that allocator amounts have been swapped for allocators, that gain + loss is netted out 0
     *  for original allocator, and that the new allocators gain has been set to the original allocators gain.
     *  We don't transfer the loss because we have the information how much was initially invested + gain,
     *  and the new allocator didn't cause any loss thus we don't really need to add to it.
     */
    function migrate() external override onlyGuardian isMigrating {
        // reads
        IERC20[] memory utilityTokensArray = utilityTokens();
        address newAllocator = extender.getAllocatorByID(extender.getTotalAllocatorCount() - 1);
	uint256 idLength = _ids.length;
	uint256 utilLength = utilityTokensArray.length;

        // interactions
        for (uint256 i; i < idLength; i++) {
            IERC20 token = _tokens[i];

            token.safeTransfer(newAllocator, token.balanceOf(address(this)));
            extender.report(_ids[i], type(uint128).max, type(uint128).max);
        }

        for (uint256 i; i < utilLength; i++) {
            IERC20 utilityToken = utilityTokensArray[i];
            utilityToken.safeTransfer(newAllocator, utilityToken.balanceOf(address(this)));
        }

        // turn off Allocator
        deactivate(false);

        emit MigrationExecuted(newAllocator);
    }

    /**
     * @notice
     *  Activates the Allocator.
     * @dev
     *  Only the Guardian can call this.
     *
     *  Add any logic you need during activation, say interactions with Extender or something else,
     *  in the virtual method `_activate`.
     */
    function activate() external override onlyGuardian onlyOffline {
        // effects
        _activate();
        status = AllocatorStatus.ACTIVATED;

        emit AllocatorActivated();
    }

    /**
     * @notice
     *  Adds a deposit ID to the Allocator.
     * @dev
     *  Only the Extender calls this.
     * @param id id to add to the allocator
     */
    function addId(uint256 id) external override onlyExtender {
        _ids.push(id);
        tokenIds[id] = _ids.length - 1;
    }

    /**
     * @notice
     *  Returns all deposit IDs registered with the Allocator.
     * @return the deposit IDs registered
     */
    function ids() external view override returns (uint256[] memory) {
        return _ids;
    }

    /**
     * @notice
     *  Returns all tokens registered with the Allocator.
     * @return the tokens
     */
    function tokens() external view override returns (IERC20[] memory) {
        return _tokens;
    }

    /**
     * @notice
     *  Deactivates the Allocator.
     * @dev
     *  Only the Guardian can call this.
     *
     *  Add any logic you need during deactivation, say interactions with Extender or something else,
     *  in the virtual method `_deactivate`. Be careful to specifically use the internal or public function
     *  depending on what you need.
     * @param panic should panic logic be executed
     */
    function deactivate(bool panic) public override onlyGuardian {
        // effects
        _deactivate(panic);
        status = AllocatorStatus.OFFLINE;

        emit AllocatorDeactivated(panic);
    }

    /**
     * @notice
     *  Getter for Allocator version.
     * @return Returns the Allocators version.
     */
    function version() public pure override returns (string memory) {
        return "v2.0.0";
    }

    /**
     * @notice
     *  Internal check if the loss limit has been violated by the Allocator.
     * @dev
     *  Called as part of `update`. The rule is that the already sustained loss + newly sustained
     *  has to be larger or equal to the limit to break the contract.
     * @param id deposit id as in `TreasuryExtender`
     * @param loss the amount of newly sustained loss
     * @return true if the the loss limit has been broken
     */
    function _lossLimitViolated(uint256 id, uint128 loss) internal returns (bool) {
        // read
        uint128 lastLoss = extender.getAllocatorPerformance(id).loss;

        // events
        if ((loss + lastLoss) >= extender.getAllocatorLimits(id).loss) {
            emit LossLimitViolated(lastLoss, loss, amountAllocated(tokenIds[id]));
            return true;
        }

        return false;
    }

    /**
     * @notice
     *  Internal check to see if sender is extender.
     */
    function _onlyExtender(address sender) internal view {
        if (sender != address(extender)) revert BaseAllocator_OnlyExtender(sender);
    }

    /**
     * @notice
     *  Internal check to see if allocator is activated.
     */
    function _onlyActivated(AllocatorStatus inputStatus) internal pure {
        if (inputStatus != AllocatorStatus.ACTIVATED) revert BaseAllocator_AllocatorNotActivated();
    }

    /**
     * @notice
     *  Internal check to see if allocator is offline.
     */
    function _onlyOffline(AllocatorStatus inputStatus) internal pure {
        if (inputStatus != AllocatorStatus.OFFLINE) revert BaseAllocator_AllocatorNotOffline();
    }

    /**
     * @notice
     *  Internal check to see if allocator is not migrating.
     */
    function _notMigrating(AllocatorStatus inputStatus) internal pure {
        if (inputStatus == AllocatorStatus.MIGRATING) revert BaseAllocator_Migrating();
    }

    /**
     * @notice
     *  Internal check to see if allocator is migrating.
     */
    function _isMigrating(AllocatorStatus inputStatus) internal pure {
        if (inputStatus != AllocatorStatus.MIGRATING) revert BaseAllocator_NotMigrating();
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.8.10;

struct AllocatorPerformance {
    uint128 gain;
    uint128 loss;
}

struct AllocatorLimits {
    uint128 allocated;
    uint128 loss;
}

struct AllocatorHoldings {
    uint256 allocated;
}

struct AllocatorData {
    AllocatorHoldings holdings;
    AllocatorLimits limits;
    AllocatorPerformance performance;
}

/**
 * @title Interface for the TreasuryExtender
 */
interface ITreasuryExtender {
    /**
     * @notice
     *  Emitted when a new Deposit is registered.
     */
    event NewDepositRegistered(address allocator, address token, uint256 id);

    /**
     * @notice
     *  Emitted when an Allocator is funded
     */
    event AllocatorFunded(uint256 id, uint256 amount, uint256 value);

    /**
     * @notice
     *  Emitted when allocated funds are withdrawn from an Allocator
     */
    event AllocatorWithdrawal(uint256 id, uint256 amount, uint256 value);

    /**
     * @notice
     *  Emitted when rewards are withdrawn from an Allocator
     */
    event AllocatorRewardsWithdrawal(address allocator, uint256 amount, uint256 value);

    /**
     * @notice
     *  Emitted when an Allocator reports a gain
     */
    event AllocatorReportedGain(uint256 id, uint128 gain);

    /**
     * @notice
     *  Emitted when an Allocator reports a loss
     */
    event AllocatorReportedLoss(uint256 id, uint128 loss);

    /**
     * @notice
     *  Emitted when an Allocator reports a migration
     */
    event AllocatorReportedMigration(uint256 id);

    /**
     * @notice
     *  Emitted when an Allocator limits are modified
     */
    event AllocatorLimitsChanged(uint256 id, uint128 allocationLimit, uint128 lossLimit);

    function registerDeposit(address newAllocator) external;

    function setAllocatorLimits(uint256 id, AllocatorLimits memory limits) external;

    function report(
        uint256 id,
        uint128 gain,
        uint128 loss
    ) external;

    function requestFundsFromTreasury(uint256 id, uint256 amount) external;

    function returnFundsToTreasury(uint256 id, uint256 amount) external;

    function returnRewardsToTreasury(
        uint256 id,
        address token,
        uint256 amount
    ) external;

    function getTotalAllocatorCount() external view returns (uint256);

    function getAllocatorByID(uint256 id) external view returns (address);

    function getAllocatorAllocated(uint256 id) external view returns (uint256);

    function getAllocatorLimits(uint256 id) external view returns (AllocatorLimits memory);

    function getAllocatorPerformance(uint256 id) external view returns (AllocatorPerformance memory);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IOlympusAuthority {
    /* ========== EVENTS ========== */

    event GovernorPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event GuardianPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event PolicyPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event VaultPushed(address indexed from, address indexed to, bool _effectiveImmediately);

    event GovernorPulled(address indexed from, address indexed to);
    event GuardianPulled(address indexed from, address indexed to);
    event PolicyPulled(address indexed from, address indexed to);
    event VaultPulled(address indexed from, address indexed to);

    /* ========== VIEW ========== */

    function governor() external view returns (address);

    function guardian() external view returns (address);

    function policy() external view returns (address);

    function vault() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface ITreasury {
    function deposit(
        uint256 _amount,
        address _token,
        uint256 _profit
    ) external returns (uint256);

    function withdraw(uint256 _amount, address _token) external;

    function tokenValue(address _token, uint256 _amount) external view returns (uint256 value_);

    function mint(address _recipient, uint256 _amount) external;

    function manage(address _token, uint256 _amount) external;

    function incurDebt(uint256 amount_, address token_) external;

    function repayDebtWithReserve(uint256 amount_, address token_) external;

    function excessReserves() external view returns (uint256);

    function baseSupply() external view returns (uint256);
}

pragma solidity ^0.8.10;

import "../interfaces/IOlympusAuthority.sol";

error UNAUTHORIZED();
error AUTHORITY_INITIALIZED();

/// @dev Reasoning for this contract = modifiers literaly copy code
/// instead of pointing towards the logic to execute. Over many
/// functions this bloats contract size unnecessarily.
/// imho modifiers are a meme.
abstract contract OlympusAccessControlledV2 {
    /* ========== EVENTS ========== */

    event AuthorityUpdated(IOlympusAuthority authority);

    /* ========== STATE VARIABLES ========== */

    IOlympusAuthority public authority;

    /* ========== Constructor ========== */

    constructor(IOlympusAuthority _authority) {
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }

    /* ========== "MODIFIERS" ========== */

    modifier onlyGovernor {
	_onlyGovernor();
	_;
    }

    modifier onlyGuardian {
	_onlyGuardian();
	_;
    }

    modifier onlyPolicy {
	_onlyPolicy();
	_;
    }

    modifier onlyVault {
	_onlyVault();
	_;
    }

    /* ========== GOV ONLY ========== */

    function initializeAuthority(IOlympusAuthority _newAuthority) internal {
        if (authority != IOlympusAuthority(address(0))) revert AUTHORITY_INITIALIZED();
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }

    function setAuthority(IOlympusAuthority _newAuthority) external {
        _onlyGovernor();
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }

    /* ========== INTERNAL CHECKS ========== */

    function _onlyGovernor() internal view {
        if (msg.sender != authority.governor()) revert UNAUTHORIZED();
    }

    function _onlyGuardian() internal view {
        if (msg.sender != authority.guardian()) revert UNAUTHORIZED();
    }

    function _onlyPolicy() internal view {
        if (msg.sender != authority.policy()) revert UNAUTHORIZED();
    }

    function _onlyVault() internal view {
        if (msg.sender != authority.vault()) revert UNAUTHORIZED();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import {IERC20} from "../interfaces/IERC20.sol";

/// @notice Safe IERC20 and ETH transfer library that safely handles missing return values.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/libraries/TransferHelper.sol)
/// Taken from Solmate
library SafeERC20 {
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }

    function safeApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.approve.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "APPROVE_FAILED");
    }

    function safeTransferETH(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}(new bytes(0));

        require(success, "ETH_TRANSFER_FAILED");
    }
}