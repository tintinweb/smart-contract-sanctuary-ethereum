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

// SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @dev Utilities for generating JSON metadata.
 */
library EncodeUtils {
    using Strings for uint256;

    /**
     * @dev Generates an metadata key:value notation for further JSON encoding. 
     * @param name metadata key name.
     * @param value metadata key value.
     * @param isNumber if value is number in a string form.
     * @param isLast if value is a last metadata attribute.
     * @return a "name":"value" string for further JSON encoding.
     */
    function attributeNameAndValue(string memory name, string memory value, bool isNumber, bool isLast) internal pure returns (string memory) {
        return string(abi.encodePacked(
            "\"", name, "\":",
            isNumber ? "" : "\"",
            value,
            isNumber ? "" : "\"",
            isLast ? "" : ","
        ));
    }

    /**
     * @dev Generates an attribute for the attributes array in the ERC721 metadata standard.
     * @param traitType the trait type to reference as the metadata key.
     * @param value the token"s trait associated with the key.
     * @param isNumber if value is number in a string form.
     * @return a JSON dictionary for the single attribute.
     */
    function attributeForTypeAndValue(string memory traitType, string memory value, bool isNumber) internal pure returns (string memory) {
        return string(abi.encodePacked(
            "{\"trait_type\":\"",
            traitType,
            "\",\"value\":",
            isNumber ? "" : "\"",
            value,
            isNumber ? "" : "\"",
            "}"
        ));
    }

    /** BASE 64 - Written by Brech Devos */
  
    string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Encode abi encoded byte string into base64 encoding.
     * @param data abi encoded byte string.
     * @return base64 encoded string.
     */
    function base64(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";
        
        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        // solhit-disable no-inline-assembly
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
                dataPtr := add(dataPtr, 3)
                
                // read 3 bytes
                let input := mload(dataPtr)
                
                // write 4 characters
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
                resultPtr := add(resultPtr, 1)
            }
            
            // padding with "="
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}

// SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.0;

/**
 * @dev Random selector of colors (16 bit palette) to generate pixel clouds.
 */
library PixelCloud {
    uint24 constant public PALETTE_0 = 0x9803d6;
    uint24 constant public PALETTE_1 = 0xd65efe;
    uint24 constant public PALETTE_2 = 0x1369d3;
    uint24 constant public PALETTE_3 = 0x00b4ff;
    uint24 constant public PALETTE_4 = 0x5eb5fe;
    uint24 constant public PALETTE_5 = 0x27d0e9;
    uint24 constant public PALETTE_6 = 0x5ee9fe;
    uint24 constant public PALETTE_7 = 0x2fbadd;
    uint24 constant public PALETTE_8 = 0xe9409b;
    uint24 constant public PALETTE_9 = 0xfe5ec4;
    uint24 constant public PALETTE_A = 0xec2cea;
    uint24 constant public PALETTE_B = 0xec2cc6;
    uint24 constant public PALETTE_C = 0xdf47c3;
    uint24 constant public PALETTE_D = 0xee66b0;
    uint24 constant public PALETTE_E = 0xd65efe;
    uint24 constant public PALETTE_F = 0xfe5ec4;

    struct PixelBlock {
        uint256 x;
        uint256 y;
        uint256 w;
        uint256 h;  
        uint24 color;    
    }

    /**
     * @dev Define color based on hex digit.
     * @param _i index from 0 to 63.
     * @param _chunk1 bytes32 chunk used as storage.
     * @param _chunk2 additional bytes32 chunk used as storage for indexes between 64 and 127.
     * @return color as hex number.
     */
    function getColor(uint256 _i, bytes32 _chunk1, bytes32 _chunk2) internal pure returns (uint24) {
        require(_i < 127, "index overflow");
        if (_i < 64) {
            return getColorByChar(getCharByIndex(_i, _chunk1));
        } else {
            return getColorByChar(getCharByIndex(_i % 64, _chunk2));
        }
    }

    /**
     * @dev Use bytes32 storage as 64 index storage by utilising hex encoding.
     * @param _i index from 0 to 63.
     * @param _chunk bytes32 chunk used as storage.
     * @return single character byte in hex encoding.
     */
    function getCharByIndex(uint256 _i, bytes32 _chunk) internal pure returns (bytes1) {
        require(_i < 64, "index overflow");
        uint256 _j = _i / 2;
        uint256 _m = _i % 2;

        bytes1 _currentByte = bytes1(_chunk << (_j * 8));
        
        uint8 _c1 = uint8(bytes1((_currentByte << 4) >> 4));
        uint8 _c2 = uint8(bytes1((_currentByte >> 4)));
    
        if (_m == 0) {
            if (_c2 >= 0 && _c2 <= 9) return bytes1(_c2 + 48);
            return bytes1(_c2 + 87);
        }

        if (_c1 >= 0 && _c1 <= 9) return bytes1(_c1 + 48);
        return bytes1(_c1 + 87);
    }

    /**
     * @dev Define color based on hex digit.
     * @param _char digit byte in hex encoding.
     * @return hex number of a color to optimise storage.
     */
    function getColorByChar(bytes1 _char) internal pure returns (uint24) {
        if (_char == bytes1("1")) return PALETTE_1;
        if (_char == bytes1("2")) return PALETTE_2;
        if (_char == bytes1("3")) return PALETTE_3;
        if (_char == bytes1("4")) return PALETTE_4;
        if (_char == bytes1("5")) return PALETTE_5;
        if (_char == bytes1("6")) return PALETTE_6;
        if (_char == bytes1("7")) return PALETTE_7;
        if (_char == bytes1("8")) return PALETTE_8;
        if (_char == bytes1("9")) return PALETTE_9;
        if (_char == bytes1("a")) return PALETTE_A;
        if (_char == bytes1("b")) return PALETTE_B;
        if (_char == bytes1("c")) return PALETTE_C;
        if (_char == bytes1("d")) return PALETTE_D;
        if (_char == bytes1("e")) return PALETTE_E;
        if (_char == bytes1("f")) return PALETTE_F;
        return PALETTE_0;
    }

    /**
     * @dev Render individual rectangle in a pixel cloud based on it's index.
     * @param _block pixel structure for rendering.
     * @return SVG rectangle string as utf8 bytes.
     */
    function renderBlock(PixelBlock memory _block) internal pure returns (bytes memory) {
        return abi.encodePacked(
            "<rect x=\\\"", toDecString(_block.x),
            "\\\" y=\\\"", toDecString(_block.y), "\\\" width=\\\"", toDecString(_block.w),
            "\\\" height=\\\"", toDecString(_block.h),
            "\\\" fill=\\\"#", toHexColor(toHexString(_block.color)), "\\\" />"
        );
    }

    /**
     * @dev Convert individual digit in a hex form.
     * @param _d hex color number for conversion
     * @return single digit byte in a hex encoding
     */
    function toHexDigit(uint8 _d) internal pure returns (bytes1) {
        if (0 <= _d && _d <= 9) {
            return bytes1(uint8(bytes1("0")) + _d);
        } else if (10 <= uint8(_d) && uint8(_d) <= 15) {
            return bytes1(uint8(bytes1("a")) + _d - 10);
        }
        revert("Invalid hex digit");
    }

    /**
     * @dev Convert number to string in a hex form e.g. 0xff to '0xff'
     * @param _a hex color number for conversion
     * @return string in a hex encoding
     */
    function toHexString(uint256 _a) internal pure returns (string memory) {
        uint256 _count = 0;
        uint256 _b = _a;
        while (_b != 0) {
            _count++;
            _b /= 16;
        }
        bytes memory _res = new bytes(_count);
        for (uint256 _i = 0; _i < _count; ++_i) {
            _b = _a % 16;
            _res[_count - _i - 1] = toHexDigit(uint8(_b));
            _a /= 16;
        }
        return string(_res);
    }

    /**
     * @dev Conversion to string may trim the leading 00 for the hex color, ensure that it's there.
     * @param _str string to check.
     * @return valid color string in a hex encoding.
     */
    function toHexColor(string memory _str) internal pure returns (string memory) {
        if (bytes(_str).length < 6) return string(abi.encodePacked("00", _str));
        return _str;
    }

    /**
     * @dev oraclizeAPI function to convert uint256 to memory string.
     * @param _i number to convert.
     * @return number string in a decimal encoding.
     */
    function toDecString(uint256 _i) internal pure returns (string memory) {
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
        uint256 k = len - 1;
        
        unchecked {
            while (_i != 0) {
                bstr[k--] = bytes1(uint8(48 + _i % 10));
                _i /= 10;
            }
        }
        return string(bstr);
    }
}

// SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.0;

import "./PixelCloud.sol";

/**
 * @dev 9x9 square of random pixels in SVG format.
 */
library SVG9x9 {
    /**
     * @dev Render SVG of 9x9.
     * @param _content Inner SVG content
     * @return SVG markup.
     */
    function renderImage(string memory _content) internal pure returns (string memory) {
        return string(abi.encodePacked(
            "<svg xmlns=\\\"http://www.w3.org/2000/svg\\\" style=\\\"width: 100%; height: 100%\\\" viewBox=\\\"0 0 9 9\\\">",
            _content,
            "</svg>"
        ));
    }
    
    /**
     * @dev Generate deterministic pixel could as SVG image from string used as a seed.
     * @param _name Domain name or other string to make the cloud.
     * @return pixel cloud SVG image.
     */
    function renderPixelCloud(string memory _name) internal pure returns (string memory) {
        return renderImage(string(abi.encodePacked(
            renderPixelCloudNoWrap(_name),
            renderText(_name)
        )));
    }

    /**
     * @dev Generate deterministic pixel could in form of SVG rectangle notations from string used as a seed.
     * @param _name Domain name or other string to make the cloud.
     * @return SVG group of pixel cloud rectangles.
     */
    function renderPixelCloudNoWrap(string memory _name) internal pure returns (string memory) {
        bytes32 _chunk1 = keccak256(bytes(_name));
        bytes32 _chunk2 = keccak256(abi.encodePacked(_chunk1));

        bytes memory _rendered;

        for (uint256 _i = 0; _i < 81; _i++) {
            _rendered = abi.encodePacked(_rendered, PixelCloud.renderBlock(PixelCloud.PixelBlock(
                _i % 9,
                _i / 9,
                1,
                1,
                PixelCloud.getColor(_i, _chunk1, _chunk2)
            )));
        }

        return string(abi.encodePacked(
            "<g>",
            _rendered,
            "</g>"
        ));
    }

    /**
     * @dev SVG markup for text.
     * @param _text Arbitary text.
     * @return text SVG node notation.
     */
    function renderText(string memory _text) internal pure returns (string memory) {
        return string(abi.encodePacked(
            "<text fill=\\\"#ffffff\\\" x=\\\"0.5\\\" y=\\\"1.5\\\" style=\\\"font: bold 1pt 'Roboto sans-serif'\\\">",
            _text,
            "</text>"
        ));
    }
}

// SPDX-License-Identifier: BSD-2-Clause
pragma solidity ^0.8.0;

interface ICRS {

    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);

    // Logged when an operator is added or removed.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function setRecord(bytes32 node, address owner, address resolver, uint64 ttl) external;
    function setSubnodeRecord(bytes32 node, bytes32 label, address owner, address resolver, uint64 ttl) external;
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external returns(bytes32);
    function setResolver(bytes32 node, address resolver) external;
    function setOwner(bytes32 node, address owner) external;
    function setTTL(bytes32 node, uint64 ttl) external;
    function setApprovalForAll(address operator, bool approved) external;
    function owner(bytes32 node) external view returns (address);
    function resolver(bytes32 node) external view returns (address);
    function ttl(bytes32 node) external view returns (uint64);
    function recordExists(bytes32 node) external view returns (bool);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITextResolver {
    event TextChanged(bytes32 indexed node, string indexed indexedKey, string value);

    /**
     * Returns the text data associated with a CRS node and key.
     * @param node The CRS node to query.
     * @param key The text data key to query.
     * @return The associated text data.
     */
    function text(bytes32 node, string calldata key) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITokenURIProxy {
    /**
     * @dev Returns proxy contract address which resolves into some content.
     * @param _id The token id.
     * @param _name The domain name.
     * @param _customAvatar URL to custom avatar.
     * @return Metadata URI or base64 encoded metadata.
     */
    function tokenURI(uint256 _id, string memory _name, string memory _customAvatar) external view returns (string memory);
}

// SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.10;

interface IVirtualDistributor {
    function pendingRewards(address _nftContract, uint256 _tokenId) external view returns (uint256);
    function isRewardSafelyLocked(address _nftContract, uint256 _tokenId) external view returns (bool);
}

// SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.10;

import "@le7el/generative_art/src/SVG9x9.sol";
import "@le7el/generative_art/src/EncodeUtils.sol";
import "@le7el/web3_crs/contracts/registry/ICRS.sol";
import "@le7el/web3_crs/contracts/resolver/proxies/ITokenURIProxy.sol";
import "@le7el/web3_crs/contracts/resolver/profile/ITextResolver.sol";
import "../resolver/profile/ILevelResolver.sol";
import "../interface/IVirtualDistributor.sol";

/** 
 * @dev Use pixel cloud as default image, unless set by user.
 *      Add level, experience and claims for L7L tokens as metadata attributes.
 */
contract AvatarMetadataProxyV1 is ITokenURIProxy {
    string public constant SUFFIX = ".avatar";
    bytes32 public constant EMPTY_STRING_KECCAK = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

    ICRS public immutable crs;
    bytes32 public immutable baseNode;

    constructor(ICRS _crs, bytes32 _baseNode) {
        crs = _crs;
        baseNode = _baseNode;
    }

    /**
     * Returns proxy contract address which resolves into some content.
     * @param _id NFT id.
     * @param _name Domain name.
     * @param _customImage URL to custom image.
     * @return Metadata URI or base64 encoded metadata.
     */
    function tokenURI(uint256 _id, string memory _name, string memory _customImage) external view returns (string memory) {
        string memory _fullname = string(abi.encodePacked(_name, SUFFIX));
        string memory metadata = string(abi.encodePacked(
            "{",
                EncodeUtils.attributeNameAndValue("name", _fullname, false, false),
                EncodeUtils.attributeNameAndValue("description", "LE7EL avatar", false, false),
                (keccak256(abi.encodePacked(_customImage)) == EMPTY_STRING_KECCAK ?
                    EncodeUtils.attributeNameAndValue("image_data", SVG9x9.renderPixelCloud(_fullname), false, false) :
                    EncodeUtils.attributeNameAndValue("image", _customImage, false, false)),
                "\"attributes\":",
                _compileAttributes(_id),
            "}"
        ));

        return string(abi.encodePacked(
            "data:application/json;base64,",
            EncodeUtils.base64(bytes(metadata))
        ));
    }

    /**
    * @dev Sets the attributes of the NFTs
    *
    * @return string with generated attributes.
    */
    function _compileAttributes(uint256 _id) internal view returns (string memory) {
        string memory _type = "Avatar";
        bytes32 _baseNode = baseNode;
        bytes32 _node = keccak256(abi.encodePacked(_baseNode, bytes32(_id)));
        address _rawResolver = crs.resolver(_node);
        ILevelResolver _resolver = ILevelResolver(_rawResolver);
        uint256 _level = _resolver.level(_baseNode, _node);
        uint256 _exp = _resolver.experience(_baseNode, _node);
        (address _distributor) = abi.decode(bytes(ITextResolver(crs.resolver(_baseNode)).text(_baseNode, "L7L_REWARDS_DISTRIBUTOR")), (address));
        uint256 _l7l = IVirtualDistributor(_distributor).pendingRewards(msg.sender, _id) / 1e16; // 2 digit float precision
        bool _locked = IVirtualDistributor(_distributor).isRewardSafelyLocked(msg.sender, _id);
        string memory _suffix = _locked ? "" : " (lock, to show rewards)";
        
        return string(abi.encodePacked(
            "[",
            EncodeUtils.attributeForTypeAndValue("Type", _type, false),
            ",",
            EncodeUtils.attributeForTypeAndValue("Level", _uint2str(_level), true),
            ",",
            EncodeUtils.attributeForTypeAndValue("Experience", _uint2str(_exp), true),
            ",",
            EncodeUtils.attributeForTypeAndValue(string(abi.encodePacked("L7L claims", _suffix)), _locked ? _uint2floatstr(_l7l) : "0.00", true),
            "]"
        ));
    }

    /**
     * @dev Convet uint256 into string for rendering.
     *
     * @param _i number to convert.
     * @return _uintAsString number in a string form
     */
    function _uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    /**
     * @dev Same as _uint2str, but adds "." before the last 2 digits
     *
     * @param _i number to convert.
     * @return _uintAsString number in a string form
     */
    function _uint2floatstr(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0.00";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr;
        uint k = len;
        if (len == 1) {
            bstr = new bytes(len + 3);
            bstr[0] = '0';
            bstr[1] = '.';
            bstr[2] = '0';
            k = 4;
        }
        else if (len == 2) {
            bstr = new bytes(len + 2);
            bstr[0] = '0';
            bstr[1] = '.';
            k = 4;
        }
        else {
            bstr = new bytes(len + 1);
            k += 1;
        }
        while (_i != 0) {
            k -= 1;
            // Add "." before the last 2 digits
            if (len > 2 && k == len - 2) {
                bstr[k] = '.';
                k -= 1;
            }
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}

// SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.10;

interface ILevelResolver {
    event AdvancedToNextLevel(
        bytes32 indexed project,
        bytes32 indexed node,
        uint256 newExperience,
        uint256 totalExperience
    );

    event ProjectLevelingRulesChanged(
        bytes32 indexed project,
        bytes4 indexed burnInterface,
        address indexed experienceToken,
        uint256 experienceTokenId,
        address levelingFormulaProxy
    );

    /**
     * @dev Level based on experience.
     * @param _project node for a project which issue experience.
     * @param _node the node to query.
     * @return level based on experience
     */
    function level(bytes32 _project, bytes32 _node) external view returns (uint256);

    /**
     * @dev Experience in scope of project.
     * @param _project node for a project which issue experience.
     * @param _node the node to query.
     * @return project experience
     */
    function experience(bytes32 _project, bytes32 _node) external view returns (uint256);
}