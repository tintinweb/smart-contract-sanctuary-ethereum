// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IERC20 {
    function balanceOf(address) external returns (uint256);
}

interface IAggregationExecutorV5 {
    /// @notice propagates information about original msg.sender and executes arbitrary data
    function execute(address msgSender) external payable; // 0x4b64e492
}

interface IAggregationExecutorV4 {
    /// @notice Make calls on `msgSender` with specified data
    function callBytes(address msgSender, bytes calldata data) external payable; // 0x2636f7f8
}

interface IAggregationRouterV4 {
    function swap(
        IAggregationExecutorV4 caller,
        SwapDescriptionV4 memory desc,
        bytes calldata data
    )
        external
        payable
        returns (uint256 returnAmount, uint256 spentAmount, uint256 gasLeft);
}

interface IAggregationRouterV5 {
    function swap(
        IAggregationExecutorV5 caller,
        SwapDescriptionV5 memory desc,
        bytes calldata permit,
        bytes calldata data
    ) external payable returns (uint256 returnAmount, uint256 spentAmount);
}

interface BVault {
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

    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external returns (uint256 amountCalculated);
}

struct SwapDescriptionV4 {
    address srcToken;
    address dstToken;
    address payable srcReceiver;
    address payable dstReceiver;
    uint256 amount;
    uint256 minReturnAmount;
    uint256 flags;
    bytes permit;
}

struct SwapDescriptionV5 {
    address srcToken;
    address dstToken;
    address payable srcReceiver;
    address payable dstReceiver;
    uint256 amount;
    uint256 minReturnAmount;
    uint256 flags;
}

// This is SwapDescription minus the amount. The version of weiroll
// used does not support dynamic types withing tuples, so in this case
// the amount will be passed as a single variable to avoid being part
// of the dynamic tuple
struct TruncatedSwapDescriptionV4 {
    address srcToken;
    address dstToken;
    address payable srcReceiver;
    address payable dstReceiver;
    uint256 minReturnAmount;
    uint256 flags;
    bytes permit;
}

struct TruncatedSwapDescriptionV5 {
    address srcToken;
    address dstToken;
    address payable srcReceiver;
    address payable dstReceiver;
    uint256 minReturnAmount;
    uint256 flags;
}

enum SwapKind {
    GIVEN_IN,
    GIVEN_OUT
}

enum JoinKind {
    INIT,
    EXACT_TOKENS_IN_FOR_BPT_OUT,
    TOKEN_IN_FOR_EXACT_BPT_OUT,
    ALL_TOKENS_IN_FOR_EXACT_BPT_OUT
}
enum ExitKind {
    EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
    EXACT_BPT_IN_FOR_TOKENS_OUT,
    BPT_IN_FOR_EXACT_TOKENS_OUT
}

struct SimplifiedSingleSwap {
    SwapKind kind;
    address assetIn;
    address assetOut;
}

struct SingleSwap {
    bytes32 poolId;
    SwapKind kind;
    address assetIn;
    address assetOut;
    uint256 amount;
    bytes userData;
}

struct FundManagement {
    address sender;
    bool fromInternalBalance;
    address payable recipient;
    bool toInternalBalance;
}

struct JoinPoolRequest {
    address[] assets;
    uint256[] maxAmountsIn;
    bytes userData;
    bool fromInternalBalance;
}

struct ExitPoolRequest {
    address[] assets;
    uint256[] minAmountsOut;
    bytes userData;
    bool toInternalBalance;
}

contract SeasolverHelper {
    function flattened1InchSwapV4(
        IAggregationRouterV4 router,
        IAggregationExecutorV4 caller,
        TruncatedSwapDescriptionV4 calldata truncatedDesc,
        uint256 amount,
        bytes calldata data
    ) external payable returns (uint256 returnAmount) {
        SwapDescriptionV4 memory desc = SwapDescriptionV4(
            truncatedDesc.srcToken,
            truncatedDesc.dstToken,
            truncatedDesc.srcReceiver,
            truncatedDesc.dstReceiver,
            amount,
            truncatedDesc.minReturnAmount,
            truncatedDesc.flags,
            truncatedDesc.permit
        );

        (returnAmount, , ) = router.swap(caller, desc, data);
        return returnAmount;
    }

    function flattened1InchSwapV5(
        IAggregationRouterV5 router,
        IAggregationExecutorV5 executor,
        TruncatedSwapDescriptionV5 calldata truncatedDesc,
        uint256 amount,
        bytes calldata permit,
        bytes calldata data
    ) external payable returns (uint256 returnAmount) {
        SwapDescriptionV5 memory desc = SwapDescriptionV5(
            truncatedDesc.srcToken,
            truncatedDesc.dstToken,
            truncatedDesc.srcReceiver,
            truncatedDesc.dstReceiver,
            amount,
            truncatedDesc.minReturnAmount,
            truncatedDesc.flags
        );

        (returnAmount, ) = router.swap(executor, desc, permit, data);
        return returnAmount;
    }

    function flattenedBalancerSwap(
        BVault bvault,
        bytes32 poolId,
        SimplifiedSingleSwap memory ssw,
        uint256 amountGiven,
        address payable tradeHandler,
        uint256 limit
    ) external returns (uint256) {
        SingleSwap memory singleSwap = SingleSwap(
            poolId,
            ssw.kind,
            ssw.assetIn,
            ssw.assetOut,
            amountGiven,
            abi.encode(0)
        );
        return
            bvault.swap(
                singleSwap,
                FundManagement(tradeHandler, false, tradeHandler, false),
                limit,
                2 ** 256 - 1
            );
    }

    // === REFERENCE ===
    // https://github.com/balancer-labs/balancer-v2-monorepo/blob/master/pkg/balancer-js/src/pool-weighted/encoder.ts

    function flattenedBalancerJoinPool(
        BVault bvault,
        bool isSelling,
        IERC20 outToken,
        bytes32 poolId,
        address tradeHandler,
        uint256 amountGiven,
        uint256 enterIndex,
        address[] memory assets
    ) external returns (uint256) {
        uint256[] memory maxAmountsIn = new uint256[](assets.length);
        maxAmountsIn[enterIndex] = amountGiven;
        bytes memory userData = isSelling
            ? abi.encode(JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT, maxAmountsIn, 0)
            : abi.encode(
                JoinKind.TOKEN_IN_FOR_EXACT_BPT_OUT,
                amountGiven,
                enterIndex
            );
        JoinPoolRequest memory request = JoinPoolRequest(
            assets,
            maxAmountsIn,
            userData,
            false
        );
        uint256 balanceBefore = outToken.balanceOf(address(tradeHandler));
        bvault.joinPool(poolId, tradeHandler, tradeHandler, request);
        uint256 balanceAfter = outToken.balanceOf(address(tradeHandler));
        return
            isSelling
                ? balanceAfter - balanceBefore
                : balanceBefore - balanceAfter;
    }

    function flattenedBalancerExitPool(
        BVault bvault,
        bool isSelling,
        IERC20 outToken,
        bytes32 poolId,
        address payable tradeHandler,
        uint256 amountGiven,
        uint256 exitIndex,
        address[] memory assets
    ) external returns (uint256) {
        uint256[] memory minAmountsOut = new uint256[](assets.length);
        uint256[] memory amountsOut = new uint256[](assets.length);
        amountsOut[exitIndex] = amountGiven;
        bytes memory userData = isSelling
            ? abi.encode(
                ExitKind.EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
                amountGiven,
                exitIndex
            )
            : abi.encode(
                ExitKind.BPT_IN_FOR_EXACT_TOKENS_OUT,
                amountsOut,
                2 ** 256 - 1
            );
        ExitPoolRequest memory request = ExitPoolRequest(
            assets,
            minAmountsOut,
            userData,
            false
        );
        uint256 balanceBefore = outToken.balanceOf(address(tradeHandler));
        bvault.exitPool(poolId, tradeHandler, tradeHandler, request);
        uint256 balanceAfter = outToken.balanceOf(address(tradeHandler));
        return balanceAfter - balanceBefore;
    }
}