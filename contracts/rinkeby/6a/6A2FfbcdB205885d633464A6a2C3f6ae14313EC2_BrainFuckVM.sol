// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library BrainFuckVM {
  uint constant public TAPE_SIZE = 3_000_000; 
  uint constant public LOOPING_STACK_SIZE = 8192;

  function run(bytes calldata code, bytes calldata input) public pure returns (bytes memory out) {
    out = "";
    bytes memory tape = new bytes(TAPE_SIZE);
    
    uint readIndex = 0;
    uint ptr = 0;
    bool isLooping = false;
    uint innerLoops = 0;
    // technically a max of 4096 nested loops
    uint[] memory loopingStack = new uint[](LOOPING_STACK_SIZE);
    uint loopingStackIndex = 0;

    for (uint i = 0; i < code.length; ++i) {
      bytes1 opcode = code[i];
      if (isLooping) {
        // [
        if (opcode == 0x5B) {
          innerLoops++; 
        }
        // ]
        if(opcode == 0x5D) {
          if(innerLoops == 0) isLooping = false;
          else innerLoops--;
        }
      } else {
        // +
        if (opcode == 0x2B) {
          tape[ptr] = tape[ptr] == bytes1(0xFF) ? bytes1(0x00) : bytes1(uint8(tape[ptr]) + 1);
        }
        // -
        if (opcode == 0x2D) {
          tape[ptr] = tape[ptr] == bytes1(0x00) ? bytes1(0xFF) : bytes1(uint8(tape[ptr]) - 1);
        }
        // ,
        if (opcode == 0x2C) {
          tape[ptr] = readIndex < input.length ? input[readIndex] : bytes1(0);
          readIndex++;
        }
        // .
        if (opcode == 0x2E) {
          out = abi.encodePacked(out, tape[ptr]);
        }
        // !
        if (opcode == 0x21) {
          ptr = 0;
        }
        // >
        if (opcode == 0x3E) {
          ptr++;
        }
        // <
        if (opcode == 0x3C) {
          ptr--;
        }
        // [
        if (opcode == 0x5B) {
          if (tape[ptr] == 0x0) {
            isLooping = true;
          } else {
            loopingStack[loopingStackIndex] = i;
            loopingStackIndex++;
          }
        }
        // ]
        if (opcode == 0x5D) {
         if (tape[ptr] != 0x00) {
            i = loopingStack[loopingStackIndex - 1];
          } else {
            loopingStack[loopingStackIndex--] = 0;
          }
        }
      }
    }
  } 
}