/**
 *Submitted for verification at Etherscan.io on 2022-11-09
*/

// File: gat2.sol


pragma solidity 0.8.17;

    contract Meraz { 
    
    bytes32 private constant length = keccak256("mystoragelocation");
    bytes32 private constant data = keccak256(abi.encodePacked(length));

    function storeString(string memory _string) public {
        bytes32 _length = length;
        bytes32 _data = data;

        assembly {
            let stringLength := mload(_string)

            switch gt(stringLength, 0x1F)

            // If string length <= 31 we store a short array
            // length storage variable layout : 
            // bytes 0 - 31 : string data
            // byte 32 : length * 2
            // data storage variable is UNUSED in this case
            case 0x00 {
                sstore(_length, or(mload(add(_string, 0x20)), mul(stringLength, 2)))
            }

            // If string length > 31 we store a long array
            // length storage variable layout :
            // bytes 0 - 32 : length * 2 + 1
            // data storage layout :
            // bytes 0 - 32 : string data
            // If more than 32 bytes are required for the string we write them
            // to the slot(s) following the slot of the data storage variable
            case 0x01 {
                 // Store length * 2 + 1 at slot length
                sstore(_length, add(mul(stringLength, 2), 1))

                // Then store the string content by blocks of 32 bytes
                for {let i:= 0} lt(mul(i, 0x20), stringLength) {i := add(i, 0x01)} {
                    sstore(add(_data, i), mload(add(_string, mul(add(i, 1), 0x20))))
                }
            }
        }

    }

    function getURL() public view returns (string memory returnURL) {
        bytes32 _length = length;
        bytes32 _data = data;

        assembly {
            let stringLength := sload(_length)

            // Check if what type of array we are dealing with
            // The return array will need to be taken from STORAGE
            // respecting the STORAGE layout of string, but rebuilt
            // in MEMORY according to the MEMORY layout of string.
            switch and(stringLength, 0x01)

            // Short array
            case 0x00 {
                let decodedStringLength := div(and(stringLength, 0xFF), 2)

                // Add length in first 32 byte slot 
                mstore(returnURL, decodedStringLength)
                mstore(add(returnURL, 0x20), and(stringLength, not(0xFF)))
                mstore(0x40, add(returnURL, 0x40))
            }

            // Long array
            case 0x01 {
                let decodedStringLength := div(stringLength, 2)
                let i := 0

                mstore(returnURL, decodedStringLength)
                
                // Write to memory as many blocks of 32 bytes as necessary taken from data storage variable slot + i
                for {} lt(mul(i, 0x20), decodedStringLength) {i := add(i, 0x01)} {
                    mstore(add(add(returnURL, 0x20), mul(i, 0x20)), sload(add(_data, i)))
                }

                mstore(0x40, add(returnURL, add(0x20, mul(i, 0x20))))
            }
        }
    }
}