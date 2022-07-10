// SPDX-License-Identifier: MIT
import { IStringValidator } from '../interfaces/IStringValidator.sol';

pragma solidity ^0.8.6;


contract StringValidator is IStringValidator {
  function validate(bytes memory str) external pure override returns (bool) {
    for(uint i; i < str.length; i++){
      bytes1 char = str[i];
        if(!(
         (char >= 0x30 && char <= 0x39) || //0-9
         (char >= 0x41 && char <= 0x5A) || //A-Z
         (char >= 0x61 && char <= 0x7A) || //a-z
         (char == 0x20) || //SP
         (char == 0x23) || // #
         (char == 0x28) || // (
         (char == 0x29) || // )
         (char == 0x2C) || //,
         (char == 0x2D) || //-
         (char == 0x2E) // .
        )) {
          return false;
      }
    }
    return true;
  }

  function sanitizeJason(string memory _str) external override pure returns(bytes memory) {
    bytes memory src = bytes(_str);
    bytes memory res;
    uint i;
    for (i=0; i<src.length; i++) {
      uint8 b = uint8(src[i]);
      // Skip control codes, escape backslash and double-quote
      if (b >= 0x20) {
        if  (b == 0x5c || b == 0x22) {
          res = abi.encodePacked(res, bytes1(0x5c));
        }
        res = abi.encodePacked(res, b);
      }
    }
    return res;
  }  
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IStringValidator {
  function validate(bytes memory str) external pure returns (bool);
  function sanitizeJason(string memory _str) external pure returns(bytes memory);
}