/**
 *Submitted for verification at Etherscan.io on 2022-09-08
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract Box {
    uint private _value;

    event NewValue(uint newValue);

    function store(uint newValue) public {
        bytes32 eventHash = bytes32(keccak256("NewValue(uint256)"));

        assembly {
            // We use the sstore opcode to update the storage
            // We specify which slot do we want to update and the new value
            sstore(0, newValue)

            // To emit an event we first need to store the value in memory.
            mstore(0x80, newValue)
            // Now to emit the event we use the log1 opcode. First arg is the memory address,
            // second is the number of bytes and the third is the hashed event signature
            log1(0x80, 32, eventHash)
        }
    }

    function retrieve() public view returns (uint) {
        assembly {
            // We first declare a variable called value and load the value
            // from the first slot
            let value := sload(0)

            // The value is now stored on the stack so if we want to
            // return it we have to store it in memory.
            // We use the mstore opcode and we store the value at 0x80 address
            mstore(0x80, value)

            // Now we can just return the value. We first specify the memory location
            // and then the number of bytes we want to return
            return(0x80, 32)
        }
    }
}