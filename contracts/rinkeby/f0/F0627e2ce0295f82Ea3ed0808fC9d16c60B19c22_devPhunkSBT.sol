// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Strings.sol";


abstract contract Ownable {
    address public owner; 
    constructor() { owner = msg.sender; }
    modifier onlyOwner { require(owner == msg.sender, "Not Owner!"); _; }
    function transferOwnership(address new_) external onlyOwner { owner = new_; }
}

interface iOCP {
    function tokenURI(uint256 tokenId_) external view returns (string memory);
}

interface iCryptoPhunks {
    function totalSupply() external view returns (uint256);
    function ownerOf(uint256 tokenId_) external view returns (address);
    function balanceOf(address address_) external view returns (uint256); 
}

contract devPhunkSBT is Ownable, iCryptoPhunks {
    
    // Token Details
    string public name = "Dev Phunks SBT";
    string public symbol = "DPSBT";

    string private uri = "https://gateway.pinata.cloud/ipfs/QmcfS3bYBErM2zo3dSRLbFzr2bvitAVJCMh5vmDf3N3B9X/";

    using Strings for uint256;


    function setNameAndSymbol(string calldata name_, string calldata symbol_) external onlyOwner { 
        name = name_;
        symbol = symbol_; 
    }

    uint[] private devPhunks = 
    [8812,8348,6473,6397,1957,826,70,9995,9964,9858,9792,9920,33,9737,9730,9912,9900,9971,
    9746,9830,9721,9725,9724,9710,9750,9985,9597,9708,9610,9699,9583,9467,9436,9451,9260,9345,9388,9332,9344,
    9389,9418,9330,9402,9343,9241,9532,9126,9236,9208,9171,9099,9109,9104,9087,9121,9038,8993,9036,9013,8967,
    8973,9070,9021,8972,8991,8961,8924,8860,8883,8800,8930,8922,8839,8859,8772,8793,8785,8818,8663,8710,8760,
    8664,8654,8640,8692,8636,8600,8585,8546,8525,8594,8517,8463,8448,8513,8442,8514,8450,8418,8435,8402,8457,
    8361,8387,8349,8272,8160,8128,8134,8000,8005,8025,8027,8098,8014,8101,8117,8075,7988,7924,7843,7867,7861,
    7806,7885,7708,7684,7631,7603,7516,7615,7536,7500,7467,7582,7645,7480,7596,7455,7578,7432,7430,7425,7366,
    7389,7360,7335,7299,7297,7287,7296,7154,7206,7117,7129,7253,7286,7096,7179,7067,7066,7041,7142,7028,7018,
    6979,6973,6881,6936,6967,6839,6873,6828,6970,6804,6786,6611,6772,6577,6767,6729,6799,6566,6539,6605,6536,
    6534,6527,6492,6365,6414,6307,6345,6199,6247,6207,6193,6190,6194,6229,6299,6150,6176,6107,6123,6102,6097,
    6019,5981,6054,5987,5887,5961,5859,5849,5720,5742,5772,5615,5655,5614,5541,5618,5640,5498,5468,5470,5481,
    5441,5447,5423,5458,5430,5381,5312,5311,5306,5305,5283,5212,5213,5296,5303,5883,5163,5158,5066,5099,5008,
    4970,4980,4983,5075,4917,4851,4771,4897,4794,4714,4676,4662,4654,4637,4672,4630,4608,4563,4581,4590,4548,
    4497,4489,4583,4487,4480,4443,4445,4482,4457,4414,4401,4371,4366,4368,4265,4218,4239,4196,4163,4200,4190,
    4134,4121,4115,4072,4060,3998,3973,3933,4081,4065,3967,3927,3904,3876,3866,3851,3865,3628,3805,3637,3834,
    3538,3491,3549,3477,3576,3488,3474,3616,3452,3461,3450,3417,3408,3401,3301,3376,3274,3264,3232,3279,3231,
    3214,3226,3198,3177,3151,3165,3145,3133,3126,3144,3110,3095,3048,3023,3067,3004,3021,2982,3002,2998,2979,
    2975,2891,2867,2898,2941,2849,2825,2773,2835,2737,2711,2686,2697,2676,2645,2603,2616,2561,2569,2578,2529,
    2517,2477,2540,2492,2474,2467,2427,2393,2387,2372,2352,2339,2323,2294,2285,2268,2253,2263,2159,2227,2032,
    2241,2038,2148,2221,2031,2005,2117,1996,2334,1971,1943,1949,1940,1939,1934,1912,1910,1875,1775,1814,1709,
    1693,1640,1630,1598,1747,1836,1593,1559,1566,1552,1550,1540,1530,1521,1497,1520,153,1439,1395,1478,1488,
    1448,1430,1323,1453,1406,1296,1281,1261,1255,1232,1244,1203,1201,1220,1176,1097,1156,1089,1071,1073,1036,
    991,983,970,1149,946,945,937,898,918,942,833,785,757,791,725,738,709,679,606,565,553,65,594,652,517,516,
    468,470,405,366,390,316,285,113,230,227,216];

    // Interfaces
    iOCP public OCP = iOCP(0x3Ce95E9aD8DCFBe45fc8267B83B3Ec188D792f40);
    function setOCP(address address_) external onlyOwner {
        OCP = iOCP(address_); }

    iCryptoPhunks public Phunks = iCryptoPhunks(0x5212d789377492fED051fB1c85Ba69a8EF832493);
    function setPhunks(address address_) external onlyOwner {
        Phunks = iCryptoPhunks(address_); 
    }
    
    // Magic Events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    // Magic Logic
    function totalSupply() public pure returns (uint256) {
        // return Phunks.totalSupply();
        return 496;
    }
    function ownerOf(uint256 tokenId_) public view returns (address) {
        return Phunks.ownerOf(tokenId_);
    }
    function balanceOf(address address_) public view returns (uint256) {
        return Phunks.balanceOf(address_);//fix this
    }

    // Token URI
    function tokenURI(uint256 tokenId_) public view returns (string memory) {

        return string(abi.encodePacked(uri, tokenId_.toString()));
        // return OCP.tokenURI(tokenId_);
    }

    function setURI(string memory _uri) external onlyOwner {
        uri = _uri;
    } 

    // ERC721 OpenZeppelin Standard Stuff
    function supportsInterface(bytes4 interfaceId_) public pure returns (bool) {
        return (interfaceId_ == type(iCryptoPhunks).interfaceId || interfaceId_ == type(iOCP).interfaceId);
    }

    function initialize() external onlyOwner {
        for (uint i = 0; i < devPhunks.length; ++i) {
            emit Transfer(address(0), address(this), i);
        }
    }

    function initializeToOwners() external onlyOwner {
        for (uint i = 0; i < devPhunks.length; ++i) {
            emit Transfer(address(0), Phunks.ownerOf(i), i);
        }
    }

}

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