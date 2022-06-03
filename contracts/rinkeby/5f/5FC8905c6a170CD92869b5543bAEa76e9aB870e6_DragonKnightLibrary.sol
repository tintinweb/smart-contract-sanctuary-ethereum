// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library DragonKnightLibrary {
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    
    /**
     * @dev Converts layer into path svg data.
     * @param _layerId The index of the layer.
     * @param color Hex color value 1
     * @param color2 Hex color value 2
     */
    function getLayer(uint256 _layerId, string memory color, string memory color2) public pure returns (string memory retVal) {
        string memory beg = '<path stroke="';
        if(_layerId == 0) {
            return string(abi.encodePacked('<rect fill="', color, '" width="64" height="64" />'));
        }
        if(_layerId == 1) {
            return string(abi.encodePacked(beg, color, '" d="M24,24h16M24,25h16M24,26h16M24,27h16M20,28h4M28,28h8M40,28h4M20,29h4M28,29h8M40,29h4M20,30h4M28,30h8M40,30h4M20,31h4M28,31h8M40,31h4M24,32h16M24,33h16M24,34h16M24,35h16" />'));
        }
        if(_layerId == 2) {
            return string(abi.encodePacked(beg, color, '" d="M24,28h4M24,29h4M24,30h4M24,31h4" />', beg, color2, '" d="M36,28h4M36,29h4M36,30h4M36,31h4" />'));
        }
        if(_layerId == 5) {
            string memory armordark = string(abi.encodePacked(beg, color, '" d="M20,12h24M20,13h24M20,14h24M20,15h24M24,16h4M36,16h4M24,17h4M36,17h4M24,18h4M36,18h4M24,19h4M36,19h4M16,20h4M44,20h4M16,21h4M44,21h4M16,22h4M44,22h4M16,23h4M44,23h4M16,24h4M44,24h4M16,25h4M44,25h4M16,26h4M44,26h4M16,27h4M44,27h4M16,28h4M44,28h4M16,29h4M44,29h4M16,30h4M44,30h4M16,31h4M44,31h4M16,32h4M44,32h4M16,33h4M44,33h4M16,34h4M44,34h4M16,35h4M44,35h4M20,36h4M40,36h4M20,37h4M40,37h4M20,38h4M40,38h4M20,39h4M40,39h4M16,40h4M24,40h4M36,40h4M44,40h4M16,41h4M24,41h4M36,41h4M44,41h4M16,42h4M24,42h4M36,42h4M44,42h4M16,43h4M24,43h4M36,43h4M44,43h4M24,44h16M24,45h16M24,46h16M24,47h16M24,48h16M24,49h16M24,50h16M24,51h16" />'));
            string memory armorlight = string(abi.encodePacked(beg, color2, '" d="M28,16h8M28,17h8M28,18h8M28,19h8M20,20h24M20,21h24M20,22h24M20,23h24M24,36h16M24,37h16M24,38h16M24,39h16M28,40h8M28,41h8M28,42h8M28,43h8M24,52h4M36,52h4M24,53h4M36,53h4M24,54h4M36,54h4M24,55h4M36,55h4M24,60h4M36,60h4M24,61h4M36,61h4M24,62h4M36,62h4M24,63h4M36,63h4" />'));

            return string(abi.encodePacked(armordark, armorlight));
        }
        if(_layerId == 3) {
            return string(abi.encodePacked('<path stroke="', color, '" d="M20,16h4M40,16h4M20,17h4M40,17h4M20,18h4M40,18h4M20,19h4M40,19h4" />'));
        }
        if(_layerId == 4) {
            return string(abi.encodePacked(beg, color, '" d="M48,40h4M48,41h4M48,42h4M48,43h4M48,44h4M48,45h4M48,46h4M48,47h4M48,48h4M48,49h4M48,50h4M48,51h4" />', beg, color2, '" d="M52,44h12M52,45h12M52,46h12M52,47h12" />'));
        }
    }

    function getHelmetHornsTeethLayer() public pure returns(string memory) {
        return '<path stroke="#bdbdbd" d="M20,4h4M40,4h4M20,5h4M40,5h4M20,6h4M40,6h4M20,7h4M40,7h4M20,8h4M40,8h4M20,9h4M40,9h4M20,10h4M40,10h4M20,11h4M40,11h4M20,24h4M40,24h4M20,25h4M40,25h4M20,26h4M40,26h4M20,27h4M40,27h4M20,32h4M40,32h4M20,33h4M40,33h4M20,34h4M40,34h4M20,35h4M40,35h4M16,44h4M44,44h4M16,45h4M44,45h4M16,46h4M44,46h4M16,47h4M44,47h4M24,56h4M36,56h4M24,57h4M36,57h4M24,58h4M36,58h4M24,59h4M36,59h4" />';
    }
    
    // Helper functions
    function substring(string memory  str, uint startIndex, uint endIndex) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return string(result);
    }

    // Thank you mouse dev
    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

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
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
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

    function parseInt(string memory _a)
        internal
        pure
        returns (uint8 _parsedInt)
    {
        bytes memory bresult = bytes(_a);
        uint8 mint = 0;
        for (uint8 i = 0; i < bresult.length; i++) {
            if (
                (uint8(uint8(bresult[i])) >= 48) &&
                (uint8(uint8(bresult[i])) <= 57)
            ) {
                mint *= 10;
                mint += uint8(bresult[i]) - 48;
            }
        }
        return mint;
    }
}