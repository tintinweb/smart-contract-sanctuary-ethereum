// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@0xsequence/sstore2/contracts/SSTORE2.sol";

import {Integers} from "../utils/Integers.sol";
import {Array} from "../utils/Array.sol";

struct Attribute {
    string trait_type;
    string value;
}

struct TokenData {
    string image;
    string description;
    string name;
    Attribute[] attributes;
}

/**  @title BaseRenderer
 *
 *   This library contains shared functionality and constants for the renderers.
 *
 * @author Clement Walter <[email protected]>
 */
library RendererCommons {
    using Integers for uint256;
    using Integers for uint8;
    using Array for string[];

    string public constant DATA_URI = "data:image/svg+xml,";
    string public constant XMLNS_HEADER =
        "xmlns=%27http://www.w3.org/2000/svg%27";
    string public constant SPACE = "%20";
    string public constant QUOTE = "%27";
    string public constant NUMBER_SIGN = "%23";
    string public constant TAG_START = "%3c";
    string public constant TAG_END = "/%3e";

    event BytesStored(address pointer);

    /**
     * @dev Usually colors are already defined in hex color space so we just concat all the colors. No check is made
     *      and this function only concatenates the input colors.
     * @param palette The list of colors as hex strings, without the leading #.
     * @return The concatenated colors as string. To be used as bytes afterwards.
     */
    function encodePalette(string[] memory palette)
        public
        pure
        returns (string memory)
    {
        return string.concat("0x", palette.join());
    }

    /** @dev Returns one single color reading directly from the storage.
     * @param pointer The pointer to the palette bytes array where each color is R, G, B at storage i, i+1, i+2.
     * @param index The index of the color to retrieve
     * @return The hexstring representation of the color, e.g. "a3120f".
     */
    function getFill(address pointer, uint256 index)
        public
        view
        returns (string memory)
    {
        bytes memory palette = SSTORE2.read(pointer, 3 * index, 3 * index + 3);

        return
            string.concat(
                uint8(palette[0]).toString(16, 2),
                uint8(palette[1]).toString(16, 2),
                uint8(palette[2]).toString(16, 2)
            );
    }

    /** @dev Returns one single color from a pre-loaded whole palette as a bytes array.
     * @param palette A bytes array encoding several RGB colors. Length should be a multiple of 3.
     * @param index The index of the color to retrieve
     * @return The hexstring representation of the color, e.g. "a3120f".
     */
    function getFill(bytes memory palette, uint256 index)
        public
        pure
        returns (string memory)
    {
        return
            string.concat(
                uint8(palette[3 * index]).toString(16, 2),
                uint8(palette[3 * index + 1]).toString(16, 2),
                uint8(palette[3 * index + 2]).toString(16, 2)
            );
    }

    /** @dev Decode the whole palette once for all and returns an array of hexstrings.
     * @param pointer The pointer to the palette bytes array where each color is at storage at i, i+1, i+2.
     * @return An array of hexstring representation of the color, e.g. "a3120f".
     */
    function getPalette(address pointer) public view returns (string[] memory) {
        bytes memory palette = SSTORE2.read(pointer);
        return getPalette(palette);
    }

    function getPalette(bytes memory palette)
        public
        pure
        returns (string[] memory)
    {
        uint256 paletteSize = palette.length / 3;
        string[] memory paletteHex = new string[](paletteSize);
        for (uint256 i = 0; i < paletteSize; i++) {
            paletteHex[i] = getFill(palette, i);
        }
        return paletteHex;
    }

    /** @dev Retrieve the names encoded with the collection: description, characteristics and traits names array.
     * @param names The bytes the names encoded by the RectEncoder.
     */
    function decodeNames(bytes memory names)
        public
        pure
        returns (
            string memory description,
            string[] memory characteristicNames,
            string[][] memory traitNames
        )
    {
        return abi.decode(names, (string, string[], string[][]));
    }

    /** @dev Retrieve the names encoded with the collection: description, characteristics and traits names array.
     * @param pointer The address of the SSTORE2 contract for the names.
     */
    function decodeNames(address pointer)
        public
        view
        returns (
            string memory description,
            string[] memory characteristicNames,
            string[][] memory traitNames
        )
    {
        return decodeNames(SSTORE2.read(pointer));
    }


    /** @dev This is just a direct call to abi.encode to insure standard encoding scheme for the names across renders.
     * @param description The description of the collection.
     * @param characteristicNames The names of the characteristics.
     * @param traitNames The names of the traits.
     * @return The encoded bytes.
     */
    function encodeNames(string memory description, string[] memory characteristicNames, string[][] memory traitNames)
        public
        pure
        returns (bytes memory)
    {
        return abi.encode(
            description, characteristicNames, traitNames
        );
    }

    function tokenData(address pointer, uint256[] memory items)
        public
        view
        returns (TokenData memory)
    {
        (
            string memory description,
            string[] memory characteristicNames,
            string[][] memory traitNames
        ) = decodeNames(SSTORE2.read(pointer));
        Attribute[] memory attributes = new Attribute[](items.length);
        for (uint256 i = 0; i < items.length; i++) {
            attributes[i] = Attribute(
                characteristicNames[i],
                traitNames[i][items[i]]
            );
        }
        return TokenData("", description, "", attributes);
    }

    function tokenURI(address pointer, uint256[] memory items) public view returns (string memory) {
        TokenData memory _tokenData = tokenData(pointer, items);
        string[] memory attributes = new string[](_tokenData.attributes.length);
        for (uint256 i = 0; i < _tokenData.attributes.length; i++) {
            attributes[i] = string.concat(
                '{"trait_type": "',
                _tokenData.attributes[i].trait_type,
                '", "value": "',
                _tokenData.attributes[i].value,
                '"}'
            );
        }
        return
            string.concat(
                "data:application/json,",
                '{"image": "',
                _tokenData.image,
                '"',
                ',"description": "',
                _tokenData.description,
                '"',
                ',"name": "',
                _tokenData.name,
                '"',
                ',"attributes": ',
                "[",
                attributes.join(","),
                "]",
                "}"
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./utils/Bytecode.sol";

/**
  @title A key-value storage with auto-generated keys for storing chunks of data with a lower write & read cost.
  @author Agustin Aguilar <[email protected]>

  Readme: https://github.com/0xsequence/sstore2#readme
*/
library SSTORE2 {
  error WriteError();

  /**
    @notice Stores `_data` and returns `pointer` as key for later retrieval
    @dev The pointer is a contract address with `_data` as code
    @param _data to be written
    @return pointer Pointer to the written `_data`
  */
  function write(bytes memory _data) internal returns (address pointer) {
    // Append 00 to _data so contract can't be called
    // Build init code
    bytes memory code = Bytecode.creationCodeFor(
      abi.encodePacked(
        hex'00',
        _data
      )
    );

    // Deploy contract using create
    assembly { pointer := create(0, add(code, 32), mload(code)) }

    // Address MUST be non-zero
    if (pointer == address(0)) revert WriteError();
  }

  /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @return data read from `_pointer` contract
  */
  function read(address _pointer) internal view returns (bytes memory) {
    return Bytecode.codeAt(_pointer, 1, type(uint256).max);
  }

  /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @param _start number of bytes to skip
    @return data read from `_pointer` contract
  */
  function read(address _pointer, uint256 _start) internal view returns (bytes memory) {
    return Bytecode.codeAt(_pointer, _start + 1, type(uint256).max);
  }

  /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @param _start number of bytes to skip
    @param _end index before which to end extraction
    @return data read from `_pointer` contract
  */
  function read(address _pointer, uint256 _start, uint256 _end) internal view returns (bytes memory) {
    return Bytecode.codeAt(_pointer, _start + 1, _end + 1);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * Integers Library updated from https://github.com/willitscale/solidity-util
 *
 * In summary this is a simple library of integer functions which allow a simple
 * conversion to and from strings
 *
 * @author Clement Walter <[email protected]>
 */
library Integers {
    /**
     * To String
     *
     * Converts an unsigned integer to the string equivalent value, returned as bytes
     * Equivalent to javascript's toString(base)
     *
     * @param _number The unsigned integer to be converted to a string
     * @param _base The base to convert the number to
     * @param  _padding The target length of the string; result will be padded with 0 to reach this length while padding
     *         of 0 means no padding
     * @return bytes The resulting ASCII string value
     */
    function toString(
        uint256 _number,
        uint8 _base,
        uint8 _padding
    ) public pure returns (string memory) {
        uint256 count = 0;
        uint256 b = _number;
        while (b != 0) {
            count++;
            b /= _base;
        }
        if (_number == 0) {
            count++;
        }
        bytes memory res;
        if (_padding == 0) {
            res = new bytes(count);
        } else {
            res = new bytes(_padding);
        }
        for (uint256 i = 0; i < res.length; ++i) {
            b = _number % _base;
            if (b < 10) {
                res[res.length - i - 1] = bytes1(uint8(b + 48)); // 0-9
            } else {
                res[res.length - i - 1] = bytes1(uint8((b % 10) + 65)); // A-F
            }
            _number /= _base;
        }

        for (uint256 i = count; i < _padding; ++i) {
            res[res.length - i - 1] = hex"30"; // 0
        }

        return string(res);
    }

    function toString(uint256 _number) public pure returns (string memory) {
        return toString(_number, 10, 0);
    }

    function toString(uint256 _number, uint8 _base)
        public
        pure
        returns (string memory)
    {
        return toString(_number, _base, 0);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


library Bytecode {
  error InvalidCodeAtRange(uint256 _size, uint256 _start, uint256 _end);

  /**
    @notice Generate a creation code that results on a contract with `_code` as bytecode
    @param _code The returning value of the resulting `creationCode`
    @return creationCode (constructor) for new contract
  */
  function creationCodeFor(bytes memory _code) internal pure returns (bytes memory) {
    /*
      0x00    0x63         0x63XXXXXX  PUSH4 _code.length  size
      0x01    0x80         0x80        DUP1                size size
      0x02    0x60         0x600e      PUSH1 14            14 size size
      0x03    0x60         0x6000      PUSH1 00            0 14 size size
      0x04    0x39         0x39        CODECOPY            size
      0x05    0x60         0x6000      PUSH1 00            0 size
      0x06    0xf3         0xf3        RETURN
      <CODE>
    */

    return abi.encodePacked(
      hex"63",
      uint32(_code.length),
      hex"80_60_0E_60_00_39_60_00_F3",
      _code
    );
  }

  /**
    @notice Returns the size of the code on a given address
    @param _addr Address that may or may not contain code
    @return size of the code on the given `_addr`
  */
  function codeSize(address _addr) internal view returns (uint256 size) {
    assembly { size := extcodesize(_addr) }
  }

  /**
    @notice Returns the code of a given address
    @dev It will fail if `_end < _start`
    @param _addr Address that may or may not contain code
    @param _start number of bytes of code to skip on read
    @param _end index before which to end extraction
    @return oCode read from `_addr` deployed bytecode

    Forked from: https://gist.github.com/KardanovIR/fe98661df9338c842b4a30306d507fbd
  */
  function codeAt(address _addr, uint256 _start, uint256 _end) internal view returns (bytes memory oCode) {
    uint256 csize = codeSize(_addr);
    if (csize == 0) return bytes("");

    if (_start > csize) return bytes("");
    if (_end < _start) revert InvalidCodeAtRange(csize, _start, _end); 

    unchecked {
      uint256 reqSize = _end - _start;
      uint256 maxSize = csize - _start;

      uint256 size = maxSize < reqSize ? maxSize : reqSize;

      assembly {
        // allocate output byte array - this could also be done without assembly
        // by using o_code = new bytes(size)
        oCode := mload(0x40)
        // new "memory end" including padding
        mstore(0x40, add(oCode, and(add(add(size, 0x20), 0x1f), not(0x1f))))
        // store length in memory
        mstore(oCode, size)
        // actually retrieve the code, this needs assembly
        extcodecopy(_addr, add(oCode, 0x20), _start, size)
      }
    }
  }
}