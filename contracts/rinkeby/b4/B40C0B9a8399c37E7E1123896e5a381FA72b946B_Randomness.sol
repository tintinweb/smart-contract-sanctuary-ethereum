// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

/** Logic for lobby battle */
contract Randomness {
  function random() public view virtual returns (uint256) {
    // sha3 and now have been deprecated
    return
      uint256(
        keccak256(
          abi.encodePacked(block.difficulty, block.timestamp, msg.sender)
        )
      );
    // convert hash to integer
    // players is an array of entrants
  }
}