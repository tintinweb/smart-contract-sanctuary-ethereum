/**
 *Submitted for verification at Etherscan.io on 2021-09-02
*/

pragma solidity 0.7.6;

contract BasicUpkeep {
  bool public shouldPerformUpkeep;
  bytes public bytesToSend;
  bytes public receivedBytes;

  function setShouldPerformUpkeep(bool _should) public {
    shouldPerformUpkeep = _should;
  }

  function setBytesToSend(bytes memory _bytes) public {
    bytesToSend = _bytes;
  }

  function checkUpkeep(bytes calldata data) public view returns (bool, bytes memory) {
    return (shouldPerformUpkeep, bytesToSend);
  }

  function performUpkeep(bytes calldata data) external {
    // shouldPerformUpkeep = false;
    receivedBytes = data;
  }
}