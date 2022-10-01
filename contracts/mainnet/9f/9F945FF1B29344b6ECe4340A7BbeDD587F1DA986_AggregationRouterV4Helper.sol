/**
 *Submitted for verification at Etherscan.io on 2022-09-30
*/

pragma experimental ABIEncoderV2;
pragma solidity ^0.7.6;

interface AggregationRouterV4 {
    function swap(
        address caller,
        SwapDescription memory desc,
        bytes calldata data
    ) external payable returns (
        uint256 returnAmount,    
        uint256 spentAmount,   
        uint256 gasLeft);
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

contract AggregationRouterV4Helper {
    function flattenedSwap(
        address router,
        address caller,
        SimpleSwapDescription calldata simpleSwapDescription,
        uint256 amount,
        bytes calldata data
    ) public {
        SwapDescription memory desc = SwapDescription(
            simpleSwapDescription.srcToken, 
            simpleSwapDescription.dstToken, 
            simpleSwapDescription.srcReceiver, 
            simpleSwapDescription.dstReceiver, 
            amount, 
            simpleSwapDescription.minReturnAmount, 
            simpleSwapDescription.flags, 
            simpleSwapDescription.permit);

        AggregationRouterV4(router).swap(
            caller, 
            desc, 
            data);
    }
}