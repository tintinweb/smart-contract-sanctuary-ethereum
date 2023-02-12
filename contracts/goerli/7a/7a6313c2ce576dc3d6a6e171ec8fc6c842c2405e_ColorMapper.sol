contract ColorMapper {
    mapping (uint256 => mapping (bytes8 => string)) public colorsMaps;
    uint256 colorMapIndex;

    function addNewColorMap (string[] memory colors) public {
        colorMapIndex++;
        for (uint256 i = 1; i < colors.length; i++) {
            bytes memory byteRepresentation = abi.encode(i);
            bytes8 byteRepresentation8;
            assembly {
                byteRepresentation8 := mload(add(byteRepresentation, 0x20))
            }
            colorsMaps[colorMapIndex][byteRepresentation8] = colors[i];
        }
    }

    function getColor (uint256 mapId, bytes8 index) public view returns (string memory) {
        return colorsMaps[mapId][index];
    }

    function getAllColors (uint256 mapId) public view returns (string[] memory) {
        string[] memory result = new string[](256);
        for (uint256 i = 0; i < 256; i++) {
            bytes memory byteRepresentation = abi.encode(i);
            bytes8 byteRepresentation8;
            assembly {
                byteRepresentation8 := mload(add(byteRepresentation, 0x20))
            }
            result[i] = colorsMaps[mapId][byteRepresentation8];
        }
        return result;
    }
}