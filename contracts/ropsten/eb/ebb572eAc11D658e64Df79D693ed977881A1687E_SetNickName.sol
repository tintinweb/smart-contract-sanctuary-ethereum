//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;


contract SetNickName {

  constructor() {
  }

  function setNickName(address _ctfContract) public {
    bytes memory payload = abi.encodeWithSignature("setNickname(bytes32)", "Redmann");
    (bool success, bytes memory returnData) = address(_ctfContract).delegatecall(payload);
    require(success);
  }
}