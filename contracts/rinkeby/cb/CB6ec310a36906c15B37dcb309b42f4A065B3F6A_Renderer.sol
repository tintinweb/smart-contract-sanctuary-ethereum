//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import './SVG.sol';
import './Utils.sol';

contract Renderer {
    string[] private wordsList = [
        "you are the light",
        "love yourself",
        "you've got this",
        "nothing will stop you",
        "you're the best",
        "believe",
        "you are worthy",
        "trust the process",
        "remember why you're here",
        "thank you for being you",
        "you're beautiful",
        "beloved",
        "you're amazing",
        "keep going",
        "it'll all be ok",
        "endure",
        "dream big",
        "believe in yourself",
        "yes, you can",
        "love your friends",
        "live laugh love",
        "prove them wrong",
        "you excite me",
        "just keep swimming",
        "hold on to hope"
    ];

    function gradientColor1(uint256 _tokenId) public pure returns (string memory) {
        return string.concat("hsla(", utils.uint2str(_tokenId), ", 70%, 80%, 0.8)");
    }

    function gradientColor2(uint256 _tokenId) public pure returns (string memory) {
        return string.concat("hsla(", utils.uint2str(_tokenId + 100), ", 70%, 80%, 0.6)");
    }

    function wordText(uint256 _tokenId) public view returns (string memory) {
        return wordsList[_tokenId % wordsList.length];
    }

    function render(uint256 _tokenId) public view returns (string memory) {
        return string.concat(
            '<svg width="320px" height="320px" viewBox="0 0 320 320" xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges" style="border-radius:10px">',
            svg.el(
                'defs',
                utils.NULL,
                svg.linearGradient(
                    string.concat(
                        svg.prop('id', 'linearGradient'),
                        svg.prop('gradientTransform', 'rotate(90)')
                    ),
                    string.concat(
                        svg.gradientStop(
                            20,
                            gradientColor1(_tokenId),
                            utils.NULL
                        ),
                        svg.gradientStop(
                            50,
                            gradientColor2(_tokenId),
                            utils.NULL
                        )
                    ) 
                )
            ),
            svg.rect(
                string.concat(
                    svg.prop('width', '320'),
                    svg.prop('height', '320'),
                    svg.prop('fill', utils.getDefURL('linearGradient'))
                ),
                utils.NULL
            ),
            svg.path(
                svg.prop('id', 'textPath'),
                svg.el(
                    'animate',
                    string.concat(
                        svg.prop('attributeName', 'd'),
                        svg.prop('from', 'm0,110 h0'),
                        svg.prop('to', 'm0,110 h1100'),
                        svg.prop('dur', '4s'),
                        svg.prop('begin', '0s'),
                        svg.prop('repeatCount', 'indefinite')
                    )
                )
            ),
            svg.text(
                string.concat(
                    svg.prop('fill', 'black'),
                    svg.prop('font-family', 'monospace'),
                    svg.prop('font-size', '24px'),
                    svg.prop('x', '50%'),
                    svg.prop('y', '0%'),
                    svg.prop('dominant-baseline', 'middle'),
                    svg.prop('text-anchor', 'middle')
                ),
                svg.el(
                    'textPath',
                    svg.prop('href', '#textPath'),
                    wordText(_tokenId)
                )
            ),
            '</svg>'
        );
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
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
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
}