/**
 *Submitted for verification at Etherscan.io on 2022-06-06
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

// PoS Block Oracle.
contract PosBlockOracle {
  uint256 firstRegisteredPosBlock = 0;
  event RegisterPos(uint256 _blockNumber, address _setter);

  // Set the current block as the first PoS Block if:
  // - We are in PoS
  // - It's nos set yet
  function setPosBlock() public {
    require(firstRegisteredPosBlock == 0, "First registered PoS Block already set");
    require(isPosActive(), "We are still on PoW");

    firstRegisteredPosBlock = block.number;
    emit RegisterPos(firstRegisteredPosBlock, msg.sender);
  }

  function getFirstRegisteredPosBlock() public view returns (uint256) {
    require(firstRegisteredPosBlock >= 0, "PoS Block not set yet");
    return firstRegisteredPosBlock;
  }

  // Check if we are in PoS.
  // @dev Check https://eips.ethereum.org/EIPS/eip-4399#using-264-threshold-to-determine-pos-blocks
  function isPosActive() public view returns (bool) {
    return block.difficulty > 2**64;
  }
}