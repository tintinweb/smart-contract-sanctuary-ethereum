//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {ERC721_address_specific} from './ERC721_address_specific.sol';
import {svg} from './SVG.sol';
import {json} from './JSON.sol';
import {utils} from './Utils.sol';
import {WordWrap} from './WordWrap.sol';

contract LockNote is ERC721_address_specific {
    

    uint256 constant MAX_MESSAGE = 280;
    uint256 MESSAGE_PRICE = 0.0042069 ether; 

    constructor () ERC721_address_specific("Lock Note", unicode"🔏"){}

    struct MESSAGE {
        string text;
        address sender;
    }

    mapping (uint256 => MESSAGE) public messages;

    function tokenURI(uint256 id) public view override returns (string memory) {
        require(ownerOf(id) == getAddressfromId(id), "NOT MINTED");
        MESSAGE memory _message = messages[id];

        WordWrap.WordWrapInfo memory bodyTextFormatting = WordWrap.WordWrapInfo({
            line_width: 30,
            x: 10,
            yFirst: 55,
            spacing: 20 
        });

        return json.formattedMetadata(
            'Lock Note',
            'Lock Note is an NFT based messaging application. Users can mint a message up to 280 characters long to any address, which can only be burned by the owner of that address. Have fun with Lock Note however you like.',
            svg._svg(
                    'width="350" height="215"', //style="background: gainsboro; box-shadow: 0 0 0 3px rgba(169,169,169,1)',
                    svg.text(
                            'font-family="monospace" font-size="14px" fill="steelblue"',
                            WordWrap.toElement(_message.text, bodyTextFormatting)
                        )
                    
                    /*string.concat(
                        svg.text(
                            'x="269" y="20" font-family="sans-serif" font-size="12px" font-style="italic"',
                            unicode'Lock Note'
                        ),
                        svg.text(
                            'x="10" y="35" font-family="sans-serif" font-size="12px" font-style="italic"',
                            utils.toHexString(getIdfromAddress(_message.sender))
                        ),
                        svg.text(
                            'font-family="monospace" font-size="14px" fill="steelblue"',
                            WordWrap.toElement(_message.text, bodyTextFormatting)
                        )
                    )*/
            )
        );
    }

    function getIdfromAddress(address user) public pure returns (uint256) {
        return uint256(uint160(user));
    }

    function getAddressfromId(uint256 id) public pure returns (address) {
        return address(uint160(id));
    }

    function readText(address user) public view returns (string memory) {
        require(balanceOf(user) != 0, "NOT MINTED");

        return messages[getIdfromAddress(user)].text;
    }

    function readSender(address user) public view returns (address) {
        require(balanceOf(user) != 0, "NOT MINTED");

        return messages[getIdfromAddress(user)].sender;
    }

    function mint(address to, string memory message) public payable {
        require(utils.utfStringLength(message) <= MAX_MESSAGE, 'MSG TOO LONG');
        uint256 _id = getIdfromAddress(to);
        messages[_id].text = message;
        messages[_id].sender = msg.sender;
        _mint(to, _id);
    }

    function burn() public payable {
        uint256 _id = getIdfromAddress(msg.sender);
        messages[_id].text = ' ';
        messages[_id].sender = address(0);
        _burn(_id);
    }

    // Need to add treasury functions



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

    function tspan(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('tspan', _props, _children);
    }

    function tspan(string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('tspan', '', _children);
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

    // Opensea will not render foreignObjects as of 29 Apr 2022
    function foreignObject(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('foreignObject', _props, _children);
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

    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.13;

import {utils} from '../src/Utils.sol';
import {svg} from './SVG.sol';
import {strings} from 'stringUtils/strings.sol';

library WordWrap {
    using strings for *;

    struct WordWrapInfo {
        uint256 line_width;
        uint256 x;
        uint256 yFirst;
        uint256 spacing;
    }


    //yields and error if the first word is more than line_width Char long.
    function toArray(string memory _raw_text, uint256 _line_width) internal pure returns (string[] memory) {

        strings.slice memory s = _raw_text.toSlice();
        strings.slice memory delim = ' '.toSlice();
        string[] memory words  = new string[](s.count(delim));
        string[] memory completedLines = new string[](10); //set to max number of lines possible

        string memory nextLine = s.split(delim).toString();
        uint256 wordLength;
        uint256 nextLineLength;
        uint256 j = 0;

        for(uint256 i = 0; i < words.length; i++) {
            words[i] = s.split(delim).toString();
        }

        for(uint256 i = 0; i < words.length; i++) {
            wordLength = utils.utfStringLength(words[i]);
            if(wordLength > _line_width) {
                completedLines[j] = nextLine;
                j++;
                completedLines[j] = words[i];
                j++;
                nextLine = '';
                nextLineLength = 0;
            } else if ((nextLineLength + wordLength) >= _line_width) {
                completedLines[j] = nextLine;
                j++;
                nextLine = words[i];
                nextLineLength = 0;
            } else {
                nextLine = string.concat(
                    nextLine,
                    ' ',
                    words[i]
                );
                nextLineLength += wordLength;
                if (i == (words.length - 1)) {
                    completedLines[j] = nextLine;
                    // if we don't need the entire max array setup another and return just that.
                    string[] memory completedLinesShorter = new string[](j+1);
                    for (uint256 k = 0; k <= j; k++) {
                        completedLinesShorter[k] = completedLines[k];
                    }
                    return completedLinesShorter;
                }
            }
        }

        return completedLines;

    }
    
    function toElement(string memory raw_text, WordWrapInfo memory formatting) pure internal returns (string memory) {

        string memory el;
        string[] memory arrayText = toArray(raw_text, formatting.line_width);

        string memory xProp = svg.prop('x', utils.toString(formatting.x));

        for (uint256 i = 0; i<arrayText.length; i++) {
            el = string.concat(
                el,
                svg.tspan(
                    string.concat(
                        xProp,
                        svg.prop('y', utils.toString(formatting.yFirst + (i * formatting.spacing)), true)
                    ),
                    arrayText[i]
                )
            );
        }

        return el;

    }



    /*

    <tspan x={0} dy={index === 0 ? 0 : 14}>
    {word}
  </tspan>

  */

}

/*
 * @title String & slice utility library for Solidity contracts.
 * @author Nick Johnson <[email protected]>
 *
 * @dev Functionality in this library is largely implemented using an
 *      abstraction called a 'slice'. A slice represents a part of a string -
 *      anything from the entire string to a single character, or even no
 *      characters at all (a 0-length slice). Since a slice only has to specify
 *      an offset and a length, copying and manipulating slices is a lot less
 *      expensive than copying and manipulating the strings they reference.
 *
 *      To further reduce gas costs, most functions on slice that need to return
 *      a slice modify the original one instead of allocating a new one; for
 *      instance, `s.split(".")` will return the text up to the first '.',
 *      modifying s to only contain the remainder of the string after the '.'.
 *      In situations where you do not want to modify the original slice, you
 *      can make a copy first with `.copy()`, for example:
 *      `s.copy().split(".")`. Try and avoid using this idiom in loops; since
 *      Solidity has no memory management, it will result in allocating many
 *      short-lived slices that are later discarded.
 *
 *      Functions that return two slices come in two versions: a non-allocating
 *      version that takes the second slice as an argument, modifying it in
 *      place, and an allocating version that allocates and returns the second
 *      slice; see `nextRune` for example.
 *
 *      Functions that have to copy string data will return strings rather than
 *      slices; these can be cast back to slices for further processing if
 *      required.
 *
 *      For convenience, some functions are provided with non-modifying
 *      variants that create a new slice and return both; for instance,
 *      `s.splitNew('.')` leaves s unmodified, and returns two values
 *      corresponding to the left and right parts of the string.
 */

pragma solidity ^0.8.0;

library strings {
    struct slice {
        uint _len;
        uint _ptr;
    }

    function memcpy(uint dest, uint src, uint len) private pure {
        // Copy word-length chunks while possible
        for(; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = type(uint).max;
        if (len > 0) {
            mask = 256 ** (32 - len) - 1;
        }
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /*
     * @dev Returns a slice containing the entire string.
     * @param self The string to make a slice from.
     * @return A newly allocated slice containing the entire string.
     */
    function toSlice(string memory self) internal pure returns (slice memory) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    /*
     * @dev Returns the length of a null-terminated bytes32 string.
     * @param self The value to find the length of.
     * @return The length of the string, from 0 to 32.
     */
    function len(bytes32 self) internal pure returns (uint) {
        uint ret;
        if (self == 0)
            return 0;
        if (uint(self) & type(uint128).max == 0) {
            ret += 16;
            self = bytes32(uint(self) / 0x100000000000000000000000000000000);
        }
        if (uint(self) & type(uint64).max == 0) {
            ret += 8;
            self = bytes32(uint(self) / 0x10000000000000000);
        }
        if (uint(self) & type(uint32).max == 0) {
            ret += 4;
            self = bytes32(uint(self) / 0x100000000);
        }
        if (uint(self) & type(uint16).max == 0) {
            ret += 2;
            self = bytes32(uint(self) / 0x10000);
        }
        if (uint(self) & type(uint8).max == 0) {
            ret += 1;
        }
        return 32 - ret;
    }

    /*
     * @dev Returns a slice containing the entire bytes32, interpreted as a
     *      null-terminated utf-8 string.
     * @param self The bytes32 value to convert to a slice.
     * @return A new slice containing the value of the input argument up to the
     *         first null.
     */
    function toSliceB32(bytes32 self) internal pure returns (slice memory ret) {
        // Allocate space for `self` in memory, copy it there, and point ret at it
        assembly {
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, 0x20))
            mstore(ptr, self)
            mstore(add(ret, 0x20), ptr)
        }
        ret._len = len(self);
    }

    /*
     * @dev Returns a new slice containing the same data as the current slice.
     * @param self The slice to copy.
     * @return A new slice containing the same data as `self`.
     */
    function copy(slice memory self) internal pure returns (slice memory) {
        return slice(self._len, self._ptr);
    }

    /*
     * @dev Copies a slice to a new string.
     * @param self The slice to copy.
     * @return A newly allocated string containing the slice's text.
     */
    function toString(slice memory self) internal pure returns (string memory) {
        string memory ret = new string(self._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }

    /*
     * @dev Returns the length in runes of the slice. Note that this operation
     *      takes time proportional to the length of the slice; avoid using it
     *      in loops, and call `slice.empty()` if you only need to know whether
     *      the slice is empty or not.
     * @param self The slice to operate on.
     * @return The length of the slice in runes.
     */
    function len(slice memory self) internal pure returns (uint l) {
        // Starting at ptr-31 means the LSB will be the byte we care about
        uint ptr = self._ptr - 31;
        uint end = ptr + self._len;
        for (l = 0; ptr < end; l++) {
            uint8 b;
            assembly { b := and(mload(ptr), 0xFF) }
            if (b < 0x80) {
                ptr += 1;
            } else if(b < 0xE0) {
                ptr += 2;
            } else if(b < 0xF0) {
                ptr += 3;
            } else if(b < 0xF8) {
                ptr += 4;
            } else if(b < 0xFC) {
                ptr += 5;
            } else {
                ptr += 6;
            }
        }
    }

    /*
     * @dev Returns true if the slice is empty (has a length of 0).
     * @param self The slice to operate on.
     * @return True if the slice is empty, False otherwise.
     */
    function empty(slice memory self) internal pure returns (bool) {
        return self._len == 0;
    }

    /*
     * @dev Returns a positive number if `other` comes lexicographically after
     *      `self`, a negative number if it comes before, or zero if the
     *      contents of the two slices are equal. Comparison is done per-rune,
     *      on unicode codepoints.
     * @param self The first slice to compare.
     * @param other The second slice to compare.
     * @return The result of the comparison.
     */
    function compare(slice memory self, slice memory other) internal pure returns (int) {
        uint shortest = self._len;
        if (other._len < self._len)
            shortest = other._len;

        uint selfptr = self._ptr;
        uint otherptr = other._ptr;
        for (uint idx = 0; idx < shortest; idx += 32) {
            uint a;
            uint b;
            assembly {
                a := mload(selfptr)
                b := mload(otherptr)
            }
            if (a != b) {
                // Mask out irrelevant bytes and check again
                uint mask = type(uint).max; // 0xffff...
                if(shortest < 32) {
                  mask = ~(2 ** (8 * (32 - shortest + idx)) - 1);
                }
                unchecked {
                    uint diff = (a & mask) - (b & mask);
                    if (diff != 0)
                        return int(diff);
                }
            }
            selfptr += 32;
            otherptr += 32;
        }
        return int(self._len) - int(other._len);
    }

    /*
     * @dev Returns true if the two slices contain the same text.
     * @param self The first slice to compare.
     * @param self The second slice to compare.
     * @return True if the slices are equal, false otherwise.
     */
    function equals(slice memory self, slice memory other) internal pure returns (bool) {
        return compare(self, other) == 0;
    }

    /*
     * @dev Extracts the first rune in the slice into `rune`, advancing the
     *      slice to point to the next rune and returning `self`.
     * @param self The slice to operate on.
     * @param rune The slice that will contain the first rune.
     * @return `rune`.
     */
    function nextRune(slice memory self, slice memory rune) internal pure returns (slice memory) {
        rune._ptr = self._ptr;

        if (self._len == 0) {
            rune._len = 0;
            return rune;
        }

        uint l;
        uint b;
        // Load the first byte of the rune into the LSBs of b
        assembly { b := and(mload(sub(mload(add(self, 32)), 31)), 0xFF) }
        if (b < 0x80) {
            l = 1;
        } else if(b < 0xE0) {
            l = 2;
        } else if(b < 0xF0) {
            l = 3;
        } else {
            l = 4;
        }

        // Check for truncated codepoints
        if (l > self._len) {
            rune._len = self._len;
            self._ptr += self._len;
            self._len = 0;
            return rune;
        }

        self._ptr += l;
        self._len -= l;
        rune._len = l;
        return rune;
    }

    /*
     * @dev Returns the first rune in the slice, advancing the slice to point
     *      to the next rune.
     * @param self The slice to operate on.
     * @return A slice containing only the first rune from `self`.
     */
    function nextRune(slice memory self) internal pure returns (slice memory ret) {
        nextRune(self, ret);
    }

    /*
     * @dev Returns the number of the first codepoint in the slice.
     * @param self The slice to operate on.
     * @return The number of the first codepoint in the slice.
     */
    function ord(slice memory self) internal pure returns (uint ret) {
        if (self._len == 0) {
            return 0;
        }

        uint word;
        uint length;
        uint divisor = 2 ** 248;

        // Load the rune into the MSBs of b
        assembly { word:= mload(mload(add(self, 32))) }
        uint b = word / divisor;
        if (b < 0x80) {
            ret = b;
            length = 1;
        } else if(b < 0xE0) {
            ret = b & 0x1F;
            length = 2;
        } else if(b < 0xF0) {
            ret = b & 0x0F;
            length = 3;
        } else {
            ret = b & 0x07;
            length = 4;
        }

        // Check for truncated codepoints
        if (length > self._len) {
            return 0;
        }

        for (uint i = 1; i < length; i++) {
            divisor = divisor / 256;
            b = (word / divisor) & 0xFF;
            if (b & 0xC0 != 0x80) {
                // Invalid UTF-8 sequence
                return 0;
            }
            ret = (ret * 64) | (b & 0x3F);
        }

        return ret;
    }

    /*
     * @dev Returns the keccak-256 hash of the slice.
     * @param self The slice to hash.
     * @return The hash of the slice.
     */
    function keccak(slice memory self) internal pure returns (bytes32 ret) {
        assembly {
            ret := keccak256(mload(add(self, 32)), mload(self))
        }
    }

    /*
     * @dev Returns true if `self` starts with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function startsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        if (self._ptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let selfptr := mload(add(self, 0x20))
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }
        return equal;
    }

    /*
     * @dev If `self` starts with `needle`, `needle` is removed from the
     *      beginning of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function beyond(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        bool equal = true;
        if (self._ptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let selfptr := mload(add(self, 0x20))
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
            self._ptr += needle._len;
        }

        return self;
    }

    /*
     * @dev Returns true if the slice ends with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function endsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        uint selfptr = self._ptr + self._len - needle._len;

        if (selfptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }

        return equal;
    }

    /*
     * @dev If `self` ends with `needle`, `needle` is removed from the
     *      end of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function until(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        uint selfptr = self._ptr + self._len - needle._len;
        bool equal = true;
        if (selfptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
        }

        return self;
    }

    // Returns the memory address of the first byte of the first occurrence of
    // `needle` in `self`, or the first byte after `self` if not found.
    function findPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr = selfptr;
        uint idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask;
                if (needlelen > 0) {
                    mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));
                }

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                uint end = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr >= end)
                        return selfptr + selflen;
                    ptr++;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }

                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }

    // Returns the memory address of the first byte after the last occurrence of
    // `needle` in `self`, or the address of `self` if not found.
    function rfindPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask;
                if (needlelen > 0) {
                    mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));
                }

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                ptr = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr <= selfptr)
                        return selfptr;
                    ptr--;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr + needlelen;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }
                ptr = selfptr + (selflen - needlelen);
                while (ptr >= selfptr) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr + needlelen;
                    ptr -= 1;
                }
            }
        }
        return selfptr;
    }

    /*
     * @dev Modifies `self` to contain everything from the first occurrence of
     *      `needle` to the end of the slice. `self` is set to the empty slice
     *      if `needle` is not found.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function find(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len -= ptr - self._ptr;
        self._ptr = ptr;
        return self;
    }

    /*
     * @dev Modifies `self` to contain the part of the string from the start of
     *      `self` to the end of the first occurrence of `needle`. If `needle`
     *      is not found, `self` is set to the empty slice.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function rfind(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len = ptr - self._ptr;
        return self;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and `token` to everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function split(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = self._ptr;
        token._len = ptr - self._ptr;
        if (ptr == self._ptr + self._len) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
            self._ptr = ptr + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and returning everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` up to the first occurrence of `delim`.
     */
    function split(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        split(self, needle, token);
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and `token` to everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function rsplit(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = ptr;
        token._len = self._len - (ptr - self._ptr);
        if (ptr == self._ptr) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and returning everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` after the last occurrence of `delim`.
     */
    function rsplit(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        rsplit(self, needle, token);
    }

    /*
     * @dev Counts the number of nonoverlapping occurrences of `needle` in `self`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return The number of occurrences of `needle` found in `self`.
     */
    function count(slice memory self, slice memory needle) internal pure returns (uint cnt) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) + needle._len;
        while (ptr <= self._ptr + self._len) {
            cnt++;
            ptr = findPtr(self._len - (ptr - self._ptr), ptr, needle._len, needle._ptr) + needle._len;
        }
    }

    /*
     * @dev Returns True if `self` contains `needle`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return True if `needle` is found in `self`, false otherwise.
     */
    function contains(slice memory self, slice memory needle) internal pure returns (bool) {
        return rfindPtr(self._len, self._ptr, needle._len, needle._ptr) != self._ptr;
    }

    /*
     * @dev Returns a newly allocated string containing the concatenation of
     *      `self` and `other`.
     * @param self The first slice to concatenate.
     * @param other The second slice to concatenate.
     * @return The concatenation of the two strings.
     */
    function concat(slice memory self, slice memory other) internal pure returns (string memory) {
        string memory ret = new string(self._len + other._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }

    /*
     * @dev Joins an array of slices, using `self` as a delimiter, returning a
     *      newly allocated string.
     * @param self The delimiter to use.
     * @param parts A list of slices to join.
     * @return A newly allocated string containing all the slices in `parts`,
     *         joined with `self`.
     */
    function join(slice memory self, slice[] memory parts) internal pure returns (string memory) {
        if (parts.length == 0)
            return "";

        uint length = self._len * (parts.length - 1);
        for(uint i = 0; i < parts.length; i++)
            length += parts[i]._len;

        string memory ret = new string(length);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        for(uint i = 0; i < parts.length; i++) {
            memcpy(retptr, parts[i]._ptr, parts[i]._len);
            retptr += parts[i]._len;
            if (i < parts.length - 1) {
                memcpy(retptr, self._ptr, self._len);
                retptr += self._len;
            }
        }

        return ret;
    }
}