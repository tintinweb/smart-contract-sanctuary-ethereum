/**
 *Submitted for verification at Etherscan.io on 2022-06-21
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

/// @title Multicall - Aggregate results from multiple read-only function calls
/// @author Michael Elliot <[email protected]>
/// @author Joshua Levine <[email protected]>
/// @author Nick Johnson <[email protected]>

contract MulticallV2 {
    struct Call {
        address target;
        bytes callData;
    }
    function aggregate(Call[] memory calls) public returns (uint256 blockNumber, bytes[] memory returnData) {
        blockNumber = block.number;
        returnData = new bytes[](calls.length);
        for(uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = calls[i].target.call(calls[i].callData);
            require(success);
            returnData[i] = ret;
        }
    }
    function aggregateV2(Call[] memory calls) public returns (uint256 blockNumber, bytes[] memory returnData, bool[] memory returnStatus) {
        blockNumber = block.number;
        returnData = new bytes[](calls.length);
        returnStatus = new bool[](calls.length);
        for(uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = calls[i].target.call(calls[i].callData);
            if (success) {
                returnStatus[i] = success;
                returnData[i] = ret;
            } else {
                assembly {
                    // Note we are manually writing the memory slot 0. We can safely overwrite whatever is
                    // stored there as we take full control of the execution and then immediately return.

                    // We copy the first 4 bytes to check if it matches with the expected signature, otherwise
                    // there was another revert reason and we should forward it.
                    returndatacopy(0, 0, 0x04)
                    let error := and(mload(0), 0xffffffff00000000000000000000000000000000000000000000000000000000)

                    // If the first 4 bytes don't match with the expected signature, we forward the revert reason.
                    if eq(eq(error, 0xfa61cc1200000000000000000000000000000000000000000000000000000000), 0) {
                        returndatacopy(0, 0, returndatasize())
                        revert(0, returndatasize())
                    }

                    // The returndata contains the signature, followed by the raw memory representation of an array:
                    // length + data. We need to return an ABI-encoded representation of this array.
                    // An ABI-encoded array contains an additional field when compared to its raw memory
                    // representation: an offset to the location of the length. The offset itself is 32 bytes long,
                    // so the smallest value we  can use is 32 for the data to be located immediately after it.
                    mstore(0, 32)

                    // We now copy the raw memory array from returndata into memory. Since the offset takes up 32
                    // bytes, we start copying at address 0x20. We also get rid of the error signature, which takes
                    // the first four bytes of returndata.
                    let size := sub(returndatasize(), 0x04)
                    returndatacopy(0x20, 0x04, size)

                    // We finally return the ABI-encoded array, which has a total length equal to that of the array
                    // (returndata), plus the 32 bytes for the offset.
                    return(0, add(size, 32))
                }
            }
        }
    }
    // Helper functions
    function getEthBalance(address addr) public view returns (uint256 balance) {
        balance = addr.balance;
    }
    function getBlockHash(uint256 blockNumber) public view returns (bytes32 blockHash) {
        blockHash = blockhash(blockNumber);
    }
    function getLastBlockHash() public view returns (bytes32 blockHash) {
        blockHash = blockhash(block.number - 1);
    }
    function getCurrentBlockTimestamp() public view returns (uint256 timestamp) {
        timestamp = block.timestamp;
    }
    function getCurrentBlockDifficulty() public view returns (uint256 difficulty) {
        difficulty = block.difficulty;
    }
    function getCurrentBlockGasLimit() public view returns (uint256 gaslimit) {
        gaslimit = block.gaslimit;
    }
    function getCurrentBlockCoinbase() public view returns (address coinbase) {
        coinbase = block.coinbase;
    }
}