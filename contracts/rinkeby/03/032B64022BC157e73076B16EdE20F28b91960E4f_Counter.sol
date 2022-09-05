/**
 *Submitted for verification at Etherscan.io on 2022-09-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract Counter {
    uint public count;

    // Function to get the current count
    function get() public view returns (uint) {
        return count;
    }

    // Function to increment count by 1
    function inc() public {
        count += 1;
    }

    // Function to decrement count by 1
    function dec() public {
        count -= 1;
    }
    
  function rand() public view returns (uint256 random) {
    random = uint256(
      keccak256(
        abi.encodePacked(
          msg.sender,
          blockhash(block.number - 1),
          block.difficulty
        )
      )
    );
  }
}