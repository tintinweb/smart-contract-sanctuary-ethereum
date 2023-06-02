// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

/// @notice implements popular `IMulticall` (https://github.com/makerdao/multicall)
contract Multicall {
  function aggregate(Call[] calldata calls) public returns (uint256 blockNumber, bytes[] memory returnData) {
    blockNumber = block.number;
    returnData = new bytes[](calls.length);
    for (uint256 i = 0; i < calls.length; ) {
      // solhint-disable-next-line avoid-low-level-calls
      (bool success, bytes memory data) = calls[i].target.delegatecall(calls[i].callData);
      if (!success) {
        // solhint-disable-next-line no-inline-assembly
        assembly ("memory-safe") {
          let size := mload(data)
          revert(add(32, data), size)
        }
      }
      returnData[i] = data;
      unchecked {
        ++i;
      }
    }
  }

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

struct Call {
  address target;
  bytes callData;
}