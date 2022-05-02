//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;


contract SetNickName3 {

  constructor() {
  }

  function setName(address _ctfContract) public {
    bytes memory payload = abi.encodeWithSignature("setNickname(bytes32)", "0x5265646d616e6e000000000000000000000000000000000000000000000000");
    (bool success, bytes memory returnData) = address(_ctfContract).delegatecall(payload);
    require(success);
  }
}