// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "@openzeppelin/[email protected]/token/ERC721/ERC721.sol";
import "@openzeppelin/[email protected]/token/ERC721/IERC721Enumerable.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";
import "@openzeppelin/[email protected]/math/SafeMath.sol";
import "@openzeppelin/[email protected]/math/Math.sol";
import "@openzeppelin/[email protected]/utils/Arrays.sol";
import "@openzeppelin/[email protected]/utils/ReentrancyGuard.sol";
import "./CryptopunksData.sol";
import "./BleachBackground.sol";

contract PandemicWarhols is ERC721, Ownable, ReentrancyGuard {

    using SafeMath for uint256;

    uint256 public constant MAX_TOKENS = 10000;

    uint256 public constant MAX_TOKENS_PER_PURCHASE = 20;

    uint256 private price = 80000000000000000; // 0.08 Ether

    address public renderingContractAddress;
    address public backgroundContractAddress;

    constructor() ERC721("Pandemic Warhols", "PWAR") Ownable() {}

    function setRenderingContractAddress(address _renderingContractAddress) public onlyOwner {
        renderingContractAddress = _renderingContractAddress;
    }

    function setBackgroundContractAddress(address _backgroundContractAddress) public onlyOwner {
        backgroundContractAddress = _backgroundContractAddress;
    }

    // Mint functionality

    function mint(uint256 _count) public payable nonReentrant {
        uint256 totalSupply = totalSupply();
        require(_count > 0 && _count < MAX_TOKENS_PER_PURCHASE + 1);
        require(totalSupply + _count < MAX_TOKENS + 1);
        require(msg.value >= price.mul(_count));
        for(uint256 i = 0; i < _count; i++){
            _safeMint(msg.sender, totalSupply + i);
        }
    }

    function setPrice(uint256 _newPrice) public onlyOwner() {
        price = _newPrice;
    }

    function getPrice() public view returns (uint256){
        return price;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    function tokensByOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    // Random function

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    // Random punk

    function randomPunk(uint256 tokenId) public view returns (uint16) {
        uint256 v = uint(keccak256(abi.encodePacked("a0867ed705a0", block.timestamp, block.difficulty, toString(tokenId)))) % 10000;
        uint16 original = uint16(v);
        return original;
    }

    // Background color

    function backgroundColor(uint256 tokenId) private view returns (string memory) {

      string[32] memory r;
      string[32] memory s = ["1", "6", "3", "9", "c", "4", "b", "d", "e", "8", "5", "0", "a", "f", "2", "7", "b", "7", "5", "1", "8", "d", "2", "a", "6", "c", "4", "f", "9", "0", "e", "3"];

      uint l = s.length;
      uint i;
      string memory t;

      while (l > 0) {
          uint256 v = random(string(abi.encodePacked("f09ceaa019e6", block.timestamp, block.difficulty, toString(tokenId))));
          i = v % l--;
          t = s[l];
          s[l] = s[i];
          s[i] = t;
      }

      r = s;

      string memory m = r[16];
      string memory f = "f";
      string memory o = "0";
      string memory j;

      if (keccak256(bytes(m)) == keccak256(bytes(f))) {
          j = "ffffff";
      } else if (keccak256(bytes(m)) == keccak256(bytes(o))) {
          j = "000000";
      } else {
          j = string(abi.encodePacked(r[5],r[11],r[7],r[4],r[10],r[15]));
      }

      return j;

    }

    // Make Attributes

    function makeAttributes(uint256 tokenId) private view returns (string memory) {

        string[2] memory traits;
        string memory originalPunk = toString(randomPunk(tokenId));

        traits[0] = string(abi.encodePacked('{"trait_type":"Background Color: #","value":"', backgroundColor(tokenId), '"}'));
        traits[1] = string(abi.encodePacked('{"trait_type":"Original Punk: #","value":"', originalPunk, '"}'));

        string memory attributes = string(abi.encodePacked(traits[0], ',', traits[1]));

        return attributes;
    }

    function replaceValue(string memory svg,uint256 position, string memory replace) internal pure returns (string memory) {
        string memory t = _stringReplace(svg,position,replace);
        return t;
    }

    function getBleach(uint256 tokenId) public view returns (string memory) {

        BleachBackground bleachBackground = BleachBackground(backgroundContractAddress);

        uint16 t = uint16(tokenId);

        string memory b = bleachBackground.getBleach(t);
        return b;
    }


    function getPlain(uint256 tokenId) public view returns (string memory) {

        CryptopunksData cryptopunksData = CryptopunksData(renderingContractAddress); // Running

        uint16 t = randomPunk(tokenId);

        string memory punkSvg = cryptopunksData.punkImageSvg(t); // Running

        // Add replacement values
        string[24] memory r = ["<","s","v","g",">","<","r","e","c","t",">","<","/","r","e","c","t",">","<","/","s","v","g",">"];

        string memory a = replaceValue(punkSvg,0,r[0]);
        a = replaceValue(a,1,r[1]);
        a = replaceValue(a,2,r[2]);
        a = replaceValue(a,3,r[3]);
        a = replaceValue(a,4,r[4]);
        a = replaceValue(a,5,r[5]);
        a = replaceValue(a,6,r[6]);
        a = replaceValue(a,7,r[7]);
        a = replaceValue(a,8,r[8]);
        a = replaceValue(a,9,r[9]);
        a = replaceValue(a,10,r[10]);
        a = replaceValue(a,11,r[11]);
        a = replaceValue(a,12,r[12]);
        a = replaceValue(a,13,r[13]);
        a = replaceValue(a,14,r[14]);
        a = replaceValue(a,15,r[15]);
        a = replaceValue(a,16,r[16]);
        a = replaceValue(a,17,r[17]);
        a = replaceValue(a,18,r[18]);
        a = replaceValue(a,19,r[19]);
        a = replaceValue(a,20,r[20]);
        a = replaceValue(a,21,r[21]);
        a = replaceValue(a,22,r[22]);
        a = replaceValue(a,23,r[23]);

        return a;

    }

    function getDescription(uint256 tokenId) public view returns (string memory) {

        string memory description;
        string memory a = "We create and perceive our world simultaneously. And our mind does this so well that we don't even know that it's happening.";
        string memory b = "You create the world of the dream. We bring the subject into that dream and they fill it with their subconcious.";
        string memory c = "Well, dreams they feel real while we're in them, right? It's only when we wake up that we realize something was actually strange?";
        string memory d = "You never really remember the beginning of a dream, do you? You always wind up right in the middle of what's going on.";

        uint256 v = uint(keccak256(abi.encodePacked("a70c1946af4f", block.timestamp, block.difficulty, toString(tokenId)))) % 4;

        if (v == 0) {
            description = a;
        } else if (v == 1) {
            description = b;
        } else if (v == 2) {
            description = c;
        } else {
            description = d;
        }

        return description;

    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {

        string[12] memory p;

        p[0] = '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.2" viewBox="0 0 600 600"><defs><pattern id="bleach" x="0" y="0" width="0.125" height="0.125"><image x="0" y="0" width="75" height="75" xlink:href="';
        
        p[1] = getBleach(tokenId);

        p[2] = '" /></pattern></defs><rect viewBox="0 0 600 600" width="600" height="600" fill="#';

        p[3] = backgroundColor(tokenId);

        p[4] = '" /><rect viewBox="0 0 600 600" width="600" height="600" fill="url(#bleach)" /><svg x="60" y="0" width="600" height="600" viewBox="0 0 600 600">';

        p[5] = getPlain(tokenId);

        p[6] = '</svg>';

        p[7] = getPlain(tokenId);

        p[8] = '<svg x="-60" y="0" width="600" height="600" viewBox="0 0 600 600">';

        p[9] = getPlain(tokenId);

        p[10] = '</svg></svg>';

        string memory o = string(abi.encodePacked(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8]));
        o = string(abi.encodePacked(o, p[9], p[10]));

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Pandemic Warhol #', toString(tokenId), '", "description": "', getDescription(tokenId), '", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(o)), '", "attributes": \x5B ', makeAttributes(tokenId), ' \x5D}'))));
        o = string(abi.encodePacked('data:application/json;base64,', json));

        return o;
    }

    // to String utility

    function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
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

    // Replace string utility

    function _stringReplace(string memory _string, uint256 _pos, string memory _letter) internal pure returns (string memory) {
        bytes memory _stringBytes = bytes(_string);
        bytes memory result = new bytes(_stringBytes.length);

        for(uint i = 0; i < _stringBytes.length; i++) {
                result[i] = _stringBytes[i];
                if(i==_pos)
                result[i]=bytes(_letter)[0];
            }
            return  string(result);
    }

}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

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
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
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
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;


contract BleachBackground {

    function getBleach(uint16 index) external pure returns (string memory bleach) {

        // 400px

        bleach = string(abi.encodePacked('data:image/png;base64,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')); 

    }

}

/**
 *Submitted for verification at Etherscan.io on 2021-08-18
*/

pragma solidity 0.7.6;

/**
 *   ____                  _                          _          ____        _
 *  / ___|_ __ _   _ _ __ | |_ ___  _ __  _   _ _ __ | | _____  |  _ \  __ _| |_ __ _
 * | |   | '__| | | | '_ \| __/ _ \| '_ \| | | | '_ \| |/ / __| | | | |/ _` | __/ _` |
 * | |___| |  | |_| | |_) | || (_) | |_) | |_| | | | |   <\__ \ | |_| | (_| | || (_| |
 *  \____|_|   \__, | .__/ \__\___/| .__/ \__,_|_| |_|_|\_\___/ |____/ \__,_|\__\__,_|
 *             |___/|_|            |_|
 *
 * On-chain Cryptopunk images and attributes, by Larva Labs.
 *
 * This contract holds the image and attribute data for the Cryptopunks on-chain.
 * The Cryptopunk images are available as raw RGBA pixels, or in SVG format.
 * The punk attributes are available as a comma-separated list.
 * Included in the attribute list is the head type (various color male and female heads,
 * plus the rare zombie, ape, and alien types).
 *
 * This contract was motivated by community members snowfro and 0xdeafbeef, including a proof-of-concept contract created by 0xdeafbeef.
 * Without their involvement, the project would not have come to fruition.
 */
contract CryptopunksData {

    string internal constant SVG_HEADER = 'data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" version="1.2" viewBox="0 0 24 24">';
    string internal constant SVG_FOOTER = '</svg>';

    bytes private palette;
    mapping(uint8 => bytes) private assets;
    mapping(uint8 => string) private assetNames;
    mapping(uint64 => uint32) private composites;
    mapping(uint8 => bytes) private punks;

    address payable internal deployer;
    bool private contractSealed = false;

    modifier onlyDeployer() {
        require(msg.sender == deployer, "Only deployer.");
        _;
    }

    modifier unsealed() {
        require(!contractSealed, "Contract sealed.");
        _;
    }

    constructor() {
        deployer = msg.sender;
    }

    function setPalette(bytes memory _palette) external onlyDeployer unsealed {
        palette = _palette;
    }

    function addAsset(uint8 index, bytes memory encoding, string memory name) external onlyDeployer unsealed {
        assets[index] = encoding;
        assetNames[index] = name;
    }

    function addComposites(uint64 key1, uint32 value1, uint64 key2, uint32 value2, uint64 key3, uint32 value3, uint64 key4, uint32 value4) external onlyDeployer unsealed {
        composites[key1] = value1;
        composites[key2] = value2;
        composites[key3] = value3;
        composites[key4] = value4;
    }

    function addPunks(uint8 index, bytes memory _punks) external onlyDeployer unsealed {
        punks[index] = _punks;
    }

    function sealContract() external onlyDeployer unsealed {
        contractSealed = true;
    }

    /**
     * The Cryptopunk image for the given index.
     * The image is represented in a row-major byte array where each set of 4 bytes is a pixel in RGBA format.
     * @param index the punk index, 0 <= index < 10000
     */
    function punkImage(uint16 index) public view returns (bytes memory) {
        require(index >= 0 && index < 10000);
        bytes memory pixels = new bytes(2304);
        for (uint j = 0; j < 8; j++) {
            uint8 asset = uint8(punks[uint8(index / 100)][(index % 100) * 8 + j]);
            if (asset > 0) {
                bytes storage a = assets[asset];
                uint n = a.length / 3;
                for (uint i = 0; i < n; i++) {
                    uint[4] memory v = [
                        uint(uint8(a[i * 3]) & 0xF0) >> 4,
                        uint(uint8(a[i * 3]) & 0xF),
                        uint(uint8(a[i * 3 + 2]) & 0xF0) >> 4,
                        uint(uint8(a[i * 3 + 2]) & 0xF)
                    ];
                    for (uint dx = 0; dx < 2; dx++) {
                        for (uint dy = 0; dy < 2; dy++) {
                            uint p = ((2 * v[1] + dy) * 24 + (2 * v[0] + dx)) * 4;
                            if (v[2] & (1 << (dx * 2 + dy)) != 0) {
                                bytes4 c = composite(a[i * 3 + 1],
                                        pixels[p],
                                        pixels[p + 1],
                                        pixels[p + 2],
                                        pixels[p + 3]
                                    );
                                pixels[p] = c[0];
                                pixels[p+1] = c[1];
                                pixels[p+2] = c[2];
                                pixels[p+3] = c[3];
                            } else if (v[3] & (1 << (dx * 2 + dy)) != 0) {
                                pixels[p] = 0;
                                pixels[p+1] = 0;
                                pixels[p+2] = 0;
                                pixels[p+3] = 0xFF;
                            }
                        }
                    }
                }
            }
        }
        return pixels;
    }

    /**
     * The Cryptopunk image for the given index, in SVG format.
     * In the SVG, each "pixel" is represented as a 1x1 rectangle.
     * @param index the punk index, 0 <= index < 10000
     */
    function punkImageSvg(uint16 index) external view returns (string memory svg) {
        bytes memory pixels = punkImage(index);
        svg = string(abi.encodePacked(SVG_HEADER));
        bytes memory buffer = new bytes(8);
        for (uint y = 0; y < 24; y++) {
            for (uint x = 0; x < 24; x++) {
                uint p = (y * 24 + x) * 4;
                if (uint8(pixels[p + 3]) > 0) {
                    for (uint i = 0; i < 4; i++) {
                        uint8 value = uint8(pixels[p + i]);
                        buffer[i * 2 + 1] = _HEX_SYMBOLS[value & 0xf];
                        value >>= 4;
                        buffer[i * 2] = _HEX_SYMBOLS[value & 0xf];
                    }
                    svg = string(abi.encodePacked(svg,
                        '<rect x="', toString(x), '" y="', toString(y),'" width="1" height="1" shape-rendering="crispEdges" fill="#', string(buffer),'"/>'));
                }
            }
        }
        svg = string(abi.encodePacked(svg, SVG_FOOTER));
    }

    /**
     * The Cryptopunk attributes for the given index.
     * The attributes are a comma-separated list in UTF-8 string format.
     * The first entry listed is not technically an attribute, but the "head type" of the Cryptopunk.
     * @param index the punk index, 0 <= index < 10000
     */
    function punkAttributes(uint16 index) external view returns (string memory text) {
        require(index >= 0 && index < 10000);
        uint8 cell = uint8(index / 100);
        uint offset = (index % 100) * 8;
        for (uint j = 0; j < 8; j++) {
            uint8 asset = uint8(punks[cell][offset + j]);
            if (asset > 0) {
                if (j > 0) {
                    text = string(abi.encodePacked(text, ", ", assetNames[asset]));
                } else {
                    text = assetNames[asset];
                }
            } else {
                break;
            }
        }
    }

    function composite(byte index, byte yr, byte yg, byte yb, byte ya) internal view returns (bytes4 rgba) {
        uint x = uint(uint8(index)) * 4;
        uint8 xAlpha = uint8(palette[x + 3]);
        if (xAlpha == 0xFF) {
            rgba = bytes4(uint32(
                    (uint(uint8(palette[x])) << 24) |
                    (uint(uint8(palette[x+1])) << 16) |
                    (uint(uint8(palette[x+2])) << 8) |
                    xAlpha
                ));
        } else {
            uint64 key =
                (uint64(uint8(palette[x])) << 56) |
                (uint64(uint8(palette[x + 1])) << 48) |
                (uint64(uint8(palette[x + 2])) << 40) |
                (uint64(xAlpha) << 32) |
                (uint64(uint8(yr)) << 24) |
                (uint64(uint8(yg)) << 16) |
                (uint64(uint8(yb)) << 8) |
                (uint64(uint8(ya)));
            rgba = bytes4(composites[key]);
        }
    }

    //// String stuff from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol

    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../math/Math.sol";

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
   /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Receiver.sol";
import "../../introspection/ERC165.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";
import "../../utils/EnumerableSet.sol";
import "../../utils/EnumerableMap.sol";
import "../../utils/Strings.sol";

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSet.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMap.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURI;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _holderTokens[owner].length();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a prefix in {tokenURI} to each token's URI, or
    * to the token ID if no specific URI is set for that token ID.
    */
    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || ERC721.isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _tokenOwners.contains(tokenId);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || ERC721.isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     d*
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId); // internal owner

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own"); // internal owner
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    function _approve(address to, uint256 tokenId) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId); // internal owner
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
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
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMap {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;

        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) { // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({ _key: key, _value: value }));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) { // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

   /**
    * @dev Returns the key-value pair stored at position `index` in the map. O(1).
    *
    * Note that there are no guarantees on the ordering of entries inside the
    * array, and it may change when more entries are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function _tryGet(Map storage map, bytes32 key) private view returns (bool, bytes32) {
        uint256 keyIndex = map._indexes[key];
        if (keyIndex == 0) return (false, 0); // Equivalent to contains(map, key)
        return (true, map._entries[keyIndex - 1]._value); // All indexes are 1-based
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, "EnumerableMap: nonexistent key"); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

   /**
    * @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key), errorMessage))));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}