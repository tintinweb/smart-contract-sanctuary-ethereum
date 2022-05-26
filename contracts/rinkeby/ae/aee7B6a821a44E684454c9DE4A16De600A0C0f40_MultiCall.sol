// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

//import "hardhat/console.sol";

contract MultiCall
{
    struct Call {
        address target;
        uint256 gasLimit;
        bytes callData;
    }

    struct Result {
        bool success;
        uint256 gasUsed;
        bytes returnData;
    }

    function multicall(Call[] memory calls) external returns (uint256 blockNumber, Result[] memory returnData) {
        blockNumber = block.number;
        returnData = new Result[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            (address target, uint256 gasLimit, bytes memory callData) = (calls[i].target, calls[i].gasLimit, calls[i].callData);
            uint256 gasLeftBefore = gasleft();

            // console.log("gasLeftBefore %s", gasLeftBefore);
            (bool success, bytes memory ret) = target.delegatecall{gas: gasLimit}(callData);
            uint256 gasUsed = gasLeftBefore - gasleft();

            // console.log("gasUsed %s", gasUsed);
            // console.log("ret %s", ret);

            returnData[i] = Result(success, gasUsed, ret);
        }
    }

}