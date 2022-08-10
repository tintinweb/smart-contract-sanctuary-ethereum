// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract TornadoRenderer {

    address admin;
    address tornadoTypes;


    constructor() { admin = msg.sender; }

    function setInventory(address tornadoTypes_) external {
        require(msg.sender == admin, "not admin");
        tornadoTypes        = tornadoTypes_;
    }

    function getURI(uint256 id, uint256 tornadoType, uint256 fujitaScale) external view returns(string memory uri) {
        uri = _getMetadata(id, tornadoType, fujitaScale);
    }

    function _getMetadata(uint256 id, uint256 tornadoType, uint256 fujitaScale) internal view returns (string memory meta) {
        string memory svg = _getSvg(id, tornadoType);

        meta = 
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Strings.encode(
                        abi.encodePacked(
                            '{"name":"', "Tornado", " #", Strings.toString(id),
                            '","description":"',
                            '","image": "data:image/svg+xml;base64,', svg,
                            '","attributes":[', _getAttributes(tornadoType, fujitaScale),']}')
                        )
                    )
                );
    }




    function _getAttributes(uint256 tornadoType, uint256 fujitaScale) internal pure returns (string memory atts_) {
        atts_ = string(abi.encodePacked(
            '{"trait_type":"Type","value":"', _getName(tornadoType),'"},',
            '{"trait_type":"Fujita Scale","value":', "F", Strings.toString(fujitaScale),'}'
            ));


    }

    function _getName(uint256 id) internal pure returns (string memory name_) {
        // if (id == 1)  name_ = "Nut";
        // if (id == 2)  name_ = "Tar";
        // if (id == 3)  name_ = "Dust";
        // if (id == 4)  name_ = "Blood";
        // if (id == 5)  name_ = "Ice";
        // if (id == 6)  name_ = "Water";
        // if (id == 7)  name_ = "Wind";
        // if (id == 8)  name_ = "Cash";
        // if (id == 9)  name_ = "Piss";
        // if (id == 10)  name_ = "Shit";
        if (id == 1)  name_ = "Nut";
        if (id == 2)  name_ = "Shit";
        if (id == 3)  name_ = "Piss";
        if (id == 4)  name_ = "Tar";
        if (id == 5)  name_ = "Dust";
        if (id == 6)  name_ = "Blood";
        if (id == 7)  name_ = "Ice";
        if (id == 8)  name_ = "Water";
        if (id == 9)  name_ = "Wind";
        if (id == 10) name_ = "Cash";
    }

    function _bg(uint256 tokenId) internal pure returns (string memory bg_) {
        uint256 id = (tokenId % 10) + 1;
        // if (id ==  1) bg_ = "483d8b";
        // if (id ==  2) bg_ = "40e0d0";
        // if (id ==  3) bg_ = "ff69b4";
        // if (id ==  4) bg_ = "00bfff";
        // if (id ==  5) bg_ = "ff7f50";
        // if (id ==  6) bg_ = "9370db";
        // if (id ==  7) bg_ = "ff00ff";
        // if (id ==  8) bg_ = "f08080";
        // if (id ==  9) bg_ = "5b6ee1";
        // if (id == 10) bg_ = "9400D3";
        if (id ==  1) bg_ = "9b2442";
        if (id ==  2) bg_ = "c03c6d";
        if (id ==  3) bg_ = "a7386d";
        if (id ==  4) bg_ = "ec6daf";
        if (id ==  5) bg_ = "985ea5";
        if (id ==  6) bg_ = "cc9fd6";
        if (id ==  7) bg_ = "4c466e";
        if (id ==  8) bg_ = "726b96";
        if (id ==  9) bg_ = "165286";
        if (id == 10) bg_ = "3189bc";
    }

    function _getSvg(uint256 id, uint256 tornadoTypeId) internal view returns (string memory svg) {

        // string memory tornadoType = InventoryLike(profAddress).professions(profession);
        string memory tornadoType = InventoryLike(tornadoTypes).tornados(tornadoTypeId);
        
        svg = Strings.encode(abi.encodePacked(header, getBg(id), wrapTag(tornadoType) ,footer));
    }

    function getBg(uint256 id) internal pure returns (string memory bg) {
        bg = string(abi.encodePacked('<rect width="100%" height="100%" style="fill:#', _bg(id) ,'" />'));
    }

    function wrapTag(string memory uri) internal pure returns (string memory) {
        return string(abi.encodePacked('<image x="0" y="0" width="24" height="24" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,', uri, '"/>'));
    }

    string constant header = '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" id="tornado" width="100%" height="100%" version="1.1" viewBox="0 0 24 24">';
    string constant footer = '<style>#tornado{shape-rendering: crispedges;image-rendering: -webkit-crisp-edges;image-rendering: -moz-crisp-edges;image-rendering: crisp-edges;image-rendering: pixelated;-ms-interpolation-mode: nearest-neighbor;}</style></svg>';
}

library Strings {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);
        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)
            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)
                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)
                mstore(resultPtr, out)
                resultPtr := add(resultPtr, 4)
            }
            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
            mstore(result, encodedLen)
        }
        return string(result);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
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
}

interface InventoryLike {
    function tornados(uint256 id) external pure returns (string memory str);
}