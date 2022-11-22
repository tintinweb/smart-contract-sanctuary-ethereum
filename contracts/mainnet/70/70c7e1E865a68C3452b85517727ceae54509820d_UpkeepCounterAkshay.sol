pragma solidity ^0.7.6;

contract UpkeepCounterAkshay {
  event PerformingUpkeep(
    address indexed from,
    uint256 initialBlock,
    uint256 lastBlock,
    uint256 previousBlock,
    uint256 counter,
    bytes performData
  );

  uint256 public interval;
  uint256 public lastBlock;
  uint256 public previousPerformBlock;
  uint256 public initialBlock;
  uint256 public counter;
  uint256 public performGasToBurn;
  mapping(bytes32 => bool) public dummyMap; // used to force storage lookup
  uint256 performDataSize;

  constructor(uint256 _interval) {
    interval = _interval;
    previousPerformBlock = 0;
    lastBlock = block.number;
    initialBlock = 0;
    counter = 0;
    performGasToBurn = 0;
  }

  function checkUpkeep(bytes calldata data) external returns (bool, bytes memory) {
    uint256 startGas = gasleft();
    bytes memory data = new bytes(4 * performDataSize);
    uint256 blockNum = block.number;
    while (startGas - gasleft() < 100000) {
      // Hard coded check gas to burn
      dummyMap[blockhash(blockNum)] = false; // arbitrary storage writes
      blockNum--;
    }
    return (eligible(), data);
  }

  function performUpkeep(bytes calldata performData) external {
    uint256 startGas = gasleft();
    if (initialBlock == 0) {
      initialBlock = block.number;
    }
    lastBlock = block.number;
    counter = counter + 1;
    emit PerformingUpkeep(
      tx.origin,
      initialBlock,
      lastBlock,
      previousPerformBlock,
      counter,
      performData
    );
    previousPerformBlock = lastBlock;

    uint256 blockNum = block.number;
    while (startGas - gasleft() < performGasToBurn) {
      dummyMap[blockhash(blockNum)] = false; // arbitrary storage writes
      blockNum--;
    }
  }

  function eligible() public view returns (bool) {
    if (initialBlock == 0) {
      return true;
    }

    return (block.number - lastBlock) >= interval;
  }

  function setPerformGasToBurn(uint256 value) public {
    performGasToBurn = value;
  }

  function setPerformDataSize(uint256 value) public {
    performDataSize = value;
  }

  function setSpread(uint256 _interval) external {
    interval = _interval;
    initialBlock = 0;
    counter = 0;
  }
}