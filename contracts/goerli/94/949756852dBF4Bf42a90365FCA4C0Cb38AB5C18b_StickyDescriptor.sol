pragma solidity 0.8.6;

/// @title Pool NFT descriptor
/// @dev From the The Nouns NFT descriptor


import { Strings } from "Strings.sol";
import { NFTDescriptor } from "NFTDescriptor.sol";
import { IJellyPool } from "IJellyPool.sol";
import { IJellyContract } from "IJellyContract.sol";
import "IJellyAccessControls.sol";
import "Base64.sol";
import "BokkyPooBahsDateTimeLibrary.sol";

interface IStickyPool {
    function locked__end(uint _tokenId) external view returns (uint);
    function balanceOfNFT(uint _tokenId) external view returns (uint);
    function totalSupply() external view returns (uint);
}

contract StickyDescriptor is  IJellyContract, NFTDescriptor {
    using Strings for uint256;
    using Strings for address;
    using BokkyPooBahsDateTimeLibrary for uint;

    IJellyPool public poolAddress;
    IJellyAccessControls public accessControls;

    uint256 public constant override TEMPLATE_TYPE = 8;
    bytes32 public constant override TEMPLATE_ID = keccak256("STICKY_DESCRIPTOR");
    uint256 private constant PERCENTAGE_PRECISION = 100e18;

    // Whether or not `tokenURI` should be returned as a data URI (Default: true)
    bool public isDataURIEnabled ;
    /// @notice Whether staking has been initialised or not.
    bool private initialised;
    // Base URI
    string public baseURI;
    string public tokenName;
    string public tokenDescription;
    string public imgUrl;

    uint256 public maxPercentage;

    event DataURIToggled(bool enabled);
    event BaseURIUpdated(string baseURI);
    event PoolSet(address poolAddress);
    event TokenNameSet(string tokenName);
    event TokenDescriptionSet(string tokenName);

    /**
     * @notice Toggle a boolean value which determines if `tokenURI` returns a data URI
     * or an HTTP URL.
     * @dev This can only be called by the owner.
     */
    function toggleDataURIEnabled() external  {
        require(accessControls.hasAdminRole(msg.sender));
        bool enabled = !isDataURIEnabled;

        isDataURIEnabled = enabled;
        emit DataURIToggled(enabled);
    }


    function setDataURI(bool enabled) external {
        require(accessControls.hasAdminRole(msg.sender));

        isDataURIEnabled = enabled;
        emit DataURIToggled(enabled);
    }


    /**
     * @notice Set the base URI for all token IDs. It is automatically
     * added as a prefix to the value returned in {tokenURI}, or to the
     * token ID if {tokenURI} is empty.
     * @dev This can only be called by the owner.
     */
    function setBaseURI(string calldata _baseURI) external   {
        require(accessControls.hasAdminRole(msg.sender));
        baseURI = _baseURI;

        emit BaseURIUpdated(_baseURI);
    }

    /**
     * @notice Set the base URI for all token IDs. It is automatically
     * added as a prefix to the value returned in {tokenURI}, or to the
     * token ID if {tokenURI} is empty.
     * @dev This can only be called by the owner.
     */
    function setPool(address _poolAddress) external   {
        require(accessControls.hasAdminRole(msg.sender));
        poolAddress = IJellyPool(_poolAddress);
        emit PoolSet(_poolAddress);
    }

    function setTokenName(string calldata _tokenName) external   {
        require(accessControls.hasAdminRole(msg.sender));

        tokenName = _tokenName;
        emit TokenNameSet(_tokenName);
    }

    function setTokenDescription(string calldata _tokenDescription) external   {
        require(accessControls.hasAdminRole(msg.sender));
        tokenDescription = _tokenDescription;
        emit TokenDescriptionSet(_tokenDescription);
    }

    function setMaxPercentage(uint256 _maxPercentage) external {
        require(accessControls.hasAdminRole(msg.sender));
        maxPercentage = _maxPercentage;
    }

    function setImgUrl(string memory _url) external {
        require(accessControls.hasAdminRole(msg.sender));
        imgUrl = _url;
    }

    /**
     * @notice Given a token ID and seed, construct a token URI for an NFT.
     * @dev The returned value may be a base64 encoded data URI or an API URL.
     */
    function tokenURI(uint256 tokenId) external view  returns (string memory) {
        if (isDataURIEnabled) {
            return dataURI(tokenId);
        }
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }


    /**
     * @notice Given a token ID and seed, construct a base64 encoded data URI for an NFT.
     */
    function dataURI(uint256 tokenId) public view returns (string memory) {
        string memory name = string(abi.encodePacked('veNFT #', tokenId.toString()));

        uint256 end = IStickyPool(address(poolAddress)).locked__end(tokenId);
        uint256 veAmount = IStickyPool(address(poolAddress)).balanceOfNFT(tokenId);
        uint256 totalSupply = IStickyPool(address(poolAddress)).totalSupply();
        uint256 amount = poolAddress.stakedBalance(tokenId);

        string memory dopplerSvg;
        string memory imgSvg;
        string memory textSvg;

        {
            uint vePercentage =  PERCENTAGE_PRECISION * veAmount / totalSupply;
            string memory width;
            string memory height;
            string memory xy;
            if(vePercentage < maxPercentage) {
                uint wh = PERCENTAGE_PRECISION * vePercentage / maxPercentage;
                string memory formattedWh = formatAmountDecimals(wh);
                xy = (100-wh/1e18).toString();
                width = formattedWh;
                height = formattedWh;
            } else {
                xy = '0';
                width = '100';
                height = '100';
            }
            dopplerSvg = _getDopplerSvg(width, height, xy);
            imgSvg = _getImgSvg(width, height, xy);
            textSvg = _getTextSvg(formatAmountSeperators(veAmount), end, formatAmountSeperators(amount));    
        }

        string memory image = string(abi.encodePacked('data:image/svg+xml;base64,', Base64.encode(bytes(_tokenImage(imgSvg, dopplerSvg, textSvg)))));
        string memory description = string(abi.encodePacked('This NFT represents locked tokens, staked until the lock end date.'));
        string memory attributes = generateAttributesList(tokenId);

        return genericDataURI(name, description, image, attributes);
    }

    /**
     * @notice Given a token ID, construct a base64 encoded SVG.
     */
    function _tokenImage(string memory veJellySvg, string memory dopplerSvg, string memory textSvg) internal pure returns (string memory output) {
        output = '<svg viewBox="0 0 1200 1200" xmlns="http://www.w3.org/2000/svg"><rect width="100%" height="100%" fill="black"/>';
        output = string(abi.encodePacked(output, veJellySvg, dopplerSvg, textSvg, '</svg>'));
    }

    function _getImgSvg(string memory width, string memory height, string memory xy) internal view returns (string memory output) {
        output = string(abi.encodePacked('<svg x="', xy, '%" y="', xy, '%" width="', width, '%" height="', height, '%" viewBox="0 0 1460 1550" preserveAspectRatio="xMidYMid meet">'));
        output = string(abi.encodePacked(output, '<image class="svg-image" href="', imgUrl, '"/></svg>'));

        // output = string(abi.encodePacked('<svg x="', x, '%" width="', width, '%" height="', height, '%" viewBox="0 0 380 380" fill="#8866D4" fill-opacity="0.85">', '<path  d="M185.8,381l-30.35-57.59-52.36,38.77L100.8,297.1,36.86,309.3,63,249.64,0,232.88,49.47,190.5,0,148.12l63-16.76L36.86,71.7l64,12.21,2.28-65.1,52.36,38.77L185.8,0l30.35,57.58,52.36-38.77,2.29,65.1L334.75,71.7l-26.1,59.66,63,16.76L322.13,190.5l49.47,42.38-63,16.77,26.09,59.66L270.8,297.1l-2.29,65.1-52.35-38.78Zm-23-90.08,23,43.54,23-43.54,39.51,29.27L250,271l48.36,9.24-19.72-45.08,47.53-12.66-37.39-32,37.39-32-47.53-12.66,19.73-45.08L250,110,248.27,60.8,208.75,90.07,185.8,46.54l-23,43.53L123.33,60.8,121.61,110l-48.36-9.24L93,145.82,45.45,158.48l37.38,32-37.38,32L93,235.18,73.25,280.26,121.61,271l1.72,49.18Z" /> </svg>'));
    } 

    function _getDopplerSvg(string memory width, string memory height, string memory y) internal pure returns (string memory output) {
        output = string(abi.encodePacked('<svg y="', y, '%" width="', width, '%" height="', height, '%" viewBox="0 0 360 360" translate="(20,2.5)" rotate="10" fill="#071B7E" fill-opacity="0.9">', '<path class="cls-1" d="M180.42,240.38l-60-60,60-60,60,60Zm-28.1-60,28.1,28.09,28.09-28.09-28.09-28.1Z"/><path class="cls-1" d="M180.42,300,60.87,180.42,180.42,60.87,300,180.42ZM92.74,180.42l87.68,87.67,87.67-87.67L180.42,92.74Z"/><path class="cls-1" d="M180.42,360.83,0,180.42,180.42,0,360.84,180.42ZM31.88,180.42,180.42,329,329,180.42,180.42,31.87Z"/><polygon class="cls-1" points="213.81 358.43 244.64 358.43 358.54 244.54 358.54 213.7 213.81 358.43"/><polygon class="cls-1" points="213.59 2.17 358.54 147.13 358.54 116.29 244.42 2.17 213.59 2.17"/><polygon class="cls-1" points="147.25 2.17 116.41 2.17 1.25 117.33 1.25 148.17 147.25 2.17"/><polygon class="cls-1" points="1.25 243.5 116.19 358.43 147.03 358.43 1.25 212.66 1.25 243.5"/><polygon class="cls-1" points="84.61 2.17 53.42 2.17 1.25 54.34 1.25 85.53 84.61 2.17"/><polygon class="cls-1" points="84.39 358.43 1.25 275.3 1.25 306.49 53.2 358.43 84.39 358.43"/><polygon class="cls-1" points="358.54 84.48 358.54 53.3 307.42 2.17 276.23 2.17 358.54 84.48"/><polygon class="cls-1" points="276.45 358.43 307.64 358.43 358.54 307.53 358.54 276.35 276.45 358.43"/></svg>'));
    } 

    function _getTextSvg(string memory _balanceOf, uint _locked_end, string memory _value) internal pure returns (string memory output) {
        output = '<svg preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 20px; }</style>';
        output = string(abi.encodePacked(output, '<text x="90" y="160" class="base">ve balance ', _balanceOf, '</text><text x="90" y="185" class="base">lock end date ', timestampToString(_locked_end), '</text><text x="90" y="210" class="base">staked ', _value, '</text></svg>'));
    } 

    /**
     * @notice Convert an amount to decimals as a string with 2dp
     */
    function formatAmountDecimals(uint256 amount) internal view returns (string memory) {
        string memory amountStr = (amount / 10 ** 18).toString();
        uint256 remainder = (amount / 10 ** 16) % 100;
        string memory remainderStr;
        if (remainder > 9) {
            remainderStr = string(abi.encodePacked((remainder).toString()));
        } else if (remainder == 0) {
            remainderStr = '00';
        } else  {
            remainderStr = string(abi.encodePacked('0', (remainder).toString()));
        }
        return string(abi.encodePacked(amountStr, '.', remainderStr)); 
    }

    /**
     * @notice Pads missing zeros from modulus amounts
     */
    function formatModStr(uint256 amount) internal pure returns (string memory) {
        if (amount > 99) {
            return string(abi.encodePacked((amount).toString()));
        } else if (amount > 9) {
            return string(abi.encodePacked('0',(amount).toString()));
        } else if (amount == 0) {
            return '000';
        } else {
            return string(abi.encodePacked('00',(amount).toString()));
        }
    }

    /**
     * @notice Comma serperated thousand seperators
     */
    function formatAmountSeperators(uint256 amount) internal view returns (string memory) {
        uint256 modAmount = amount / 10 ** 18;
        uint256 first = (amount / 10 ** 18) % 1000;
        uint256 second = (amount / 10 ** 21) % 1000;
        uint256 third = (amount / 10 ** 24) % 1000;
        uint256 fourth = (amount / 10 ** 27) % 1000;

        if (modAmount > 999999999) {
            return string(abi.encodePacked(fourth.toString(), ',', formatModStr(third),  ',',formatModStr(second), ',', formatModStr(first)));
        } else if (modAmount > 999999) {
            return string(abi.encodePacked(third.toString(),  ',', formatModStr(second),  ',', formatModStr(first)));
        } else if (modAmount > 999) {
            return string(abi.encodePacked(second.toString(),  ',', formatModStr(first)));
        } else  {
            return modAmount.toString();
        }
    }

    /**
     * @notice NFT Atrributes based on Token ID
     */
    function generateAttributesList(uint256 tokenId) public view returns (string memory) {
        uint256 amount = poolAddress.stakedBalance(tokenId);
        return string(
            abi.encodePacked(
                '{"trait_type":"Staked Amount","value":', formatAmountDecimals(amount),'},',
                '{"trait_type":"Lock ID","value":', tokenId.toString(),'}'
            )
        );
    }

    /**
     * @notice Given a name, description, and seed, construct a base64 encoded data URI.
     */
    function genericDataURI(
        string memory _name,
        string memory _description,
        string memory _image,
        string memory _attributes
    ) public view returns (string memory) {
        TokenURIParams memory params = TokenURIParams({
            name: _name,
            description: _description,
            image: _image,
            attributes: _attributes
        });
        return constructTokenURI(params);
    }

    function timestampToDate(uint timestamp) public pure returns (uint year, uint month, uint day) {
        (year, month, day) = BokkyPooBahsDateTimeLibrary.timestampToDate(timestamp);
    }

    function timestampToString(uint timestamp) public pure returns (string memory) {
        (uint year, uint month, uint day) = BokkyPooBahsDateTimeLibrary.timestampToDate(timestamp);
        return string(abi.encodePacked(dayOfMonthString(day), ' ', monthStringShort(month), ' ', year.toString()));
    }

    function monthStringShort (uint month) public pure returns (string memory) {
        if (month == 1) return "Jan";
        if (month == 2) return "Feb";
        if (month == 3) return "Mar";
        if (month == 4) return "Apr";
        if (month == 5) return "May";
        if (month == 6) return "Jun";
        if (month == 7) return "Jul";
        if (month == 8) return "Aug";
        if (month == 9) return "Sep";
        if (month == 10) return "Oct";
        if (month == 11) return "Nov";
        if (month == 12) return "Dec";
        return "";
    }

    function dayOfMonthString (uint dayOfMonth) public pure returns (string memory) {
        if (dayOfMonth == 1) return "1st";
        if (dayOfMonth == 2) return "2nd";
        if (dayOfMonth == 3) return "3rd";
        if (dayOfMonth == 21) return "21st";
        if (dayOfMonth == 22) return "22nd";
        if (dayOfMonth == 23) return "23rd";
        if (dayOfMonth == 31) return "31st";
        if (dayOfMonth < 31 && dayOfMonth > 0 ) {
            return string(abi.encodePacked(dayOfMonth.toString(), 'th'));
        }
    }


    //--------------------------------------------------------
    // Factory
    //--------------------------------------------------------

    /**
     * @notice Initializes main contract variables.
     * @dev Init function.
     * @param _poolAddress Address of the pool contract.

     */
    function initDescriptor(
        address _poolAddress,
        address _accessControls,
        uint256 _maxPercentage
    ) public 
    {
        require(!initialised);
        poolAddress = IJellyPool(_poolAddress);
        accessControls = IJellyAccessControls(_accessControls);
        isDataURIEnabled = true;
        initialised = true;
        maxPercentage = _maxPercentage;
    }

    function init(bytes calldata _data) external override payable {}

    function initContract(
        bytes calldata _data
    ) external override {
        (
        address _poolAddress,
        address _accessControls,
        uint256 _maxPercentage
        ) = abi.decode(_data, (address, address, uint256));

        initDescriptor(
                        _poolAddress,
                        _accessControls,
                        _maxPercentage
                    );
    }

}

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
        require(value == 0);
        return string(buffer);
    }
}

/// @title A library used to construct ERC721 token URIs and SVG images
/// @dev From the Nouns NFT descriptor

pragma solidity 0.8.6;

import { Base64 } from "Base64.sol";

contract NFTDescriptor {
    struct TokenURIParams {
        string name;
        string description;
        string image;
        string attributes;
    }

    /**
     * @notice Construct an ERC721 token URI.
     */
    function constructTokenURI(TokenURIParams memory params)
        public
        view
        returns (string memory)
    {
        // prettier-ignore
        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked('{"name":"', params.name, '", "description":"', params.description, '", "image": "', params.image,'", "attributes": [', params.attributes, ']}')
                    )
                )
            )
        );
    }

}

pragma solidity 0.8.6;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

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
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}

pragma solidity 0.8.6;

interface IJellyPool {

    function setRewardsContract(address _addr) external;
    function setTokensClaimable(bool _enabled) external;

    function stakedTokenTotal() external view returns(uint256);
    function stakedBalance(uint256 _tokenId) external view returns(uint256);
    function tokensClaimable() external view returns(bool);
    function poolToken() external view returns(address);

}

pragma solidity 0.8.6;

import "IMasterContract.sol";

interface IJellyContract is IMasterContract {
    /// @notice Init function that gets called from `BoringFactory.deploy`.
    /// Also kown as the constructor for cloned contracts.

    function TEMPLATE_ID() external view returns(bytes32);
    function TEMPLATE_TYPE() external view returns(uint256);
    function initContract( bytes calldata data ) external;

}

pragma solidity 0.8.6;

interface IMasterContract {
    /// @notice Init function that gets called from `BoringFactory.deploy`.
    /// Also kown as the constructor for cloned contracts.
    /// Any ETH send to `BoringFactory.deploy` ends up here.
    /// @param data Can be abi encoded arguments or anything else.
    function init(bytes calldata data) external payable;
}

pragma solidity 0.8.6;

interface IJellyAccessControls {
    function hasAdminRole(address _address) external  view returns (bool);
    function addAdminRole(address _address) external;
    function removeAdminRole(address _address) external;
    function hasMinterRole(address _address) external  view returns (bool);
    function addMinterRole(address _address) external;
    function removeMinterRole(address _address) external;
    function hasOperatorRole(address _address) external  view returns (bool);
    function addOperatorRole(address _address) external;
    function removeOperatorRole(address _address) external;
    function initAccessControls(address _admin) external ;

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.01
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------

library BokkyPooBahsDateTimeLibrary {

    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;

    uint constant DOW_MON = 1;
    uint constant DOW_TUE = 2;
    uint constant DOW_WED = 3;
    uint constant DOW_THU = 4;
    uint constant DOW_FRI = 5;
    uint constant DOW_SAT = 6;
    uint constant DOW_SUN = 7;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   https://aa.usno.navy.mil/faq/JD_formula.html
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(uint year, uint month, uint day) internal pure returns (uint _days) {
        require(year >= 1970);
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        int __days = _day
          - 32075
          + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
          + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
          - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
          - OFFSET19700101;

        _days = uint(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function timestampFromDate(uint year, uint month, uint day) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }
    function timestampFromDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR + minute * SECONDS_PER_MINUTE + second;
    }
    function timestampToDate(uint timestamp) internal pure returns (uint year, uint month, uint day) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function timestampToDateTime(uint timestamp) internal pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function isValidDate(uint year, uint month, uint day) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }
    function isValidDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (bool valid) {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }
    function isLeapYear(uint timestamp) internal pure returns (bool leapYear) {
        (uint year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }
    function _isLeapYear(uint year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }
    function isWeekDay(uint timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }
    function isWeekEnd(uint timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }
    function getDaysInMonth(uint timestamp) internal pure returns (uint daysInMonth) {
        (uint year, uint month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }
    function _getDaysInMonth(uint year, uint month) internal pure returns (uint daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }
    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint timestamp) internal pure returns (uint dayOfWeek) {
        uint _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = (_days + 3) % 7 + 1;
    }

    function getYear(uint timestamp) internal pure returns (uint year) {
        (year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getMonth(uint timestamp) internal pure returns (uint month) {
        (,month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getDay(uint timestamp) internal pure returns (uint day) {
        (,,day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getHour(uint timestamp) internal pure returns (uint hour) {
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }
    function getMinute(uint timestamp) internal pure returns (uint minute) {
        uint secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }
    function getSecond(uint timestamp) internal pure returns (uint second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = (month - 1) % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }
    function addMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }
    function addSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = yearMonth % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }
    function subMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }
    function subSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _years) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear,,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear,,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }
    function diffMonths(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _months) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear, uint fromMonth,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear, uint toMonth,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }
    function diffDays(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }
    function diffHours(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _hours) {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }
    function diffMinutes(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _minutes) {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }
    function diffSeconds(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _seconds) {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
    }
}