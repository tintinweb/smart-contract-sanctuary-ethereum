// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

error MultiReadCall__Unequallength();

/// @author Airstack Team
/// @title MultiReadCall

contract MultiReadCall {
    struct Response {
        bool status;
        bytes response;
    }

    // Takes in array off address & calldatas to call and returns the response array
    /// @param tokenAddresses : addresses where functions must be called
    /// @param inputDatas : represent function callldatas

    function makeStaticCall(
        address[] calldata tokenAddresses,
        bytes[] calldata inputDatas
    ) external view returns (Response[] memory) {
        uint256 len = tokenAddresses.length;
        if (len != inputDatas.length) {
            revert MultiReadCall__Unequallength();
        }
        Response[] memory responseArray = new Response[](len);
        for (uint256 i = 0; i < len; i++) {
            (bool status, bytes memory data) = tokenAddresses[i].staticcall(
                inputDatas[i]
            );
            responseArray[i] = Response(status, data);
        }
        return responseArray;
    }
}