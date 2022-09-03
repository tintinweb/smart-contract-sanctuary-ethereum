// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract TupleHelper {
    function insertElement(bytes calldata tuple, uint256 index, bytes32 element, bool returnRaw)
        public
        pure
        returns (bytes memory newTuple)
    {
        uint256 byteIndex;
        unchecked { byteIndex = index * 32; }
        require(byteIndex <= tuple.length);
        newTuple = bytes.concat(tuple[:byteIndex], element, tuple[byteIndex:]);
        if (returnRaw) {
            assembly {
                return(add(newTuple, 32), tuple.length)
            }
        }
    }

    function replaceElement(bytes calldata tuple, uint256 index, bytes32 element, bool returnRaw)
        public
        pure
        returns (bytes memory newTuple)
    {
        uint256 byteIndex;
        unchecked {
            byteIndex = index * 32;
            require(tuple.length >= 32 && byteIndex <= tuple.length - 32);
            newTuple = bytes.concat(tuple[:byteIndex], element, tuple[byteIndex+32:]);
        }
        if (returnRaw) {
            assembly {
                return(add(newTuple, 32), tuple.length)
            }
        }
    }

    function getElement(bytes memory tuple, uint256 index)
        public
        pure
        returns (bytes32)
    {
        assembly {
            return(add(tuple, mul(add(index, 1), 32)), 32)
        }
    }
}