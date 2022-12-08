// SPDX-License-Identifier: MIT

/**
       ###    ##    ## #### ##     ##    ###
      ## ##   ###   ##  ##  ###   ###   ## ##
     ##   ##  ####  ##  ##  #### ####  ##   ##
    ##     ## ## ## ##  ##  ## ### ## ##     ##
    ######### ##  ####  ##  ##     ## #########
    ##     ## ##   ###  ##  ##     ## ##     ##
    ##     ## ##    ## #### ##     ## ##     ##
*/

pragma solidity ^0.8.15;
pragma abicoder v2;

import "./Strings.sol";

import "./OnlyBotsData.sol";

contract OnlyBotsDeserializerV1 is OnlyBotsDeserializer {
    error InvalidLength(uint256 length);
    error InvalidCharacter(uint256 bits);
    error InvalidDirection(uint256 direction);
    error InvalidEndOffset(uint256 offset, uint256 expected, uint256 length);

    uint256 public constant COLOR_COUNT_BITWIDTH = 4;
    uint256 public constant COLOR_RGB = 8;
    uint256 public constant BOT_LENGTH = 16;
    uint256 public constant NAME_COUNT = 5;
    uint256 public constant NAME_CHAR = 6;
    uint256 public constant ANCHOR_XZ_SIGN = 1;
    uint256 public constant ANCHOR_X = 4;
    uint256 public constant ANCHOR_Y = 3;
    uint256 public constant ANCHOR_Z = 4;
    uint256 public constant MATERIAL_COUNT = 2;
    uint256 public constant MATERIAL_PRESET = 8;
    uint256 public constant LAYER_VOXEL_LIST_COUNT_BITWIDTH = 4;
    uint256 public constant LAYER_COUNT = 5;
    uint256 public constant LAYER_TYPE = 3;
    uint256 public constant LAYER_MATERIAL = 2;
    uint256 public constant LAYER_VOXEL_ORIGIN = 4;
    uint256 public constant LAYER_VOXEL_FORMAT = 1;
    uint256 public constant LAYER_VOXEL_FIELD_LENGTH = 4;
    uint256 public constant LAYER_VOXEL_FIELD_FLAG = 1;
    uint256 public constant LAYER_VOXEL_LIST_FOURBIT = 1;
    uint256 public constant LAYER_VOXEL_LIST_DIRECTION = 2;

    uint256 public constant DIRECTION_XYZ = 0;
    uint256 public constant DIRECTION_YZ = 1;
    uint256 public constant DIRECTION_XZ = 2;
    uint256 public constant DIRECTION_XY = 3;

    struct Color {
        uint256 r;
        uint256 g;
        uint256 b;
    }

    struct Material {
        Color color;
        uint256 preset;
    }

    struct Coordinate3D {
        uint256 x;
        uint256 y;
        uint256 z;
    }

    struct Layer {
        uint256 _type;
        uint256 material;
        Coordinate3D[] voxels;
    }

    struct Anchor {
        bool x_sign;
        uint256 x;
        uint256 y;
        bool z_sign;
        uint256 z;
    }

    struct Bot {
        string name;
        Anchor anchor;
        Material[] materials;
        Layer[] layers;
    }

    struct Data {
        bytes buffer;
        uint256 offset; // in BITS
    }

    // NOTE: _botId is 1-indexed
    function deserialize(
        DataContract memory _contract,
        uint256, /* _batchIndex */
        uint128 _botId
    ) public pure override returns (string memory) {
        Data memory data = Data(_contract.dataContract.getBuffer(), 0);

        uint256 colorCountBitwidth = readUint256Bits(data, COLOR_COUNT_BITWIDTH);
        uint256 colorCount = readUint256Bits(data, colorCountBitwidth) + 1;
        Color[] memory colors = new Color[](colorCount);
        for (uint256 i = 0; i < colorCount; i++) {
            colors[i] = Color(
                readUint256Bits(data, COLOR_RGB),
                readUint256Bits(data, COLOR_RGB),
                readUint256Bits(data, COLOR_RGB)
            );
        }

        // i = 1 is not a typo
        for (uint256 i = 1; i < _botId; i++) {
            uint256 skipLength = readUint256Bits(data, BOT_LENGTH);
            data.offset += skipLength;
        }

        uint256 botLength = readUint256Bits(data, BOT_LENGTH);
        uint256 endOffset = data.offset + botLength;

        uint256 nameLength = readUint256Bits(data, NAME_COUNT) + 1;
        bytes memory name = new bytes(nameLength);
        for (uint256 i = 0; i < nameLength; i++) {
            name[i] = mapBitsToAscii(readUint256Bits(data, NAME_CHAR));
        }

        Anchor memory anchor = Anchor(
            readUint256Bits(data, ANCHOR_XZ_SIGN) == 0 ? false : true,
            readUint256Bits(data, ANCHOR_X),
            readUint256Bits(data, ANCHOR_Y),
            readUint256Bits(data, ANCHOR_XZ_SIGN) == 0 ? false : true,
            readUint256Bits(data, ANCHOR_Z)
        );
        uint256 materialCount = readUint256Bits(data, MATERIAL_COUNT) + 1;
        Material[] memory materials = new Material[](materialCount);
        for (uint256 i = 0; i < materialCount; i++) {
            uint256 colorIndex = readUint256Bits(data, colorCountBitwidth);
            materials[i] = Material(colors[colorIndex], readUint256Bits(data, MATERIAL_PRESET));
        }

        uint256 layerListCountBitwidth = readUint256Bits(data, LAYER_VOXEL_LIST_COUNT_BITWIDTH);
        uint256 layerCount = readUint256Bits(data, LAYER_COUNT) + 1;
        Layer[] memory layers = new Layer[](layerCount);
        for (uint256 i = 0; i < layerCount; i++) {
            layers[i] = deserializeLayer(data, layerListCountBitwidth);
        }

        if (data.offset != endOffset) {
            revert InvalidEndOffset(data.offset, endOffset, botLength);
        }
        return serialize(Bot(string(name), anchor, materials, layers));
    }

    function deserializeLayer(Data memory data, uint256 _layerListCountBitwidth) private pure returns (Layer memory) {
        uint256 layerType = readUint256Bits(data, LAYER_TYPE);
        uint256 materialIndex = readUint256Bits(data, LAYER_MATERIAL);
        Coordinate3D memory origin = Coordinate3D(
            readUint256Bits(data, LAYER_VOXEL_ORIGIN),
            readUint256Bits(data, LAYER_VOXEL_ORIGIN),
            readUint256Bits(data, LAYER_VOXEL_ORIGIN)
        );
        uint256 format = readUint256Bits(data, LAYER_VOXEL_FORMAT);

        if (format > 0) {
            uint256 coordinateBitSize = readUint256Bits(data, LAYER_VOXEL_LIST_FOURBIT) > 0 ? 4 : 3;
            uint256 direction = readUint256Bits(data, LAYER_VOXEL_LIST_DIRECTION);
            uint256 listLength = readUint256Bits(data, _layerListCountBitwidth) + 1;
            Coordinate3D[] memory voxels = new Coordinate3D[](listLength);
            if (direction == DIRECTION_XYZ) {
                for (uint256 j = 0; j < listLength; j++) {
                    voxels[j] = Coordinate3D(
                        origin.x + readUint256Bits(data, coordinateBitSize),
                        origin.y + readUint256Bits(data, coordinateBitSize),
                        origin.z + readUint256Bits(data, coordinateBitSize)
                    );
                }
            } else if (direction == DIRECTION_XY) {
                for (uint256 j = 0; j < listLength; j++) {
                    voxels[j] = Coordinate3D(
                        origin.x + readUint256Bits(data, coordinateBitSize),
                        origin.y + readUint256Bits(data, coordinateBitSize),
                        origin.z
                    );
                }
            } else if (direction == DIRECTION_XZ) {
                for (uint256 j = 0; j < listLength; j++) {
                    voxels[j] = Coordinate3D(
                        origin.x + readUint256Bits(data, coordinateBitSize),
                        origin.y,
                        origin.z + readUint256Bits(data, coordinateBitSize)
                    );
                }
            } else if (direction == DIRECTION_YZ) {
                for (uint256 j = 0; j < listLength; j++) {
                    voxels[j] = Coordinate3D(
                        origin.x,
                        origin.y + readUint256Bits(data, coordinateBitSize),
                        origin.z + readUint256Bits(data, coordinateBitSize)
                    );
                }
            } else {
                revert InvalidDirection(direction);
            }

            return Layer(layerType, materialIndex, voxels);
        } else {
            Coordinate3D memory length = Coordinate3D(
                readUint256Bits(data, LAYER_VOXEL_FIELD_LENGTH) + 1,
                readUint256Bits(data, LAYER_VOXEL_FIELD_LENGTH) + 1,
                readUint256Bits(data, LAYER_VOXEL_FIELD_LENGTH) + 1
            );
            bool[][][] memory field = new bool[][][](length.x);
            uint256 count = 0;
            for (uint256 x = 0; x < length.x; x++) {
                field[x] = new bool[][](length.y);
                for (uint256 y = 0; y < length.y; y++) {
                    field[x][y] = new bool[](length.z);
                    for (uint256 z = 0; z < length.z; z++) {
                        field[x][y][z] = readUint256Bits(data, LAYER_VOXEL_FIELD_FLAG) > 0;
                        if (field[x][y][z]) {
                            count++;
                        }
                    }
                }
            }

            uint256 insert = 0;
            Coordinate3D[] memory voxels = new Coordinate3D[](count);
            for (uint256 x = 0; x < length.x; x++) {
                for (uint256 y = 0; y < length.y; y++) {
                    for (uint256 z = 0; z < length.z; z++) {
                        if (field[x][y][z]) {
                            voxels[insert++] = Coordinate3D(origin.x + x, origin.y + y, origin.z + z);
                        }
                    }
                }
            }

            return Layer(layerType, materialIndex, voxels);
        }
    }

    function serialize(Bot memory _bot) private pure returns (string memory) {
        string memory materials = "";
        for (uint256 i = 0; i < _bot.materials.length; i++) {
            Material memory material = _bot.materials[i];
            materials = string.concat(
                materials,
                '{"color":[',
                Strings.toString(material.color.r),
                ",",
                Strings.toString(material.color.g),
                ",",
                Strings.toString(material.color.b),
                '],"preset":',
                Strings.toString(material.preset),
                "}",
                i < _bot.materials.length - 1 ? "," : ""
            );
        }

        string memory layers = "";
        for (uint256 i = 0; i < _bot.layers.length; i++) {
            Layer memory layer = _bot.layers[i];
            layers = string.concat(
                layers,
                '{"type":',
                Strings.toString(layer._type),
                ',"material":',
                Strings.toString(layer.material),
                ',"voxels":['
            );
            for (uint256 j = 0; j < layer.voxels.length; j++) {
                Coordinate3D memory voxel = layer.voxels[j];
                layers = string.concat(
                    layers,
                    "[",
                    Strings.toString(voxel.x),
                    ",",
                    Strings.toString(voxel.y),
                    ",",
                    Strings.toString(voxel.z),
                    "]",
                    j < layer.voxels.length - 1 ? "," : ""
                );
            }
            layers = string.concat(layers, "]}", i < _bot.layers.length - 1 ? "," : "");
        }

        return
            string.concat(
                "{",
                '"name":"',
                _bot.name,
                '","anchor":',
                string.concat(
                    "{",
                    '"x":',
                    _bot.anchor.x_sign ? "" : "-",
                    Strings.toString(_bot.anchor.x),
                    ',"y":',
                    Strings.toString(_bot.anchor.y),
                    ',"z":',
                    _bot.anchor.z_sign ? "" : "-",
                    Strings.toString(_bot.anchor.z),
                    "}"
                ),
                ',"materials":[',
                materials,
                '],"layers":[',
                layers,
                "]}"
            );
    }

    function readUint256Bits(Data memory _data, uint256 length) private pure returns (uint256) {
        if (length < 1 || length > 256) {
            revert InvalidLength(length);
        }

        uint256 offsetBytes = _data.offset == 0 ? 0 : _data.offset / 8;
        uint8 offsetBits = uint8(_data.offset % 8);

        uint256 totalBits = length + offsetBits;

        uint256 bytesToRead = (totalBits / 8) + (totalBits % 8 != 0 ? 1 : 0);
        uint256 rightShift = (bytesToRead * 8) - (length + offsetBits);

        bytes1 on = 0xFF;
        uint256 result = 0;

        for (uint256 i = 0; i < bytesToRead; i++) {
            bytes1 value = _data.buffer[offsetBytes + i];
            if (i == 0) {
                // If this is the first byte, clear bits before the offset
                bytes1 mask = on >> offsetBits;
                value = value & mask;
            }
            if (i == (bytesToRead - 1)) {
                // If this is the last byte, shift value to the end of the byte
                value = value >> rightShift;
            }

            uint256 converted = uint256(uint8(value));

            if (i != (bytesToRead - 1)) {
                converted = converted << (((bytesToRead - 1 - i) * 8) - rightShift);
            }

            result += converted;
        }

        _data.offset += length;
        return result;
    }

    function mapBitsToAscii(uint256 _bits) private pure returns (bytes1) {
        // 0 to 58 => 32 to 90
        if (_bits >= 0 && _bits <= 58) {
            return bytes1(uint8(_bits + 32));
        }

        // 59 => 92
        if (_bits == 59) {
            return bytes1(uint8(92));
        }

        // 60 => 94
        if (_bits == 60) {
            return bytes1(uint8(94));
        }

        // 61 => 95
        if (_bits == 61) {
            return bytes1(uint8(95));
        }

        // 62 => 124
        if (_bits == 62) {
            return bytes1(uint8(124));
        }

        // 63 => 126
        if (_bits == 63) {
            return bytes1(uint8(126));
        }

        revert InvalidCharacter(_bits);
    }
}