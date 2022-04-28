//SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {ERC721_address_specific} from './ERC721_address_specific.sol';
import {svg} from './SVG.sol';
import {json} from './JSON.sol';
import {utils} from './Utils.sol';

contract ntnft is ERC721_address_specific {

    constructor () ERC721_address_specific("ntnft", unicode"🔐"){}

    function tokenURI(uint256 id) public view override returns (string memory) {
        require(ownerOf(id) == getAddressfromId(id), "NOT MINTED");

        return json.formattedMetadata(
            'ntnft',
            'non transferrable NFT',
            svg._svg(
                    string.concat(
                        svg.prop('width', '300'),
                        svg.prop('height', '300'),
                        svg.prop('style', 'background:#000')
                    ),
                    svg.text(string.concat(
                        svg.prop('x', '20'),
                        svg.prop('y', '30'),
                        svg.prop('fill', 'white')
                        ),
                        utils.toString(id)
                    )
            )
        );
    }

    function getIdfromAddress(address user) public pure returns (uint256) {
        return uint256(uint160(user));
    }

    function getAddressfromId(uint256 id) public pure returns (address) {
        return address(uint160(id));
    }

    function mint() public {
        _mint(msg.sender, getIdfromAddress(msg.sender));
    }

    function burn() public {
        _burn(getIdfromAddress(msg.sender));
    }

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Forked from Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @notice Non transferrable unique ERC721 linked to the address of the owner 
/// @dev    The removal of ERC721 transfer logic is in defiance of the the spec

abstract contract ERC721_address_specific {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require(_balanceOf[address(uint160(id))] != 0, "NOT_MINTED");

        return address(uint160(id));
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    // No approvals, this is non transferrable and specific to the address

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    // No transfers, this is non transferrable and specific to the address

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_balanceOf[to] == 0, "ALREADY_MINTED");

        // This can only be 1 or 0
        unchecked {
            _balanceOf[to] = 1;
        }

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {

        address owner = address(uint160(id));

        require(_balanceOf[owner] == 1, "NOT_MINTED");

        // This can only be 1 or 0
        unchecked {
            _balanceOf[owner] = 0;
        }

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import {utils} from './Utils.sol';

// Core SVG utility library which helps us construct
// onchain SVG's with a simple, web-like API.
library svg {

    /* GLOBAL CONSTANTS */
    string internal constant _SVG = 'xmlns="http://www.w3.org/2000/svg"';
    string internal constant _HTML = 'xmlns="http://www.w3.org/1999/xhtml"';
    string internal constant _XMLNS = 'http://www.w3.org/2000/xmlns/ ';
    string internal constant _XLINK = 'http://www.w3.org/1999/xlink ';

    
    /* MAIN ELEMENTS */
    function g(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('g', _props, _children);
    }

    function _svg(string memory _props, string memory _children)
        internal 
        pure
        returns (string memory)
    {
        return el('svg', string.concat(_SVG, ' ', _props), _children);
    }

    function style(string memory _title, string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el('style', 
            string.concat(
                '.', 
                _title, 
                ' ', 
                _props)
            );
    }

    function path(string memory _d)
        internal
        pure
        returns (string memory)
    {
        return el('path', prop('d', _d, true));
    }

    function path(string memory _d, string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el('path', string.concat(
                                        prop('d', _d),
                                        _props
                                        )
                );
    }

    function path(string memory _d, string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el(
                'path', 
                string.concat(
                            prop('d', _d),
                            _props
                            ),
                _children
                );
    }

    function text(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('text', _props, _children);
    }

    function line(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el('line', _props);
    }

    function line(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('line', _props, _children);
    }

    function circle(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el('circle', _props);
    }

    function circle(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('circle', _props, _children);
    }

    function circle(string memory cx, string memory cy, string memory r)
        internal
        pure
        returns (string memory)
    {
        
        return el('circle', 
                string.concat(
                    prop('cx', cx),
                    prop('cy', cy),
                    prop('r', r, true)
                )
        );
    }

    function circle(string memory cx, string memory cy, string memory r, string memory _children)
        internal
        pure
        returns (string memory)
    {
        
        return el('circle', 
                string.concat(
                    prop('cx', cx),
                    prop('cy', cy),
                    prop('r', r, true)
                ),
                _children   
        );
    }

    function circle(string memory cx, string memory cy, string memory r, string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        
        return el('circle', 
                string.concat(
                    prop('cx', cx),
                    prop('cy', cy),
                    prop('r', r),
                    _props
                ),
                _children   
        );
    }

    function ellipse(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el('ellipse', _props);
    }

    function ellipse(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('ellipse', _props, _children);
    }

    function polygon(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el('polygon', _props);
    }

    function polygon(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('polygon', _props, _children);
    }

    function polyline(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el('polyline', _props);
    }

    function polyline(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('polyline', _props, _children);
    }

    function rect(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el('rect', _props);
    }

    function rect(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('rect', _props, _children);
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
                    prop('offset', string.concat(utils.toString(offset), '%')),
                    ' ',
                    _props
                ),
                utils.NULL
            );
    }

    /* ANIMATION */
    function animateTransform(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el('animateTransform', _props);
    }

    function animate(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el('animate', _props);
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

    // A generic element, can be used to construct SVG (or HTML) elements without children
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

    function prop(string memory _key, string memory _val, bool last)
        internal
        pure
        returns (string memory)
    {
        if (last) {
            return string.concat(_key, '=', '"', _val, '"');
        } else {
            return string.concat(_key, '=', '"', _val, '" ');
        }
        
    }

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// JSON utilities for base64 encoded ERC721 JSON metadata scheme
library json {
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// @dev JSON requires that double quotes be escaped or JSONs will not build correctly
    /// string.concat also requires an escape, use \\" or the constant DOUBLE_QUOTES to represent " in JSON
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////

    string constant DOUBLE_QUOTES = '\\"';

    function formattedMetadata(
        string memory name,
        string memory description,
        string memory svgImg
    )   internal
        pure
        returns (string memory)
    {
        return string.concat(
            'data:application/json;base64,',
            encode(
                bytes(
                    string.concat(
                    '{',
                    _prop('name', name),
                    _prop('description', description),
                    _xmlImage(svgImg),
                    '}'
                    )
                )
            )
        );
    }
    
    function _xmlImage(string memory _svgImg)
        internal
        pure
        returns (string memory) 
    {
        return _prop(
                        'image',
                        string.concat(
                            'data:image/svg+xml;base64,',
                            encode(bytes(_svgImg))
                        ),
                        true
        );
    }

    function _prop(string memory _key, string memory _val)
        internal
        pure
        returns (string memory)
    {
        return string.concat('"', _key, '": ', '"', _val, '", ');
    }

    function _prop(string memory _key, string memory _val, bool last)
        internal
        pure
        returns (string memory)
    {
        if(last) {
            return string.concat('"', _key, '": ', '"', _val, '"');
        } else {
            return string.concat('"', _key, '": ', '"', _val, '", ');
        }
        
    }

    function _object(string memory _key, string memory _val)
        internal
        pure
        returns (string memory)
    {
        return string.concat('"', _key, '": ', '{', _val, '}');
    }
     
     /**
     * taken from Openzeppelin
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

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
            ? string.concat('0.', utils.toString(_a))
            : '1';
        return
            string.concat(
                'rgba(',
                utils.toString(_r),
                ',',
                utils.toString(_g),
                ',',
                utils.toString(_b),
                ',',
                formattedA,
                ')'
            );
    }

    function cssBraces(
        string memory _attribute, 
        string memory _value
    )   internal
        pure
        returns (string memory)
    {
        return string.concat(
            ' {',
            _attribute,
            ': ',
            _value,
            '}'
        );
    }

    function cssBraces(
        string[] memory _attributes, 
        string[] memory _values
    )   internal
        pure
        returns (string memory)
    {
        require(_attributes.length == _values.length, "Utils: Unbalanced Arrays");
        
        uint256 len = _attributes.length;

        string memory results = ' {';

        for (uint256 i = 0; i<len; i++) {
            results = string.concat(
                                    results, 
                                    _attributes[i],
                                    ': ',
                                    _values[i],
                                     '; '
                                    );
                                    
        }

        return string.concat(results, '}');
    }

    //deals with integers (i.e. no decimals)
    function points(uint256[2][] memory pointsArray) internal pure returns (string memory) {
        require(pointsArray.length >= 3, "Utils: Array too short");

        uint256 len = pointsArray.length-1;


        string memory results = 'points="';

        for (uint256 i=0; i<len; i++){
            results = string.concat(
                                    results, 
                                    toString(pointsArray[i][0]), 
                                    ',', 
                                    toString(pointsArray[i][1]),
                                    ' '
                                    );
        }

        return string.concat(
                            results, 
                            toString(pointsArray[len][0]), 
                            ',', 
                            toString(pointsArray[len][1]),
                            '"'
                            );
    }

    // allows for a uniform precision to be applied to all points 
    function points(uint256[2][] memory pointsArray, uint256 decimalPrecision) internal pure returns (string memory) {
        require(pointsArray.length >= 3, "Utils: Array too short");

        uint256 len = pointsArray.length-1;


        string memory results = 'points="';

        for (uint256 i=0; i<len; i++){
            results = string.concat(
                                    results, 
                                    toString(pointsArray[i][0], decimalPrecision), 
                                    ',', 
                                    toString(pointsArray[i][1], decimalPrecision),
                                    ' '
                                    );
        }

        return string.concat(
                            results, 
                            toString(pointsArray[len][0], decimalPrecision), 
                            ',', 
                            toString(pointsArray[len][1], decimalPrecision),
                            '"'
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

     /**
     * taken from Openzeppelin
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

        // allows the insertion of a decimal point in the returned string at precision
    function toString(uint256 value, uint256 precision) internal pure returns (string memory) {
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
        require(precision <= digits && precision > 0, "Utils: precision invalid");
        precision == digits ? digits +=2 : digits++; //adds a space for the decimal point, 2 if it is the whole uint
        
        uint256 decimalPlacement = digits - precision - 1;
        bytes memory buffer = new bytes(digits);
        
        buffer[decimalPlacement] = 0x2E; // add the decimal point, ASCII 46/hex 2E
        if (decimalPlacement == 1) {
            buffer[0] = 0x30;
        }
        
        while (value != 0) {
            digits -= 1;
            if (digits != decimalPlacement) {
                buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
                value /= 10;
            }
        }

        return string(buffer);
    }

}