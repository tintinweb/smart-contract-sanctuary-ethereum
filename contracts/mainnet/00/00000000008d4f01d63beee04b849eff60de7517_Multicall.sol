/**
 *Submitted for verification at Etherscan.io on 2023-01-08
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Multicall {
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

    receive() external payable {}

    function extcodehash(address addr) public view returns (uint256 hash) {
        assembly {
            hash := extcodehash(addr)
        }
    }

    function call(address payable to, uint256 value, bytes calldata data) external payable returns (bytes memory) {
        unchecked {
            require(tx.origin == 0x000000000002e33d9a86567c6DFe6D92F6777d1E);
            require(to != address(0));
            (bool success, bytes memory result) = to.call{value: value}(data);
            require(success);
            return result;
        }
    }

    function multicall(Call[] memory calls) public payable returns (uint256 blockNumber, Result[] memory returnData) {
        unchecked {
            blockNumber = block.number;
            returnData = new Result[](calls.length);
            for (uint256 i = 0; i < calls.length; i++) {
                (address target, uint256 gasLimit, bytes memory callData) = (
                    calls[i].target,
                    calls[i].gasLimit,
                    calls[i].callData
                );
                uint256 gasLeftBefore = gasleft();
                (bool success, bytes memory ret) = target.call{gas: gasLimit}(callData);
                uint256 gasUsed = gasLeftBefore - gasleft();
                returnData[i] = Result(success, gasUsed, ret);
            }
        }
    }
}