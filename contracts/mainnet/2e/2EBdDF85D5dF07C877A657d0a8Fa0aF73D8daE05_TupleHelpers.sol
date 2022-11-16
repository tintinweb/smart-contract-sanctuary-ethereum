// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**
  * @notice Helper contract to extract a variety of types from a tuple within the context of a weiroll script
  */
contract TupleHelpers {

    /**
      * @notice Extract a bytes32 encoded static type from a tuple
      * @dev Use with .rawValue() in the weiroll planner
      * @param tuple The bytes encoded tuple
      * @param index The index of the value to be extracted
      */
    function extractElement(bytes memory tuple, uint256 index) public pure returns (bytes32) {
        assembly {
            // let offset := mul(add(index, 1), 32)
            // return(add(tuple, offset), 32)
            return(add(tuple, mul(add(index, 1), 32)), 32)
        }
    }

    /**
      * @notice Extract a bytes encoded dynamic type from a tuple
      * @dev Use with .rawValue() in the weiroll planner
      * @param tuple The bytes encoded tuple
      * @param index The index of the string or bytes to be extracted
      */
    function extractDynamicElement(bytes memory tuple, uint256 index) public pure returns (bytes32) {
        assembly {
            let offset := add(mload(add(tuple, mul(add(index, 1), 32))), 32)
            let length := mload(add(tuple, offset))
            if gt(mod(length, 32), 0) {
              length := mul(add(div(length, 32), 1), 32)
            }
            return(add(tuple, add(offset, 32)), length)
        }
    }

    /**
      * @notice Extract a bytes encoded tuple from another tuple
      * @dev Use with .rawValue() in the weiroll planner
      * @param tuple The bytes encoded parent tuple
      * @param index The index of the tuple to be extracted
      * @param isDynamicTypeFormat Boolean to define whether the child tuple is dynamically sized. If the child tuple contains bytes or string variables, set to "true"
      */
    function extractTuple(
        bytes memory tuple,
        uint256 index,
        bool[] memory isDynamicTypeFormat
    ) public pure returns (bytes32) {
        uint256 offset;
        uint256 length;
        assembly {
            offset := add(mload(add(tuple, mul(add(index, 1), 32))), 32)
        }
        for (uint256 i = 0; i < isDynamicTypeFormat.length; i++) {
            length += 32;
            if (isDynamicTypeFormat[i]) {
                assembly {
                    let paramOffset := add(offset, mload(add(tuple, add(offset, mul(i, 32)))))
                    let paramLength := add(mload(add(tuple, paramOffset)), 32)
                    if gt(mod(paramLength, 32), 0) {
                      paramLength := mul(add(div(paramLength, 32), 1), 32)
                    }
                    length := add(length, paramLength)
                }
            }
        }
        assembly {
            return(add(tuple, add(mload(add(tuple, mul(add(index, 1), 32))), 32)), length)
        }
    }

    /**
      * @notice Extract a bytes encoded static array from a tuple
      * @dev Use with .rawValue() in the weiroll planner
      * @param tuple The bytes encoded array
      * @param index The index of the array to be extracted
      */
    function extractArray(bytes memory tuple, uint256 index) public pure returns (bytes32) {
        assembly {
            // let offset := add(mload(add(tuple, mul(add(index, 1), 32))), 32)
            // let numberOfElements := mload(add(tuple, offset))
            // return(add(tuple, add(offset, 32)), mul(numberOfElements, 32))
            return(add(tuple, add(add(mload(add(tuple, mul(add(index, 1), 32))), 32), 32)), mul(mload(add(tuple, add(mload(add(tuple, mul(add(index, 1), 32))), 32))), 32))
        }
    }

    /**
      * @notice Extract a bytes encoded dynamic array from a tuple
      * @dev Use with .rawValue() in the weiroll planner
      * @param tuple The bytes encoded tuple
      * @param index The index of the dynamic array to be extracted
      */
    function extractDynamicArray(bytes memory tuple, uint256 index) public pure returns (bytes32) {
        uint256 numberOfElements;
        uint256 offset;
        assembly {
            offset := add(mload(add(tuple, mul(add(index, 1), 32))), 32)
            numberOfElements := mload(add(tuple, offset))
            //numberOfElements := mload(add(tuple, add(mload(add(tuple, mul(add(index, 1), 32))), 32)))
        }

        uint256 length;
        for (uint256 i = 1; i <= numberOfElements; i++) {
            assembly {
                let paramOffset := add(offset, mul(add(i, 1), 32))
                let paramLength := mload(add(tuple, paramOffset))
                if gt(mod(paramLength, 32), 0) {
                  paramLength := mul(add(div(paramLength, 32), 1), 32)
                }
                length := add(length, paramLength)
                //length := add(length, mload(add(tuple, add(add(mload(add(tuple, mul(add(index, 1), 32))), 32), mul(add(i, 1), 32)))))
            }
        }
        assembly {
            // return(add(tuple, add(offset, 32)), add(length, 32))
            return(add(tuple, add(add(mload(add(tuple, mul(add(index, 1), 32))), 32), 32)), add(length, 32))
        }
    }

    /**
      * @notice Extract a bytes encoded array of tuples from a tuple
      * @dev Use with .rawValue() in the weiroll planner
      * @param tuple The bytes encoded tuple
      * @param index The index of the tuple array to be extracted
      * @param isDynamicTypeFormat Boolean to define whether the tuples in the array are dynamically sized. If the array tuple contains bytes or string variables, set to "true"
      */
    function extractTupleArray(
        bytes memory tuple,
        uint256 index,
        bool[] memory isDynamicTypeFormat
    ) public pure returns (bytes32) {
        uint256 numberOfElements;
        assembly {
            // let offset := add(mload(add(tuple, mul(add(index, 1), 32))), 32)
            // numberOfElements := mload(add(tuple, offset))
            numberOfElements := mload(add(tuple, add(mload(add(tuple, mul(add(index, 1), 32))), 32)))
        }
        uint256 length = numberOfElements * 32;
        for (uint256 i = 1; i <= numberOfElements; i++) {
            for (uint256 j = 0; j < isDynamicTypeFormat.length; j++) {
                length += 32;
                if (isDynamicTypeFormat[j]) {
                    assembly {
                        // let tupleOffset := add(offset,mload(add(tuple, add(offset, mul(i, 32)))))
                        // let paramOffset := add(tupleOffset, mload(add(tuple, add(tupleOffset, mul(add(j,1), 32)))))
                        // let paramLength := add(mload(add(tuple, paramOffset)),32)
                        // length := add(length, paramLength)
                        length := add(length, add(mload(add(tuple, add(add(add(mload(add(tuple, mul(add(index, 1), 32))), 32),mload(add(tuple, add(add(mload(add(tuple, mul(add(index, 1), 32))), 32), mul(i, 32))))), mload(add(tuple, add(add(add(mload(add(tuple, mul(add(index, 1), 32))), 32),mload(add(tuple, add(add(mload(add(tuple, mul(add(index, 1), 32))), 32), mul(i, 32))))), mul(add(j,1), 32))))))),32))
                    }
                }
            }
        }
        assembly {
            // return(add(tuple, add(offset,32)), length)
            return(add(tuple, add(add(mload(add(tuple, mul(add(index, 1), 32))), 32),32)), length)
        }
    }
}