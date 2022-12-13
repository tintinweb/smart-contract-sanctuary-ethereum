/**
 *Submitted for verification at Etherscan.io on 2022-12-13
*/

//SPDX-License-Identifier: UNLICENSED

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.17;

contract Santa {
  function whereGift(string calldata email) external pure returns(string memory) {
    if (keccak256(bytes(email)) == 0x888e65d3d0ce889ec787c91cd1dbb6ff3c6e910a436496a59ca047717103e3e7) {
      return "Black cubby by the window. Key on the side.";
    }

    revert("email does not match");
  }

  function a() external pure returns(string memory) {
    return "aaa";
  }
}