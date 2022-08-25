// SPDX-License-Identifier: MIT

/**                                                                
 *******************************************************************************
 * Sharkz Soul ID Data
 *******************************************************************************
 * Creator: Sharkz Entertainment
 * Author: Jason Hoi
 *
 */

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./ISoulData.sol";
import "./IScore.sol";
import "./Adminable.sol";
import "../Base64.sol";

interface IBalanceOf {
  function balanceOf(address owner) external view returns (uint256 balance);
}

interface IBalanceOfSoul {
  function balanceOfSoul(address soulContract, uint256 soulTokenId) external view returns (uint256 balance);
}

interface IName {
  function name() external view returns (string memory);
}

contract SoulData is ISoulData, Adminable {
    struct ContractData {
        address rawContract;
        uint16 size;
    }

    struct ContractDataPages {
        uint256 maxPageNumber;
        bool exists;
        mapping (uint256 => ContractData) pages;
    }

    // Mapping from string key to on-chain contract data storage 
    mapping (string => ContractDataPages) internal _contractDataPages;

    // Token image key
    string public tokenImageKey;

    // TokenURI Render mode
    // 0 : data:application/json;utf8, token image data:image/svg+xml;base64
    // 1 : data:application/json;utf8, token image data:image/svg+xml;utf8
    // 2 : data:application/json;base64, token image data:image/svg+xml;base64
    // 3 : data:application/json;base64, token image data:image/svg+xml;utf8
    uint256 internal _tokenURIMode;

    // Trait type index sequence coding mode
    // 0 : Braille unicode
    // 1 : Alphabet code, A, B, C, ..., Z, AA, AB ...
    uint256 internal _traitTypeSeqCoding;

    constructor() {
        tokenImageKey = "svgHead";
    }

    //////// Admin-only functions ////////
    /**
     * @dev See {ISoulData-saveData}.
     */
    function saveData(
        string memory _key, 
        uint256 _pageNumber, 
        bytes memory _b
    )
        external 
        onlyAdmin 
    {
        require(_b.length <= 24576, "Exceeded 24,576 bytes max contract space");
        /**
         * 
         * `init` variable is the header of contract data
         * 61_00_00 -- PUSH2 (contract code size)
         * 60_00 -- PUSH1 (code position)
         * 60_00 -- PUSH1 (mem position)
         * 39 CODECOPY
         * 61_00_00 PUSH2 (contract code size)
         * 60_00 PUSH1 (mem position)
         * f3 RETURN
         *
        **/
        bytes memory init = hex"610000_600e_6000_39_610000_6000_f3";
        bytes1 size1 = bytes1(uint8(_b.length));
        bytes1 size2 = bytes1(uint8(_b.length >> 8));
        // 2 bytes = 2 x uint8 = 65,536 max contract code size
        init[1] = size2;
        init[2] = size1;
        init[9] = size2;
        init[10] = size1;
        
        // contract code content
        bytes memory code = abi.encodePacked(init, _b);

        // create the contract
        address dataContract;
        assembly {
            dataContract := create(0, add(code, 32), mload(code))
            if eq(dataContract, 0) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        // record the created contract data page
        _saveDataRecord(
            _key,
            _pageNumber,
            dataContract,
            _b.length
        );
    }

    // store the generated contract data store address
    function _saveDataRecord(
        string memory _key,
        uint256 _pageNumber,
        address _dataContract,
        uint256 _size
    )
        internal
    {
        // Pull the current data for the contractData
        ContractDataPages storage _cdPages = _contractDataPages[_key];

        // Store the maximum page
        if (_cdPages.maxPageNumber < _pageNumber) {
            _cdPages.maxPageNumber = _pageNumber;
        }

        // Keep track of the existance of this key
        _cdPages.exists = true;

        // Add the page to the location needed
        _cdPages.pages[_pageNumber] = ContractData(
            _dataContract,
            uint16(_size)
        );
    }
    
    // Change token image key
    function setTokenImageKey(string calldata _tokenImageKey) external onlyAdmin {
        tokenImageKey = _tokenImageKey;
    }

    // Update tokenURI render mode
    function setTokenURIMode(uint256 _mode) external onlyAdmin {
        _tokenURIMode = _mode;
    }

    // Update trait type index sequence coding mode
    function setTraitSeqCoding(uint256 _mode) external onlyAdmin {
        _traitTypeSeqCoding = _mode;
    }

    //////// End of Admin-only functions ////////

    /**
     * @dev See {ISoulData-getPageData}.
     */
    function getPageData(
        string memory _key,
        uint256 _pageNumber
    )
        external 
        view 
        returns (bytes memory)
    {
        ContractDataPages storage _cdPages = _contractDataPages[_key];
        
        require(_pageNumber <= _cdPages.maxPageNumber, "Page number not in range");
        bytes memory _totalData = new bytes(_cdPages.pages[_pageNumber].size);

        // For each page, pull and compile
        uint256 currentPointer = 32;

        ContractData storage dataPage = _cdPages.pages[_pageNumber];
        address dataContract = dataPage.rawContract;
        uint256 size = uint256(dataPage.size);
        uint256 offset = 0;

        // Copy directly to total data
        assembly {
            extcodecopy(dataContract, add(_totalData, currentPointer), offset, size)
        }
        return _totalData;
    }

    /**
     * @dev See {ISoulData-getData}.
     */
    function getData(
        string memory _key
    )
        public 
        view 
        returns (bytes memory)
    {
        ContractDataPages storage _cdPages = _contractDataPages[_key];

        // Determine the total size
        uint256 totalSize;
        for (uint256 idx; idx <= _cdPages.maxPageNumber; idx++) {
            totalSize += _cdPages.pages[idx].size;
        }

        // Create a region large enough for all of the data
        bytes memory _totalData = new bytes(totalSize);

        // For each page, pull and compile
        uint256 currentPointer = 32;
        for (uint256 idx; idx <= _cdPages.maxPageNumber; idx++) {
            ContractData storage dataPage = _cdPages.pages[idx];
            address dataContract = dataPage.rawContract;
            uint256 size = uint256(dataPage.size);
            uint256 offset = 0;

            // Copy directly to total data
            assembly {
                extcodecopy(dataContract, add(_totalData, currentPointer), offset, size)
            }

            // Update the current pointer
            currentPointer += size;
        }

        return _totalData;
    }

    /**
     * @dev See {ISoulData-tokenURI}.
     */
    function tokenURI(uint256 _tokenId, string calldata _metaName, 
                      string calldata _metaDesc, string calldata _badgeTraits, uint256 _score, 
                      uint256 _creationTime, string calldata _customName) 
        external 
        view  
        returns (string memory) 
    {
        bytes memory output = abi.encodePacked(
            tokenMetaAndImage(_tokenId, _metaName, _metaDesc, _creationTime, _customName),
            tokenAttributes(_badgeTraits, _score, _creationTime)
        );

        // TokenURI Render mode
        // 0 : data:application/json;utf8, token image data:image/svg+xml;base64
        // 1 : data:application/json;utf8, token image data:image/svg+xml;utf8
        // 2 : data:application/json;base64, token image data:image/svg+xml;base64
        // 3 : data:application/json;base64, token image data:image/svg+xml;utf8
        if (_tokenURIMode == 0 || _tokenURIMode == 1) {
            return string(abi.encodePacked("data:application/json;utf8,", output));
        } else {
            return string(abi.encodePacked("data:application/json;base64,", Base64.encode(output)));
        }
    }

    /**
     * @dev See {ISoulData-tokenMetaAndImage}.
     */
    function tokenMetaAndImage(uint256 _tokenId, string calldata _metaName, string calldata _metaDesc, uint256 _creationTime, string calldata _name) 
        public  
        view 
        returns (string memory) 
    {
        string memory tokenImage = string(abi.encodePacked(
            string(getData(tokenImageKey)),
            _svgText(
              _name,
              "8.5",
              "208", 
              "107.8", 
              "4"
            ),
            _svgText(
              string(abi.encodePacked(toString(_creationTime),"#",toString(_tokenId))),
              "11",
              "208", 
              "251.5", 
              "4"
            ),
            "</svg>"
        ));

        // 0 : data:application/json;utf8, token image data:image/svg+xml;base64
        // 1 : data:application/json;utf8, token image data:image/svg+xml;utf8
        // 2 : data:application/json;base64, token image data:image/svg+xml;base64
        // 3 : data:application/json;base64, token image data:image/svg+xml;utf8
        if (_tokenURIMode == 0 || _tokenURIMode == 2) {
            return string(abi.encodePacked(
                '{"name":"', _metaName, toString(_tokenId), '","description":"', _metaDesc, '","image":"data:image/svg+xml;base64,', Base64.encode(bytes(tokenImage)), '",'
            ));
        } else {
            return string(abi.encodePacked(
                '{"name":"', _metaName, toString(_tokenId), '","description":"', _metaDesc, '","image":"data:image/svg+xml;utf8,', tokenImage, '",'
            ));
        }
        
        
    }

    /**
     * @dev See {ISoulData-tokenAttributes}.
     */
    function tokenAttributes(string calldata _badgeTraits, uint256 _score, uint256 _creationTime) 
        public  
        pure 
        returns (string memory) 
    {
        return string(abi.encodePacked('"attributes":[',
            '{"trait_type":"Creation Time","value":', toString(_creationTime), ',"display_type": "date"},',
            _badgeTraits,
            '{"trait_type":"Score","value":', toString(_score), '}]}'
        ));
    }

    // render dynamic svg <text> element with token internal data
    function _svgText(string memory _text, string memory _fontSize, string memory _x, string memory _y, string memory _rotate) 
        internal 
        pure 
        returns (string memory) 
    {
        if (bytes(_text).length > 0) {
            // sample output: 
            // <text text-anchor='middle' x='208' y='241.5' fill='#8ecad8' font-family='custom' 
            //  font-size='8.5' transform='rotate(4)' letter-spacing='0.5'>1626561212#471</text>
            return string(abi.encodePacked(
                "<text text-anchor='middle' x='", _x, "' y='", _y ,"' fill='#8ecad8' font-family='custom' font-size='",_fontSize,
                "' transform='rotate(", _rotate, ")' letter-spacing='0.5'>", _svgSpace(_text),"</text>"
            ));
        }

        return "";
    }

    // convert space charachter to better svg text space
    function _svgSpace(string memory _name) 
        internal  
        pure 
        returns (string memory)
    {
        bytes memory input = bytes(_name);
        bytes memory output;
        uint256 index;
        while(index < input.length) {
            // replace "space" to "&#160;"
            if (keccak256(abi.encodePacked(input[index])) == keccak256(abi.encodePacked(" "))) {
                output = abi.encodePacked(output, "&#160;&#160;");
            } else {
                output = abi.encodePacked(output, input[index]);
            }
            index += 1;
        }
        return string(output);
    }

    /**
     * @dev See {ISoulData-getTokenCollectionName}.
     */
    function getTokenCollectionName(address _contract) public view returns (string memory) {
        try IName(_contract).name() returns (string memory name) {
            return name;
        } catch (bytes memory) {
            // when reverted, just returns...
            return "";
        }
    }

    /**
     * @dev See {ISoulData-getBadgeBaseScore}.
     */
    function getBadgeBaseScore(address _badgeContract) external view returns (uint256) {
        try IScore(_badgeContract).baseScore() returns (uint256 score) {
            return score;
        } catch (bytes memory) {
            // when reverted, just returns...
            return 0;
        }
    }

    /**
     * @dev See {ISoulData-getBadgeTrait}.
     */
     function getBadgeTrait(address _badgeContract, uint256 _traitIndex, address _soulContract, uint256 _soulTokenId, address _soulTokenOwner) 
        external 
        view 
        returns (string memory) 
    {
        string memory output;
        string memory traitName;
        string memory traitValue;

        traitValue = getTokenCollectionName(_badgeContract);
        uint256 traitValueLength = bytes(traitValue).length;

        // generate sequence code for multiple dynamic trait index number
        string memory traitSeqCode;
        if (_traitTypeSeqCoding == 0) {
            traitSeqCode = toBrailleCodeUnicode(_traitIndex);
        } else {
            traitSeqCode = toAlphabetCode(_traitIndex);
        }

        // ERC165 interface ID for ERC721 is 0x80ac58cd
        if (isImplementing(_badgeContract, 0x80ac58cd)) {
            // target contract is ERC721
            if (getERC721Balance(_badgeContract, _soulTokenOwner) > 0) {
                if (traitValueLength != 0) {
                    traitName = string(abi.encodePacked("ERC721 NFT ", traitSeqCode));
                    output = string(abi.encodePacked(output, '{"trait_type":"',traitName,'","value":"',traitValue, '"},'));
                }
            }
        } else {
            // target contract is Soul Badge contracts
            if (getSoulBadgeBalanceForSoul(_soulContract, _soulTokenId, _badgeContract) > 0) {
                if (traitValueLength != 0) {
                    traitName = string(abi.encodePacked("Soul Badge ", traitSeqCode));
                    output = string(abi.encodePacked(output, '{"trait_type":"',traitName,'","value":"',traitValue, '"},'));
                }
            }    
        }
        return output;
    }

    /**
     * @dev See {ISoulData-getSoulBadgeBalanceForSoul}.
     */
    function getSoulBadgeBalanceForSoul(address _soulContract, uint256 _soulTokenId, address _badgeContract) public view returns (uint256) {
        if (_soulContract == address(0) || _badgeContract == address(0)) return 0;
        
        try IBalanceOfSoul(_badgeContract).balanceOfSoul(_soulContract, _soulTokenId) returns (uint256 rtbal) {
            return rtbal;
        } catch (bytes memory) {
            // when reverted, just returns...
            return 0;
        }
    }

    /**
     * @dev See {ISoulData-getERC721Balance}.
     */
    function getERC721Balance(address _contract, address _ownerAddress) public view returns (uint256) {
        if (_contract == address(0) || _ownerAddress == address(0)) return 0;

        try IBalanceOf(_contract).balanceOf(_ownerAddress) returns (uint256 balance) {
            return balance;
        } catch (bytes memory) {
            // when reverted, just returns...
            return 0;
        }
    }

    /**
     * @dev See {ISoulData-isValidCustomNameFormat}.
     */
    function isValidCustomNameFormat(string calldata name) external pure returns (bool) {
        bytes memory data = bytes(name);
        uint8 char;
        for (uint256 i; i < data.length; i++) {
            char = uint8(data[i]);
            // accepted char: space(32) ,(44) -(45) .(46) :(58) A-Z:(64-90) a-z:(97-122)
            if (!(char == 32 || (char >= 44 && char <= 46) || (char == 58) 
                  || (char >= 64 && char <= 90) || (char >= 97 && char <= 122) )) {
              return false;
            }
        }
        return true;
    }

    /**
     * @dev See {ISoulData-isImplementing}.
     */
    function isImplementing(address _contract, bytes4 _interfaceCode) public view returns (bool) {
        try IERC165(_contract).supportsInterface(_interfaceCode) returns (bool result) {
            return result;
        } catch (bytes memory) {
            // when reverted, just returns...
            return false;
        }
    }

    /**
     * @dev See {ISoulData-toBrailleCodeUnicode}.
     */
    function toBrailleCodeUnicode(uint256 _value) 
        public 
        pure 
        returns (string memory) 
    {
        // base 256 codes Braille pattern unicode
        // @See https://www.htmlsymbols.xyz/braille-patterns
        uint256 base = 256;

        // Braille 0 = 0xe2a080
        if (_value == 0) {
            bytes memory zero = new bytes(3);
            zero[0] = 0xe2;
            zero[1] = 0xa0;
            zero[2] = 0x80;
            return string(zero);
        }
        // calculate string length
        uint256 temp = _value;
        uint256 digits = 0;
        while (temp != 0) {
            digits += 1;
            temp /= base;
        }
        // construct output string bytes
        // Solidity unicode character is 3 bytes long
        uint256 codeSize = 3;
        
        // Brallie Unicode, each byte is over 127 (avoid colliding Lower ASCII 32 - 127)
        // 1st bytes1 keeping at 0xe2 (uint8 226)
        // 2nd bytes1 starts at 0xa0 (uint8 160)
        // 3rd bytes1 starts at 0x80 (uint8 128)
        // Brallie unicode span 4 sections, each section contains only 64 numbers total 256 numbers.
        // Part 1: 0xe2a080 - 0xe2a0bf
        // Part 2: 0xe2a180 - 0xe2a1bf
        // Part 3: 0xe2a280 - 0xe2a2bf
        // Part 4: 0xe2a380 - 0xe2a3bf
        bytes memory buffer = new bytes(digits*codeSize);
        uint256 code;
        unchecked {
            while (_value != 0) {
                digits -= 1;
                // 1st byte always the same
                buffer[digits*codeSize+0] = 0xe2;

                // 2nd byte number
                code = _value % base;
                if (code / 64 == 0) {
                    buffer[digits*codeSize+1] = 0xa0;
                } else if (code / 64 == 1) {
                    buffer[digits*codeSize+1] = 0xa1;
                } else if (code / 64 == 2) {
                    buffer[digits*codeSize+1] = 0xa2;
                } else if (code / 64 == 3) {
                    buffer[digits*codeSize+1] = 0xa3;
                }

                // 3rd byte, always starts at 128 to 191 (64 numbers)
                // after mod 64, convert to uint8, it will fit in 1 byte
                buffer[digits*codeSize+2] = bytes1(uint8(128 + code % 64));

                _value /= base;
            }
        }
        return string(buffer);
    }

    /**
     * @dev See {ISoulData-toBrailleCodeHtml}.
     */
    function toBrailleCodeHtml(uint256 _value) 
        public 
        pure 
        returns (string memory) 
    {
        // base 256 codes html code from [&#10240;] to [&#10495;]
        // https://www.htmlsymbols.xyz/braille-patterns
        uint256 base = 256;

        if (_value == 0) {
            return "&#10240;";
        }
        // calculate string length
        uint256 temp = _value;
        uint256 digits = 0;
        while (temp != 0) {
            digits += 1;
            temp /= base;
        }
        // construct output string bytes
        bytes memory buffer = new bytes(digits*8);
        uint256 code;
        bytes memory codeChars;
        uint256 codeCharIndex;
        unchecked {
            while (_value != 0) {
                digits -= 1;
                // calculate brallie html code number, from 10240 - 10495 (base 256)
                // and format as  &#{code};  string bytes
                code = 10240 + _value % base;
                codeChars = bytes(toString(code));
                buffer[digits*8+0] = bytes1("&");
                buffer[digits*8+1] = bytes1("#");
                for (codeCharIndex = 0; codeCharIndex < codeChars.length; codeCharIndex ++) {
                    buffer[digits*8+2+codeCharIndex] = codeChars[codeCharIndex];
                }
                buffer[digits*8+7] = bytes1(";");
                _value /= base;
            }
        }
        return string(buffer);
    }

    /**
     * @dev See {ISoulData-toAlphabetCode}.
     */
    function toAlphabetCode(uint256 _value) 
        public 
        pure 
        returns (string memory) 
    {
        // base 26 alphabet codes starts from A
        if (_value == 0) {
            return "A";
        }
        // calculate string length
        uint256 temp = _value;
        uint256 letters = 0;
        while (temp != 0) {
            letters += 1;
            temp /= 26;
        }
        uint256 max = letters - 1;
        // construct output string bytes
        bytes memory buffer = new bytes(letters);
        while (_value != 0) {
            letters -= 1;
            if (letters < max) {
                buffer[letters] = bytes1(uint8(64 + uint256(_value % 26)));
            } else {
                buffer[letters] = bytes1(uint8(65 + uint256(_value % 26)));
            }
            _value /= 26;
        }
        return string(buffer);
    }

    /**
     * Converts `uint256` to ASCII `string`
     */
    function toString(uint256 value) 
        public 
        pure 
        returns (string memory ptr) 
    {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit),
            // but we allocate 128 bytes to keep the free memory pointer 32-byte word aliged.
            // We will need 1 32-byte word to store the length,
            // and 3 32-byte words to store a maximum of 78 digits. Total: 32 + 3 * 32 = 128.
            ptr := add(mload(0x40), 128)
            // Update the free memory pointer to allocate.
            mstore(0x40, ptr)

            // Cache the end of the memory to calculate the length later.
            let end := ptr

            // We write the string from the rightmost digit to the leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // Costs a bit more than early returning for the zero case,
            // but cheaper in terms of deployment and overall runtime costs.
            for {
                // Initialize and perform the first pass without check.
                let temp := value
                // Move the pointer 1 byte leftwards to point to an empty character slot.
                ptr := sub(ptr, 1)
                // Write the character to the pointer. 48 is the ASCII index of '0'.
                mstore8(ptr, add(48, mod(temp, 10)))
                temp := div(temp, 10)
            } temp {
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
            } {
                // Body of the for loop.
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
            }

            let length := sub(end, ptr)
            // Move the pointer 32 bytes leftwards to make room for the length.
            ptr := sub(ptr, 32)
            // Store the length.
            mstore(ptr, length)
        }
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

/**
 *******************************************************************************
 * ISoulIDData interface
 *******************************************************************************
 * Creator: Sharkz Entertainment
 * Author: Jason Hoi
 *
 */

pragma solidity ^0.8.7;

/**
 * @dev Interface of Sharkz Soul ID Data storage and utilities
 */
interface ISoulData {
    /**
     * @dev Render tokenURI dynamic metadata string
     */
    function tokenURI(uint256 tokenId, string calldata metaName, string calldata metaDesc, string calldata badgeTraits, uint256 score, uint256 creationTime, string calldata customName) external view returns (string memory);

    /**
     * @dev Render token meta name, desc, and image
     */
    function tokenMetaAndImage(uint256 tokenId, string calldata metaName, string calldata metaDesc, uint256 creationTime, string calldata name) external view returns (string memory);

    /**
     * @dev Render token meta attributes
     */
    function tokenAttributes(string calldata badgeTraits, uint256 score, uint256 creationTime) external pure returns (string memory);

    /**
     * @dev Save/Update/Clear a page of data with a key, max size is 24576 bytes (24KB)
     */
    function saveData(string memory key, uint256 pageNumber, bytes memory data) external;

    /**
     * @dev Get all data from all data pages for a key
     */
    function getData(string memory key) external view returns (bytes memory);

    /**
     * @dev Get one page of data chunk
     */
    function getPageData(string memory key, uint256 pageNumber) external view returns (bytes memory);

    /**
     * @dev Returns external Token collection name
     */
    function getTokenCollectionName(address _contract) external view returns (string memory);

    /**
     * @dev Returns Soul Badge balance for a Soul
     */
    function getSoulBadgeBalanceForSoul(address soulContract, uint256 soulTokenId, address badgeContract) external view returns (uint256);

    /**
     * @dev Returns Badge base score (unit score per one qty
     */
    function getBadgeBaseScore(address badgeContract) external view returns (uint256);

    /**
     * @dev Returns the token metadata trait string for a badge contract (support ERC721 and ERC5114 Soul Badge)
     */
    function getBadgeTrait(address badgeContract, uint256 traitIndex, address soulContract, uint256 soulTokenId, address soulTokenOwner) external view returns (string memory);

    /**
     * @dev Returns whether an address is a ERC721 token owner
     */
    function getERC721Balance(address _contract, address ownerAddress) external view returns (uint256);

    /**
     * @dev Returns whether custom name contains valid characters
     *      We only accept [a-z], [A-Z], [space] and certain punctuations
     */
    function isValidCustomNameFormat(string calldata name) external pure returns (bool);

    /**
     * @dev Returns whether target contract reported it implementing an interface (based on IERC165)
     */
    function isImplementing(address _contract, bytes4 interfaceCode) external view returns (bool);
    
    /** 
     * @dev Converts a `uint256` to Unicode Braille patterns (0-255)
     * Braille patterns https://www.htmlsymbols.xyz/braille-patterns
     */
    function toBrailleCodeUnicode(uint256 value) external pure returns (string memory);

    /** 
     * @dev Converts a `uint256` to HTML code of Braille patterns (0-255)
     * Braille patterns https://www.htmlsymbols.xyz/braille-patterns
     */
    function toBrailleCodeHtml(uint256 value) external pure returns (string memory);

    /** 
     * @dev Converts a `uint256` to ASCII base26 alphabet sequence code
     * For example, 0:A, 1:B 2:C ... 25:Z, 26:AA, 27:AB...
     */
    function toAlphabetCode(uint256 value) external pure returns (string memory);

    /**
     * @dev Converts `uint256` to ASCII `string`
     */
    function toString(uint256 value) external pure returns (string memory ptr);
}

// SPDX-License-Identifier: MIT

/**
 *******************************************************************************
 * IScore interface
 *******************************************************************************
 * Creator: Sharkz Entertainment
 * Author: Jason Hoi
 *
 */

pragma solidity ^0.8.7;

/**
 * @dev Interface of token score, external token contract may accumulate total 
 * score from multiple IScore tokens.
 */
interface IScore {
    /**
     * @dev Get base score for each token (this is the unit score for different
     *  `tokenId` or owner address)
     */
    function baseScore() external view returns (uint256);

    /**
     * @dev Get score for individual `tokenId`
     * This function is needed only when score varies between token ids.
     * In order to accumulate score, try to avoid any revert() if user submitted 
     * non-existent token id or owner address.
     *
     */
    function scoreByToken(uint256 tokenId) external view returns (uint256);

    /**
     * @dev Get score of an address
     * In order to accumulate score, try to avoid any revert() if user submitted 
     * non-existent token id or owner address.
     *
     */
    function scoreByAddress(address addr) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

/**
 *******************************************************************************
 * Adminable access control
 *******************************************************************************
 * Author: Jason Hoi
 *
 */
pragma solidity ^0.8.7;

/**
 * @dev Contract module which provides basic multi-admin access control mechanism,
 * admins are granted exclusive access to specific functions with the provided 
 * modifier.
 *
 * By default, the contract owner is the first admin.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyAdmin`, which can be applied to your functions to restrict access.
 * 
 */
contract Adminable {
    event AdminCreated(address indexed addr);
    event AdminRemoved(address indexed addr);

    // mapping for admin address
    mapping(address => uint256) _admins;

    // add the first admin with contract creator
    constructor() {
        _admins[_msgSenderAdminable()] = 1;
    }

    modifier onlyAdmin() {
        require(isAdmin(_msgSenderAdminable()), "Adminable: caller is not admin");
        _;
    }

    function isAdmin(address addr) public view virtual returns (bool) {
        return _admins[addr] == 1;
    }

    function setAdmin(address to, bool approved) public virtual onlyAdmin {
        require(to != address(0), "Adminable: cannot set admin for the zero address");

        if (approved) {
            require(!isAdmin(to), "Adminable: add existing admin");
            _admins[to] = 1;
            emit AdminCreated(to);
        } else {
            require(isAdmin(to), "Adminable: remove non-existent admin");
            delete _admins[to];
            emit AdminRemoved(to);
        }
    }

    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * For GSN compatible contracts, you need to override this function.
     */
    function _msgSenderAdminable() internal view virtual returns (address) {
        return msg.sender;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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