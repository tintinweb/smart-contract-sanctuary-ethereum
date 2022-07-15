//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import './SVG.sol';
import './Utils.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/Base64.sol';

/// ============ epochs interface ============
interface IEpochs {
    function getEpochLabels() external view returns (string[12] memory);

    function getEpochs(uint256 blockNumber)
        external
        pure
        returns (uint256[12] memory);
}

// Core Renderer called from the main contract.
contract Renderer {
    /// ============ get epochs ============

    address internal constant EPOCH_ADDRESS =
        0xde9f0c369Ef3692B4bF9D40803A9029a3722B9c4; // mainnet

    // address internal constant EPOCH_ADDRESS =
    //     0x6710B4419eb05a8CDB7940268bf7AE40D0bF7773; // rinkeby

    function getEpochLabels() public view returns (string[12] memory) {
        return IEpochs(EPOCH_ADDRESS).getEpochLabels();
    }

    function getEpochs(uint256 blockNumber)
        public
        pure
        returns (uint256[12] memory)
    {
        return IEpochs(EPOCH_ADDRESS).getEpochs(blockNumber);
    }

    string[12] public epochLabels = getEpochLabels();

    /// ============ get colors ============
    function getColor(string memory _add, uint256 multiplier)
        internal
        pure
        returns (string memory)
    {
        string[7] memory colors = [
            string.concat('00', utils.getSlice(3, 6, _add)),
            utils.getSlice(7, 12, _add),
            utils.getSlice(13, 18, _add),
            utils.getSlice(19, 24, _add),
            utils.getSlice(25, 30, _add),
            utils.getSlice(31, 36, _add),
            utils.getSlice(37, 42, _add)
        ];
        return utils.pluck(multiplier, 'COLORS', colors);
    }

    /// ============ build NFT ============

    function render(uint256 _tokenId, string memory _address)
        public
        view
        returns (string memory)
    {
        uint256[12] memory epochs = getEpochs(block.number);
        return
            string.concat(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        string.concat(
                            '{',
                            getName(_tokenId, epochs),
                            getImage(_address, epochs),
                            getDescription(_address, epochs),
                            '}'
                        )
                    )
                )
            );
    }

    function getName(uint256 tokenId, uint256[12] memory _epochs)
        internal
        pure
        returns (string memory)
    {
        return
            string.concat(
                '"name":',
                '"NEBULAETH',
                ' ',
                string.concat(
                    utils.uint2str(tokenId + 1),
                    '-',
                    utils.uint2str(_epochs[3]),
                    utils.uint2str(_epochs[2]),
                    utils.uint2str(_epochs[1])
                ),
                '",'
            );
    }

    function getImage(string memory _add, uint256[12] memory _epochs)
        internal
        view
        returns (string memory)
    {
        return
            string.concat(
                '"image": "data:image/svg+xml;base64,',
                Base64.encode(bytes(getSVG(_add, _epochs))),
                '",'
            );
    }

    function getSVG(string memory _add, uint256[12] memory _epochs)
        internal
        view
        returns (string memory)
    {
        return
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 600 600" style="height: 100vh; width: 100vw; min-height: 600px; min-width: 600px;">',
                radialGradient(_add, _epochs),
                filter(_epochs),
                svg.el(
                    'circle',
                    string.concat(
                        svg.prop('cx', '50%'),
                        svg.prop('cy', '50%'),
                        svg.prop('r', '55%'),
                        svg.prop('fill', 'url(#a)'),
                        svg.prop('filter', 'url(#b)')
                    )
                ),
                '</svg>'
            );
    }

    function radialGradient(string memory _add, uint256[12] memory _epochs)
        internal
        view
        returns (string memory)
    {
        string memory _color1 = string.concat(
            '#',
            getColor(_add, block.number * _epochs[0])
        );
        string memory _color2 = string.concat(
            '#',
            getColor(_add, block.number / _epochs[0])
        );
        string memory _color3 = string.concat(
            '#',
            getColor(_add, block.number)
        );
        return
            svg.el(
                'radialGradient',
                string.concat(svg.prop('id', 'a')),
                string.concat(
                    svg.el('stop', svg.prop('stop-color', _color1)),
                    svg.el(
                        'stop',
                        string.concat(
                            svg.prop('offset', '0.125'),
                            svg.prop('stop-color', _color2)
                        )
                    ),
                    svg.el(
                        'stop',
                        string.concat(
                            svg.prop('offset', '.25'),
                            svg.prop('stop-color', _color3)
                        )
                    ),
                    svg.el('stop', string.concat(svg.prop('offset', '.5')))
                )
            );
    }

    function seed(uint256[12] memory _epochs)
        internal
        pure
        returns (string memory)
    {
        string memory _seed1 = string.concat(
            utils.uint2str(_epochs[0]),
            utils.uint2str(_epochs[1]),
            utils.uint2str(_epochs[2]),
            utils.uint2str(_epochs[3])
        );
        string memory _seed2 = string.concat(
            utils.uint2str(_epochs[4]),
            utils.uint2str(_epochs[5]),
            utils.uint2str(_epochs[6]),
            utils.uint2str(_epochs[7])
        );
        string memory _seed3 = string.concat(
            utils.uint2str(_epochs[8]),
            utils.uint2str(_epochs[9]),
            utils.uint2str(_epochs[10]),
            utils.uint2str(_epochs[11])
        );
        return string.concat(_seed1, _seed2, _seed3);
    }

    function filter(uint256[12] memory _epochs)
        internal
        view
        returns (string memory)
    {
        return
            svg.el(
                'filter',
                string.concat(svg.prop('id', 'b')),
                string.concat(
                    svg.el(
                        'feTurbulence',
                        string.concat(
                            svg.prop(
                                'baseFrequency',
                                string.concat('0.', utils.uint2str(_epochs[0]))
                            ),
                            svg.prop('seed', utils.uint2str(block.number))
                        )
                    ),
                    svg.el(
                        'feColorMatrix',
                        string.concat(
                            svg.prop(
                                'values',
                                '0 0 0 9 -5 0 0 0 9 -5 0 0 0 9 -5 0 0 0 0 1'
                            ),
                            svg.prop('result', 's')
                        )
                    ),
                    svg.el(
                        'feTurbulence',
                        string.concat(
                            svg.prop('type', 'fractalNoise'),
                            svg.prop(
                                'baseFrequency',
                                string.concat(
                                    '0.0',
                                    utils.uint2str(_epochs[7]),
                                    utils.uint2str(_epochs[0])
                                )
                            ),
                            svg.prop('numOctaves', utils.uint2str(_epochs[1])),
                            svg.prop('seed', seed(_epochs))
                        )
                    ),
                    svg.el(
                        'feDisplacementMap',
                        string.concat(
                            svg.prop('in', 'SourceGraphic'),
                            svg.prop(
                                'scale',
                                string.concat(
                                    utils.uint2str(_epochs[0]),
                                    utils.uint2str(_epochs[2])
                                )
                            )
                        )
                    ),
                    svg.el(
                        'feBlend',
                        string.concat(
                            svg.prop('in', 's'),
                            svg.prop('mode', 'screen')
                        )
                    )
                )
            );
    }

    function getDescription(string memory _add, uint256[12] memory _epochs)
        internal
        view
        returns (string memory)
    {
        return
            string.concat(
                '"description": "A nebulaeth discovered  in ',
                epochLabels[6],
                ' ',
                utils.uint2str(_epochs[6]),
                ' ',
                epochLabels[5],
                ' ',
                utils.uint2str(_epochs[5]),
                ' ',
                epochLabels[4],
                ' ',
                utils.uint2str(_epochs[4]),
                ' by ',
                _add,
                '.\\n\\n##[nebulaeth.space](https://nebulaeth.space)\\n\\n[epochs.cosmiccomputation.org](https://epochs.cosmiccomputation.org)"'
            );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

// Core utils used extensively to format CSS and numbers.
library utils {
    // used to simulate empty strings
    string internal constant NULL = '';

    // formats a CSS variable line. includes a semicolon for formatting.
    function setCssVar(string memory _key, string memory _val)
        internal
        pure
        returns (string memory)
    {
        return string.concat('--', _key, ':', _val, ';');
    }

    // formats getting a css variable
    function getCssVar(string memory _key)
        internal
        pure
        returns (string memory)
    {
        return string.concat('var(--', _key, ')');
    }

    // formats getting a def URL
    function getDefURL(string memory _id)
        internal
        pure
        returns (string memory)
    {
        return string.concat('url(#', _id, ')');
    }

    // formats rgba white with a specified opacity / alpha
    function white_a(uint256 _a) internal pure returns (string memory) {
        return rgba(255, 255, 255, _a);
    }

    // formats rgba black with a specified opacity / alpha
    function black_a(uint256 _a) internal pure returns (string memory) {
        return rgba(0, 0, 0, _a);
    }

    // formats generic rgba color in css
    function rgba(
        uint256 _r,
        uint256 _g,
        uint256 _b,
        uint256 _a
    ) internal pure returns (string memory) {
        string memory formattedA = _a < 100
            ? string.concat('0.', utils.uint2str(_a))
            : '1';
        return
            string.concat(
                'rgba(',
                utils.uint2str(_r),
                ',',
                utils.uint2str(_g),
                ',',
                utils.uint2str(_b),
                ',',
                formattedA,
                ')'
            );
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

    // converts an unsigned integer to a string
    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return '0';
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

    // gets slice from string
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
        uint256 multiplier,
        string memory keyPrefix,
        string[7] memory sourceArray
    ) internal pure returns (string memory) {
        uint256 rand = random(
            string(abi.encodePacked(keyPrefix, uint2str(multiplier)))
        );
        string memory output = sourceArray[rand % sourceArray.length];
        output = string(abi.encodePacked(output));
        return output;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import './Utils.sol';

// Core SVG utilitiy library which helps us construct
// onchain SVG's with a simple, web-like API.
library svg {
    /* MAIN ELEMENTS */
    function g(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('g', _props, _children);
    }

    function path(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('path', _props, _children);
    }

    function text(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('text', _props, _children);
    }

    function line(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('line', _props, _children);
    }

    function circle(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('circle', _props, _children);
    }

    function circle(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el('circle', _props);
    }

    function rect(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('rect', _props, _children);
    }

    function rect(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el('rect', _props);
    }

    function filter(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('filter', _props, _children);
    }

    function cdata(string memory _content)
        internal
        pure
        returns (string memory)
    {
        return string.concat('<![CDATA[', _content, ']]>');
    }

    /* GRADIENTS */
    function radialGradient(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('radialGradient', _props, _children);
    }

    function linearGradient(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('linearGradient', _props, _children);
    }

    function gradientStop(
        uint256 offset,
        string memory stopColor,
        string memory _props
    ) internal pure returns (string memory) {
        return
            el(
                'stop',
                string.concat(
                    prop('stop-color', stopColor),
                    ' ',
                    prop('offset', string.concat(utils.uint2str(offset), '%')),
                    ' ',
                    _props
                )
            );
    }

    function animateTransform(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el('animateTransform', _props);
    }

    function image(string memory _href, string memory _props)
        internal
        pure
        returns (string memory)
    {
        return
            el(
                'image',
                string.concat(prop('href', _href), ' ', _props)
            );
    }

    /* COMMON */
    // A generic element, can be used to construct any SVG (or HTML) element
    function el(
        string memory _tag,
        string memory _props,
        string memory _children
    ) internal pure returns (string memory) {
        return
            string.concat(
                '<',
                _tag,
                ' ',
                _props,
                '>',
                _children,
                '</',
                _tag,
                '>'
            );
    }

    // A generic element, can be used to construct any SVG (or HTML) element without children
    function el(
        string memory _tag,
        string memory _props
    ) internal pure returns (string memory) {
        return
            string.concat(
                '<',
                _tag,
                ' ',
                _props,
                '/>'
            );
    }

    // an SVG attribute
    function prop(string memory _key, string memory _val)
        internal
        pure
        returns (string memory)
    {
        return string.concat(_key, '=', '"', _val, '" ');
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