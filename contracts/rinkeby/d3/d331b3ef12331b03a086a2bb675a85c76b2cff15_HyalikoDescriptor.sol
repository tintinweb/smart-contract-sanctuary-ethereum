// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {Base64} from "./base64.sol";
import {BytesLib} from "./bytes.sol";

/*********************************
 * ░░░░░░░░░░███████████░░░░░░░░░░ *
 * ░░░░░░████░░░░░░░░░░░████░░░░░░ *
 * ░░░░██░░░░░░░░░░░░░░░░░░░██░░░░ *
 * ░░██░░░░░░░░░░░░░░░░░░░░░░░██░░ *
 * ░░██░░░░░████░░░░░████░░░░░██░░ *
 * ██░░░░░░██░░██░░░██░░██░░░░░░██ *
 * ██░░░░░░██░░██░░░██░░██░░░░░░██ *
 * ██░░░░░░░░░░░░░░░░░░░░░░░░░░░██ *
 * ░░██░░░░░░░░░░░░░░░░░░░░░░░██░░ *
 * ░░██░░░░░░░░░░░░░░░░░░░░░░░██░░ *
 * ░░░░██░░░░░░░░░░░░░░░░░░░██░░░░ *
 * ░░░░░░████░░░░░░░░░░░████░░░░░░ *
 * ░░░░░░░░░░███████████░░░░░░░░░░ *
 *********************************/

contract HyalikoDescriptor is Ownable {
    uint8 constant NUM_MESHES = 32;
    uint8 constant NUM_FACES = 58;
    uint8 constant NUM_BODIES = 60;
    uint8 constant NUM_COLORS = 26;

    uint256 public constant NUM_TRAITS = 6;
    uint8[NUM_TRAITS] public TRAIT_LENGTHS = [
        NUM_BODIES,
        NUM_FACES,
        NUM_COLORS,
        10,
        10,
        255
    ];

    //
    // MESH DATA
    //

    bytes[] public meshData;

    //
    // FACE DATA
    //

    bytes[] public faceData;

    //
    // BODY DATA
    //

    bytes[] public bodyData;

    //
    // COLORS
    //

    string[] public colorData;

    // Number of traits. Body, face, color and three hidden traits.

    // Whether or not new Hyaliko parts can be added
    bool public arePartsLocked;

    constructor() Ownable() {}

    /**
     * @notice Require that the parts have not been locked.
     */
    modifier whenPartsNotLocked() {
        require(!arePartsLocked, "Parts are locked");
        _;
    }

    /**
     * @notice Lock all hyaliko parts.
     * @dev This cannot be reversed and can only be called by the owner when not locked.
     */
    function lockParts() external onlyOwner whenPartsNotLocked {
        require(meshData.length == NUM_MESHES);
        require(bodyData.length == NUM_BODIES);
        require(faceData.length == NUM_FACES);
        require(colorData.length == NUM_COLORS);
        arePartsLocked = true;
    }


    function splitNumber(uint256 _number)
        internal
        pure
        returns (uint16[NUM_TRAITS] memory numbers)
    {
        for (uint256 i = 0; i < numbers.length; i++) {
            numbers[i] = uint16(_number % 10000);
            _number >>= 14;
        }
        return numbers;
    }

    function getTraitIndex(
        uint16 _dna,
        uint8 _index
    ) public view returns (uint8) {
        uint256 numTraits = uint256(TRAIT_LENGTHS[_index]);
        uint256 x1 = numTraits * uint256(_dna);
        uint256 x2 = x1 / 10000;
        return uint8(x2);
    }

    function getTraits(uint256 _dna)
        public
        view
        returns (bytes[6] memory traits)
    {
        uint16[NUM_TRAITS] memory dna = splitNumber(_dna);
        for (uint8 i = 0; i < NUM_TRAITS; i++) {
            uint8 trait = getTraitIndex(dna[i], i);
            traits[i] = abi.encodePacked(trait);
        }
        return traits;
    }

    /**
     * @notice Batch add Hyaliko bodies.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyMeshes(bytes[] calldata _meshes)
        external
        onlyOwner
        whenPartsNotLocked
    {
        for (uint256 i = 0; i < _meshes.length; i++) {
            meshData.push(_meshes[i]);
        }
        require(meshData.length <= NUM_MESHES);
    }

    /**
     * @notice Batch add Hyaliko bodies.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyBodies(bytes[] calldata _bodies)
        external
        onlyOwner
        whenPartsNotLocked
    {
        for (uint256 i = 0; i < _bodies.length; i++) {
            bodyData.push(_bodies[i]);
        }
        require(bodyData.length <= NUM_BODIES);
    }

    /**
     * @notice Batch add Hyaliko faces.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyFaces(bytes[] calldata _faces)
        external
        onlyOwner
        whenPartsNotLocked
    {
        for (uint256 i = 0; i < _faces.length; i++) {
            faceData.push(_faces[i]);
        }
        require(faceData.length <= NUM_FACES);
    }

    /**
     * @notice Batch add Hyaliko colors.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyColors(string[] calldata _colors)
        external
        onlyOwner
        whenPartsNotLocked
    {
        for (uint256 i = 0; i < _colors.length; i++) {
            colorData.push(_colors[i]);
        }
        require(colorData.length <= NUM_COLORS);
    }

    function strConcat(string memory _a, string memory _b)
        internal
        pure
        returns (string memory result)
    {
        result = string(abi.encodePacked(bytes(_a), bytes(_b)));
    }

    function tokenGltfDataForDna(uint256 dna)
        public
        view
        returns (string memory)
    {
        return tokenGltfData(getTraits(dna));
    }

    function tokenGltfData(bytes[6] memory data)
        public
        view
        returns (string memory)
    {
        uint8 body = uint8(bytes1(data[0]));
        uint8 face = uint8(bytes1(data[1]));
        uint8 color = uint8(bytes1(data[2]));
        uint8 size = uint8(bytes1(data[3]));
        uint8 opacity = uint8(bytes1(data[4]));

        uint8 bodyMeshIndex = BytesLib.toUint8(bodyData[body], 0);
        uint8 numBodyTransformations = BytesLib.toUint8(bodyData[body], 5);
        bytes memory faceZ = BytesLib.slice(bodyData[body], 1, 4);

        uint16 bufferViewLength1 = BytesLib.toUint16(
            meshData[bodyMeshIndex],
            0
        );
        uint16 bufferViewLength2 = BytesLib.toUint16(
            meshData[bodyMeshIndex],
            2
        );

        string
            memory gltfAccumulator = '{"asset":{"generator":"Hyaliko.sol","version":"2.0"},"scene":0,"scenes":[{"nodes":[0]}],"nodes":[{"children":[1,2]';
        if (size > 7) {
            gltfAccumulator = strConcat(
                gltfAccumulator,
                ',"scale":[1.2,1.2,1.2]'
            );
        } else if (size < 3) {
            gltfAccumulator = strConcat(
                gltfAccumulator,
                ',"scale":[0.8,0.8,0.8]'
            );
        }
        gltfAccumulator = strConcat(
            gltfAccumulator,
            '},{"mesh":0,"name":"face","translation":[0,0,'
        );
        gltfAccumulator = strConcat(gltfAccumulator, string(faceZ));
        gltfAccumulator = strConcat(gltfAccumulator, "]},");
        gltfAccumulator = strConcat(gltfAccumulator, '{"children":[');
        if (numBodyTransformations == 0) {
            gltfAccumulator = strConcat(gltfAccumulator, "3");
        } else {
            for (uint8 i = 1; i < numBodyTransformations + 1; i++) {
                gltfAccumulator = strConcat(
                    gltfAccumulator,
                    Strings.toString(2 + i)
                );
                if (i != numBodyTransformations) {
                    gltfAccumulator = strConcat(gltfAccumulator, ",");
                }
            }
        }
        gltfAccumulator = strConcat(gltfAccumulator, "]},");
        if (numBodyTransformations == 0) {
            gltfAccumulator = strConcat(
                gltfAccumulator,
                '{"mesh":1,"name":"body"}'
            );
        } else {
            for (uint16 i = 0; i < numBodyTransformations; i++) {
                uint16 byteOffset = 6 + (i * 58);
                gltfAccumulator = strConcat(
                    gltfAccumulator,
                    '{"mesh":1,"name":"body"'
                );
                gltfAccumulator = strConcat(
                    gltfAccumulator,
                    ',"translation":['
                );
                bytes memory bodyLayoutBytes = bodyData[body];
                bytes memory translationBytes = BytesLib.slice(
                    bodyLayoutBytes,
                    byteOffset,
                    16
                );
                gltfAccumulator = strConcat(
                    gltfAccumulator,
                    string(translationBytes)
                );
                gltfAccumulator = strConcat(gltfAccumulator, "]");
                gltfAccumulator = strConcat(gltfAccumulator, ',"rotation":[');
                bytes memory rotationBytes = BytesLib.slice(
                    bodyLayoutBytes,
                    byteOffset + 16,
                    26
                );
                gltfAccumulator = strConcat(
                    gltfAccumulator,
                    string(rotationBytes)
                );
                gltfAccumulator = strConcat(gltfAccumulator, "]");
                gltfAccumulator = strConcat(gltfAccumulator, ',"scale":[');
                bytes memory scaleBytes = BytesLib.slice(
                    bodyLayoutBytes,
                    byteOffset + 42,
                    16
                );
                gltfAccumulator = strConcat(
                    gltfAccumulator,
                    string(scaleBytes)
                );
                gltfAccumulator = strConcat(gltfAccumulator, "]");
                gltfAccumulator = strConcat(gltfAccumulator, "}");
                if (i != numBodyTransformations - 1) {
                    gltfAccumulator = strConcat(gltfAccumulator, ",");
                }
            }
        }
        gltfAccumulator = strConcat(gltfAccumulator, "],");
        gltfAccumulator = strConcat(
            gltfAccumulator,
            '"materials":[{"alphaCutoff":0.5,"alphaMode":"MASK","name":"faceMaterial","pbrMetallicRoughness":{"baseColorTexture":{"index":0,"texCoord":0},"metallicFactor":0,"roughnessFactor":1, "baseColorFactor":[1,1,1,1]}},'
        );
        gltfAccumulator = strConcat(
            gltfAccumulator,
            '{"pbrMetallicRoughness": {"baseColorFactor":['
        );
        gltfAccumulator = strConcat(gltfAccumulator, colorData[color]);
        gltfAccumulator = strConcat(gltfAccumulator, ",");
        if (opacity > 6) {
            gltfAccumulator = strConcat(gltfAccumulator, "1");
        } else if (opacity > 2) {
            gltfAccumulator = strConcat(gltfAccumulator, "0.9");
        } else {
            gltfAccumulator = strConcat(gltfAccumulator, "0.5");
        }
        gltfAccumulator = strConcat(
            gltfAccumulator,
            '],"metallicFactor":1,"roughnessFactor":0.25},"alphaMode":"BLEND","alpha":0.9,"emissiveFactor":['
        );
        gltfAccumulator = strConcat(gltfAccumulator, colorData[color]);
        gltfAccumulator = strConcat(
            gltfAccumulator,
            '],"name":"bodyMaterial"}],'
        );
        gltfAccumulator = strConcat(
            gltfAccumulator,
            '"meshes":[{"primitives":[{"attributes":{"POSITION":0,"TEXCOORD_0":1},"indices":2,"material":0}],"name":"Plane"},{"primitives":[{"attributes":{"POSITION":3},"indices":4,"material":1}],"name":"Mesh0"}],'
        );
        gltfAccumulator = strConcat(
            gltfAccumulator,
            '"textures": [{ "sampler": 0, "source": 0 }],'
        );
        gltfAccumulator = strConcat(
            gltfAccumulator,
            '"images": [{ "bufferView" : 3, "mimeType" : "image/png", "name" : "face1" }],'
        );
        gltfAccumulator = strConcat(
            gltfAccumulator,
            '"accessors": [{"bufferView" : 0,"componentType" :5126,"count" : 4,"max" : [0.6,0.6,0],"min" : [-0.6,-0.6,0],"type" : "VEC3"},{"bufferView":1,"componentType":5126,"count":4,"type":"VEC2"},{"bufferView":2,"componentType":5123,"count":6,"type":"SCALAR"},{"bufferView":4,"componentType":5126,"count":'
        );
        gltfAccumulator = strConcat(
            gltfAccumulator,
            Strings.toString(BytesLib.toUint16(meshData[bodyMeshIndex], 0))
        );
        gltfAccumulator = strConcat(
            gltfAccumulator,
            ',"max":[1,1,1],"min":[-1,-1,-1],"type":"VEC3"},{"bufferView":5,"componentType":5123,"count":'
        );
        gltfAccumulator = strConcat(
            gltfAccumulator,
            Strings.toString(BytesLib.toUint16(meshData[bodyMeshIndex], 2))
        );
        gltfAccumulator = strConcat(gltfAccumulator, ',"type":"SCALAR"}],');
        gltfAccumulator = strConcat(gltfAccumulator, '"bufferViews":[');
        gltfAccumulator = strConcat(
            gltfAccumulator,
            '{"buffer":0,"byteLength":48,"byteOffset":0},{"buffer":0,"byteLength":32,"byteOffset":48},{"buffer":0,"byteLength":12,"byteOffset":80},{"buffer":1,"byteLength":'
        );
        gltfAccumulator = strConcat(
            gltfAccumulator,
            Strings.toString(faceData[face].length)
        );
        gltfAccumulator = strConcat(gltfAccumulator, ',"byteOffset":0},');
        gltfAccumulator = strConcat(
            gltfAccumulator,
            '{"buffer":2,"byteLength":'
        );
        gltfAccumulator = strConcat(
            gltfAccumulator,
            Strings.toString(bufferViewLength1 * 12)
        );
        gltfAccumulator = strConcat(gltfAccumulator, ',"byteOffset":0},');
        gltfAccumulator = strConcat(
            gltfAccumulator,
            '{"buffer":2,"byteLength":'
        );
        gltfAccumulator = strConcat(
            gltfAccumulator,
            Strings.toString(bufferViewLength2 * 2)
        );
        gltfAccumulator = strConcat(gltfAccumulator, ',"byteOffset":');
        gltfAccumulator = strConcat(
            gltfAccumulator,
            Strings.toString(bufferViewLength1 * 12)
        );
        gltfAccumulator = strConcat(gltfAccumulator, "}");
        gltfAccumulator = strConcat(gltfAccumulator, "],");
        gltfAccumulator = strConcat(
            gltfAccumulator,
            '"samplers" : [{"magFilter" : 9728,"minFilter" : 9728}],'
        );
        gltfAccumulator = strConcat(gltfAccumulator, '"buffers": [');
        gltfAccumulator = strConcat(
            gltfAccumulator,
            '{"byteLength": 92,"uri": "data:application/octet-stream;base64,9t0evwrXI7/shs8z9t0ePwrXI7/shs8z9t0ePwrXIz/shs+z9t0evwrXIz/shs+zAAAAAAAAgD8AAIA/AACAPwAAgD8AAAAAAAAAAAAAAAAAAAEAAgAAAAIAAwA="},'
        );
        gltfAccumulator = strConcat(gltfAccumulator, '{"byteLength":');
        gltfAccumulator = strConcat(
            gltfAccumulator,
            Strings.toString(faceData[face].length)
        );
        gltfAccumulator = strConcat(
            gltfAccumulator,
            ',"uri": "data:application/octet-stream;base64,'
        );
        gltfAccumulator = strConcat(
            gltfAccumulator,
            Base64.encode(faceData[face], 0)
        );
        gltfAccumulator = strConcat(gltfAccumulator, '"},');
        gltfAccumulator = strConcat(
            gltfAccumulator,
            '{"byteLength": 11580,"uri": "data:application/octet-stream;base64,'
        );
        gltfAccumulator = strConcat(
            gltfAccumulator,
            Base64.encode(meshData[bodyMeshIndex], 4)
        );
        gltfAccumulator = strConcat(gltfAccumulator, '"}]');
        gltfAccumulator = strConcat(gltfAccumulator, "}");
        return gltfAccumulator;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    // Edited by Collin McKinney on 3/23/22. Added `start` argument.
    function encode(bytes memory data, uint256 start) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)
            
            // prepare the lookup table
            let tablePtr := add(table, 1)
            
            // input ptr
            // let dataPtr := data
            // Added by Collin McKinney
            let dataPtr := add(data, start)
            let endPtr := add(dataPtr, mload(data))
            
            // result ptr, jump over length
            let resultPtr := add(result, 32)
            
            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;


library BytesLib {
    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}