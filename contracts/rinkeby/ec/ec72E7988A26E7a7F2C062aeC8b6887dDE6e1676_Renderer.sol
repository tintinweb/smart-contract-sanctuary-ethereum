//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// Base libraries
import "./Utils.sol";
import "./Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// ============ epochs interface ============
interface IEpochs {
    function getEpochLabels() external view returns (string[12] memory);

    function currentEpochs() external view returns (uint256[12] memory);

    function getEpochs(uint256 blockNumber)
        external
        pure
        returns (uint256[12] memory);
}

// Core Renderer called from the main contract.
contract Renderer {

    string public add = Strings.toHexString(uint256(uint160(msg.sender)));

    string[] private colors = [
        string(abi.encodePacked("ff", getSlice(3, 6, add))),
        getSlice(7, 12, add),
        getSlice(13, 18, add),
        getSlice(19, 24, add),
        getSlice(25, 30, add),
        getSlice(31, 36, add),
        getSlice(37, 42, add)
    ];

    function getColor(uint256 multiplier)
        internal
        view
        returns (string memory)
    {
        return pluck(multiplier, "COLORS", colors);
    }

    /// ============ get epochs ============

    address epochsAddr = 0x6710B4419eb05a8CDB7940268bf7AE40D0bF7773; // rinkeby

    function getEpochLabels() public view returns (string[12] memory) {
        return IEpochs(epochsAddr).getEpochLabels();
    }

    function getCurrentEpoch() public view returns (uint256[12] memory) {
        return IEpochs(epochsAddr).currentEpochs();
    }

    function getEpochs() public view returns (uint256[12] memory) {
        return IEpochs(epochsAddr).getEpochs(block.number);
    }

    uint256[12] public currentEpoch = getCurrentEpoch();
    string[12] public epochLabels = getEpochLabels();

    function render(uint tokenId) public view returns (string memory) {
        return
            string.concat(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        getNebulaeth(
                            getName(tokenId),
                            getImage(),
                            getDescription(),
                            getAttributes()
                        )
                    )
                )
            );
    }
    
    function getNebulaeth(
        string memory _getName,
        string memory _getImage,
        string memory _getDescription,
        string memory _getAttributes
    ) public pure returns (string memory) {
        return
            string.concat(
                '{',
                _getName,
                _getImage,
                _getDescription,
                _getAttributes,
                "}"
            );
    }

    function getName(uint tokenId) public pure returns (string memory) {
        return
        string.concat('"name":', '"nebulaeth #', numberToString(tokenId + 1) , '",');
    }

    function getImage() public view returns (string memory) {
        return
            string.concat(
                '"image": "data:image/svg+xml;base64,',
                Base64.encode(bytes(getSVG())),
                '",'
            );
    }

    function getSVG() public view returns (string memory) {
        return
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 1000 1000"><radialGradient id="a"><stop stop-color="#',
                getColor(block.number * currentEpoch[5]),
                '"/><stop offset=".25" stop-color="#',
                getColor(block.number / currentEpoch[5]),
                '"/><stop offset=".4" stop-color="#',
                getColor(block.number),
                '"/><stop offset=".5"/></radialGradient><filter id="b"><feTurbulence baseFrequency=".',
                numberToString(currentEpoch[0]),
                string.concat(
                    '" seed="',
                    numberToString(block.number),
                    '"/><feColorMatrix values="0 0 0 9 -5 0 0 0 9 -5 0 0 0 9 -5 0 0 0 0 1" result="s"/><feTurbulence type="fractalNoise" baseFrequency=".0',
                    numberToString(currentEpoch[0]),
                    numberToString(currentEpoch[1]),
                    '" numOctaves="',
                    numberToString(currentEpoch[2]),
                    '" seed="',
                    numberToString(currentEpoch[3]),
                    '"/><feDisplacementMap in="SourceGraphic" scale="99"/><feBlend in="s" mode="screen"/></filter><circle cx="50%" cy="50%" r="50%" fill="url(#a)" filter="url(#b)"/></svg>'
                )
            );
    }

    function getDescription() public view returns (string memory) {
        return
            string.concat(
                '"description": "A nebulaeth discovered  in ',
                epochLabels[6],
                " ",
                numberToString(currentEpoch[6]),
                " ",
                epochLabels[5],
                " ",
                numberToString(currentEpoch[5]),
                " ",
                epochLabels[4],
                " ",
                numberToString(currentEpoch[4]),
                " by ",
                add,
                '.\\n\\n##[nebulaeth.space](https://nebulaeth.space)\\n\\n[epochs.cosmiccomputation.org](https://epochs.cosmiccomputation.org)",'
            );
    }

    function getAttributes() public view returns (string memory) {
        return
            string.concat(
                '"attributes":[',
                attributeString(
                    epochLabels[6],
                    numberToString(currentEpoch[6])
                ), ',',
                attributeString(
                    epochLabels[5],
                    numberToString(currentEpoch[5])
                ), ',',
                attributeString(
                    epochLabels[4],
                    numberToString(currentEpoch[4])
                ), ',',
                attributeString(
                    epochLabels[3],
                    numberToString(currentEpoch[3])
                ), ',',
                attributeString(
                    epochLabels[2],
                    numberToString(currentEpoch[2])
                ), ',',
                attributeString(
                    epochLabels[1],
                    numberToString(currentEpoch[1])
                ), ',',
                attributeString(
                    epochLabels[0],
                    numberToString(currentEpoch[0])
                ),
                "]"
            );
    }


    /// ============ helpers ============

    function numberToString(uint256 value)
        internal
        pure
        returns (string memory)
    {
        return Strings.toString(value);
    }

    function getSlice(
        uint256 begin,
        uint256 end,
        string memory text
    ) internal pure returns (string memory) {
        bytes memory a = new bytes(end - begin + 1);
        for (uint256 i = 0; i <= end - begin; i++) {
            a[i] = bytes(text)[i + begin - 1];
        }
        return string(a);
    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function pluck(
        uint256 tokenId,
        string memory keyPrefix,
        string[] memory sourceArray
    ) internal pure returns (string memory) {
        uint256 rand = random(
            string(abi.encodePacked(keyPrefix, numberToString(tokenId)))
        );
        string memory output = sourceArray[rand % sourceArray.length];
        output = string(abi.encodePacked(output));
        return output;
    }

    function attributeString(string memory _name, string memory _value)
        public
        pure
        returns (string memory)
    {
        return
            string.concat(
                "{",
                kv("trait_type", string.concat('"', _name, '"')),
                ",",
                kv("value", string.concat('"', _value, '"')),
                "}"
            );
    }

    function kv(string memory _key, string memory _value)
        public
        pure
        returns (string memory)
    {
        return string.concat('"', _key, '"', ":", _value);
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
// Author: Brecht Devos

pragma solidity ^0.8.0;

library Base64 {
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

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
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// Core utils used extensively to format CSS and numbers.
library utils {
    // used to simulate empty strings
    string internal constant NULL = "";

    // formats getting a def URL
    function getDefURL(string memory _id)
        internal
        pure
        returns (string memory)
    {
        return string.concat("url(#", _id, ")");
    }

    // checks if two strings are equal
    function stringsEqual(string memory _a, string memory _b)
        internal
        pure
        returns (bool)
    {
        return
            keccak256(abi.encodePacked(_a)) == keccak256(abi.encodePacked(_b));
    }

    // returns the length of a string in characters
    function utfStringLength(string memory _str)
        internal
        pure
        returns (uint256 length)
    {
        uint256 i = 0;
        bytes memory string_rep = bytes(_str);

        while (i < string_rep.length) {
            if (string_rep[i] >> 7 == 0) i += 1;
            else if (string_rep[i] >> 5 == bytes1(uint8(0x6))) i += 2;
            else if (string_rep[i] >> 4 == bytes1(uint8(0xE))) i += 3;
            else if (string_rep[i] >> 3 == bytes1(uint8(0x1E)))
                i += 4;
                //For safety
            else i += 1;

            length++;
        }
    }

    // converts an unsigned integer to a string
    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

}