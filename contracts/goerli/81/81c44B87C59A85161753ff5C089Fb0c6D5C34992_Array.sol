// SPDX-License-Identifier: MIT

/*
 * @title Arrays Utils
 * @author Clement Walter <[email protected]>
 * Source: https://github.com/ClementWalter/eth-projects-monorepo/blob/main/packages/eth-projects-contracts/contracts/lib/utils/Array.sol
 *
 * @notice An attempt at implementing some of the widely used javascript's Array functions in solidity.
 */
pragma solidity ^0.8.6;

error EmptyArray();
error GlueOutOfBounds(uint256 length);

library Array {
    function join(string[] memory a, string memory glue)
        public
        pure
        returns (string memory)
    {
        uint256 inputPointer;
        uint256 gluePointer;

        assembly {
            inputPointer := a
            gluePointer := glue
        }
        return string(_joinReferenceType(inputPointer, gluePointer));
    }

    function join(string[] memory a) public pure returns (string memory) {
        return join(a, "");
    }

    function join(bytes[] memory a, bytes memory glue)
        public
        pure
        returns (bytes memory)
    {
        uint256 inputPointer;
        uint256 gluePointer;

        assembly {
            inputPointer := a
            gluePointer := glue
        }
        return _joinReferenceType(inputPointer, gluePointer);
    }

    function join(bytes[] memory a) public pure returns (bytes memory) {
        return join(a, bytes(""));
    }

    function join(bytes2[] memory a) public pure returns (bytes memory) {
        uint256 pointer;

        assembly {
            pointer := a
        }
        return _joinValueType(pointer, 2, 0);
    }

    /// @dev Join the underlying array of bytes2 to a string.
    function join(uint16[] memory a) public pure returns (bytes memory) {
        uint256 pointer;

        assembly {
            pointer := a
        }
        return _joinValueType(pointer, 2, 256 - 16);
    }

    function join(bytes3[] memory a) public pure returns (bytes memory) {
        uint256 pointer;

        assembly {
            pointer := a
        }
        return _joinValueType(pointer, 3, 0);
    }

    function join(bytes4[] memory a) public pure returns (bytes memory) {
        uint256 pointer;

        assembly {
            pointer := a
        }
        return _joinValueType(pointer, 4, 0);
    }

    function join(bytes8[] memory a) public pure returns (bytes memory) {
        uint256 pointer;

        assembly {
            pointer := a
        }
        return _joinValueType(pointer, 8, 0);
    }

    function join(bytes16[] memory a) public pure returns (bytes memory) {
        uint256 pointer;

        assembly {
            pointer := a
        }
        return _joinValueType(pointer, 16, 0);
    }

    function join(bytes32[] memory a) public pure returns (bytes memory) {
        uint256 pointer;

        assembly {
            pointer := a
        }
        return _joinValueType(pointer, 32, 0);
    }

    function _joinValueType(
        uint256 a,
        uint256 typeLength,
        uint256 shiftLeft
    ) private pure returns (bytes memory) {
        bytes memory tempBytes;

        assembly {
            let inputLength := mload(a)
            let inputData := add(a, 0x20)
            let end := add(inputData, mul(inputLength, 0x20))

            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Initialize the length of the final bytes: length is typeLength x inputLength (array of bytes4)
            mstore(tempBytes, mul(inputLength, typeLength))
            let memoryPointer := add(tempBytes, 0x20)

            // Iterate over all bytes4
            for {
                let pointer := inputData
            } lt(pointer, end) {
                pointer := add(pointer, 0x20)
            } {
                let currentSlot := shl(shiftLeft, mload(pointer))
                mstore(memoryPointer, currentSlot)
                memoryPointer := add(memoryPointer, typeLength)
            }

            mstore(0x40, and(add(memoryPointer, 31), not(31)))
        }
        return tempBytes;
    }

    function _joinReferenceType(uint256 inputPointer, uint256 gluePointer)
        public
        pure
        returns (bytes memory tempBytes)
    {
        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Skip the first 32 bytes where we will store the length of the result
            let memoryPointer := add(tempBytes, 0x20)

            // Load glue
            let glueLength := mload(gluePointer)
            if gt(glueLength, 0x20) {
                revert(gluePointer, 0x20)
            }
            let glue := mload(add(gluePointer, 0x20))

            // Load the length (first 32 bytes)
            let inputLength := mload(inputPointer)
            let inputData := add(inputPointer, 0x20)
            let end := add(inputData, mul(inputLength, 0x20))

            // Initialize the length of the final string
            let stringLength := 0

            // Iterate over all strings (a string is itself an array).
            for {
                let pointer := inputData
            } lt(pointer, end) {
                pointer := add(pointer, 0x20)
            } {
                let currentStringArray := mload(pointer)
                let currentStringLength := mload(currentStringArray)
                stringLength := add(stringLength, currentStringLength)
                let currentStringBytesCount := add(
                    div(currentStringLength, 0x20),
                    gt(mod(currentStringLength, 0x20), 0)
                )

                let currentPointer := add(currentStringArray, 0x20)

                for {
                    let copiedBytesCount := 0
                } lt(copiedBytesCount, currentStringBytesCount) {
                    copiedBytesCount := add(copiedBytesCount, 1)
                } {
                    mstore(
                        add(memoryPointer, mul(copiedBytesCount, 0x20)),
                        mload(currentPointer)
                    )
                    currentPointer := add(currentPointer, 0x20)
                }
                memoryPointer := add(memoryPointer, currentStringLength)
                mstore(memoryPointer, glue)
                memoryPointer := add(memoryPointer, glueLength)
            }

            mstore(
                tempBytes,
                add(stringLength, mul(sub(inputLength, 1), glueLength))
            )
            mstore(0x40, and(add(memoryPointer, 31), not(31)))
        }
        return tempBytes;
    }
}