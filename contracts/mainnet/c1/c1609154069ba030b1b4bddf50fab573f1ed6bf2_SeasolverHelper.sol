/**
 *Submitted for verification at Etherscan.io on 2022-12-09
*/

pragma solidity 0.8.15;
pragma experimental ABIEncoderV2;

interface IERC20 {
    function balanceOf(address) external returns (uint256);
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

    function batchSwap(
        uint256 kind,
        BatchSwapStep[] memory swaps,
        address[] memory assets,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
    ) external payable returns (int256[] memory);
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

struct SimplifiedBatchSwapStep {
    bytes32 poolId;
    uint256 assetInIndex;
    uint256 assetOutIndex;
}

struct BatchSwapStep {
    bytes32 poolId;
    uint256 assetInIndex;
    uint256 assetOutIndex;
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
        uint256 kind,
        IERC20 outToken,
        SimplifiedBatchSwapStep[] memory simplifiedSteps,
        uint256 amountGiven,
        address[] memory assets,
        address payable tradeHandler,
        int256[] memory limits
    ) external returns (uint256) {
        BatchSwapStep[] memory steps = new BatchSwapStep[](simplifiedSteps.length);
        for (uint8 i = 0; i < simplifiedSteps.length; i++) {
            SimplifiedBatchSwapStep memory simplifiedStep = simplifiedSteps[i];
            steps[i] = BatchSwapStep(
                simplifiedStep.poolId,
                simplifiedStep.assetInIndex,
                simplifiedStep.assetOutIndex,
                i == 0 ? amountGiven : 0,
                abi.encode(0)
            );
        }

        uint256 balanceBefore = outToken.balanceOf(address(tradeHandler));
        bvault.batchSwap(
            kind,
            steps,
            assets,
            FundManagement(tradeHandler, false, tradeHandler, false),
            limits,
            2**256 - 1
        );
        uint256 balanceAfter = outToken.balanceOf(address(tradeHandler));
        return balanceAfter - balanceBefore;
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
}