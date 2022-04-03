/**
 *Submitted for verification at Etherscan.io on 2022-04-03
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

contract Factory {
  event Deployed(address addr, uint256 salt);

  function deploy(bytes memory code, uint256 salt) public {
    address addr;
    assembly {
      addr := create2(0, add(code, 0x20), mload(code), salt)
      if iszero(extcodesize(addr)) {
        revert(0, 0)
      }
    }

    emit Deployed(addr, salt);
  }
}