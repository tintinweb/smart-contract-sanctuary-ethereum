// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.17;

contract Multicall {
    struct Call {
        address target;
        bytes callData;
        uint256 gasLimit;
    }

    struct Result {
        bool success;
        uint256 usedGas;
        bytes returnData;
    }

    function multicall(Call[] calldata calls) public payable returns (Result[] memory returnData) {
        uint256 length = calls.length;
        returnData = new Result[](length);
        uint256 gasBefore;
        for (uint256 i = 0; i < length; i++) {
            gasBefore = gasleft();
            if (gasBefore < (calls[i].gasLimit + 1000)) {
                return returnData;
            }

            Result memory result = returnData[i];
            (result.success, result.returnData) = calls[i].target.call(calls[i].callData);
            result.usedGas = gasBefore-gasleft();
        }
    }
}