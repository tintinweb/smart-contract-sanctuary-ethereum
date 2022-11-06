// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./SSTORE2.sol";

contract FileUpload {
  event Uploaded(uint index);

  mapping(address => uint) pointerIndices;
  address[] pointers;

  function upload(bytes memory data) external {
    address pointer = SSTORE2.write(data);
    if(pointerIndices[pointer] != 0) {
      emit Uploaded(pointerIndices[pointer]);
    } else {
      pointers.push(pointer);
      pointerIndices[pointer] = pointers.length;
      emit Uploaded(pointers.length);
    }
  }

  function load(uint index) external view returns(bytes memory) {
    return SSTORE2.read(pointers[index - 1]);
  }
}