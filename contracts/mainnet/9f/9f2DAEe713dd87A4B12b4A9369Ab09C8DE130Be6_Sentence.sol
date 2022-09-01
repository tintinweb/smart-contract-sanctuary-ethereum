// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./common/EnumerableMap.sol";
import "./common/Descriptor.sol";
import "./Word.sol";

contract Sentence is ERC721, ERC721Enumerable, Ownable {
    // lib
    using EnumerableMap for EnumerableMap.Bytes32ToUintMap;
    using Strings for uint256;

    // struct

    // constant

    // storage
    uint256 private _counter;
    Word public wordAddress;
    string private _basePath;

    mapping(bytes32 => uint256) public sentenceHash2TokenID;
    mapping(uint256 => bytes32) public sentenceTokenID2Hash;
    mapping(bytes32 => string) public sentenceHash2String;
    mapping(uint256 => uint256) public sentenceTokenID2Color;

    // event

    constructor(address _word) ERC721("Sentence", "STC") {
        wordAddress = Word(_word);
    }

    function splitSentence(string memory sentence)
        public
        pure
        returns (string[] memory words)
    {
        bytes memory b = bytes(sentence);
        uint16 len = uint16(b.length);
        require(len >= 1 && len <= 319, "sentence length illegal!");

        uint16 count = 0;
        uint16 code = uint8(b[0]);
        require(
            code >= 32 && code <= 126,
            "sentence contains illegal characters!"
        );
        bool isPrevWord = (code >= 48 && code <= 57) ||
            (code >= 65 && code <= 90) ||
            (code >= 97 && code <= 122);
        bool isWord = false;
        uint16[] memory arrIndex = new uint16[](320);
        uint16 arrIndexIndex = 0;
        if (isPrevWord) {
            arrIndex[arrIndexIndex++] = 0;
        }

        for (uint16 i = 1; i < len - 1; ++i) {
            code = uint8(b[i]);
            require(
                code >= 32 && code <= 126,
                "sentence contains illegal characters!"
            );
            isWord =
                (code >= 48 && code <= 57) ||
                (code >= 65 && code <= 90) ||
                (code >= 97 && code <= 122);
            if (isWord && !isPrevWord) {
                arrIndex[arrIndexIndex++] = i;
            } else if (!isWord && isPrevWord) {
                arrIndex[arrIndexIndex++] = i;
                count++;
            }
            isPrevWord = isWord;
        }

        code = uint8(b[len - 1]);
        require(
            code >= 32 && code <= 126,
            "sentence contains illegal characters!"
        );
        isWord =
            (code >= 48 && code <= 57) ||
            (code >= 65 && code <= 90) ||
            (code >= 97 && code <= 122);
        if (isWord) {
            if (isPrevWord) {
                arrIndex[arrIndexIndex++] = len;
            } else {
                arrIndex[arrIndexIndex++] = len - 1;
                arrIndex[arrIndexIndex++] = len;
            }
            count++;
        } else {
            if (isPrevWord) {
                arrIndex[arrIndexIndex++] = len - 1;
                count++;
            }
        }

        words = new string[](count);
        for (uint16 i = 0; i < count; ++i) {
            uint16 start = arrIndex[i * 2];
            uint16 end = arrIndex[i * 2 + 1];
            bytes memory word = new bytes(end - start);
            for (uint16 j = start; j < end; ++j) {
                word[j - start] = b[j];
            }
            words[i] = string(word);
        }
    }

    function queryPrice(string memory sentence)
        public
        view
        returns (uint256 ret)
    {
        string[] memory words = splitSentence(sentence);
        bytes32[] memory wordHashs = new bytes32[](words.length);
        uint256 price = wordAddress.sentenceWordPrice();
        for (uint256 i = 0; i < words.length; ++i) {
            bytes32 wordHash = wordAddress.getWordHash(words[i]);
            if (wordAddress.isWordLock(wordHash)) {
                continue;
            }
            bool find = false;
            for (uint256 j = 0; j < i; ++j){
                if (wordHash == wordHashs[j]){
                    find = true;
                    continue;
                }
            }
            if (find){
                continue;
            }

            wordHashs[i] = wordHash;
            ret += price;
        }
    }

    function mint(string memory sentence, uint24 color) public payable {
        string[] memory words = splitSentence(sentence);

        bytes memory byteSentence = bytes(sentence);
        bytes memory byteLowerCaseSentence = new bytes(byteSentence.length);
        require((uint8)(byteSentence[byteSentence.length - 1]) != 32, "space at end");

        // tolowercase
        for (uint256 i = 0; i < byteLowerCaseSentence.length; ++i) {
            if (byteSentence[i] >= 0x41 && byteSentence[i] <= 0x5a) {
                byteLowerCaseSentence[i] = bytes1(uint8(byteSentence[i]) + 32);
            }
            else{
                byteLowerCaseSentence[i] = byteSentence[i];
            }
        }

        bytes32 hashSentence = keccak256(byteLowerCaseSentence);
        require(sentenceHash2TokenID[hashSentence] == 0, "sentence exsit!");

        // mint token
        _counter++;
        _mint(msg.sender, _counter);
        sentenceHash2TokenID[hashSentence] = _counter;
        sentenceHash2String[hashSentence] = sentence;
        sentenceTokenID2Hash[_counter] = hashSentence;
        sentenceTokenID2Color[_counter] = color;

        // word proc
        wordAddress.sentenceMint{value:msg.value}(_counter, words);
    }

    function queryTokenID(string memory sentence) public view returns (uint256) {
        bytes memory byteSentence = bytes(sentence);

        // tolowercase
        for (uint256 i = 0; i < byteSentence.length; ++i) {
            if (byteSentence[i] >= 0x41 && byteSentence[i] <= 0x5a) {
                byteSentence[i] = bytes1(uint8(byteSentence[i]) + 32);
            }
        }

        return sentenceHash2TokenID[keccak256(byteSentence)];
    }

    function querySentence(uint256 tokenID) public view returns (string memory) {
        return sentenceHash2String[sentenceTokenID2Hash[tokenID]];
    }

    // url
    function setBaseURI(string calldata path) public onlyOwner {
        _basePath = path;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        if (bytes(_basePath).length > 0) {
            return string(abi.encodePacked(_basePath, tokenId.toString()));
        }

        return Descriptor.GetSentenceDesc(tokenId, sentenceHash2String[sentenceTokenID2Hash[tokenId]], uint24(sentenceTokenID2Color[tokenId]));
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableMap.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

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
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct Map {
        // Storage of keys
        EnumerableSet.Bytes32Set _keys;
        mapping(bytes32 => bytes32) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(
        Map storage map,
        bytes32 key,
        bytes32 value
    ) private returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._keys.length();
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
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function _tryGet(Map storage map, bytes32 key) private view returns (bool, bytes32) {
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (_contains(map, key), bytes32(0));
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || _contains(map, key), "EnumerableMap: nonexistent key");
        return value;
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function _get(
        Map storage map,
        bytes32 key,
        string memory errorMessage
    ) private view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || _contains(map, key), errorMessage);
        return value;
    }

    // Bytes32ToUintMap
    struct Bytes32ToUintMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToUintMap storage map,
        bytes32 key,
        uint256 value
    ) internal returns (bool) {
        return _set(map._inner, key, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToUintMap storage map, bytes32 key) internal returns (bool) {
        return _remove(map._inner, key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool) {
        return _contains(map._inner, key);
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(Bytes32ToUintMap storage map) internal view returns (uint256) {
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
    function at(Bytes32ToUintMap storage map, uint256 index) internal view returns (bytes32, uint256) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (key, uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = _tryGet(map._inner, key);
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToUintMap storage map, bytes32 key) internal view returns (uint256) {
        return uint256(_get(map._inner, key));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library Descriptor {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    bytes internal constant FONT_DATA = "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";
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

    function GetSentenceDesc(uint256 tokenId, string memory sentence, uint24 color) public pure returns (string memory){
        string memory output = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMiDYMid meet" viewBox="0 0,360,360"><style>@font-face {font-family: "Unifont";font-style: normal;font-weight: normal;src: url(data:font/woff;base64,',
                FONT_DATA,
                ') format("woff");}</style><style>.base{fill:rgb(',
                toString(uint8(bytes3(color)[0])),
                ',',
                toString(uint8(bytes3(color)[1])),
                ',',
                toString(uint8(bytes3(color)[2])),
                '); font-family:Unifont;font-size:22px;text-anchor:start;white-space:pre}</style><rect width="100%" height="100%" fill="black" />'
            )
        );
        bytes memory b = bytes(sentence);
        uint256 len = b.length / 29;
        uint256 startPosY = 35;
        uint256 i = 0;
        for (; i < len; ++i){
            bytes memory temp = new bytes(29);
            for (uint256 j = 0; j < 29; ++j){
                temp[j] = b[i*29+j];
            }
            bytes memory line = abi.encodePacked(
                '<text x="20" y="',
                toString(startPosY + i * 30),
                '" class="base"><![CDATA[',
                temp,
                ']]></text>'
                );
            output = string(abi.encodePacked(output, line));
        }

        uint256 remain = b.length % 29;
        if (remain > 0){
            bytes memory temp = new bytes(remain);
            for (uint256 j = 0; j < remain; ++j){
                temp[j] = b[i*29+j];
            }
            bytes memory line = abi.encodePacked(
                '<text x="20" y="',
                toString(startPosY + i * 30),
                '" class="base"><![CDATA[',
                temp,
                ']]></text>'
                );
            output = string(abi.encodePacked(output, line));
        }
        output = string(abi.encodePacked(output, "</svg>"));

        string memory json = encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Sentence#',
                        toString(tokenId),
                        '", "description": "", "image": "data:image/svg+xml;base64,',
                        encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );
        output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }


    function GetWordDesc(uint256 tokenId, string memory word) public pure returns (string memory) {
        string memory output = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMiDYMid meet" viewBox="0 0,360,360"><style>@font-face {font-family: "Unifont";font-style: normal;font-weight: normal;src: url(data:font/woff;base64,',
                FONT_DATA,
                ') format("woff");}</style><style>.base{fill:rgb(255,255,255); font-family:Unifont;font-size:22px;text-anchor:middle}</style><rect width="100%" height="100%" fill="black" /><text x="180" y="195" class="base">',
                word,
                "</text></svg>"
            )
        );
        string memory json = encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Word#',
                        toString(tokenId),
                        '", "description": "", "image": "data:image/svg+xml;base64,',
                        encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );
        output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );
        return output;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./common/EnumerableMap.sol";
import "./common/Descriptor.sol";

contract Word is ERC721, ERC721Enumerable, Ownable, ReentrancyGuard {
    // lib
    using EnumerableMap for EnumerableMap.Bytes32ToUintMap;
    using Strings for uint256;
    using ECDSA for bytes32;

    // struct

    // constant
    uint256 public constant mintPrice = 0.1 ether;
    uint256 public constant sentenceWordPrice = 0.01 ether;
    uint256 public constant publicMintDate = 1662408000;

    uint256 public constant whitelistMintMaxNum = 10;
    uint256[] public whitelistMintPrize = [0.08 ether, 0.04 ether, 0.01 ether];
    uint256[] public whitelistMintDate = [1662321600, 1662235200, 1662148800];

    // storage
    uint256 private _counter;

    uint256 public maxSupply;

    mapping(bytes32 => uint256) public wordHash2TokenID;
    mapping(uint256 => bytes32) public wordTokenID2Hash;
    mapping(bytes32 => string) public wordHash2String;

    EnumerableMap.Bytes32ToUintMap private _lockWord;

    string private _basePath;

    uint256 public mintRevenue;

    address public senteceAddress;
    mapping(bytes32 => uint256[]) public sentenceMintTokenIDs;
    mapping(uint256 => uint256) public sentenceMintRevenue;

    address public mineAddress;

    uint256 public feePer = 0;

    mapping(address => uint256) public whitelistMintNum;
    address public signAddress;

    // event
    event ClaimSentenceRevenue(uint256 tokenID);
    event FeePerChange(uint256 newFee);

    constructor(address _mineAddress, address _signAddress) ERC721("Word", "WD") {
        mineAddress = _mineAddress;
        signAddress = _signAddress;
    }

    function setSignAddress(address _signAddress) public onlyOwner{
        signAddress = _signAddress;
    }

    function setSentenceAddress(address addr) public onlyOwner {
        senteceAddress = addr;
    }

    function setMineAddress(address addr) public onlyOwner{
        mineAddress = addr;
    }

    function setMaxSupply(uint256 num) public onlyOwner {
        maxSupply = num;
    }

    function setFeePer(uint256 per) public onlyOwner{
        require(per <= 1000, "per overflow");
        feePer = per;
        emit FeePerChange(per);
    }

    function updateLockWord(string[] memory words, uint256[] memory wordDates)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < words.length; ++i) {
            string memory tempStr = toLowerCase(words[i]);
            bytes32 tempHash = keccak256(bytes(tempStr));
            _lockWord.set(tempHash, wordDates[i]);
            wordHash2String[tempHash] = tempStr;
        }
    }

    function getAllLockWord()
        public
        view
        returns (string[] memory, uint256[] memory)
    {
        uint256 len = _lockWord.length();
        string[] memory words = new string[](len);
        uint256[] memory dates = new uint256[](len);
        bytes32 tempHash;
        for (uint256 i = 0; i < len; ++i) {
            (tempHash, dates[i]) = _lockWord.at(i);
            words[i] = wordHash2String[tempHash];
        }

        return (words, dates);
    }

    function toLowerCase(string memory word)
        public
        pure
        returns (string memory)
    {
        unchecked {
            bytes memory s = bytes(word);
            for (uint256 i = 0; i < s.length; ++i) {
                uint8 temp = uint8(s[i]);
                require(
                    (temp >= 0x30 && temp <= 0x39) ||
                        (temp >= 0x41 && temp <= 0x5a) ||
                        (temp >= 0x61 && temp <= 0x7a),
                    "word contains illegal characters!"
                );
                if (temp >= 0x41 && temp <= 0x5a) {
                    s[i] = bytes1(temp + 32);
                }
            }
        }

        return word;
    }

    function whitelistMint(string memory word, uint256 level, bytes calldata sig) public payable{
        require(level < whitelistMintDate.length, "level error");
        require(block.timestamp >= whitelistMintDate[level], "mint date is not enabled");
        require(whitelistMintNum[msg.sender] < whitelistMintMaxNum, "mint num limit");
        require(block.timestamp < publicMintDate, "public mint enabled");

        bytes32 hash = keccak256(abi.encode(msg.sender, level, address(this)));
        require(hash.recover(sig) == signAddress, "sign error");
        whitelistMintNum[msg.sender]++;
        _mint(word, whitelistMintPrize[level]);
    }

    function mint(string memory word) public payable {
        require(block.timestamp >= publicMintDate, "mint date is not enabled");
        _mint(word, mintPrice);
    }

    function _mint(string memory word, uint256 price) private {
        require(
            maxSupply <= 0 || totalSupply() < maxSupply,
            "max supply limit"
        );
        word = toLowerCase(word);
        bytes memory s = bytes(word);
        bytes32 wordHash = keccak256(s);

        require(s.length > 0 && s.length <= 18, "word length illegal!");
        require(msg.value == price, "eth illegal!");
        require(_exists(wordHash2TokenID[wordHash]) == false, "word exist!");
        (bool suc, uint256 date) = _lockWord.tryGet(wordHash);
        if (suc) {
            require(date > 0 && block.timestamp >= date, "word locked!");
        }
        unchecked {
            mintRevenue += msg.value;
            _counter++;
        }
        _mint(msg.sender, _counter);
        wordHash2TokenID[wordHash] = _counter;
        wordHash2String[wordHash] = word;
        wordTokenID2Hash[_counter] = wordHash;
    }

    function sentenceMint(uint256 tokenID, string[] memory words)
        public
        payable
    {
        require(msg.sender == senteceAddress, "sentence address error!");
        unchecked {
            uint256 price = 0;
            uint256 mineAmount = 0;
            uint256 feeRevenueUnit = (sentenceWordPrice / 10000) * feePer;
            uint256 priceUnit = sentenceWordPrice - feeRevenueUnit;
            uint256 feeRevenue = 0;
            string memory word;
            bytes32 wordHash;
            uint256 wordTokenID;
            bytes32[] memory wordHashs = new bytes32[](words.length);
            for (uint256 i = 0; i < words.length; ++i) {
                word = toLowerCase(words[i]);
                wordHash = keccak256(bytes(word));

                bool find = false;
                for (uint256 j = 0; j < i; ++j) {
                    if (wordHash == wordHashs[j]) {
                        find = true;
                        continue;
                    }
                }
                if (find) {
                    continue;
                }
                wordHashs[i] = wordHash;

                if (!isWordLock(wordHash)) {
                    wordTokenID = wordHash2TokenID[wordHash];
                    price += sentenceWordPrice;
                    feeRevenue += feeRevenueUnit;
                    if (wordTokenID != 0){
                        sentenceMintRevenue[wordTokenID] += priceUnit;
                    }
                    else{
                        mineAmount += priceUnit;
                    }
                }

                sentenceMintTokenIDs[wordHash].push(tokenID);
            }

            mintRevenue += feeRevenue;

            require(msg.value == price, "eth not enough");
            if (mineAmount > 0){
                _sendEth(mineAddress, mineAmount);
            }
        }
    }

    function sentenceMintNum(bytes32 wordHash) public view returns (uint256){
        return sentenceMintTokenIDs[wordHash].length;
    }

    function queryTokenID(string memory word) public view returns (uint256) {
        return wordHash2TokenID[keccak256(bytes(toLowerCase(word)))];
    }

    function queryWord(uint256 tokenID) public view returns (string memory) {
        return wordHash2String[wordTokenID2Hash[tokenID]];
    }

    function isWordLock(bytes32 wordHash) public view returns (bool) {
        if (_exists(wordHash2TokenID[wordHash])) {
            return false;
        }
        (bool suc, uint256 date) = _lockWord.tryGet(wordHash);
        if (suc && (date == 0 || block.timestamp < date)) {
            return true;
        }

        return false;
    }

    function getWordHash(string memory word) public pure returns (bytes32) {
        return keccak256(bytes(toLowerCase(word)));
    }

    function ownerClaimMintRevenue() public onlyOwner nonReentrant {
        _sendEth(msg.sender, mintRevenue);
        mintRevenue = 0;
    }

    function claimSentenceRevenue(uint256[] memory tokenIDs)
        public
        nonReentrant
    {
        unchecked {
            uint256 amount = 0;
            uint256 tokenID;
            for (uint256 i = 0; i < tokenIDs.length; ++i) {
                tokenID = tokenIDs[i];
                require(ownerOf(tokenID) == msg.sender, "not owned!");
                amount += sentenceMintRevenue[tokenID];
                sentenceMintRevenue[tokenID] = 0;

                emit ClaimSentenceRevenue(tokenID);
            }
            _sendEth(msg.sender, amount);
        }
    }

    function _sendEth(address to, uint256 value) private{
        (bool suc,) = to.call{value:value}("");
        require(suc, "sendEth fail");
    }

    // url
    function setBaseURI(string calldata path) public onlyOwner {
        _basePath = path;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        if (bytes(_basePath).length > 0) {
            return string(abi.encodePacked(_basePath, tokenId.toString()));
        }

        return Descriptor.GetWordDesc(tokenId, queryWord(tokenId));
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

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
        mapping(bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

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
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../utils/Context.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

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
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
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

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
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
        _setApprovalForAll(_msgSender(), operator, approved);
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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
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
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
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
        return _owners[tokenId] != address(0);
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
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
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
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
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

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
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
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
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
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
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
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
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
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}