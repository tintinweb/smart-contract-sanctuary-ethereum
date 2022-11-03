/**
 *Submitted for verification at Etherscan.io on 2022-11-03
*/

pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

/// source: https://etherscan.io/address/0x5ba1e12693dc8f9c48aad8770482f4739beed696
/// call swapped out for delegatecall

contract MultiDelegatecall {
    struct Call {
        address target;
        bytes callData;
    }

    function aggregate(Call[] memory calls) public returns (uint256 blockNumber, bytes[] memory returnData) {
        blockNumber = block.number;
        returnData = new bytes[](calls.length);
        for(uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = calls[i].target.delegatecall(calls[i].callData);
            require(success, "Multicall aggregate: call failed");
            returnData[i] = ret;
        }
    }
}