/**
 *Submitted for verification at Etherscan.io on 2022-11-16
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

contract InitReset {

  bytes32 constant _initializedSlot = 0x4e5f991bca30eca2d4643aaefa807e88f96a4a97398933d572a3c0d973004a01;

  function reset() external {
    assembly {
      sstore(_initializedSlot, 0x0000000000000000000000000000000000000000000000000000000000000000)
    }
  }

}