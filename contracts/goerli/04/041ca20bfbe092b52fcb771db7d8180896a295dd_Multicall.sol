/**
 *Submitted for verification at Etherscan.io on 2023-02-02
*/

pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

contract Multicall {
    struct Call {
        address target;
        bytes callData;
    }
    function aggregate(Call[] calldata calls) public view returns (uint256 blockNumber, bytes[] memory returnData) {
        blockNumber = block.number;
        returnData = new bytes[](calls.length);
        for(uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = calls[i].target.staticcall(calls[i].callData);
            require(success);
            returnData[i] = ret;
        }
    }
}