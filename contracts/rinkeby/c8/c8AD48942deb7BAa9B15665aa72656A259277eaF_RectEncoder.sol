// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {Array} from "../utils/Array.sol";

error CoordinatesOutOfRange(uint256 coordinate);

struct Rect {
    uint32 x;
    uint32 y;
    uint32 width;
    uint32 height;
    uint32 fillIndex;
}

struct Trait {
    Rect[] rects;
    string name;
}

struct TraitEncoded {
    bytes rects;
    string name;
}

struct Characteristic {
    Trait[] traits;
    string name;
}

struct CharacteristicEncoded {
    bytes traits;
    string[] names;
    string name;
}

struct Collection {
    Characteristic[] characteristics;
    string description;
}

struct CollectionEncoded {
    bytes names;
    bytes traits;
}

/**  @title RectEncoder
 *
 *   This library can be used (off-chain !) to encode a collection to be deployed and render on-chain images with the
 *   RectRenderer.
 *
 * @author Clement Walter <[email protected]>
 */
contract RectEncoder {
    using Array for string[];
    using Array for bytes[];
    using Array for uint16[];
    using Array for bytes4[];

    /** @dev Use this function to encode a single <rect> as expected by the renderer. Use this off-chain!
     *
     * @param rect The <rect> to encode
     * @return The encoded rectangle as a bytes4
     */
    function encodeRect(Rect memory rect) public pure returns (bytes4) {
        // each coordinates should use only 6 bits and is consequently stored like 00nnnnnn
        if (rect.x > 63) revert CoordinatesOutOfRange(rect.x);
        if (rect.y > 63) revert CoordinatesOutOfRange(rect.y);
        if (rect.width > 63) revert CoordinatesOutOfRange(rect.width);
        if (rect.height > 63) revert CoordinatesOutOfRange(rect.height);
        return
            bytes4(rect.x << 26) |
            bytes4(rect.y << 20) |
            bytes4(rect.width << 14) |
            bytes4(rect.height << 8) |
            bytes4(rect.fillIndex);
    }

    /** @dev Use this function to encode a _trait_, i.e. a list of <rect>s with a name, as expected by the renderer.
     *       Use this off-chain!
     *
     * @param trait The list of <rect>s to encode with a given name; should be shorter than 32 char.
     * @return The encoded list of rectangle
     */
    function encodeTrait(Trait memory trait)
        public
        pure
        returns (TraitEncoded memory)
    {
        bytes4[] memory rects = new bytes4[](trait.rects.length);
        for (uint256 i = 0; i < trait.rects.length; i++) {
            rects[i] = encodeRect(trait.rects[i]);
        }
        return TraitEncoded(rects.join(), trait.name);
    }

    /** @dev Use this function to encode a characteristic, i.e. a list of traits belongings to the same group. Note that
     *       there is no intrinsic difference between a characteristic and a whole collection (all the traits of all the
     *       characteristics) but it's how it's used and expected today so we keep the wording here.
     *       Use this off-chain and push the result using RendererCommon.storeBytes
     *  @param characteristic The list of Trait constituting the characteristic.
     *  @return The encoded characteristic (mainly a bytes memory whose encoding somehow follows solidity memory storage rules.)
     */
    function encodeCharacteristic(Characteristic memory characteristic)
        public
        pure
        returns (CharacteristicEncoded memory)
    {
        bytes[] memory rects = new bytes[](characteristic.traits.length);
        string[] memory names = new string[](characteristic.traits.length);
        uint16[] memory lengths = new uint16[](
            characteristic.traits.length + 1
        );
        uint16 cumSum = 4 +
            2 *
            uint16(characteristic.traits.length % type(uint16).max); // 2 extra bytes for storing start & end for each trait
        for (uint256 i = 0; i < characteristic.traits.length; i++) {
            TraitEncoded memory tmp = encodeTrait(characteristic.traits[i]);
            rects[i] = tmp.rects;
            names[i] = tmp.name;
            lengths[i] = cumSum;
            cumSum += uint16(rects[i].length % type(uint16).max);
        }
        lengths[characteristic.traits.length] = cumSum;
        return (
            CharacteristicEncoded(
                bytes.concat(
                    bytes2(
                        uint16(
                            (characteristic.traits.length + 1) %
                                type(uint16).max
                        )
                    ),
                    lengths.join(),
                    rects.join()
                ),
                names,
                characteristic.name
            )
        );
    }

    /** @dev Use this function to encode a full collection, i.e. a list of characteristics.
     *       Use this off-chain and push the result using RendererCommon.storeBytes
     *
     * @param collection The list of Characteristic constituting the collection. The description is just returned in the
     *        new object and can be used to store the description of the collection.
     * @return The encoded collection (mainly a bytes memory whose encoding somehow follows solidity memory storage rules.)
     */
    function encodeCollection(Collection memory collection)
        public
        pure
        returns (CollectionEncoded memory)
    {
        bytes[] memory traits = new bytes[](collection.characteristics.length);
        string[] memory characteristicNames = new string[](
            collection.characteristics.length
        );
        string[][] memory traitNames = new string[][](
            collection.characteristics.length
        );
        uint16[] memory lengths = new uint16[](
            collection.characteristics.length
        );
        // init characteristic pointer shift with 2 bytes for length + 2 bytes per characteristic
        uint16 cumSum = 2 +
            2 *
            uint16(collection.characteristics.length % type(uint16).max);
        for (uint256 i = 0; i < collection.characteristics.length; i++) {
            CharacteristicEncoded memory tmp = encodeCharacteristic(
                collection.characteristics[i]
            );
            lengths[i] = cumSum;
            traits[i] = tmp.traits;
            traitNames[i] = tmp.names;
            characteristicNames[i] = tmp.name;
            cumSum += uint16(traits[i].length % type(uint16).max);
        }
        return (
            CollectionEncoded(
                abi.encode(
                    collection.description,
                    characteristicNames,
                    traitNames
                ),
                bytes.concat(
                    bytes2(
                        uint16(
                            collection.characteristics.length % type(uint16).max
                        )
                    ),
                    lengths.join(),
                    traits.join()
                )
            )
        );
    }
}

// SPDX-License-Identifier: MIT

/*
 * @title Arrays Utils
 * @author Clement Walter <[email protected]>
 *
 * @notice An attempt at implementing some of the widely used javascript's Array functions in solidity.
 */
pragma solidity ^0.8.12;

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