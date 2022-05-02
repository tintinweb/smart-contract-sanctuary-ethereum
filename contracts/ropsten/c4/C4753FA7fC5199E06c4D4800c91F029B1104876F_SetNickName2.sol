//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

interface ICaptureTheEther {
    function setNickname(bytes32 nickname) external;
}

contract SetNickName2 {
  address constant theEthAddress = 0x71c46Ed333C35e4E6c62D32dc7C8F00D125b4fee;
  	
  constructor() {}

  function setName(bytes32 _nick) external {
  	ICaptureTheEther(theEthAddress).setNickname(_nick);
  }
}