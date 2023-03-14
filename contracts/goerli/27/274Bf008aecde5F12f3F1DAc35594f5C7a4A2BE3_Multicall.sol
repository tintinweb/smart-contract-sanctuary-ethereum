// SPDX-License-Identifier: MIT
contract Multicall {
    struct Call {
        address target; // who to call
        bytes callData; // what to call
    }
    
    function aggregate(Call[] memory calls) public returns (uint256 blockNumber, bytes[] memory returnData) {
        // returns block number to guarantee that all values returned are from the same block
        blockNumber = block.number;
        returnData = new bytes[](calls.length);
        // loop through calls
        for(uint256 i = 0; i < calls.length; i++) {
            // call NFT function
            (bool success, bytes memory ret) = calls[i].target.call(calls[i].callData);
            require(success);
            // store call data and return when exit loop
            returnData[i] = ret;
        }
    }
}