/**
 *Submitted for verification at Etherscan.io on 2022-11-16
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

contract InitReset {

  function reset(bytes32 input) external {
    assembly {
      sstore(0x4e5f991bca30eca2d4643aaefa807e88f96a4a97398933d572a3c0d973004a01, input)
    }
  }

  function review() external view returns (bytes32 output) {
    assembly {
      output := sload(0x4e5f991bca30eca2d4643aaefa807e88f96a4a97398933d572a3c0d973004a01)
    }
  }

}