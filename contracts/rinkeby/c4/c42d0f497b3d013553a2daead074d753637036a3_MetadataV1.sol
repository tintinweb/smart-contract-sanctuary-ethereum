// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "base64/base64.sol";
import "./Image.sol";
import "./HotChainSVG.sol";

contract MetadataV1 is Image, Metadata {
    function uri(uint256) external pure returns (string memory) {
        string memory image = Base64.encode(bytes(render()));
        string memory json = string.concat(
            '{"name": "Hot Chain SVG", "background_color": "000000", "image": "data:image/svg+xml;base64,',
            image,
            '"}'
        );
        return
            string.concat(
                "data:application/json;base64,",
                Base64.encode(bytes(json))
            );
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

import "./SVG.sol";
import "./Utils.sol";

contract Image {
    string public constant font =
        "data:font/ttf;base64,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";

    function render() public pure returns (string memory) {
        return
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" width="350" height="350" style="background:#000;font-family:Courier New">',
                svg.el(
                    "style",
                    "",
                    string.concat(
                        '@font-face { font-family: tinier; src: url("',
                        font,
                        '" format(ttf); }'
                    )
                ),
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
                ),
                svg.text(
                    string.concat(
                        svg.prop("x", "20"),
                        svg.prop("y", "310"),
                        svg.prop("font-size", "20"),
                        svg.prop("font-family", "tinier"),
                        svg.prop("fill", "#E5E5E5")
                    ),
                    "Watchfaces"
                ),
                svg.text(
                    string.concat(
                        svg.prop("x", "20"),
                        svg.prop("y", "330"),
                        svg.prop("font-size", "12"),
                        svg.prop("fill", "#999")
                    ),
                    "0x8d3b078d9d9697a8624d4b32743b02d270334af1"
                ),
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
                            svg.el("stop", svg.prop("stop-color", "#F1CD89")),
                            svg.el(
                                "stop",
                                string.concat(
                                    svg.prop("stop-color", "#9943D1"),
                                    svg.prop("offset", "1")
                                )
                            )
                        )
                    )
                ),
                "</svg>"
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "solmate/auth/Owned.sol";
import "solmate/tokens/ERC1155.sol";

contract HotChainSVG is ERC1155, Owned {
    Metadata public metadata;

    constructor() Owned(msg.sender) {}

    function mint(address collection) external payable {
        uint256 tokenId = (msg.value << 160) | uint160(collection);
        _mint(msg.sender, tokenId, 1, "");
    }

    function burn(uint256 tokenId) external payable {
        _burn(msg.sender, tokenId, 1);
    }

    function withdrawAll() external {
        uint256 value = address(this).balance;
        (bool success, bytes memory message) = owner.call{value: value}("");
        require(success, string(message));
    }

    function withdrawTokens(Token token, uint256 value) external {
        require(token.transferFrom(address(this), owner, value));
    }

    function setMetadata(Metadata _metadata) external onlyOwner {
        metadata = _metadata;
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return metadata.uri(tokenId);
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
    function uri(uint256) external view returns (string memory);
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