// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "base64/base64.sol";
import "./Image.sol";
import "./HotChainSVG.sol";

contract MetadataV1 is Image, Metadata {
    function uri(uint256 tokenId, string memory name)
        external
        pure
        returns (string memory)
    {
        address collection = address(uint160(tokenId));
        uint96 value = uint96(tokenId >> 160);
        uint8 level = getLevel(value);

        string memory image = Base64.encode(
            bytes(render(name, collection, level))
        );
        string memory json = string.concat(
            '{"name":"',
            escape(name),
            ' is using Hot Chain SVG","attributes":[{"trait_type":"Level","value":',
            utils.uint2str(level + 1),
            '}],"image": "data:image/svg+xml;base64,',
            image,
            '"}'
        );
        return
            string.concat(
                "data:application/json;base64,",
                Base64.encode(bytes(json))
            );
    }

    function escape(string memory name) internal pure returns (string memory) {
        bytes memory chars = bytes(name);
        for (uint256 i = 0; i < chars.length; i++) {
            if (uint8(chars[i]) == 34) {
                chars[i] = bytes1(uint8(39));
            }
        }
        return name;
    }

    function getLevel(uint96 value) internal pure returns (uint8) {
        if (value >= 2 ether) {
            return 4;
        }
        if (value >= 1 ether) {
            return 3;
        }
        if (value >= 0.1 ether) {
            return 2;
        }
        if (value >= 0.01 ether) {
            return 1;
        }
        return 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

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
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "base64/base64.sol";
import "./SVG.sol";
import "./Utils.sol";
import "./TinierFont.sol";

contract Image {
    function render(
        string memory name,
        address collection,
        uint8 level
    ) public pure returns (string memory) {
        string[2][5] memory levels = [
            ["#AAAAAA", "#424242"],
            ["#4E7AD4", "#70DA99"],
            ["#E5C075", "#70DA99"],
            ["#F1CD89", "#9943D1"],
            ["#F9F365", "#F27400"]
        ];
        string memory startColor = levels[level][0];
        string memory stopColor = levels[level][1];

        return
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" width="350" height="350" style="background:#000;font-family:Courier New">',
                styles(),
                logo(),
                info(name, collection),
                svg.el(
                    "defs",
                    "",
                    svg.el(
                        "linearGradient",
                        string.concat(
                            svg.prop("id", "grd"),
                            svg.prop("x1", "0"),
                            svg.prop("y1", "0"),
                            svg.prop("x2", "180"),
                            svg.prop("y2", "180"),
                            svg.prop("gradientUnits", "userSpaceOnUse")
                        ),
                        string.concat(
                            svg.el("stop", svg.prop("stop-color", startColor)),
                            svg.el(
                                "stop",
                                string.concat(
                                    svg.prop("stop-color", stopColor),
                                    svg.prop("offset", "1")
                                )
                            )
                        )
                    )
                ),
                "</svg>"
            );
    }

    function tinierFontData() public pure returns (bytes memory) {
        return TinierFont.fontdata;
    }

    function tinierFontBase64() public pure returns (string memory) {
        return
            string.concat(
                "data:font/ttf;base64,",
                string(Base64.encode(TinierFont.fontdata))
            );
    }

    function tinierFontFace() public pure returns (string memory) {
        return
            string.concat(
                '@font-face{font-family:tinier;src:url("',
                tinierFontBase64(),
                '" format(ttf);}'
            );
    }

    function styles() internal pure returns (string memory) {
        return svg.el("style", "", tinierFontFace());
    }

    function logo() internal pure returns (string memory) {
        return
            string.concat(
                svg.el(
                    "mask",
                    string.concat(svg.prop("id", "hot_mask")),
                    string.concat(
                        svg.text(
                            string.concat(
                                svg.prop("x", "20"),
                                svg.prop("y", "50"),
                                svg.prop("font-size", "49"),
                                svg.prop("fill", "white")
                            ),
                            "HOT"
                        ),
                        svg.text(
                            string.concat(
                                svg.prop("x", "20"),
                                svg.prop("y", "90"),
                                svg.prop("font-size", "49"),
                                svg.prop("fill", "white")
                            ),
                            "CHAIN"
                        ),
                        svg.text(
                            string.concat(
                                svg.prop("x", "20"),
                                svg.prop("y", "130"),
                                svg.prop("font-size", "49"),
                                svg.prop("fill", "white")
                            ),
                            "SVG"
                        )
                    )
                ),
                svg.g(
                    svg.prop("mask", "url(#hot_mask)"),
                    svg.rect(
                        string.concat(
                            svg.prop("width", "180"),
                            svg.prop("height", "180"),
                            svg.prop("fill", "url(#grd)")
                        )
                    )
                )
            );
    }

    function info(string memory name, address collection)
        internal
        pure
        returns (string memory)
    {
        return
            string.concat(
                svg.text(
                    string.concat(
                        svg.prop("x", "20"),
                        svg.prop("y", "310"),
                        svg.prop("font-size", "20"),
                        svg.prop("font-family", "tinier"),
                        svg.prop("fill", "#ABABAB")
                    ),
                    string.concat("<![CDATA[", name, "]]>")
                ),
                svg.text(
                    string.concat(
                        svg.prop("x", "20"),
                        svg.prop("y", "330"),
                        svg.prop("font-size", "12"),
                        svg.prop("fill", "#999")
                    ),
                    string.concat("0x", utils.addressToAsciiString(collection))
                )
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "solmate/auth/Owned.sol";
import "solmate/tokens/ERC1155.sol";

contract HotChainSVG is ERC1155, Owned {
    Metadata public metadata;
    mapping(address => string) public collectionName;

    event CollectionNameUpdated(address indexed collection, string name);

    constructor() Owned(msg.sender) {}

    /// @notice Mint a new "Hot Chain SVG" token
    /// @param name Name of your NFT project that uses hot-chain-svg (keep it short)
    /// @param collection Contract address of your NFT project
    function mint(string calldata name, address collection) external payable {
        uint256 tokenId = (msg.value << 160) | uint160(collection);

        if (bytes(name).length > 0) {
            if (bytes(collectionName[collection]).length == 0) {
                collectionName[collection] = name;
                emit CollectionNameUpdated(collection, name);
            }
        }

        _mint(msg.sender, tokenId, 1, "");
    }

    function burn(uint256 tokenId) external payable {
        _burn(msg.sender, tokenId, 1);
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        address collection = address(uint160(tokenId));
        return metadata.uri(tokenId, collectionName[collection]);
    }

    // Admin
    function overrideCollectionName(address addr, string calldata name)
        external
        onlyOwner
    {
        collectionName[addr] = name;
        emit CollectionNameUpdated(addr, name);
    }

    function setMetadata(Metadata _metadata) external onlyOwner {
        metadata = _metadata;
    }

    function withdrawAll() external onlyOwner {
        uint256 value = address(this).balance;
        (bool success, bytes memory message) = owner.call{value: value}("");
        require(success, string(message));
    }

    function withdrawTokens(Token token, uint256 value) external onlyOwner {
        require(token.transferFrom(address(this), owner, value));
    }
}

interface Token {
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);
}

interface Metadata {
    function uri(uint256 tokenId, string memory name)
        external
        view
        returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "./Utils.sol";

// Core SVG utilitiy library which helps us construct
// onchain SVG's with a simple, web-like API.
library svg {
    /* MAIN ELEMENTS */
    function g(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("g", _props, _children);
    }

    function path(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("path", _props, _children);
    }

    function text(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("text", _props, _children);
    }

    function line(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("line", _props, _children);
    }

    function circle(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("circle", _props, _children);
    }

    function circle(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el("circle", _props);
    }

    function rect(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("rect", _props, _children);
    }

    function rect(string memory _props) internal pure returns (string memory) {
        return el("rect", _props);
    }

    function filter(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("filter", _props, _children);
    }

    function cdata(string memory _content)
        internal
        pure
        returns (string memory)
    {
        return string.concat("<![CDATA[", _content, "]]>");
    }

    /* GRADIENTS */
    function radialGradient(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("radialGradient", _props, _children);
    }

    function linearGradient(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("linearGradient", _props, _children);
    }

    function gradientStop(
        uint256 offset,
        string memory stopColor,
        string memory _props
    ) internal pure returns (string memory) {
        return
            el(
                "stop",
                string.concat(
                    prop("stop-color", stopColor),
                    " ",
                    prop("offset", string.concat(utils.uint2str(offset), "%")),
                    " ",
                    _props
                )
            );
    }

    function animateTransform(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el("animateTransform", _props);
    }

    function image(string memory _href, string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el("image", string.concat(prop("href", _href), " ", _props));
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
                "<",
                _tag,
                " ",
                _props,
                ">",
                _children,
                "</",
                _tag,
                ">"
            );
    }

    // A generic element, can be used to construct any SVG (or HTML) element without children
    function el(string memory _tag, string memory _props)
        internal
        pure
        returns (string memory)
    {
        return string.concat("<", _tag, " ", _props, "/>");
    }

    // an SVG attribute
    function prop(string memory _key, string memory _val)
        internal
        pure
        returns (string memory)
    {
        return string.concat(_key, "=", '"', _val, '" ');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// Core utils used extensively to format CSS and numbers.
library utils {
    // used to simulate empty strings
    string internal constant NULL = "";

    // formats a CSS variable line. includes a semicolon for formatting.
    function setCssVar(string memory _key, string memory _val)
        internal
        pure
        returns (string memory)
    {
        return string.concat("--", _key, ":", _val, ";");
    }

    // formats getting a css variable
    function getCssVar(string memory _key)
        internal
        pure
        returns (string memory)
    {
        return string.concat("var(--", _key, ")");
    }

    // formats getting a def URL
    function getDefURL(string memory _id)
        internal
        pure
        returns (string memory)
    {
        return string.concat("url(#", _id, ")");
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
            ? string.concat("0.", utils.uint2str(_a))
            : "1";
        return
            string.concat(
                "rgba(",
                utils.uint2str(_r),
                ",",
                utils.uint2str(_g),
                ",",
                utils.uint2str(_b),
                ",",
                formattedA,
                ")"
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

    function addressToAsciiString(address x)
        internal
        pure
        returns (string memory)
    {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library TinierFont {
    bytes public constant fontdata =
        hex"00010000000d0080000300504646544dc9896f32000010380000001c47444546006b000400001018000000204f532f327879780e0000015800000060636d6170aee1a8f0000002a80000021267617370ffff00030000101000000008676c796648d519180000053c0000087868656164f8fce8e1000000dc00000036686865610322022e0000011400000024686d74784e470000000001b8000000ee6c6f63613e1c3bfc000004bc0000007e6d6178700044001500000138000000206e616d65205e2a0c00000db400000195706f7374af212db100000f4c000000c400010000000000008bd6dffb5f0f3cf5000b019000000000cbf554c600000000cbf554c60000ff9c01f4012c00000008000200000000000000010000012cff9c000002580000000001f400010000000000000000000000000000003900010000003e0014000500000000000100000000000000000000000000000000000401710190000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007366740000c00007007d012cff9c0000012c00640000000100000000012c012c0000002000010000000000000000008500000258000000c8000000c80000019000000190000000c80000012c0000012c0000012c000000c80000012c0000019000000190000001900000019000000190000001900000019000000190000001900000019000000190000000c80000012c000001900000019000000190000001900000019000000190000001900000019000000190000000c80000012c000001900000012c00000258000001f4000001900000012c000001f4000001900000019000000190000001900000019000000190000001900000012c000001900000012c0000012c00000190000000000000000600000000000000000003000000030000001c000100000000010c000300010000001c000400f00000000e00080002000600070022003f005d005f007dffff00000007002000260041005f0061fffffffcffe400000000ffd80000000100000000000a003c000000720000000700080009000a000b0007000c000d000c000e000f001000110012001300140015001600170018001900190009001a000a001b001c001d001e001f0020002100220023002400250026002700280029002a002b002c002d0014002e002f00300003003100320033003400350036001c001d001e001f0020002100220023002400250026002700280029002a002b0038002d0014002e002f0030000300310032003300390024003a00000106000001000000000000030102000000020000000000000000000000000000000100000405060000000708090a0b070c0d0c0e0f1011121314151617181919091a0a1b001c1d1e1f202122232425262728292a2b2c2d142e2f30033132333435360037001c1d1e1f202122232425262728292a2b382d142e2f300331323339243a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000220022002e0040005400600076008c009800a400b000c600d800e600f6010a011c012c013a014e015e016e017e018e01a401ba01ca01e001f4020402140224023802440254026e027c029a02b202ce02dc02f0030203120324033c035c03720382039203a803b803c403dc03f0040404120428043c000000050000000001f4012c00030007000b000f0013000011331523373315233b01152327331523253533156464c86464646464c86464012c64012cc8c8c864646464c8c8000001000000640064012c000300003d0133156464c8c800000002000000c8012c012c000300070000373533152b013533c864c86464c8646464000000000100000000012c012c000b000033352335333533153315231564646464646464646464646400000001000000c80064012c000300003d01331564c86464000000030000000000c8012c00030007000b00003d0133153d01331507331523646464646464646464646464640000030000000000c8012c00030007000b0000372335332b0135331d012335c8646464646464646464c864640000010000006400c8012c0003000011331523c8c8012cc80000010000000000640064000300003135331564646400000000010000006400c800c8000300003d013315c86464640000000300000000012c012c00030007000b0000313533153735331507353315646464c8646464c8646464646400000200000000012c012c0003000700003111211127333523012cc86464012cfed464640000010000000000c8012c000500003335233533116464c8c864fed400000100000000012c012c0007000033352335331533156464c864c864c8640000000100000000012c012c000b00003135333523353315331523156464c86464646464646464000000000100000000012c012c000900003d0133153335331123356464646464c86464fed46400000100000000012c012c00070000313533353315231564c86464c864c8000000000100000000012c012c0005000031113315331564c8012c64c80000000200000000012c012c0005000900003d012115233507353315012c646464c864c864c864640000000100000000012c012c00070000313533353315231564c864c864c864000000000100000000012c012c00050000011123352335012c64c8012cfed464c800000002000000000064012c00030007000031353315273533156464646464c8646400020000000000c8012c0003000700003135331527353315c8c8c86464c86464000300000000012c012c00030007000b00003d01331d0135331507353315c864c864c8646464646464646400000300000000012c012c00030007000b0000313533153d01331d01353315646464c8c8c86464c8c8c8000000000100000000012c012c000700003111331533152315c86464012c6464640000000300000000012c012c00030007000b00003d0133153d0133150733152364c8c8c8c8646464646464646400000200000000012c012c0007000b000031113315231533153d013315c8646464012c646464646464000100000000012c012c000700003111211523153315012c6464012c64646400000100000000012c012c000700003111211523152315012c6464012c64646400000100000000012c012c000700001133153335331521646464fed4012cc864c8000100000000012c012c000b00003111331533353311233523156464646464012c6464fed46464000001000000000064012c000300003111331164012cfed40000020000000000c8012c000300070000313533153d0133156464646464c8c800000300000000012c012c0007000b000f0000311133153315231537353315073315236464646464646464012c646464c86464646400010000000000c8012c000500003111331533156464012cc864000000030000000001f4012c0007000b001300003111331533152315333533153d013335331123356464646464646464012c6464646464646464fed464000002000000000190012c0007000d00003111331533152315333533353311646464646464012c64646464c8fed4000000000400000000012c012c00030007000b000f00003d0133153d0133150733152337353315646464646464646464646464646464646464000000010000000000c8012c00050000311133152315c864012cc86400000002000000000190012c00050009000031112115331525333523012c64fed46464012cc864646400000200000000012c012c00050009000031113315231533353315c8646464012cc8646464000100000000012c012c0007000037233521152315236464012c6464c86464c8000100000000012c012c000700001133153335331121646464fed4012cc8c8fed4000000000300000000012c012c00030007000b0000113315233b011523133315236464646464646464012cc864012cc8000000000500000000012c012c00030007000b000f001300003135331537353315073315232723353315353315646464646464646464646464c864646464c864c86464000300000000012c012c00030007000b0000373533152b01353311353315c864c8646464c8646464fed4c8c8000100000000012c012c0007000033352335331533156464c864c864c864000000010000000000c8012c000700003111331523153315c86464012c6464640000000300000000012c012c00030007000b0000373315232723353315353315c86464646464646464c864c8646400010000000000c8012c000700003323353335233533c8c86464c8646464000000010000000000c800640003000031353315c86464000000000300000000012c012c00030007000d00003d0133153d0133150733353315236464646464c86464646464646464c800000100000000012c012c000b0000333523353335331523153315646464c864646464646464640000000100000000012c012c000b0000332335333523353315331523c8c86464c864646464646464000000010006ff9c012e012c000300003f01170306a2869474b88afefa00000300000000012c012c00030007000b00003d0133153d01331507331523646464c8c8646464646464646400000100000000012c012c000b00003135333523352115231533156464012c646464646464646400000000001000c600010000000000000009001400010000000000010006002c00010000000000020007004300010000000000030006005900010000000000040006006e0001000000000005000c008f0001000000000006000600aa0001000000000007000900c50003000104090000001200000003000104090001000c001e0003000104090002000e00330003000104090003000c004b0003000104090004000c00600003000104090005001800750003000104090006000c009c0003000104090007001200b10043006f00700079007200690067006800740000436f707972696768740000540069006e006900650072000054696e696572000052006500670075006c006100720000526567756c61720000540069006e006900650072000054696e6965720000540069006e006900650072000054696e6965720000560065007200730069006f006e00200031002e00300030000056657273696f6e20312e30300000540069006e006900650072000054696e6965720000540072006100640065006d00610072006b000054726164656d61726b000000000002000000000000000000000000000000000000000000000000000000000000003e00000102000201030003000400050009000a000b000c000d000f001000120013001400150016001700180019001a001b001c001d00200022002400250026002700280029002a002b002c002d002e002f003000310032003300340035003700380039003b003c003d003e003f004000420054005e006001040105010606676c7970683107756e693030303706676c7970683507676c797068313007676c797068323900000001ffff000200010000000e0000001800000000000200010001003d000100040000000200000000000100000000c9896f3100000000000000000000000000000000";
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnerUpdated(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                             ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        require(owners.length == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}