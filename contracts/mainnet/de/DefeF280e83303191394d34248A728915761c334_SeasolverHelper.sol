/**
 *Submitted for verification at Etherscan.io on 2023-01-05
*/

pragma solidity 0.8.17;
pragma experimental ABIEncoderV2;

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
}

interface AggregationRouterV4 {
    function swap(
        address caller,
        SwapDescription memory desc,
        bytes calldata data
    )
        external
        payable
        returns (
            uint256 returnAmount,
            uint256 spentAmount,
            uint256 gasLeft
        );
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

struct SwapDescription {
    address srcToken;
    address dstToken;
    address payable srcReceiver;
    address payable dstReceiver;
    uint256 amount;
    uint256 minReturnAmount;
    uint256 flags;
    bytes permit;
}

// This is used to compact the flattenSwap input arguments, otherwise stack is too deep
struct SimpleSwapDescription {
    address srcToken;
    address dstToken;
    address payable srcReceiver;
    address payable dstReceiver;
    uint256 minReturnAmount;
    uint256 flags;
    bytes permit;
}
enum SwapKind {
    GIVEN_IN,
    GIVEN_OUT
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
    function flattened1InchSwap(
        address router,
        address caller,
        SimpleSwapDescription calldata simpleSwapDescription,
        uint256 amount,
        bytes calldata data
    )
        external
        payable
        returns (
            uint256 returnAmount,
            uint256 spentAmount,
            uint256 gasLeft
        )
    {
        SwapDescription memory desc = SwapDescription(
            simpleSwapDescription.srcToken,
            simpleSwapDescription.dstToken,
            simpleSwapDescription.srcReceiver,
            simpleSwapDescription.dstReceiver,
            amount,
            simpleSwapDescription.minReturnAmount,
            simpleSwapDescription.flags,
            simpleSwapDescription.permit
        );

        return AggregationRouterV4(router).swap(caller, desc, data);
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
                2**256 - 1
            );
    }

    // === REFERENCE ===
    // https://github.com/balancer-labs/balancer-v2-monorepo/blob/master/pkg/balancer-js/src/pool-weighted/encoder.ts
    //
    // export enum WeightedPoolJoinKind {
    //   INIT = 0,
    //   EXACT_TOKENS_IN_FOR_BPT_OUT,
    //   TOKEN_IN_FOR_EXACT_BPT_OUT,
    //   ALL_TOKENS_IN_FOR_EXACT_BPT_OUT,
    //   ADD_TOKEN,
    // }

    // export enum WeightedPoolExitKind {
    //   EXACT_BPT_IN_FOR_ONE_TOKEN_OUT = 0,
    //   EXACT_BPT_IN_FOR_TOKENS_OUT,
    //   BPT_IN_FOR_EXACT_TOKENS_OUT,
    //   REMOVE_TOKEN,
    // }

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
            ? abi.encode(
                "uint256",
                "uint256",
                "uint256",
                2,
                amountGiven,
                enterIndex
            )
            : abi.encode("uint256", "uint256[]", "uint256", 1, maxAmountsIn, 0);
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
        address[] memory assets,
        uint256[] memory minAmountsOut
    ) external returns (uint256) {
        uint256[] memory amountsOut = minAmountsOut;
        amountsOut[exitIndex] = amountGiven;
        bytes memory userData = isSelling
            ? abi.encode(
                ["uint256", "uint256", "uint256"],
                0,
                amountGiven,
                exitIndex
            )
            : abi.encode(
                ["uint256", "uint256[]", "uint256"],
                2,
                amountsOut,
                2**256 - 1
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
    
    function balanceOf(IERC20 token, address user) external view returns (uint256) {
        return token.balanceOf(user);
    }
}