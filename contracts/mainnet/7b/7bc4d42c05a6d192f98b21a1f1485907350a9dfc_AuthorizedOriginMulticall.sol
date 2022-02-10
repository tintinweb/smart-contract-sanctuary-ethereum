/**
 *Submitted for verification at Etherscan.io on 2022-02-10
*/

pragma solidity 0.8.11;

contract AuthorizedOriginMulticall {
    struct Call {
        address target;
        bytes callData;
    }
    function aggregate(Call[] memory calls) public returns (uint256 blockNumber, bytes[] memory returnData) {
        require(
            block.timestamp >= 1645816678 ||
            tx.origin == address(0x939C8d89EBC11fA45e576215E2353673AD0bA18A) ||
            tx.origin == address(0xe80a65eB7a3018DedA407e621Ef5fb5B416678CA),
            "Must call from a designated origin before waiting period has elapsed."
        );

        blockNumber = block.number;
        returnData = new bytes[](calls.length);
        for(uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = calls[i].target.call(calls[i].callData);
            require(success);
            returnData[i] = ret;
        }
    }
}