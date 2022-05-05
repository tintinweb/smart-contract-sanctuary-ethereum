// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.11;

// External references
import { ERC20 } from "@rari-capital/solmate/src/tokens/ERC20.sol";
import { SafeTransferLib } from "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import { FixedMath } from "./external/FixedMath.sol";
import { BalancerVault, IAsset } from "./external/balancer/Vault.sol";
import { BalancerPool } from "./external/balancer/Pool.sol";
import { IERC3156FlashBorrower } from "./external/flashloan/IERC3156FlashBorrower.sol";

// Internal references
import { Errors } from "@sense-finance/v1-utils/src/libs/Errors.sol";
import { Levels } from "@sense-finance/v1-utils/src/libs/Levels.sol";
import { Trust } from "@sense-finance/v1-utils/src/Trust.sol";
import { BaseAdapter as Adapter } from "./adapters/BaseAdapter.sol";
import { BaseFactory as AdapterFactory } from "./adapters/BaseFactory.sol";
import { Divider } from "./Divider.sol";
import { PoolManager } from "@sense-finance/v1-fuse/src/PoolManager.sol";

interface SpaceFactoryLike {
    function create(address, uint256) external returns (address);

    function pools(address adapter, uint256 maturity) external view returns (address);
}

/// @title Periphery
contract Periphery is Trust, IERC3156FlashBorrower {
    using FixedMath for uint256;
    using SafeTransferLib for ERC20;
    using Levels for uint256;

    /* ========== PUBLIC CONSTANTS ========== */

    /// @notice Lower bound on the amount of Claim tokens one can swap in for Target
    uint256 public constant MIN_YT_SWAP_IN = 0.000001e18;

    /// @notice Acceptable error when estimating the tokens resulting from a specific swap
    uint256 public constant PRICE_ESTIMATE_ACCEPTABLE_ERROR = 0.00000001e18;

    /* ========== PUBLIC IMMUTABLES ========== */

    /// @notice Sense core Divider address
    Divider public immutable divider;

    /// @notice Sense core Divider address
    BalancerVault public immutable balancerVault;

    /* ========== PUBLIC MUTABLE STORAGE ========== */

    /// @notice Sense core Divider address
    PoolManager public poolManager;

    /// @notice Sense core Divider address
    SpaceFactoryLike public spaceFactory;

    /// @notice adapter factories -> is supported
    mapping(address => bool) public factories;

    /// @notice adapter -> bool
    mapping(address => bool) public verified;

    /* ========== DATA STRUCTURES ========== */

    struct PoolLiquidity {
        ERC20[] tokens;
        uint256[] amounts;
        uint256 minBptOut;
    }

    constructor(
        address _divider,
        address _poolManager,
        address _spaceFactory,
        address _balancerVault
    ) Trust(msg.sender) {
        divider = Divider(_divider);
        poolManager = PoolManager(_poolManager);
        spaceFactory = SpaceFactoryLike(_spaceFactory);
        balancerVault = BalancerVault(_balancerVault);
    }

    /* ========== SERIES / ADAPTER MANAGEMENT ========== */

    /// @notice Sponsor a new Series in any adapter previously onboarded onto the Divider
    /// @dev Called by an external address, initializes a new series in the Divider
    /// @param adapter Adapter to associate with the Series
    /// @param maturity Maturity date for the Series, in units of unix time
    /// @param withPool Whether to deploy a Space pool or not (only works for unverified adapters)
    function sponsorSeries(
        address adapter,
        uint256 maturity,
        bool withPool
    ) external returns (address pt, address yt) {
        (, address stake, uint256 stakeSize) = Adapter(adapter).getStakeAndTarget();

        // Transfer stakeSize from sponsor into this contract
        ERC20(stake).safeTransferFrom(msg.sender, address(this), stakeSize);

        // Approve divider to withdraw stake assets
        ERC20(stake).approve(address(divider), stakeSize);

        (pt, yt) = divider.initSeries(adapter, maturity, msg.sender);

        // Space pool is always created for verified adapters whilst is optional for unverified ones.
        // Automatically queueing series is only for verified adapters
        if (verified[adapter]) {
            poolManager.queueSeries(adapter, maturity, spaceFactory.create(adapter, maturity));
        } else {
            if (withPool) {
                spaceFactory.create(adapter, maturity);
            }
        }
        emit SeriesSponsored(adapter, maturity, msg.sender);
    }

    /// @notice Deploy and onboard a Adapter
    /// @dev Called by external address, deploy a new Adapter via an Adapter Factory
    /// @param f Factory to use
    /// @param target Target to onboard
    /// @param data Additional encoded data needed to deploy the adapter
    function deployAdapter(
        address f,
        address target,
        bytes memory data
    ) external returns (address adapter) {
        if (!factories[f]) revert Errors.FactoryNotSupported();
        adapter = AdapterFactory(f).deployAdapter(target, data);
        emit AdapterDeployed(adapter);
        _verifyAdapter(adapter, true);
        _onboardAdapter(adapter, true);
    }

    /* ========== LIQUIDITY UTILS ========== */

    /// @notice Swap Target to Principal Tokens of a particular series
    /// @param adapter Adapter address for the Series
    /// @param maturity Maturity date for the Series
    /// @param tBal Balance of Target to sell
    /// @param minAccepted Min accepted amount of PT
    /// @return ptBal amount of PT received
    function swapTargetForPTs(
        address adapter,
        uint256 maturity,
        uint256 tBal,
        uint256 minAccepted
    ) external returns (uint256 ptBal) {
        ERC20(Adapter(adapter).target()).safeTransferFrom(msg.sender, address(this), tBal); // pull target
        return _swapTargetForPTs(adapter, maturity, tBal, minAccepted);
    }

    /// @notice Swap Underlying to Principal Tokens of a particular series
    /// @param adapter Adapter address for the Series
    /// @param maturity Maturity date for the Series
    /// @param uBal Balance of Underlying to sell
    /// @param minAccepted Min accepted amount of PT
    /// @return ptBal amount of PT received
    function swapUnderlyingForPTs(
        address adapter,
        uint256 maturity,
        uint256 uBal,
        uint256 minAccepted
    ) external returns (uint256 ptBal) {
        ERC20 underlying = ERC20(Adapter(adapter).underlying());
        underlying.safeTransferFrom(msg.sender, address(this), uBal); // pull underlying
        uint256 tBal = Adapter(adapter).wrapUnderlying(uBal); // wrap underlying into target
        ptBal = _swapTargetForPTs(adapter, maturity, tBal, minAccepted);
    }

    /// @notice Swap Target to Yield Tokens of a particular series
    /// @param adapter Adapter address for the Series
    /// @param maturity Maturity date for the Series
    /// @param targetIn Balance of Target to sell
    /// @param targetToBorrow Balance of Target to borrow
    /// @param minOut Min accepted amount of YT
    /// @return targetBal amount of Target sent back
    /// @return ytBal amount of YT received
    function swapTargetForYTs(
        address adapter,
        uint256 maturity,
        uint256 targetIn,
        uint256 targetToBorrow,
        uint256 minOut
    ) external returns (uint256 targetBal, uint256 ytBal) {
        ERC20(Adapter(adapter).target()).safeTransferFrom(msg.sender, address(this), targetIn);
        (targetBal, ytBal) = _flashBorrowAndSwapToYTs(adapter, maturity, targetIn, targetToBorrow, minOut);
        ERC20(Adapter(adapter).target()).safeTransfer(msg.sender, targetBal);
        ERC20(divider.yt(adapter, maturity)).safeTransfer(msg.sender, ytBal);
    }

    /// @notice Swap Underlying to Yield of a particular series
    /// @param adapter Adapter address for the Series
    /// @param maturity Maturity date for the Series
    /// @param underlyingIn Balance of Underlying to sell
    /// @param targetToBorrow Balance of Target to borrow
    /// @param minOut Min accepted amount of YT
    /// @return targetBal amount of Target sent back
    /// @return ytBal amount of YT received
    function swapUnderlyingForYTs(
        address adapter,
        uint256 maturity,
        uint256 underlyingIn,
        uint256 targetToBorrow,
        uint256 minOut
    ) external returns (uint256 targetBal, uint256 ytBal) {
        ERC20 underlying = ERC20(Adapter(adapter).underlying());
        underlying.safeTransferFrom(msg.sender, address(this), underlyingIn); // Pull Underlying
        // Wrap Underlying into Target and swap it for YTs
        uint256 targetIn = Adapter(adapter).wrapUnderlying(underlyingIn);
        (targetBal, ytBal) = _flashBorrowAndSwapToYTs(adapter, maturity, targetIn, targetToBorrow, minOut);
        ERC20(Adapter(adapter).target()).safeTransfer(msg.sender, targetBal);
        ERC20(divider.yt(adapter, maturity)).safeTransfer(msg.sender, ytBal);
    }

    /// @notice Swap Principal Tokens for Target of a particular series
    /// @param adapter Adapter address for the Series
    /// @param maturity Maturity date for the Series
    /// @param ptBal Balance of PT to sell
    /// @param minAccepted Min accepted amount of Target
    function swapPTsForTarget(
        address adapter,
        uint256 maturity,
        uint256 ptBal,
        uint256 minAccepted
    ) external returns (uint256 tBal) {
        tBal = _swapPTsForTarget(adapter, maturity, ptBal, minAccepted); // swap Principal Tokens for target
        ERC20(Adapter(adapter).target()).safeTransfer(msg.sender, tBal); // transfer target to msg.sender
    }

    /// @notice Swap Principal Tokens for Underlying of a particular series
    /// @param adapter Adapter address for the Series
    /// @param maturity Maturity date for the Series
    /// @param ptBal Balance of PT to sell
    /// @param minAccepted Min accepted amount of Target
    function swapPTsForUnderlying(
        address adapter,
        uint256 maturity,
        uint256 ptBal,
        uint256 minAccepted
    ) external returns (uint256 uBal) {
        uint256 tBal = _swapPTsForTarget(adapter, maturity, ptBal, minAccepted); // swap Principal Tokens for target
        uBal = Adapter(adapter).unwrapTarget(tBal); // unwrap target into underlying
        ERC20(Adapter(adapter).underlying()).safeTransfer(msg.sender, uBal); // transfer underlying to msg.sender
    }

    /// @notice Swap YT for Target of a particular series
    /// @param adapter Adapter address for the Series
    /// @param maturity Maturity date for the Series
    /// @param ytBal Balance of Yield Tokens to swap
    function swapYTsForTarget(
        address adapter,
        uint256 maturity,
        uint256 ytBal
    ) external returns (uint256 tBal) {
        tBal = _swapYTsForTarget(msg.sender, adapter, maturity, ytBal);
        ERC20(Adapter(adapter).target()).safeTransfer(msg.sender, tBal);
    }

    /// @notice Swap YT for Underlying of a particular series
    /// @param adapter Adapter address for the Series
    /// @param maturity Maturity date for the Series
    /// @param ytBal Balance of Yield Tokens to swap
    function swapYTsForUnderlying(
        address adapter,
        uint256 maturity,
        uint256 ytBal
    ) external returns (uint256 uBal) {
        uint256 tBal = _swapYTsForTarget(msg.sender, adapter, maturity, ytBal);
        uBal = Adapter(adapter).unwrapTarget(tBal);
        ERC20(Adapter(adapter).underlying()).safeTransfer(msg.sender, uBal);
    }

    /// @notice Adds liquidity providing target
    /// @param adapter Adapter address for the Series
    /// @param maturity Maturity date for the Series
    /// @param tBal Balance of Target to provide
    /// @param mode 0 = issues and sell YT, 1 = issue and hold YT
    /// @param minBptOut Minimum BPT the user will accept out for this transaction
    /// @dev see return description of _addLiquidity
    function addLiquidityFromTarget(
        address adapter,
        uint256 maturity,
        uint256 tBal,
        uint8 mode,
        uint256 minBptOut
    )
        external
        returns (
            uint256 tAmount,
            uint256 issued,
            uint256 lpShares
        )
    {
        ERC20(Adapter(adapter).target()).safeTransferFrom(msg.sender, address(this), tBal);
        (tAmount, issued, lpShares) = _addLiquidity(adapter, maturity, tBal, mode, minBptOut);
    }

    /// @notice Adds liquidity providing underlying
    /// @param adapter Adapter address for the Series
    /// @param maturity Maturity date for the Series
    /// @param uBal Balance of Underlying to provide
    /// @param mode 0 = issues and sell YT, 1 = issue and hold YT
    /// @param minBptOut Minimum BPT the user will accept out for this transaction
    /// @dev see return description of _addLiquidity
    function addLiquidityFromUnderlying(
        address adapter,
        uint256 maturity,
        uint256 uBal,
        uint8 mode,
        uint256 minBptOut
    )
        external
        returns (
            uint256 tAmount,
            uint256 issued,
            uint256 lpShares
        )
    {
        ERC20 underlying = ERC20(Adapter(adapter).underlying());
        underlying.safeTransferFrom(msg.sender, address(this), uBal);
        // Wrap Underlying into Target
        uint256 tBal = Adapter(adapter).wrapUnderlying(uBal);
        (tAmount, issued, lpShares) = _addLiquidity(adapter, maturity, tBal, mode, minBptOut);
    }

    /// @notice Removes liquidity providing an amount of LP tokens and returns target
    /// @dev More info on `minAmountsOut`: https://github.com/balancer-labs/docs-developers/blob/main/resources/joins-and-exits/pool-exits.md#minamountsout
    /// @param adapter Adapter address for the Series
    /// @param maturity Maturity date for the Series
    /// @param lpBal Balance of LP tokens to provide
    /// @param minAmountsOut minimum accepted amounts of PTs and Target given the amount of LP shares provided
    /// @param minAccepted only used when removing liquidity on/after maturity and its the min accepted when swapping Principal Tokens to underlying
    /// @param intoTarget if true, it will try to swap PTs into Target. Will revert if there's not enough liquidity to perform the swap.
    /// @return tBal amount of target received and ptBal amount of Principal Tokens (in case it's called after maturity and redeem is restricted)
    function removeLiquidity(
        address adapter,
        uint256 maturity,
        uint256 lpBal,
        uint256[] memory minAmountsOut,
        uint256 minAccepted,
        bool intoTarget
    ) external returns (uint256 tBal, uint256 ptBal) {
        (tBal, ptBal) = _removeLiquidity(adapter, maturity, lpBal, minAmountsOut, minAccepted, intoTarget);
        ERC20(Adapter(adapter).target()).safeTransfer(msg.sender, tBal); // Send Target back to the User
    }

    /// @notice Removes liquidity providing an amount of LP tokens and returns underlying
    /// @dev More info on `minAmountsOut`: https://github.com/balancer-labs/docs-developers/blob/main/resources/joins-and-exits/pool-exits.md#minamountsout
    /// @param adapter Adapter address for the Series
    /// @param maturity Maturity date for the Series
    /// @param lpBal Balance of LP tokens to provide
    /// @param minAmountsOut minimum accepted amounts of PTs and Target given the amount of LP shares provided
    /// @param minAccepted only used when removing liquidity on/after maturity and its the min accepted when swapping Principal Tokens to underlying
    /// @param intoTarget if true, it will try to swap PTs into Target. Will revert if there's not enough liquidity to perform the swap.
    /// @return uBal amount of underlying received and ptBal Principal Tokens (in case it's called after maturity and redeem is restricted or intoTarget is false)
    function removeLiquidityAndUnwrapTarget(
        address adapter,
        uint256 maturity,
        uint256 lpBal,
        uint256[] memory minAmountsOut,
        uint256 minAccepted,
        bool intoTarget
    ) external returns (uint256 uBal, uint256 ptBal) {
        uint256 tBal;
        (tBal, ptBal) = _removeLiquidity(adapter, maturity, lpBal, minAmountsOut, minAccepted, intoTarget);
        ERC20(Adapter(adapter).underlying()).safeTransfer(msg.sender, uBal = Adapter(adapter).unwrapTarget(tBal)); // Send Underlying back to the User
    }

    /// @notice Migrates liquidity position from one series to another
    /// @dev More info on `minAmountsOut`: https://github.com/balancer-labs/docs-developers/blob/main/resources/joins-and-exits/pool-exits.md#minamountsout
    /// @param srcAdapter Adapter address for the source Series
    /// @param dstAdapter Adapter address for the destination Series
    /// @param srcMaturity Maturity date for the source Series
    /// @param dstMaturity Maturity date for the destination Series
    /// @param lpBal Balance of LP tokens to provide
    /// @param minAmountsOut Minimum accepted amounts of PTs and Target given the amount of LP shares provided
    /// @param minAccepted Min accepted amount of target when swapping Principal Tokens (only used when removing liquidity on/after maturity)
    /// @param mode 0 = issues and sell YT, 1 = issue and hold YT
    /// @param intoTarget if true, it will try to swap PTs into Target. Will revert if there's not enough liquidity to perform the swap
    /// @param minBptOut Minimum BPT the user will accept out for this transaction
    /// @dev see return description of _addLiquidity. It also returns amount of PTs (in case it's called after maturity and redeem is restricted or inttoTarget is false)
    function migrateLiquidity(
        address srcAdapter,
        address dstAdapter,
        uint256 srcMaturity,
        uint256 dstMaturity,
        uint256 lpBal,
        uint256[] memory minAmountsOut,
        uint256 minAccepted,
        uint8 mode,
        bool intoTarget,
        uint256 minBptOut
    )
        external
        returns (
            uint256 tAmount,
            uint256 issued,
            uint256 lpShares,
            uint256 ptBal
        )
    {
        if (Adapter(srcAdapter).target() != Adapter(dstAdapter).target()) revert Errors.TargetMismatch();
        uint256 tBal;
        (tBal, ptBal) = _removeLiquidity(srcAdapter, srcMaturity, lpBal, minAmountsOut, minAccepted, intoTarget);
        (tAmount, issued, lpShares) = _addLiquidity(dstAdapter, dstMaturity, tBal, mode, minBptOut);
    }

    /* ========== ADMIN ========== */

    /// @notice Enable or disable a factory
    /// @param f Factory's address
    /// @param isOn Flag setting this factory to enabled or disabled
    function setFactory(address f, bool isOn) external requiresTrust {
        if (factories[f] == isOn) revert Errors.ExistingValue();
        factories[f] = isOn;
        emit FactoryChanged(f, isOn);
    }

    /// @notice Update the address for the Space Factory
    /// @param newSpaceFactory The Space Factory addresss to set
    function setSpaceFactory(address newSpaceFactory) external requiresTrust {
        spaceFactory = SpaceFactoryLike(newSpaceFactory);
        emit SpaceFactoryChanged(newSpaceFactory);
    }

    /// @notice Update the address for the Pool Manager
    /// @param newPoolManager The Pool Manager addresss to set
    function setPoolManager(address newPoolManager) external requiresTrust {
        poolManager = PoolManager(newPoolManager);
        emit PoolManagerChanged(newPoolManager);
    }

    /// @dev Verifies an Adapter and optionally adds the Target to the money market
    /// @param adapter Adapter to verify
    function verifyAdapter(address adapter, bool addToPool) public requiresTrust {
        _verifyAdapter(adapter, addToPool);
    }

    function _verifyAdapter(address adapter, bool addToPool) private {
        verified[adapter] = true;
        if (addToPool) poolManager.addTarget(Adapter(adapter).target(), adapter);
        emit AdapterVerified(adapter);
    }

    /// @notice Onboard a single Adapter w/o needing a factory
    /// @dev Called by a trusted address, approves Target for issuance, and onboards adapter to the Divider
    /// @param adapter Adapter to onboard
    /// @param addAdapter Whether to call divider.addAdapter or not (useful e.g when upgrading Periphery)
    function onboardAdapter(address adapter, bool addAdapter) public {
        if (!divider.permissionless() && !isTrusted[msg.sender]) revert Errors.OnlyPermissionless();
        _onboardAdapter(adapter, addAdapter);
    }

    function _onboardAdapter(address adapter, bool addAdapter) private {
        ERC20 target = ERC20(Adapter(adapter).target());
        target.approve(address(divider), type(uint256).max);
        target.approve(address(adapter), type(uint256).max);
        ERC20(Adapter(adapter).underlying()).approve(address(adapter), type(uint256).max);
        if (addAdapter) divider.addAdapter(adapter);
        emit AdapterOnboarded(adapter);
    }

    /* ========== INTERNAL UTILS ========== */

    function _swap(
        address assetIn,
        address assetOut,
        uint256 amountIn,
        bytes32 poolId,
        uint256 minAccepted
    ) internal returns (uint256 amountOut) {
        // approve vault to spend tokenIn
        ERC20(assetIn).approve(address(balancerVault), amountIn);

        BalancerVault.SingleSwap memory request = BalancerVault.SingleSwap({
            poolId: poolId,
            kind: BalancerVault.SwapKind.GIVEN_IN,
            assetIn: IAsset(assetIn),
            assetOut: IAsset(assetOut),
            amount: amountIn,
            userData: hex""
        });

        BalancerVault.FundManagement memory funds = BalancerVault.FundManagement({
            sender: address(this),
            fromInternalBalance: false,
            recipient: payable(address(this)),
            toInternalBalance: false
        });

        amountOut = balancerVault.swap(request, funds, minAccepted, type(uint256).max);
        emit Swapped(msg.sender, poolId, assetIn, assetOut, amountIn, amountOut, msg.sig);
    }

    function _swapPTsForTarget(
        address adapter,
        uint256 maturity,
        uint256 ptBal,
        uint256 minAccepted
    ) internal returns (uint256 tBal) {
        address principalToken = divider.pt(adapter, maturity);
        ERC20(principalToken).safeTransferFrom(msg.sender, address(this), ptBal); // pull principal
        BalancerPool pool = BalancerPool(spaceFactory.pools(adapter, maturity));
        tBal = _swap(principalToken, Adapter(adapter).target(), ptBal, pool.getPoolId(), minAccepted); // swap Principal Tokens for underlying
    }

    function _swapTargetForPTs(
        address adapter,
        uint256 maturity,
        uint256 tBal,
        uint256 minAccepted
    ) internal returns (uint256 ptBal) {
        address principalToken = divider.pt(adapter, maturity);
        BalancerPool pool = BalancerPool(spaceFactory.pools(adapter, maturity));
        ptBal = _swap(Adapter(adapter).target(), principalToken, tBal, pool.getPoolId(), minAccepted); // swap target for Principal Tokens
        ERC20(principalToken).safeTransfer(msg.sender, ptBal); // transfer bought principal to user
    }

    function _swapYTsForTarget(
        address sender,
        address adapter,
        uint256 maturity,
        uint256 ytBal
    ) internal returns (uint256 tBal) {
        address yt = divider.yt(adapter, maturity);

        // Because there's some margin of error in the pricing functions here, smaller
        // swaps will be unreliable. Tokens with more than 18 decimals are not supported.
        if (ytBal * 10**(18 - ERC20(yt).decimals()) <= MIN_YT_SWAP_IN) revert Errors.SwapTooSmall();
        BalancerPool pool = BalancerPool(spaceFactory.pools(adapter, maturity));

        // Transfer YTs into this contract if needed
        if (sender != address(this)) ERC20(yt).safeTransferFrom(msg.sender, address(this), ytBal);

        // Calculate target to borrow by calling AMM
        bytes32 poolId = pool.getPoolId();
        (uint256 pti, uint256 targeti) = pool.getIndices();
        (ERC20[] memory tokens, uint256[] memory balances, ) = balancerVault.getPoolTokens(poolId);
        // Determine how much Target we'll need in to get `ytBal` balance of PT out
        // (space doesn't directly use of the fields from `SwapRequest` beyond `poolId`, so the values after are placeholders)
        uint256 targetToBorrow = BalancerPool(pool).onSwap(
            BalancerPool.SwapRequest({
                kind: BalancerVault.SwapKind.GIVEN_OUT,
                tokenIn: tokens[targeti],
                tokenOut: tokens[pti],
                amount: ytBal,
                poolId: poolId,
                lastChangeBlock: 0,
                from: address(0),
                to: address(0),
                userData: ""
            }),
            balances[targeti],
            balances[pti]
        );

        // Flash borrow target (following actions in `onFlashLoan`)
        tBal = _flashBorrowAndSwapFromYTs(adapter, maturity, ytBal, targetToBorrow);
    }

    /// @return tAmount if mode = 0, target received from selling YTs, otherwise, returns 0
    /// @return issued returns amount of YTs issued (and received) except first provision which returns 0
    /// @return lpShares Space LP shares received given the liquidity added
    function _addLiquidity(
        address adapter,
        uint256 maturity,
        uint256 tBal,
        uint8 mode,
        uint256 minBptOut
    )
        internal
        returns (
            uint256 tAmount,
            uint256 issued,
            uint256 lpShares
        )
    {
        // (1) compute target, issue PTs & YTs & add liquidity to space
        (issued, lpShares) = _computeIssueAddLiq(adapter, maturity, tBal, minBptOut);

        if (issued > 0) {
            // issue = 0 means that we are on the first pool provision or that the pt:target ratio is 0:target
            if (mode == 0) {
                // (2) Sell YTs
                tAmount = _swapYTsForTarget(address(this), adapter, maturity, issued);
                // (3) Send remaining Target back to the User
                ERC20(Adapter(adapter).target()).safeTransfer(msg.sender, tAmount);
            } else {
                // (4) Send YTs back to the User
                ERC20(divider.yt(adapter, maturity)).safeTransfer(msg.sender, issued);
            }
        }
    }

    /// @dev Calculates amount of Principal Tokens in target terms (see description on `_computeTarget`) then issues
    /// PTs and YTs with the calculated amount and finally adds liquidity to space with the PTs issued
    /// and the diff between the target initially passed and the calculated amount
    function _computeIssueAddLiq(
        address adapter,
        uint256 maturity,
        uint256 tBal,
        uint256 minBptOut
    ) internal returns (uint256 issued, uint256 lpShares) {
        BalancerPool pool = BalancerPool(spaceFactory.pools(adapter, maturity));
        // Compute target
        (ERC20[] memory tokens, uint256[] memory balances, ) = balancerVault.getPoolTokens(pool.getPoolId());
        (uint256 pti, uint256 targeti) = pool.getIndices(); // Ensure we have the right token Indices

        // We do not add Principal Token liquidity if it haven't been initialized yet
        bool ptInitialized = balances[pti] != 0;
        uint256 ptBalInTarget = ptInitialized ? _computeTarget(adapter, balances[pti], balances[targeti], tBal) : 0;

        // Issue PT & YT (skip if first pool provision)
        issued = ptBalInTarget > 0 ? divider.issue(adapter, maturity, ptBalInTarget) : 0;

        // Add liquidity to Space & send the LP Shares to recipient
        uint256[] memory amounts = new uint256[](2);
        amounts[targeti] = tBal - ptBalInTarget;
        amounts[pti] = issued;
        lpShares = _addLiquidityToSpace(pool, PoolLiquidity(tokens, amounts, minBptOut));
    }

    /// @dev Based on pt:target ratio from current pool reserves and tBal passed
    /// calculates amount of tBal needed so as to issue PTs that would keep the ratio
    function _computeTarget(
        address adapter,
        uint256 ptiBal,
        uint256 targetiBal,
        uint256 tBal
    ) internal returns (uint256 tBalForIssuance) {
        return
            tBal.fmul(
                ptiBal.fdiv(
                    Adapter(adapter).scale().fmul(FixedMath.WAD - Adapter(adapter).ifee()).fmul(targetiBal) + ptiBal
                )
            );
    }

    function _removeLiquidity(
        address adapter,
        uint256 maturity,
        uint256 lpBal,
        uint256[] memory minAmountsOut,
        uint256 minAccepted,
        bool intoTarget
    ) internal returns (uint256 tBal, uint256 ptBal) {
        address target = Adapter(adapter).target();
        address pt = divider.pt(adapter, maturity);
        BalancerPool pool = BalancerPool(spaceFactory.pools(adapter, maturity));
        bytes32 poolId = pool.getPoolId();

        // (0) Pull LP tokens from sender
        ERC20(address(pool)).safeTransferFrom(msg.sender, address(this), lpBal);

        // (1) Remove liquidity from Space
        uint256 _ptBal;
        (tBal, _ptBal) = _removeLiquidityFromSpace(poolId, pt, target, minAmountsOut, lpBal);
        if (divider.mscale(adapter, maturity) > 0) {
            if (uint256(Adapter(adapter).level()).redeemRestricted()) {
                ptBal = _ptBal;
            } else {
                // (2) Redeem Principal Tokens for Target
                tBal += divider.redeem(adapter, maturity, _ptBal);
            }
        } else {
            // (2) Sell Principal Tokens for Target (if there are)
            if (_ptBal > 0 && intoTarget) {
                tBal += _swap(pt, target, _ptBal, poolId, minAccepted);
            } else {
                ptBal = _ptBal;
            }
        }
        if (ptBal > 0) ERC20(pt).safeTransfer(msg.sender, ptBal); // Send PT back to the User
    }

    /// @notice Initiates a flash loan of Target, swaps target amount to PTs and combines
    /// @param adapter adapter
    /// @param maturity maturity
    /// @param ytBalIn YT amount the user has sent in
    /// @param amountToBorrow target amount to borrow
    /// @return tBal amount of Target obtained from a sale of YTs
    function _flashBorrowAndSwapFromYTs(
        address adapter,
        uint256 maturity,
        uint256 ytBalIn,
        uint256 amountToBorrow
    ) internal returns (uint256 tBal) {
        ERC20 target = ERC20(Adapter(adapter).target());
        uint256 decimals = target.decimals();
        uint256 acceptableError = decimals < 9 ? 1 : PRICE_ESTIMATE_ACCEPTABLE_ERROR / 10**(18 - decimals);
        bytes memory data = abi.encode(adapter, uint256(maturity), ytBalIn, ytBalIn - acceptableError, true);
        bool result = Adapter(adapter).flashLoan(this, address(target), amountToBorrow, data);
        if (!result) revert Errors.FlashBorrowFailed();

        tBal = target.balanceOf(address(this));
    }

    /// @notice Initiates a flash loan of Target, issues PTs/YTs and swaps the PTs to Target
    /// @param adapter adapter
    /// @param maturity taturity
    /// @param targetIn Target amount the user has sent in
    /// @param amountToBorrow Target amount to borrow
    /// @param minOut minimum amount of Target accepted out for the issued PTs
    /// @return targetBal amount of Target remaining after the flashloan has been paid back
    /// @return ytBal amount of YTs issued with the borrowed Target and the Target sent in
    function _flashBorrowAndSwapToYTs(
        address adapter,
        uint256 maturity,
        uint256 targetIn,
        uint256 amountToBorrow,
        uint256 minOut
    ) internal returns (uint256 targetBal, uint256 ytBal) {
        bytes memory data = abi.encode(adapter, uint256(maturity), targetIn, minOut, false);
        bool result = Adapter(adapter).flashLoan(this, Adapter(adapter).target(), amountToBorrow, data);
        if (!result) revert Errors.FlashBorrowFailed();

        targetBal = ERC20(Adapter(adapter).target()).balanceOf(address(this));
        ytBal = ERC20(divider.yt(adapter, maturity)).balanceOf(address(this));
        emit YTsPurchased(msg.sender, adapter, maturity, targetIn, targetBal, ytBal);
    }

    /// @dev ERC-3156 Flash loan callback
    function onFlashLoan(
        address initiator,
        address, /* token */
        uint256 amountBorrrowed,
        uint256, /* fee */
        bytes calldata data
    ) external returns (bytes32) {
        (address adapter, uint256 maturity, uint256 amountIn, uint256 minOut, bool ytToTarget) = abi.decode(
            data,
            (address, uint256, uint256, uint256, bool)
        );

        if (msg.sender != address(adapter)) revert Errors.FlashUntrustedBorrower();
        if (initiator != address(this)) revert Errors.FlashUntrustedLoanInitiator();
        BalancerPool pool = BalancerPool(spaceFactory.pools(adapter, maturity));

        if (ytToTarget) {
            ERC20 target = ERC20(Adapter(adapter).target());

            // Swap Target for PTs
            uint256 ptBal = _swap(
                address(target),
                divider.pt(adapter, maturity),
                target.balanceOf(address(this)),
                pool.getPoolId(),
                minOut // min pt out
            );

            // Combine PTs and YTs
            divider.combine(adapter, maturity, ptBal < amountIn ? ptBal : amountIn);
        } else {
            // Issue PTs and YTs
            divider.issue(adapter, maturity, amountIn + amountBorrrowed);
            ERC20 pt = ERC20(divider.pt(adapter, maturity));

            // Swap PTs for Target
            _swap(
                address(pt),
                Adapter(adapter).target(),
                pt.balanceOf(address(this)),
                pool.getPoolId(),
                minOut // min Target out
            ); // minOut should be close to amountBorrrowed so that minimal Target dust is sent back to the caller

            // Flashloaner contract will revert if not enough Target has been swapped out to pay back the loan
        }

        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    function _addLiquidityToSpace(BalancerPool pool, PoolLiquidity memory liq) internal returns (uint256 lpBal) {
        bytes32 poolId = pool.getPoolId();
        IAsset[] memory assets = _convertERC20sToAssets(liq.tokens);
        for (uint8 i; i < liq.tokens.length; i++) {
            // Tokens and amounts must be in same order
            liq.tokens[i].approve(address(balancerVault), liq.amounts[i]);
        }

        // Behaves like EXACT_TOKENS_IN_FOR_BPT_OUT, user sends precise quantities of tokens,
        // and receives an estimated but unknown (computed at run time) quantity of BPT
        BalancerVault.JoinPoolRequest memory request = BalancerVault.JoinPoolRequest({
            assets: assets,
            maxAmountsIn: liq.amounts,
            userData: abi.encode(liq.amounts, liq.minBptOut),
            fromInternalBalance: false
        });
        balancerVault.joinPool(poolId, address(this), msg.sender, request);
        lpBal = ERC20(address(pool)).balanceOf(msg.sender);
    }

    function _removeLiquidityFromSpace(
        bytes32 poolId,
        address pt,
        address target,
        uint256[] memory minAmountsOut,
        uint256 lpBal
    ) internal returns (uint256 tBal, uint256 ptBal) {
        // ExitPoolRequest params
        (ERC20[] memory tokens, , ) = balancerVault.getPoolTokens(poolId);
        IAsset[] memory assets = _convertERC20sToAssets(tokens);
        BalancerVault.ExitPoolRequest memory request = BalancerVault.ExitPoolRequest({
            assets: assets,
            minAmountsOut: minAmountsOut,
            userData: abi.encode(lpBal),
            toInternalBalance: false
        });
        balancerVault.exitPool(poolId, address(this), payable(address(this)), request);

        tBal = ERC20(target).balanceOf(address(this));
        ptBal = ERC20(pt).balanceOf(address(this));
    }

    /// @notice From: https://github.com/balancer-labs/balancer-examples/blob/master/packages/liquidity-provision/contracts/LiquidityProvider.sol#L33
    /// @dev This helper function is a fast and cheap way to convert between IERC20[] and IAsset[] types
    function _convertERC20sToAssets(ERC20[] memory tokens) internal pure returns (IAsset[] memory assets) {
        assembly {
            assets := tokens
        }
    }

    /* ========== LOGS ========== */

    event FactoryChanged(address indexed factory, bool indexed isOn);
    event SpaceFactoryChanged(address newSpaceFactory);
    event PoolManagerChanged(address newPoolManager);
    event SeriesSponsored(address indexed adapter, uint256 indexed maturity, address indexed sponsor);
    event AdapterDeployed(address indexed adapter);
    event AdapterOnboarded(address indexed adapter);
    event AdapterVerified(address indexed adapter);
    event YTsPurchased(
        address indexed sender,
        address adapter,
        uint256 maturity,
        uint256 targetIn,
        uint256 targetReturned,
        uint256 ytOut
    );
    event Swapped(
        address indexed sender,
        bytes32 indexed poolId,
        address assetIn,
        address assetOut,
        uint256 amountIn,
        uint256 amountOut,
        bytes4 indexed sig
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

    event Approval(address indexed owner, address indexed spender, uint256 amount);

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

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
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

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

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
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    event Debug(bool one, bool two, uint256 retsize);

    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                           ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.11;

/// @title Fixed point arithmetic library
/// @author Taken from https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol
library FixedMath {
    uint256 internal constant WAD = 1e18;
    uint256 internal constant RAY = 1e27;

    function fmul(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) internal pure returns (uint256) {
        return mulDivDown(x, y, baseUnit); // Equivalent to (x * y) / baseUnit rounded down.
    }

    function fmul(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function fmulUp(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) internal pure returns (uint256) {
        return mulDivUp(x, y, baseUnit); // Equivalent to (x * y) / baseUnit rounded up.
    }

    function fmulUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function fdiv(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) internal pure returns (uint256) {
        return mulDivDown(x, baseUnit, y); // Equivalent to (x * baseUnit) / y rounded down.
    }

    function fdiv(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function fdivUp(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) internal pure returns (uint256) {
        return mulDivUp(x, baseUnit, y); // Equivalent to (x * baseUnit) / y rounded up.
    }

    function fdivUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.11;

import { ERC20 } from "@rari-capital/solmate/src/tokens/ERC20.sol";

interface IAsset {}

interface BalancerVault {
    struct JoinPoolRequest {
        IAsset[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }
    struct ExitPoolRequest {
        IAsset[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }
    enum PoolSpecialization {
        GENERAL,
        MINIMAL_SWAP_INFO,
        TWO_TOKEN
    }
    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }
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

    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (
            ERC20[] memory tokens,
            uint256[] memory balances,
            uint256 maxBlockNumber
        );

    function getPool(bytes32 poolId) external view returns (address, PoolSpecialization);

    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable;

    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest memory request
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.11;

import { ERC20 } from "@rari-capital/solmate/src/tokens/ERC20.sol";
import { BalancerVault } from "./Vault.sol";

interface BalancerPool {
    function getTimeWeightedAverage(OracleAverageQuery[] memory queries)
        external
        view
        returns (uint256[] memory results);

    enum Variable {
        PAIR_PRICE,
        BPT_PRICE,
        INVARIANT
    }
    struct OracleAverageQuery {
        Variable variable;
        uint256 secs;
        uint256 ago;
    }

    function getSample(uint256 index)
        external
        view
        returns (
            int256 logPairPrice,
            int256 accLogPairPrice,
            int256 logBptPrice,
            int256 accLogBptPrice,
            int256 logInvariant,
            int256 accLogInvariant,
            uint256 timestamp
        );

    function getPoolId() external view returns (bytes32);

    function getVault() external view returns (address);

    function totalSupply() external view returns (uint256);

    struct SwapRequest {
        BalancerVault.SwapKind kind;
        ERC20 tokenIn;
        ERC20 tokenOut;
        uint256 amount;
        // Misc data
        bytes32 poolId;
        uint256 lastChangeBlock;
        address from;
        address to;
        bytes userData;
    }

    function onSwap(
        SwapRequest memory swapRequest,
        uint256 currentBalanceTokenIn,
        uint256 currentBalanceTokenOut
    ) external returns (uint256 amount);

    function getIndices() external view returns (uint256 pti, uint256 targeti);
}

pragma solidity ^0.8.0;

interface IERC3156FlashBorrower {
    /// @dev Receive a flash loan.
    /// @param initiator The initiator of the loan.
    /// @param token The loan currency.
    /// @param amount The amount of tokens lent.
    /// @param fee The additional amount of tokens to repay.
    /// @param data Arbitrary data structure, intended to contain user-defined parameters.
    /// @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.4;

library Errors {
    // Auth
    error CombineRestricted();
    error IssuanceRestricted();
    error NotAuthorized();
    error OnlyYT();
    error OnlyDivider();
    error OnlyPeriphery();
    error OnlyPermissionless();
    error RedeemRestricted();
    error Untrusted();

    // Adapters
    error TokenNotSupported();
    error FlashCallbackFailed();
    error SenderNotEligible();
    error TargetMismatch();
    error TargetNotSupported();

    // Divider
    error AlreadySettled();
    error CollectNotSettled();
    error GuardCapReached();
    error IssuanceFeeCapExceeded();
    error IssueOnSettle();
    error NotSettled();

    // Input & validations
    error AlreadyInitialized();
    error DuplicateSeries();
    error ExistingValue();
    error InvalidAdapter();
    error InvalidMaturity();
    error InvalidParam();
    error NotImplemented();
    error OutOfWindowBoundaries();
    error SeriesDoesNotExist();
    error SwapTooSmall();
    error TargetParamsNotSet();
    error PoolParamsNotSet();
    error PTParamsNotSet();

    // Periphery
    error FactoryNotSupported();
    error FlashBorrowFailed();
    error FlashUntrustedBorrower();
    error FlashUntrustedLoanInitiator();
    error UnexpectedSwapAmount();
    error TooMuchLeftoverTarget();

    // Fuse
    error AdapterNotSet();
    error FailedBecomeAdmin();
    error FailedAddTargetMarket();
    error FailedToAddPTMarket();
    error FailedAddLpMarket();
    error OracleNotReady();
    error PoolAlreadyDeployed();
    error PoolNotDeployed();
    error PoolNotSet();
    error SeriesNotQueued();
    error TargetExists();
    error TargetNotInFuse();

    // Tokens
    error MintFailed();
    error RedeemFailed();
    error TransferFailed();
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.0;

library Levels {
    uint256 private constant _INIT_BIT = 0x1;
    uint256 private constant _ISSUE_BIT = 0x2;
    uint256 private constant _COMBINE_BIT = 0x4;
    uint256 private constant _COLLECT_BIT = 0x8;
    uint256 private constant _REDEEM_BIT = 0x10;
    uint256 private constant _REDEEM_HOOK_BIT = 0x20;

    function initRestricted(uint256 level) internal pure returns (bool) {
        return level & _INIT_BIT != _INIT_BIT;
    }

    function issueRestricted(uint256 level) internal pure returns (bool) {
        return level & _ISSUE_BIT != _ISSUE_BIT;
    }

    function combineRestricted(uint256 level) internal pure returns (bool) {
        return level & _COMBINE_BIT != _COMBINE_BIT;
    }

    function collectDisabled(uint256 level) internal pure returns (bool) {
        return level & _COLLECT_BIT != _COLLECT_BIT;
    }

    function redeemRestricted(uint256 level) internal pure returns (bool) {
        return level & _REDEEM_BIT != _REDEEM_BIT;
    }

    function redeemHookDisabled(uint256 level) internal pure returns (bool) {
        return level & _REDEEM_HOOK_BIT != _REDEEM_HOOK_BIT;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.0;

/// @notice Ultra minimal authorization logic for smart contracts.
/// @author From https://github.com/Rari-Capital/solmate/blob/fab107565a51674f3a3b5bfdaacc67f6179b1a9b/src/auth/Trust.sol
abstract contract Trust {
    event UserTrustUpdated(address indexed user, bool trusted);

    mapping(address => bool) public isTrusted;

    constructor(address initialUser) {
        isTrusted[initialUser] = true;

        emit UserTrustUpdated(initialUser, true);
    }

    function setIsTrusted(address user, bool trusted) public virtual requiresTrust {
        isTrusted[user] = trusted;

        emit UserTrustUpdated(user, trusted);
    }

    modifier requiresTrust() {
        require(isTrusted[msg.sender], "UNTRUSTED");

        _;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.11;

// External references
import { ERC20 } from "@rari-capital/solmate/src/tokens/ERC20.sol";
import { SafeTransferLib } from "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import { IERC3156FlashLender } from "../external/flashloan/IERC3156FlashLender.sol";
import { IERC3156FlashBorrower } from "../external/flashloan/IERC3156FlashBorrower.sol";

// Internal references
import { Divider } from "../Divider.sol";
import { Errors } from "@sense-finance/v1-utils/src/libs/Errors.sol";

/// @title Assign value to Target tokens
abstract contract BaseAdapter is IERC3156FlashLender {
    using SafeTransferLib for ERC20;

    /* ========== CONSTANTS ========== */

    bytes32 public constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");

    /* ========== PUBLIC IMMUTABLES ========== */

    /// @notice Sense core Divider address
    address public immutable divider;

    /// @notice Target token to divide
    address public immutable target;

    /// @notice Underlying for the Target
    address public immutable underlying;

    /// @notice Issuance fee
    uint128 public immutable ifee;

    /// @notice adapter params
    AdapterParams public adapterParams;

    /* ========== DATA STRUCTURES ========== */

    struct AdapterParams {
        /// @notice Oracle address
        address oracle;
        /// @notice Token to stake at issuance
        address stake;
        /// @notice Amount to stake at issuance
        uint256 stakeSize;
        /// @notice Min maturity (seconds after block.timstamp)
        uint256 minm;
        /// @notice Max maturity (seconds after block.timstamp)
        uint256 maxm;
        /// @notice WAD number representing the percentage of the total
        /// principal that's set aside for Yield Tokens (e.g. 0.1e18 means that 10% of the principal is reserved).
        /// @notice If `0`, it means no principal is set aside for Yield Tokens
        uint64 tilt;
        /// @notice The number this function returns will be used to determine its access by checking for binary
        /// digits using the following scheme: <onRedeem(y/n)><collect(y/n)><combine(y/n)><issue(y/n)>
        /// (e.g. 0101 enables `collect` and `issue`, but not `combine`)
        uint48 level;
        /// @notice 0 for monthly, 1 for weekly
        uint16 mode;
    }

    /* ========== METADATA STORAGE ========== */

    string public name;

    string public symbol;

    constructor(
        address _divider,
        address _target,
        address _underlying,
        uint128 _ifee,
        AdapterParams memory _adapterParams
    ) {
        divider = _divider;
        target = _target;
        underlying = _underlying;
        ifee = _ifee;
        adapterParams = _adapterParams;

        name = string(abi.encodePacked(ERC20(_target).name(), " Adapter"));
        symbol = string(abi.encodePacked(ERC20(_target).symbol(), "-adapter"));

        ERC20(_target).approve(divider, type(uint256).max);
        ERC20(_adapterParams.stake).approve(divider, type(uint256).max);
    }

    /// @notice Loan `amount` target to `receiver`, and takes it back after the callback.
    /// @param receiver The contract receiving target, needs to implement the
    /// `onFlashLoan(address user, address adapter, uint256 maturity, uint256 amount)` interface.
    /// @param amount The amount of target lent.
    /// @param data (encoded adapter address, maturity and YT amount the use has sent in)
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address, /* fee */
        uint256 amount,
        bytes calldata data
    ) external returns (bool) {
        if (Divider(divider).periphery() != msg.sender) revert Errors.OnlyPeriphery();
        ERC20(target).safeTransfer(address(receiver), amount);
        bytes32 keccak = IERC3156FlashBorrower(receiver).onFlashLoan(msg.sender, target, amount, 0, data);
        if (keccak != CALLBACK_SUCCESS) revert Errors.FlashCallbackFailed();
        ERC20(target).safeTransferFrom(address(receiver), address(this), amount);
        return true;
    }

    /* ========== REQUIRED VALUE GETTERS ========== */

    /// @notice Calculate and return this adapter's Scale value for the current timestamp. To be overriden by child contracts
    /// @dev For some Targets, such as cTokens, this is simply the exchange rate, or `supply cToken / supply underlying`
    /// @dev For other Targets, such as AMM LP shares, specialized logic will be required
    /// @dev This function _must_ return a WAD number representing the current exchange rate
    /// between the Target and the Underlying.
    /// @return value WAD Scale value
    function scale() external virtual returns (uint256);

    /// @notice Cached scale value getter
    /// @dev For situations where you need scale from a view function
    function scaleStored() external view virtual returns (uint256);

    /// @notice Returns the current price of the underlying in ETH terms
    function getUnderlyingPrice() external view virtual returns (uint256);

    /* ========== REQUIRED UTILITIES ========== */

    /// @notice Deposits underlying `amount`in return for target. Must be overriden by child contracts
    /// @param amount Underlying amount
    /// @return amount of target returned
    function wrapUnderlying(uint256 amount) external virtual returns (uint256);

    /// @notice Deposits target `amount`in return for underlying. Must be overriden by child contracts
    /// @param amount Target amount
    /// @return amount of underlying returned
    function unwrapTarget(uint256 amount) external virtual returns (uint256);

    function flashFee(address token, uint256) external view returns (uint256) {
        if (token != target) revert Errors.TokenNotSupported();
        return 0;
    }

    function maxFlashLoan(address token) external view override returns (uint256) {
        return ERC20(token).balanceOf(address(this));
    }

    /* ========== OPTIONAL HOOKS ========== */

    /// @notice Notification whenever the Divider adds or removes Target
    function notify(
        address, /* usr */
        uint256, /* amt */
        bool /* join */
    ) public virtual {
        return;
    }

    /// @notice Hook called whenever a user redeems PT
    function onRedeem(
        uint256, /* uBal */
        uint256, /* mscale */
        uint256, /* maxscale */
        uint256 /* tBal */
    ) public virtual {
        return;
    }

    /* ========== PUBLIC STORAGE ACCESSORS ========== */

    function getMaturityBounds() external view returns (uint256, uint256) {
        return (adapterParams.minm, adapterParams.maxm);
    }

    function getStakeAndTarget()
        external
        view
        returns (
            address,
            address,
            uint256
        )
    {
        return (target, adapterParams.stake, adapterParams.stakeSize);
    }

    function mode() external view returns (uint256) {
        return adapterParams.mode;
    }

    function tilt() external view returns (uint256) {
        return adapterParams.tilt;
    }

    function level() external view returns (uint256) {
        return adapterParams.level;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.11;

// Internal references
import { Errors } from "@sense-finance/v1-utils/src/libs/Errors.sol";
import { BaseAdapter } from "./BaseAdapter.sol";
import { Divider } from "../Divider.sol";

abstract contract BaseFactory {
    /* ========== CONSTANTS ========== */

    /// @notice Sets level to `31` by default, which keeps all Divider lifecycle methods public
    /// (`issue`, `combine`, `collect`, etc), but not the `onRedeem` hook.
    uint48 public constant DEFAULT_LEVEL = 31;

    /* ========== PUBLIC IMMUTABLES ========== */

    /// @notice Sense core Divider address
    address public immutable divider;

    /// @notice target -> adapter
    mapping(address => address) public adapters;

    /// @notice params for adapters deployed with this factory
    FactoryParams public factoryParams;

    /* ========== DATA STRUCTURES ========== */

    struct FactoryParams {
        address oracle; // oracle address
        address stake; // token to stake at issuance
        uint256 stakeSize; // amount to stake at issuance
        uint256 minm; // min maturity (seconds after block.timstamp)
        uint256 maxm; // max maturity (seconds after block.timstamp)
        uint128 ifee; // issuance fee
        uint16 mode; // 0 for monthly, 1 for weekly
        uint64 tilt; // tilt
    }

    constructor(address _divider, FactoryParams memory _factoryParams) {
        divider = _divider;
        factoryParams = _factoryParams;
    }

    /* ========== REQUIRED DEPLOY ========== */

    /// @notice Deploys both an adapter and a target wrapper for the given _target
    /// @param _target Address of the Target token
    /// @param _data Additional data needed to deploy the adapter
    function deployAdapter(address _target, bytes memory _data) external virtual returns (address adapter) {}

    /* ========== LOGS ========== */

    /// @notice Logs the deployment of the adapter
    event AdapterAdded(address addr, address indexed target);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.11;

// External references
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { ERC20 } from "@rari-capital/solmate/src/tokens/ERC20.sol";
import { SafeTransferLib } from "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import { ReentrancyGuard } from "@rari-capital/solmate/src/utils/ReentrancyGuard.sol";
import { DateTime } from "./external/DateTime.sol";
import { FixedMath } from "./external/FixedMath.sol";

// Internal references
import { Errors } from "@sense-finance/v1-utils/src/libs/Errors.sol";

import { Levels } from "@sense-finance/v1-utils/src/libs/Levels.sol";
import { Trust } from "@sense-finance/v1-utils/src/Trust.sol";
import { YT } from "./tokens/YT.sol";
import { Token } from "./tokens/Token.sol";
import { BaseAdapter as Adapter } from "./adapters/BaseAdapter.sol";

/// @title Sense Divider: Divide Assets in Two
/// @author fedealconada + jparklev
/// @notice You can use this contract to issue, combine, and redeem Sense ERC20 Principal and Yield Tokens
contract Divider is Trust, ReentrancyGuard, Pausable {
    using SafeTransferLib for ERC20;
    using FixedMath for uint256;
    using Levels for uint256;

    /* ========== PUBLIC CONSTANTS ========== */

    /// @notice Buffer before and after the actual maturity in which only the sponsor can settle the Series
    uint256 public constant SPONSOR_WINDOW = 3 hours;

    /// @notice Buffer after the sponsor window in which anyone can settle the Series
    uint256 public constant SETTLEMENT_WINDOW = 3 hours;

    /// @notice 5% issuance fee cap
    uint256 public constant ISSUANCE_FEE_CAP = 0.05e18;

    /* ========== PUBLIC MUTABLE STORAGE ========== */

    address public periphery;

    /// @notice Sense community multisig
    address public immutable cup;

    /// @notice Principal/Yield tokens deployer
    address public immutable tokenHandler;

    /// @notice Permissionless flag
    bool public permissionless;

    /// @notice Guarded launch flag
    bool public guarded = true;

    /// @notice Number of adapters (including turned off)
    uint248 public adapterCounter;

    /// @notice adapter ID -> adapter address
    mapping(uint256 => address) public adapterAddresses;

    /// @notice adapter data
    mapping(address => AdapterMeta) public adapterMeta;

    /// @notice adapter -> maturity -> Series
    mapping(address => mapping(uint256 => Series)) public series;

    /// @notice adapter -> maturity -> user -> lscale (last scale)
    mapping(address => mapping(uint256 => mapping(address => uint256))) public lscales;

    /* ========== DATA STRUCTURES ========== */

    struct Series {
        // Principal ERC20 token
        address pt;
        // Timestamp of series initialization
        uint48 issuance;
        // Yield ERC20 token
        address yt;
        // % of underlying principal initially reserved for Yield
        uint96 tilt;
        // Actor who initialized the Series
        address sponsor;
        // Tracks fees due to the series' settler
        uint256 reward;
        // Scale at issuance
        uint256 iscale;
        // Scale at maturity
        uint256 mscale;
        // Max scale value from this series' lifetime
        uint256 maxscale;
    }

    struct AdapterMeta {
        // Adapter ID
        uint248 id;
        // Adapter enabled/disabled
        bool enabled;
        // Max amount of Target allowed to be issued
        uint256 guard;
        // Adapter level
        uint248 level;
    }

    constructor(address _cup, address _tokenHandler) Trust(msg.sender) {
        cup = _cup;
        tokenHandler = _tokenHandler;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /// @notice Enable an adapter
    /// @dev when permissionless is disabled, only the Periphery can onboard adapters
    /// @dev after permissionless is enabled, anyone can onboard adapters
    /// @param adapter Adapter's address
    function addAdapter(address adapter) external whenNotPaused {
        if (!permissionless && msg.sender != periphery) revert Errors.OnlyPermissionless();
        if (adapterMeta[adapter].id > 0 && !adapterMeta[adapter].enabled) revert Errors.InvalidAdapter();
        _setAdapter(adapter, true);
    }

    /// @notice Initializes a new Series
    /// @dev Deploys two ERC20 contracts, one for PTs and the other one for YTs
    /// @dev Transfers some fixed amount of stake asset to this contract
    /// @param adapter Adapter to associate with the Series
    /// @param maturity Maturity date for the new Series, in units of unix time
    /// @param sponsor Sponsor of the Series that puts up a token stake and receives the issuance fees
    function initSeries(
        address adapter,
        uint256 maturity,
        address sponsor
    ) external nonReentrant whenNotPaused returns (address pt, address yt) {
        if (periphery != msg.sender) revert Errors.OnlyPeriphery();
        if (!adapterMeta[adapter].enabled) revert Errors.InvalidAdapter();
        if (_exists(adapter, maturity)) revert Errors.DuplicateSeries();
        if (!_isValid(adapter, maturity)) revert Errors.InvalidMaturity();

        // Transfer stake asset stake from caller to adapter
        (address target, address stake, uint256 stakeSize) = Adapter(adapter).getStakeAndTarget();

        // Deploy Principal & Yield Tokens for this new Series
        (pt, yt) = TokenHandler(tokenHandler).deploy(adapter, adapterMeta[adapter].id, maturity);

        // Initialize the new Series struct
        uint256 scale = Adapter(adapter).scale();

        series[adapter][maturity].pt = pt;
        series[adapter][maturity].issuance = uint48(block.timestamp);
        series[adapter][maturity].yt = yt;
        series[adapter][maturity].tilt = uint96(Adapter(adapter).tilt());
        series[adapter][maturity].sponsor = sponsor;
        series[adapter][maturity].iscale = scale;
        series[adapter][maturity].maxscale = scale;

        ERC20(stake).safeTransferFrom(msg.sender, adapter, stakeSize);

        emit SeriesInitialized(adapter, maturity, pt, yt, sponsor, target);
    }

    /// @notice Settles a Series and transfers the settlement reward to the caller
    /// @dev The Series' sponsor has a grace period where only they can settle the Series
    /// @dev After that, the reward becomes MEV
    /// @param adapter Adapter to associate with the Series
    /// @param maturity Maturity date for the new Series
    function settleSeries(address adapter, uint256 maturity) external nonReentrant whenNotPaused {
        if (!adapterMeta[adapter].enabled) revert Errors.InvalidAdapter();
        if (!_exists(adapter, maturity)) revert Errors.SeriesDoesNotExist();
        if (_settled(adapter, maturity)) revert Errors.AlreadySettled();
        if (!_canBeSettled(adapter, maturity)) revert Errors.OutOfWindowBoundaries();

        // The maturity scale value is all a Series needs for us to consider it "settled"
        uint256 mscale = Adapter(adapter).scale();
        series[adapter][maturity].mscale = mscale;

        if (mscale > series[adapter][maturity].maxscale) {
            series[adapter][maturity].maxscale = mscale;
        }

        // Reward the caller for doing the work of settling the Series at around the correct time
        (address target, address stake, uint256 stakeSize) = Adapter(adapter).getStakeAndTarget();
        ERC20(target).safeTransferFrom(adapter, msg.sender, series[adapter][maturity].reward);
        ERC20(stake).safeTransferFrom(adapter, msg.sender, stakeSize);

        emit SeriesSettled(adapter, maturity, msg.sender);
    }

    /// @notice Mint Principal & Yield Tokens of a specific Series
    /// @param adapter Adapter address for the Series
    /// @param maturity Maturity date for the Series [unix time]
    /// @param tBal Balance of Target to deposit
    /// @dev The balance of PTs and YTs minted will be the same value in units of underlying (less fees)
    function issue(
        address adapter,
        uint256 maturity,
        uint256 tBal
    ) external nonReentrant whenNotPaused returns (uint256 uBal) {
        if (!adapterMeta[adapter].enabled) revert Errors.InvalidAdapter();
        if (!_exists(adapter, maturity)) revert Errors.SeriesDoesNotExist();
        if (_settled(adapter, maturity)) revert Errors.IssueOnSettle();

        uint256 level = adapterMeta[adapter].level;
        if (level.issueRestricted() && msg.sender != adapter) revert Errors.IssuanceRestricted();

        ERC20 target = ERC20(Adapter(adapter).target());

        // Take the issuance fee out of the deposited Target, and put it towards the settlement reward
        uint256 issuanceFee = Adapter(adapter).ifee();
        if (issuanceFee > ISSUANCE_FEE_CAP) revert Errors.IssuanceFeeCapExceeded();
        uint256 fee = tBal.fmul(issuanceFee);

        unchecked {
            // Safety: bounded by the Target's total token supply
            series[adapter][maturity].reward += fee;
        }
        uint256 tBalSubFee = tBal - fee;

        // Ensure the caller won't hit the issuance cap with this action
        unchecked {
            // Safety: bounded by the Target's total token supply
            if (guarded && target.balanceOf(adapter) + tBal > adapterMeta[address(adapter)].guard)
                revert Errors.GuardCapReached();
        }

        // Update values on adapter
        Adapter(adapter).notify(msg.sender, tBalSubFee, true);

        uint256 scale = level.collectDisabled() ? series[adapter][maturity].iscale : Adapter(adapter).scale();

        // Determine the amount of Underlying equal to the Target being sent in (the principal)
        uBal = tBalSubFee.fmul(scale);

        // If the caller has not collected on YT before, use the current scale, otherwise
        // use the harmonic mean of the last and the current scale value
        lscales[adapter][maturity][msg.sender] = lscales[adapter][maturity][msg.sender] == 0
            ? scale
            : _reweightLScale(
                adapter,
                maturity,
                YT(series[adapter][maturity].yt).balanceOf(msg.sender),
                uBal,
                msg.sender,
                scale
            );

        // Mint equal amounts of PT and YT
        Token(series[adapter][maturity].pt).mint(msg.sender, uBal);
        YT(series[adapter][maturity].yt).mint(msg.sender, uBal);

        target.safeTransferFrom(msg.sender, adapter, tBal);

        emit Issued(adapter, maturity, uBal, msg.sender);
    }

    /// @notice Reconstitute Target by burning PT and YT
    /// @dev Explicitly burns YTs before maturity, and implicitly does it at/after maturity through `_collect()`
    /// @param adapter Adapter address for the Series
    /// @param maturity Maturity date for the Series
    /// @param uBal Balance of PT and YT to burn
    function combine(
        address adapter,
        uint256 maturity,
        uint256 uBal
    ) external nonReentrant whenNotPaused returns (uint256 tBal) {
        if (!adapterMeta[adapter].enabled) revert Errors.InvalidAdapter();
        if (!_exists(adapter, maturity)) revert Errors.SeriesDoesNotExist();

        uint256 level = adapterMeta[adapter].level;
        if (level.combineRestricted() && msg.sender != adapter) revert Errors.CombineRestricted();

        // Burn the PT
        Token(series[adapter][maturity].pt).burn(msg.sender, uBal);

        // Collect whatever excess is due
        uint256 collected = _collect(msg.sender, adapter, maturity, uBal, uBal, address(0));

        uint256 cscale = series[adapter][maturity].mscale;
        bool settled = _settled(adapter, maturity);
        if (!settled) {
            // If it's not settled, then YT won't be burned automatically in `_collect()`
            YT(series[adapter][maturity].yt).burn(msg.sender, uBal);
            // If collect has been restricted, use the initial scale, otherwise use the current scale
            cscale = level.collectDisabled()
                ? series[adapter][maturity].iscale
                : lscales[adapter][maturity][msg.sender];
        }

        // Convert from units of Underlying to units of Target
        tBal = uBal.fdiv(cscale);
        ERC20(Adapter(adapter).target()).safeTransferFrom(adapter, msg.sender, tBal);

        // Notify only when Series is not settled as when it is, the _collect() call above would trigger a _redeemYT which will call notify
        if (!settled) Adapter(adapter).notify(msg.sender, tBal, false);
        unchecked {
            // Safety: bounded by the Target's total token supply
            tBal += collected;
        }
        emit Combined(adapter, maturity, tBal, msg.sender);
    }

    /// @notice Burn PT of a Series once it's been settled
    /// @dev The balance of redeemable Target is a function of the change in Scale
    /// @param adapter Adapter address for the Series
    /// @param maturity Maturity date for the Series
    /// @param uBal Amount of PT to burn, which should be equivalent to the amount of Underlying owed to the caller
    function redeem(
        address adapter,
        uint256 maturity,
        uint256 uBal
    ) external nonReentrant whenNotPaused returns (uint256 tBal) {
        // If a Series is settled, we know that it must have existed as well, so that check is unnecessary
        if (!_settled(adapter, maturity)) revert Errors.NotSettled();

        uint256 level = adapterMeta[adapter].level;
        if (level.redeemRestricted() && msg.sender == adapter) revert Errors.RedeemRestricted();

        // Burn the caller's PT
        Token(series[adapter][maturity].pt).burn(msg.sender, uBal);

        // Principal Token holder's share of the principal = (1 - part of the principal that belongs to Yield)
        uint256 zShare = FixedMath.WAD - series[adapter][maturity].tilt;

        // If Principal Token are at a loss and Yield have some principal to help cover the shortfall,
        // take what we can from Yield Token's principal
        if (series[adapter][maturity].mscale.fdiv(series[adapter][maturity].maxscale) >= zShare) {
            tBal = (uBal * zShare) / series[adapter][maturity].mscale;
        } else {
            tBal = uBal.fdiv(series[adapter][maturity].maxscale);
        }

        if (!level.redeemHookDisabled()) {
            Adapter(adapter).onRedeem(uBal, series[adapter][maturity].mscale, series[adapter][maturity].maxscale, tBal);
        }

        ERC20(Adapter(adapter).target()).safeTransferFrom(adapter, msg.sender, tBal);
        emit PTRedeemed(adapter, maturity, tBal);
    }

    function collect(
        address usr,
        address adapter,
        uint256 maturity,
        uint256 uBalTransfer,
        address to
    ) external nonReentrant onlyYT(adapter, maturity) whenNotPaused returns (uint256 collected) {
        uint256 uBal = YT(msg.sender).balanceOf(usr);
        return _collect(usr, adapter, maturity, uBal, uBalTransfer > 0 ? uBalTransfer : uBal, to);
    }

    /// @notice Collect YT excess before, at, or after maturity
    /// @dev If `to` is set, we copy the lscale value from usr to this address
    /// @param usr User who's collecting for their YTs
    /// @param adapter Adapter address for the Series
    /// @param maturity Maturity date for the Series
    /// @param uBal yield Token balance
    /// @param uBalTransfer original transfer value
    /// @param to address to set the lscale value from usr
    function _collect(
        address usr,
        address adapter,
        uint256 maturity,
        uint256 uBal,
        uint256 uBalTransfer,
        address to
    ) internal returns (uint256 collected) {
        if (!_exists(adapter, maturity)) revert Errors.SeriesDoesNotExist();

        // If the adapter is disabled, its Yield Token can only collect
        // if associated Series has been settled, which implies that an admin
        // has backfilled it
        if (!adapterMeta[adapter].enabled && !_settled(adapter, maturity)) revert Errors.InvalidAdapter();

        Series memory _series = series[adapter][maturity];

        // Get the scale value from the last time this holder collected (default to maturity)
        uint256 lscale = lscales[adapter][maturity][usr];

        uint256 level = adapterMeta[adapter].level;
        if (level.collectDisabled()) {
            // If this Series has been settled, we ensure everyone's YT will
            // collect yield accrued since issuance
            if (_settled(adapter, maturity)) {
                lscale = series[adapter][maturity].iscale;
                // If the Series is not settled, we ensure no collections can happen
            } else {
                return 0;
            }
        }

        // If the Series has been settled, this should be their last collect, so redeem the user's Yield Tokens for them
        if (_settled(adapter, maturity)) {
            _redeemYT(usr, adapter, maturity, uBal);
        } else {
            // If we're not settled and we're past maturity + the sponsor window,
            // anyone can settle this Series so revert until someone does
            if (block.timestamp > maturity + SPONSOR_WINDOW) {
                revert Errors.CollectNotSettled();
                // Otherwise, this is a valid pre-settlement collect and we need to determine the scale value
            } else {
                uint256 cscale = Adapter(adapter).scale();
                // If this is larger than the largest scale we've seen for this Series, use it
                if (cscale > _series.maxscale) {
                    _series.maxscale = cscale;
                    lscales[adapter][maturity][usr] = cscale;
                    // If not, use the previously noted max scale value
                } else {
                    lscales[adapter][maturity][usr] = _series.maxscale;
                }
            }
        }

        // Determine how much underlying has accrued since the last time this user collected, in units of Target.
        // (Or take the last time as issuance if they haven't yet)
        //
        // Reminder: `Underlying / Scale = Target`
        // So the following equation is saying, for some amount of Underlying `u`:
        // "Balance of Target that equaled `u` at the last collection _minus_ Target that equals `u` now"
        //
        // Because maxscale must be increasing, the Target balance needed to equal `u` decreases, and that "excess"
        // is what Yield holders are collecting
        uint256 tBalNow = uBal.fdivUp(_series.maxscale); // preventive round-up towards the protocol
        uint256 tBalPrev = uBal.fdiv(lscale);
        unchecked {
            collected = tBalPrev > tBalNow ? tBalPrev - tBalNow : 0;
        }
        ERC20(Adapter(adapter).target()).safeTransferFrom(adapter, usr, collected);
        Adapter(adapter).notify(usr, collected, false); // Distribute reward tokens

        // If this collect is a part of a token transfer to another address, set the receiver's
        // last collection to a synthetic scale weighted based on the scale on their last collect,
        // the time elapsed, and the current scale
        if (to != address(0)) {
            uint256 ytBal = YT(_series.yt).balanceOf(to);
            // If receiver holds yields, we set lscale to a computed "synthetic" lscales value that,
            // for the updated yield balance, still assigns the correct amount of yield.
            lscales[adapter][maturity][to] = ytBal > 0
                ? _reweightLScale(adapter, maturity, ytBal, uBalTransfer, to, _series.maxscale)
                : _series.maxscale;
            uint256 tBalTransfer = uBalTransfer.fdiv(_series.maxscale);
            Adapter(adapter).notify(usr, tBalTransfer, false);
            Adapter(adapter).notify(to, tBalTransfer, true);
        }
        series[adapter][maturity] = _series;

        emit Collected(adapter, maturity, collected);
    }

    /// @notice calculate the harmonic mean of the current scale and the last scale,
    /// weighted by amounts associated with each
    function _reweightLScale(
        address adapter,
        uint256 maturity,
        uint256 ytBal,
        uint256 uBal,
        address receiver,
        uint256 scale
    ) internal view returns (uint256) {
        // Target Decimals * 18 Decimals [from fdiv] / (Target Decimals * 18 Decimals [from fdiv] / 18 Decimals)
        // = 18 Decimals, which is the standard for scale values
        return (ytBal + uBal).fdiv((ytBal.fdiv(lscales[adapter][maturity][receiver]) + uBal.fdiv(scale)));
    }

    function _redeemYT(
        address usr,
        address adapter,
        uint256 maturity,
        uint256 uBal
    ) internal {
        // Burn the users's YTs
        YT(series[adapter][maturity].yt).burn(usr, uBal);

        // Default principal for a YT
        uint256 tBal = 0;

        // Principal Token holder's share of the principal = (1 - part of the principal that belongs to Yield Tokens)
        uint256 zShare = FixedMath.WAD - series[adapter][maturity].tilt;

        // If PTs are at a loss and YTs had their principal cut to help cover the shortfall,
        // calculate how much YTs have left
        if (series[adapter][maturity].mscale.fdiv(series[adapter][maturity].maxscale) >= zShare) {
            tBal = uBal.fdiv(series[adapter][maturity].maxscale) - (uBal * zShare) / series[adapter][maturity].mscale;
            ERC20(Adapter(adapter).target()).safeTransferFrom(adapter, usr, tBal);
        }

        // Always notify the Adapter of the full Target balance that will no longer
        // have its rewards distributed
        Adapter(adapter).notify(usr, uBal.fdivUp(series[adapter][maturity].maxscale), false);

        emit YTRedeemed(adapter, maturity, tBal);
    }

    /* ========== ADMIN ========== */

    /// @notice Enable or disable a adapter
    /// @param adapter Adapter's address
    /// @param isOn Flag setting this adapter to enabled or disabled
    function setAdapter(address adapter, bool isOn) public requiresTrust {
        _setAdapter(adapter, isOn);
    }

    /// @notice Set adapter's guard
    /// @param adapter Adapter address
    /// @param cap The max target that can be deposited on the Adapter
    function setGuard(address adapter, uint256 cap) external requiresTrust {
        adapterMeta[adapter].guard = cap;
        emit GuardChanged(adapter, cap);
    }

    /// @notice Set guarded mode
    /// @param _guarded bool
    function setGuarded(bool _guarded) external requiresTrust {
        guarded = _guarded;
        emit GuardedChanged(_guarded);
    }

    /// @notice Set periphery's contract
    /// @param _periphery Target address
    function setPeriphery(address _periphery) external requiresTrust {
        periphery = _periphery;
        emit PeripheryChanged(_periphery);
    }

    /// @notice Set paused flag
    /// @param _paused boolean
    function setPaused(bool _paused) external requiresTrust {
        _paused ? _pause() : _unpause();
    }

    /// @notice Set permissioless mode
    /// @param _permissionless bool
    function setPermissionless(bool _permissionless) external requiresTrust {
        permissionless = _permissionless;
        emit PermissionlessChanged(_permissionless);
    }

    /// @notice Backfill a Series' Scale value at maturity if keepers failed to settle it
    /// @param adapter Adapter's address
    /// @param maturity Maturity date for the Series
    /// @param mscale Value to set as the Series' Scale value at maturity
    /// @param _usrs Values to set on lscales mapping
    /// @param _lscales Values to set on lscales mapping
    function backfillScale(
        address adapter,
        uint256 maturity,
        uint256 mscale,
        address[] calldata _usrs,
        uint256[] calldata _lscales
    ) external requiresTrust {
        if (!_exists(adapter, maturity)) revert Errors.SeriesDoesNotExist();

        uint256 cutoff = maturity + SPONSOR_WINDOW + SETTLEMENT_WINDOW;
        // Admin can never backfill before maturity
        if (block.timestamp <= cutoff) revert Errors.OutOfWindowBoundaries();

        // Set user's last scale values the Series (needed for the `collect` method)
        for (uint256 i = 0; i < _usrs.length; i++) {
            lscales[adapter][maturity][_usrs[i]] = _lscales[i];
        }

        if (mscale > 0) {
            Series memory _series = series[adapter][maturity];
            // Set the maturity scale for the Series (needed for `redeem` methods)
            series[adapter][maturity].mscale = mscale;
            if (mscale > _series.maxscale) {
                series[adapter][maturity].maxscale = mscale;
            }

            (address target, address stake, uint256 stakeSize) = Adapter(adapter).getStakeAndTarget();

            address stakeDst = adapterMeta[adapter].enabled ? cup : _series.sponsor;
            ERC20(target).safeTransferFrom(adapter, cup, _series.reward);
            series[adapter][maturity].reward = 0;
            ERC20(stake).safeTransferFrom(adapter, stakeDst, stakeSize);
        }

        emit Backfilled(adapter, maturity, mscale, _usrs, _lscales);
    }

    /* ========== INTERNAL VIEWS ========== */

    function _exists(address adapter, uint256 maturity) internal view returns (bool) {
        return series[adapter][maturity].pt != address(0);
    }

    function _settled(address adapter, uint256 maturity) internal view returns (bool) {
        return series[adapter][maturity].mscale > 0;
    }

    function _canBeSettled(address adapter, uint256 maturity) internal view returns (bool) {
        uint256 cutoff = maturity + SPONSOR_WINDOW + SETTLEMENT_WINDOW;
        // If the sender is the sponsor for the Series
        if (msg.sender == series[adapter][maturity].sponsor) {
            return maturity - SPONSOR_WINDOW <= block.timestamp && cutoff >= block.timestamp;
        } else {
            return maturity + SPONSOR_WINDOW < block.timestamp && cutoff >= block.timestamp;
        }
    }

    function _isValid(address adapter, uint256 maturity) internal view returns (bool) {
        (uint256 minm, uint256 maxm) = Adapter(adapter).getMaturityBounds();
        if (maturity < block.timestamp + minm || maturity > block.timestamp + maxm) return false;
        (, , uint256 day, uint256 hour, uint256 minute, uint256 second) = DateTime.timestampToDateTime(maturity);

        if (hour != 0 || minute != 0 || second != 0) return false;
        uint256 mode = Adapter(adapter).mode();
        if (mode == 0) {
            return day == 1;
        }
        if (mode == 1) {
            return DateTime.getDayOfWeek(maturity) == 1;
        }
        return false;
    }

    /* ========== INTERNAL UTILS ========== */

    function _setAdapter(address adapter, bool isOn) internal {
        AdapterMeta memory am = adapterMeta[adapter];
        if (am.enabled == isOn) revert Errors.ExistingValue();
        am.enabled = isOn;

        // If this adapter is being added for the first time
        if (isOn && am.id == 0) {
            am.id = ++adapterCounter;
            adapterAddresses[am.id] = adapter;
        }

        // Set level and target (can only be done once);
        am.level = uint248(Adapter(adapter).level());
        adapterMeta[adapter] = am;
        emit AdapterChanged(adapter, am.id, isOn);
    }

    /* ========== PUBLIC GETTERS ========== */

    /// @notice Returns address of Principal Token
    function pt(address adapter, uint256 maturity) public view returns (address) {
        return series[adapter][maturity].pt;
    }

    /// @notice Returns address of Yield Token
    function yt(address adapter, uint256 maturity) public view returns (address) {
        return series[adapter][maturity].yt;
    }

    function mscale(address adapter, uint256 maturity) public view returns (uint256) {
        return series[adapter][maturity].mscale;
    }

    /* ========== MODIFIERS ========== */

    modifier onlyYT(address adapter, uint256 maturity) {
        if (series[adapter][maturity].yt != msg.sender) revert Errors.OnlyYT();
        _;
    }

    /* ========== LOGS ========== */

    /// @notice Admin
    event Backfilled(
        address indexed adapter,
        uint256 indexed maturity,
        uint256 mscale,
        address[] _usrs,
        uint256[] _lscales
    );
    event GuardChanged(address indexed adapter, uint256 cap);
    event AdapterChanged(address indexed adapter, uint256 indexed id, bool indexed isOn);
    event PeripheryChanged(address indexed periphery);

    /// @notice Series lifecycle
    /// *---- beginning
    event SeriesInitialized(
        address adapter,
        uint256 indexed maturity,
        address pt,
        address yt,
        address indexed sponsor,
        address indexed target
    );
    /// -***- middle
    event Issued(address indexed adapter, uint256 indexed maturity, uint256 balance, address indexed sender);
    event Combined(address indexed adapter, uint256 indexed maturity, uint256 balance, address indexed sender);
    event Collected(address indexed adapter, uint256 indexed maturity, uint256 collected);
    /// ----* end
    event SeriesSettled(address indexed adapter, uint256 indexed maturity, address indexed settler);
    event PTRedeemed(address indexed adapter, uint256 indexed maturity, uint256 redeemed);
    event YTRedeemed(address indexed adapter, uint256 indexed maturity, uint256 redeemed);
    /// *----* misc
    event GuardedChanged(bool indexed guarded);
    event PermissionlessChanged(bool indexed permissionless);
}

contract TokenHandler is Trust {
    /// @notice Program state
    address public divider;

    constructor() Trust(msg.sender) {}

    function init(address _divider) external requiresTrust {
        if (divider != address(0)) revert Errors.AlreadyInitialized();
        divider = _divider;
    }

    function deploy(
        address adapter,
        uint248 id,
        uint256 maturity
    ) external returns (address pt, address yt) {
        if (msg.sender != divider) revert Errors.OnlyDivider();

        ERC20 target = ERC20(Adapter(adapter).target());
        uint8 decimals = target.decimals();
        string memory symbol = target.symbol();
        (string memory d, string memory m, string memory y) = DateTime.toDateString(maturity);
        string memory date = DateTime.format(maturity);
        string memory datestring = string(abi.encodePacked(d, "-", m, "-", y));
        string memory adapterId = DateTime.uintToString(id);
        pt = address(
            new Token(
                string(abi.encodePacked(date, " ", symbol, " Sense Principal Token, A", adapterId)),
                string(abi.encodePacked("sP-", symbol, ":", datestring, ":", adapterId)),
                decimals,
                divider
            )
        );

        yt = address(
            new YT(
                adapter,
                maturity,
                string(abi.encodePacked(date, " ", symbol, " Sense Yield Token, A", adapterId)),
                string(abi.encodePacked("sY-", symbol, ":", datestring, ":", adapterId)),
                decimals,
                divider
            )
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.11;

// External reference
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import { ERC20 } from "@rari-capital/solmate/src/tokens/ERC20.sol";
import { Bytes32AddressLib } from "@rari-capital/solmate/src/utils/Bytes32AddressLib.sol";
import { PriceOracle } from "./external/PriceOracle.sol";
import { BalancerOracle } from "./external/BalancerOracle.sol";

// Internal references
import { UnderlyingOracle } from "./oracles/Underlying.sol";
import { TargetOracle } from "./oracles/Target.sol";
import { PTOracle } from "./oracles/PT.sol";
import { LPOracle } from "./oracles/LP.sol";

import { Trust } from "@sense-finance/v1-utils/src/Trust.sol";
import { Errors } from "@sense-finance/v1-utils/src/libs/Errors.sol";
import { Divider } from "@sense-finance/v1-core/src/Divider.sol";
import { BaseAdapter as Adapter } from "@sense-finance/v1-core/src/adapters/BaseAdapter.sol";

interface FuseDirectoryLike {
    function deployPool(
        string memory name,
        address implementation,
        bool enforceWhitelist,
        uint256 closeFactor,
        uint256 liquidationIncentive,
        address priceOracle
    ) external returns (uint256, address);
}

interface ComptrollerLike {
    /// Deploy cToken, add the market to the markets mapping, and set it as listed and set the collateral factor
    /// Admin function to deploy cToken, set isListed, and add support for the market and set the collateral factor
    function _deployMarket(
        bool isCEther,
        bytes calldata constructorData,
        uint256 collateralFactorMantissa
    ) external returns (uint256);

    /// Accepts transfer of admin rights. msg.sender must be pendingAdmin
    function _acceptAdmin() external returns (uint256);

    /// All cTokens addresses mapped by their underlying token addresses
    function cTokensByUnderlying(address underlying) external view returns (address);

    /// A list of all markets
    function markets(address cToken) external view returns (bool, uint256);

    /// Pause borrowing for a specific market
    function _setBorrowPaused(address cToken, bool state) external returns (bool);
}

interface MasterOracleLike {
    function initialize(
        address[] memory underlyings,
        PriceOracle[] memory _oracles,
        PriceOracle _defaultOracle,
        address _admin,
        bool _canAdminOverwrite
    ) external;

    function add(address[] calldata underlyings, PriceOracle[] calldata _oracles) external;

    function getUnderlyingPrice(address cToken) external view returns (uint256);
}

/// @title Fuse Pool Manager
/// @notice Consolidated Fuse interactions
contract PoolManager is Trust {
    /* ========== PUBLIC IMMUTABLES ========== */

    /// @notice Implementation of Fuse's comptroller
    address public immutable comptrollerImpl;

    /// @notice Implementation of Fuse's cERC20
    address public immutable cERC20Impl;

    /// @notice Fuse's pool directory
    address public immutable fuseDirectory;

    /// @notice Sense core Divider address
    address public immutable divider;

    /// @notice Implementation of Fuse's master oracle that routes to individual asset oracles
    address public immutable oracleImpl;

    /// @notice Sense oracle for SEnse Targets
    address public immutable targetOracle;

    /// @notice Sense oracle for Sense Principal Tokens
    address public immutable ptOracle;

    /// @notice Sense oracle for Space LP Shares
    address public immutable lpOracle;

    /// @notice Sense oracle for Underlying assets
    address public immutable underlyingOracle;

    /* ========== PUBLIC MUTABLE STORAGE ========== */

    /// @notice Fuse comptroller for the Sense pool
    address public comptroller;

    /// @notice Master oracle for Sense's assets deployed on Fuse
    address public masterOracle;

    /// @notice Fuse param config
    AssetParams public targetParams;
    AssetParams public ptParams;
    AssetParams public lpTokenParams;

    /// @notice Series Pools: adapter -> maturity -> (series status (pt/lp shares), AMM pool)
    mapping(address => mapping(uint256 => Series)) public sSeries;

    /* ========== ENUMS ========== */

    enum SeriesStatus {
        NONE,
        QUEUED,
        ADDED
    }

    /* ========== DATA STRUCTURES ========== */

    struct AssetParams {
        address irModel;
        uint256 reserveFactor;
        uint256 collateralFactor;
    }

    struct Series {
        // Series addition status
        SeriesStatus status;
        // Space pool for this Series
        address pool;
    }

    constructor(
        address _fuseDirectory,
        address _comptrollerImpl,
        address _cERC20Impl,
        address _divider,
        address _oracleImpl
    ) Trust(msg.sender) {
        fuseDirectory = _fuseDirectory;
        comptrollerImpl = _comptrollerImpl;
        cERC20Impl = _cERC20Impl;
        divider = _divider;
        oracleImpl = _oracleImpl;

        targetOracle = address(new TargetOracle());
        ptOracle = address(new PTOracle());
        lpOracle = address(new LPOracle());
        underlyingOracle = address(new UnderlyingOracle());
    }

    function deployPool(
        string calldata name,
        uint256 closeFactor,
        uint256 liqIncentive,
        address fallbackOracle
    ) external requiresTrust returns (uint256 _poolIndex, address _comptroller) {
        masterOracle = Clones.cloneDeterministic(oracleImpl, Bytes32AddressLib.fillLast12Bytes(address(this)));
        MasterOracleLike(masterOracle).initialize(
            new address[](0),
            new PriceOracle[](0),
            PriceOracle(fallbackOracle), // default oracle used if asset prices can't be found otherwise
            address(this), // admin
            true // admin can override existing oracle routes
        );

        (_poolIndex, _comptroller) = FuseDirectoryLike(fuseDirectory).deployPool(
            name,
            comptrollerImpl,
            false, // `whitelist` is always false
            closeFactor,
            liqIncentive,
            masterOracle
        );

        uint256 err = ComptrollerLike(_comptroller)._acceptAdmin();
        if (err != 0) revert Errors.FailedBecomeAdmin();
        comptroller = _comptroller;

        emit PoolDeployed(name, _comptroller, _poolIndex, closeFactor, liqIncentive);
    }

    function addTarget(address target, address adapter) external requiresTrust returns (address cTarget) {
        if (comptroller == address(0)) revert Errors.PoolNotDeployed();
        if (targetParams.irModel == address(0)) revert Errors.TargetParamsNotSet();

        address underlying = Adapter(adapter).underlying();

        address[] memory underlyings = new address[](2);
        underlyings[0] = target;
        underlyings[1] = underlying;

        PriceOracle[] memory oracles = new PriceOracle[](2);
        oracles[0] = PriceOracle(targetOracle);
        oracles[1] = PriceOracle(underlyingOracle);

        UnderlyingOracle(underlyingOracle).setUnderlying(underlying, adapter);
        TargetOracle(targetOracle).setTarget(target, adapter);
        MasterOracleLike(masterOracle).add(underlyings, oracles);

        bytes memory constructorData = abi.encode(
            target,
            comptroller,
            targetParams.irModel,
            ERC20(target).name(),
            ERC20(target).symbol(),
            cERC20Impl,
            hex"", // calldata sent to becomeImplementation (empty bytes b/c it's currently unused)
            targetParams.reserveFactor,
            0 // no admin fee
        );

        // Trying to deploy the same market twice will fail
        uint256 err = ComptrollerLike(comptroller)._deployMarket(false, constructorData, targetParams.collateralFactor);
        if (err != 0) revert Errors.FailedAddTargetMarket();

        cTarget = ComptrollerLike(comptroller).cTokensByUnderlying(target);

        emit TargetAdded(target, cTarget);
    }

    /// @notice queues a set of (Principal Tokens, LPShare) for a Fuse pool to be deployed once the TWAP is ready
    /// @dev called by the Periphery, which will know which pool address to set for this Series
    function queueSeries(
        address adapter,
        uint256 maturity,
        address pool
    ) external requiresTrust {
        if (Divider(divider).pt(adapter, maturity) == address(0)) revert Errors.SeriesDoesNotExist();
        if (sSeries[adapter][maturity].status != SeriesStatus.NONE) revert Errors.DuplicateSeries();

        address cTarget = ComptrollerLike(comptroller).cTokensByUnderlying(Adapter(adapter).target());
        if (cTarget == address(0)) revert Errors.TargetNotInFuse();

        (bool isListed, ) = ComptrollerLike(comptroller).markets(cTarget);
        if (!isListed) revert Errors.TargetNotInFuse();

        sSeries[adapter][maturity] = Series({ status: SeriesStatus.QUEUED, pool: pool });

        emit SeriesQueued(adapter, maturity, pool);
    }

    /// @notice open method to add queued Principal Tokens and LPShares to Fuse pool
    /// @dev this can only be done once the yield space pool has filled its buffer and has a TWAP
    function addSeries(address adapter, uint256 maturity) external returns (address cPT, address cLPToken) {
        if (sSeries[adapter][maturity].status != SeriesStatus.QUEUED) revert Errors.SeriesNotQueued();
        if (ptParams.irModel == address(0)) revert Errors.PTParamsNotSet();
        if (lpTokenParams.irModel == address(0)) revert Errors.PoolParamsNotSet();

        address pt = Divider(divider).pt(adapter, maturity);
        address pool = sSeries[adapter][maturity].pool;

        (, , , , , , uint256 sampleTs) = BalancerOracle(pool).getSample(BalancerOracle(pool).getTotalSamples() - 1);
        // Prevent this market from being deployed on Fuse if we're unable to read a TWAP
        if (sampleTs == 0) revert Errors.OracleNotReady();

        address[] memory underlyings = new address[](2);
        underlyings[0] = pt;
        underlyings[1] = pool;

        PriceOracle[] memory oracles = new PriceOracle[](2);
        oracles[0] = PriceOracle(ptOracle);
        oracles[1] = PriceOracle(lpOracle);

        PTOracle(ptOracle).setPrincipal(pt, pool);
        MasterOracleLike(masterOracle).add(underlyings, oracles);

        bytes memory constructorDataPrincipal = abi.encode(
            pt,
            comptroller,
            ptParams.irModel,
            ERC20(pt).name(),
            ERC20(pt).symbol(),
            cERC20Impl,
            hex"",
            ptParams.reserveFactor,
            0 // no admin fee
        );

        uint256 errPrincipal = ComptrollerLike(comptroller)._deployMarket(
            false,
            constructorDataPrincipal,
            ptParams.collateralFactor
        );
        if (errPrincipal != 0) revert Errors.FailedToAddPTMarket();

        // LP Share pool token
        bytes memory constructorDataLpToken = abi.encode(
            pool,
            comptroller,
            lpTokenParams.irModel,
            ERC20(pool).name(),
            ERC20(pool).symbol(),
            cERC20Impl,
            hex"",
            lpTokenParams.reserveFactor,
            0 // no admin fee
        );

        uint256 errLpToken = ComptrollerLike(comptroller)._deployMarket(
            false,
            constructorDataLpToken,
            lpTokenParams.collateralFactor
        );
        if (errLpToken != 0) revert Errors.FailedAddLpMarket();

        cPT = ComptrollerLike(comptroller).cTokensByUnderlying(pt);
        cLPToken = ComptrollerLike(comptroller).cTokensByUnderlying(pool);

        ComptrollerLike(comptroller)._setBorrowPaused(cLPToken, true);

        sSeries[adapter][maturity].status = SeriesStatus.ADDED;

        emit SeriesAdded(pt, pool);
    }

    /* ========== ADMIN ========== */

    function setParams(bytes32 what, AssetParams calldata data) external requiresTrust {
        if (what == "PT_PARAMS") ptParams = data;
        else if (what == "LP_TOKEN_PARAMS") lpTokenParams = data;
        else if (what == "TARGET_PARAMS") targetParams = data;
        else revert Errors.InvalidParam();
        emit ParamsSet(what, data);
    }

    function execute(
        address to,
        uint256 value,
        bytes memory data,
        uint256 txGas
    ) external requiresTrust returns (bool success) {
        assembly {
            success := call(txGas, to, value, add(data, 0x20), mload(data), 0, 0)
        }
    }

    /* ========== LOGS ========== */

    event ParamsSet(bytes32 indexed what, AssetParams data);
    event PoolDeployed(string name, address comptroller, uint256 poolIndex, uint256 closeFactor, uint256 liqIncentive);
    event TargetAdded(address indexed target, address indexed cTarget);
    event SeriesQueued(address indexed adapter, uint256 indexed maturity, address indexed pool);
    event SeriesAdded(address indexed pt, address indexed lpToken);
}

pragma solidity ^0.8.0;
import "./IERC3156FlashBorrower.sol";

interface IERC3156FlashLender {
    /// @dev The amount of currency available to be lent.
    /// @param token The loan currency.
    /// @return The amount of `token` that can be borrowed.
    function maxFlashLoan(address token) external view returns (uint256);

    /// @dev The fee to be charged for a given loan.
    /// @param token The loan currency.
    /// @param amount The amount of tokens lent.
    /// @return The amount of `token` to be charged for the loan, on top of the returned principal.
    function flashFee(address token, uint256 amount) external view returns (uint256);

    /// @dev Initiate a flash loan.
    /// @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
    /// @param token The loan currency.
    /// @param amount The amount of tokens lent.
    /// @param data Arbitrary data structure, intended to contain user-defined parameters.
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

pragma solidity 0.8.11;

/// @author Taken from: https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
library DateTime {
    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint256 constant SECONDS_PER_HOUR = 60 * 60;
    uint256 constant SECONDS_PER_MINUTE = 60;
    int256 constant OFFSET19700101 = 2440588;

    function timestampToDate(uint256 timestamp)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function timestampToDateTime(uint256 timestamp)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day,
            uint256 hour,
            uint256 minute,
            uint256 second
        )
    {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint256 secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function toDateString(uint256 _timestamp)
        internal
        pure
        returns (
            string memory d,
            string memory m,
            string memory y
        )
    {
        (uint256 year, uint256 month, uint256 day) = timestampToDate(_timestamp);
        d = uintToString(day);
        m = uintToString(month);
        y = uintToString(year);
        // append a 0 to numbers < 10 so we should, e.g, 01 instead of just 1
        if (day < 10) d = string(abi.encodePacked("0", d));
        if (month < 10) m = string(abi.encodePacked("0", m));
    }

    function format(uint256 _timestamp) internal pure returns (string memory datestring) {
        string[12] memory months = [
            "Jan",
            "Feb",
            "Mar",
            "Apr",
            "May",
            "June",
            "July",
            "Aug",
            "Sept",
            "Oct",
            "Nov",
            "Dec"
        ];
        (uint256 year, uint256 month, uint256 day) = timestampToDate(_timestamp);
        uint256 last = day % 10;
        string memory suffix = "th";
        if (day < 11 || day > 20) {
            if (last == 1) suffix = "st";
            if (last == 2) suffix = "nd";
            if (last == 3) suffix = "rd";
        }
        return string(abi.encodePacked(uintToString(day), suffix, " ", months[month - 1], " ", uintToString(year)));
    }

    function getDayOfWeek(uint256 timestamp) internal pure returns (uint256 dayOfWeek) {
        uint256 _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = ((_days + 3) % 7) + 1;
    }

    /// Taken from https://stackoverflow.com/questions/47129173/how-to-convert-uint-to-string-in-solidity
    function uintToString(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) return "0";
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) internal pure returns (uint256 _days) {
        require(year >= 1970);
        int256 _year = int256(year);
        int256 _month = int256(month);
        int256 _day = int256(day);

        int256 __days = _day -
            32075 +
            (1461 * (_year + 4800 + (_month - 14) / 12)) /
            4 +
            (367 * (_month - 2 - ((_month - 14) / 12) * 12)) /
            12 -
            (3 * ((_year + 4900 + (_month - 14) / 12) / 100)) /
            4 -
            OFFSET19700101;

        _days = uint256(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint256 _days)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
        int256 __days = int256(_days);

        int256 L = __days + 68569 + OFFSET19700101;
        int256 N = (4 * L) / 146097;
        L = L - (146097 * N + 3) / 4;
        int256 _year = (4000 * (L + 1)) / 1461001;
        L = L - (1461 * _year) / 4 + 31;
        int256 _month = (80 * L) / 2447;
        int256 _day = L - (2447 * _month) / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint256(_year);
        month = uint256(_month);
        day = uint256(_day);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.11;

// Internal references
import { Divider } from "../Divider.sol";
import { Token } from "./Token.sol";

/// @title Yield Token
/// @notice Strips off excess before every transfer
contract YT is Token {
    address public immutable adapter;
    address public immutable divider;
    uint256 public immutable maturity;

    constructor(
        address _adapter,
        uint256 _maturity,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address _divider
    ) Token(_name, _symbol, _decimals, _divider) {
        adapter = _adapter;
        maturity = _maturity;
        divider = _divider;
    }

    function collect() external returns (uint256 _collected) {
        return Divider(divider).collect(msg.sender, adapter, maturity, 0, address(0));
    }

    function transfer(address to, uint256 value) public override returns (bool) {
        Divider(divider).collect(msg.sender, adapter, maturity, value, to);
        return super.transfer(to, value);
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public override returns (bool) {
        if (value > 0) Divider(divider).collect(from, adapter, maturity, value, to);
        return super.transferFrom(from, to, value);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.11;

// External references
import { ERC20 } from "@rari-capital/solmate/src/tokens/ERC20.sol";

// Internal references
import { Trust } from "@sense-finance/v1-utils/src/Trust.sol";

/// @title Base Token
contract Token is ERC20, Trust {
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address _trusted
    ) ERC20(_name, _symbol, _decimals) Trust(_trusted) {}

    /// @param usr The address to send the minted tokens
    /// @param amount The amount to be minted
    function mint(address usr, uint256 amount) public requiresTrust {
        _mint(usr, amount);
    }

    /// @param usr The address from where to burn tokens from
    /// @param amount The amount to be burned
    function burn(address usr, uint256 amount) public requiresTrust {
        _burn(usr, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Library for converting between addresses and bytes32 values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/Bytes32AddressLib.sol)
library Bytes32AddressLib {
    function fromLast20Bytes(bytes32 bytesValue) internal pure returns (address) {
        return address(uint160(uint256(bytesValue)));
    }

    function fillLast12Bytes(address addressValue) internal pure returns (bytes32) {
        return bytes32(bytes20(addressValue));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.11;

import { CToken } from "./CToken.sol";

/// @title Price Oracle
/// @author Compound
/// @notice The minimum interface a contract must implement in order to work as an oracle for Fuse with Sense
/// Original from: https://github.com/Rari-Capital/compound-protocol/blob/fuse-final/contracts/PriceOracle.sol
abstract contract PriceOracle {
    /// @notice Indicator that this is a PriceOracle contract (for inspection)
    bool public constant isPriceOracle = true;

    /// @notice Get the underlying price of a cToken asset
    /// @param cToken The cToken to get the underlying price of
    /// @return The underlying asset price mantissa (scaled by 1e18).
    /// 0 means the price is unavailable.
    function getUnderlyingPrice(CToken cToken) external view virtual returns (uint256);

    /// @notice Get the price of an underlying asset.
    /// @param underlying The underlying asset to get the price of.
    /// @return The underlying asset price in ETH as a mantissa (scaled by 1e18).
    /// 0 means the price is unavailable.
    function price(address underlying) external view virtual returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.11;

interface BalancerOracle {
    function getTimeWeightedAverage(OracleAverageQuery[] memory queries)
        external
        view
        returns (uint256[] memory results);

    enum Variable {
        PAIR_PRICE,
        BPT_PRICE,
        INVARIANT
    }
    struct OracleAverageQuery {
        Variable variable;
        uint256 secs;
        uint256 ago;
    }

    function getSample(uint256 index)
        external
        view
        returns (
            int256 logPairPrice,
            int256 accLogPairPrice,
            int256 logBptPrice,
            int256 accLogBptPrice,
            int256 logInvariant,
            int256 accLogInvariant,
            uint256 timestamp
        );

    function getPoolId() external view returns (bytes32);

    function getVault() external view returns (address);

    function getIndices() external view returns (uint256 _pti, uint256 _targeti);

    function totalSupply() external view returns (uint256);

    function getTotalSamples() external pure returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.11;

// External references
import { PriceOracle } from "../external/PriceOracle.sol";
import { CToken } from "../external/CToken.sol";
import { Errors } from "@sense-finance/v1-utils/src/libs/Errors.sol";

// Internal references
import { Trust } from "@sense-finance/v1-utils/src/Trust.sol";
import { FixedMath } from "@sense-finance/v1-core/src/external/FixedMath.sol";
import { BaseAdapter as Adapter } from "@sense-finance/v1-core/src/adapters/BaseAdapter.sol";

contract UnderlyingOracle is PriceOracle, Trust {
    using FixedMath for uint256;

    /// @notice underlying address -> adapter address
    mapping(address => address) public adapters;

    constructor() Trust(msg.sender) {}

    function setUnderlying(address underlying, address adapter) external requiresTrust {
        adapters[underlying] = adapter;
    }

    function getUnderlyingPrice(CToken cToken) external view override returns (uint256) {
        return _price(address(cToken.underlying()));
    }

    function price(address underlying) external view override returns (uint256) {
        return _price(underlying);
    }

    function _price(address underlying) internal view returns (uint256) {
        address adapter = adapters[address(underlying)];
        if (adapter == address(0)) revert Errors.AdapterNotSet();

        return Adapter(adapter).getUnderlyingPrice();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.11;

// External references
import { PriceOracle } from "../external/PriceOracle.sol";
import { CToken } from "../external/CToken.sol";
import { Errors } from "@sense-finance/v1-utils/src/libs/Errors.sol";

// Internal references
import { Trust } from "@sense-finance/v1-utils/src/Trust.sol";
import { Token } from "@sense-finance/v1-core/src/tokens/Token.sol";
import { FixedMath } from "@sense-finance/v1-core/src/external/FixedMath.sol";
import { BaseAdapter as Adapter } from "@sense-finance/v1-core/src/adapters/BaseAdapter.sol";

contract TargetOracle is PriceOracle, Trust {
    using FixedMath for uint256;

    /// @notice target address -> adapter address
    mapping(address => address) public adapters;

    constructor() Trust(msg.sender) {}

    function setTarget(address target, address adapter) external requiresTrust {
        adapters[target] = adapter;
    }

    function getUnderlyingPrice(CToken cToken) external view override returns (uint256) {
        // For the sense Fuse pool, the underlying will be the Target. The semantics here can be a little confusing
        // as we now have two layers of underlying, cToken -> Target (cToken's underlying) -> Target's underlying
        Token target = Token(cToken.underlying());
        return _price(address(target));
    }

    function price(address target) external view override returns (uint256) {
        return _price(target);
    }

    function _price(address target) internal view returns (uint256) {
        address adapter = adapters[address(target)];
        if (adapter == address(0)) revert Errors.AdapterNotSet();

        // Use the cached scale for view function compatibility
        uint256 scale = Adapter(adapter).scaleStored();

        // `Target / Target's underlying` * `Target's underlying / ETH` = `Price of Target in ETH`
        //
        // `scale` and the value returned by `getUnderlyingPrice` are expected to be WADs
        return scale.fmul(Adapter(adapter).getUnderlyingPrice());
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.11;

// External references
import { ERC20 } from "@rari-capital/solmate/src/tokens/ERC20.sol";
import { PriceOracle } from "../external/PriceOracle.sol";
import { CToken } from "../external/CToken.sol";
import { BalancerOracle } from "../external/BalancerOracle.sol";
import { BalancerVault } from "@sense-finance/v1-core/src/external/balancer/Vault.sol";

// Internal references
import { Trust } from "@sense-finance/v1-utils/src/Trust.sol";
import { Errors } from "@sense-finance/v1-utils/src/libs/Errors.sol";
import { Token } from "@sense-finance/v1-core/src/tokens/Token.sol";
import { FixedMath } from "@sense-finance/v1-core/src/external/FixedMath.sol";
import { BaseAdapter as Adapter } from "@sense-finance/v1-core/src/adapters/BaseAdapter.sol";

interface SpaceLike {
    function getImpliedRateFromPrice(uint256 pTPriceInTarget) external view returns (uint256);

    function getPriceFromImpliedRate(uint256 impliedRate) external view returns (uint256);

    function getTotalSamples() external pure returns (uint256);

    function adapter() external view returns (address);
}

contract PTOracle is PriceOracle, Trust {
    using FixedMath for uint256;

    /// @notice PT address -> pool address for oracle reads
    mapping(address => address) public pools;
    /// @notice Minimum implied rate this oracle will tolerate for PTs
    uint256 public floorRate;
    uint256 public twapPeriod;

    constructor() Trust(msg.sender) {
        floorRate = 3e18; // 300%
        twapPeriod = 5.5 hours;
    }

    function setFloorRate(uint256 _floorRate) external requiresTrust {
        floorRate = _floorRate;
    }

    function setTwapPeriod(uint256 _twapPeriod) external requiresTrust {
        twapPeriod = _twapPeriod;
    }

    function setPrincipal(address pt, address pool) external requiresTrust {
        pools[pt] = pool;
    }

    function getUnderlyingPrice(CToken cToken) external view override returns (uint256) {
        // The underlying here will be a Principal Token
        return _price(cToken.underlying());
    }

    function price(address pt) external view override returns (uint256) {
        return _price(pt);
    }

    function _price(address pt) internal view returns (uint256) {
        BalancerOracle pool = BalancerOracle(pools[address(pt)]);
        if (pool == BalancerOracle(address(0))) revert Errors.PoolNotSet();

        // if getSample(buffer_size) returns 0s, the oracle buffer is not full yet and a price can't be read
        // https://dev.balancer.fi/references/contracts/apis/pools/weightedpool2tokens#api
        (, , , , , , uint256 sampleTs) = pool.getSample(SpaceLike(address(pool)).getTotalSamples() - 1);
        // Revert if the pool's oracle can't be used yet, preventing this market from being deployed
        // on Fuse until we're able to read a TWAP
        if (sampleTs == 0) revert Errors.OracleNotReady();

        BalancerOracle.OracleAverageQuery[] memory queries = new BalancerOracle.OracleAverageQuery[](1);
        // The BPT price slot in Space carries the implied rate TWAP
        queries[0] = BalancerOracle.OracleAverageQuery({
            variable: BalancerOracle.Variable.BPT_PRICE,
            secs: twapPeriod,
            ago: 1 hours // take the oracle from 1 hour ago plus twapPeriod ago to 1 hour ago
        });

        uint256[] memory results = pool.getTimeWeightedAverage(queries);
        // note: impliedRate is pulled from the BPT price slot in BalancerOracle.OracleAverageQuery
        uint256 impliedRate = results[0];

        if (impliedRate > floorRate) {
            impliedRate = floorRate;
        }

        address target = Adapter(SpaceLike(address(pool)).adapter()).target();

        // `Principal Token / target` * `target / ETH` = `Price of Principal Token in ETH`
        //
        // Assumes the caller is the master oracle, which will have its own strategy for getting the underlying price
        return
            SpaceLike(address(pool)).getPriceFromImpliedRate(impliedRate).fmul(PriceOracle(msg.sender).price(target));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.11;

// External references
import { ERC20 } from "@rari-capital/solmate/src/tokens/ERC20.sol";
import { PriceOracle } from "../external/PriceOracle.sol";
import { CToken } from "../external/CToken.sol";
import { BalancerVault } from "@sense-finance/v1-core/src/external/balancer/Vault.sol";
import { BalancerPool } from "@sense-finance/v1-core/src/external/balancer/Pool.sol";

// Internal references
import { Trust } from "@sense-finance/v1-utils/src/Trust.sol";
import { FixedMath } from "@sense-finance/v1-core/src/external/FixedMath.sol";
import { Errors } from "@sense-finance/v1-utils/src/libs/Errors.sol";
import { BaseAdapter as Adapter } from "@sense-finance/v1-core/src/adapters/BaseAdapter.sol";

interface SpaceLike {
    function getFairBPTPrice(uint256 ptTwapDuration) external view returns (uint256);

    function adapter() external view returns (address);
}

contract LPOracle is PriceOracle, Trust {
    using FixedMath for uint256;

    /// @notice PT address -> pool address for oracle reads
    mapping(address => address) public pools;
    uint256 public twapPeriod;

    constructor() Trust(msg.sender) {
        twapPeriod = 5.5 hours;
    }

    function setTwapPeriod(uint256 _twapPeriod) external requiresTrust {
        twapPeriod = _twapPeriod;
    }

    function getUnderlyingPrice(CToken cToken) external view override returns (uint256) {
        // The underlying here will be an LP Token
        return _price(cToken.underlying());
    }

    function price(address pt) external view override returns (uint256) {
        return _price(pt);
    }

    function _price(address _pool) internal view returns (uint256) {
        SpaceLike pool = SpaceLike(_pool);
        address target = Adapter(pool.adapter()).target();

        // Price per BPT in ETH terms, where the PT side of the pool is valued using the TWAP oracle
        return pool.getFairBPTPrice(twapPeriod).fmul(PriceOracle(msg.sender).price(target));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.11;

/// @title Price Oracle
/// @author Compound
interface CToken {
    function underlying() external view returns (address);

    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function repayBorrow(uint256 repayAmount) external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function decimals() external view returns (uint8);
}