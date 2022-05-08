//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Metadata is Ownable{
    using Strings for uint256;
    using Strings for uint8;

    string  public     baseURI = "https://arweave.net/zUr8QLeAV136LzRA7sNpR843-t-HF5HMLCA3BwGqnDk/";

    string[4] private     turmitesDict = ['LRR','LRL','LRRR','LRRL'];
    string[8] private     patternDict = ['Block','T-shape','C-shape','Stripes','Squares','Thorns','Inverse-L','O-shape'];
    string[68] private    color =      ['000000', '004b23', '007200', '38b000', '9ef01a', 'ffdd00', 'ffa200', 'ff8800',
                                        'ff7b00', '3c096c', '5a189a', '7b2cbf', '9d4edd', '48bfe3', '56cfe1', '64dfdf',
                                        '5aedc9', '9b2226', 'ae2012', 'bb3e03', 'ca6702', '582f0e', '7f4f24', '936639',
                                        'a68a64', 'b6ad90', '414833', 'bcbcbc', 'b1b1b1', '7d7d7d', '4d4d4d', 'ffc2d1',
                                        'ffb3c6', 'ff8fab', 'fb6f92', 'd62828', 'f77f00', 'fcbf49', 'eae2b7', '87bfff',
                                        '3f8efc', '2667ff', '3b28cc', 'ee9b00', 'ffffff', '780000', '660000', '520000',
                                        '3d0000', 'ffd700', '283035', '3b4c61', '569aaa', '6B8f6f', 'd7decd', 'fff963',
                                        '019d51', 'fb3195', '51b1cc', 'dab183', '573f77', '506a78', 'ad8b64', '703f21',
                                        '205947', 'ffd627', 'ff7626', '4e577e'];
    uint8[5][32] private colorDict = [
        [0, 1, 2, 3, 4],        [0, 5, 6, 7, 8],        [0, 9, 10, 11, 12],     [0, 13, 14, 15, 16],
        [0, 17, 18, 19, 20],    [0, 21, 22, 23, 24],    [0, 25, 26, 23, 22],    [0, 27, 28, 29, 30],
        [0, 31, 32, 33, 34],    [0, 35, 36, 37, 38],    [0, 39, 40, 41, 42],    [0, 43, 19, 18, 17],
        [44, 1, 2, 3, 4],       [44, 5, 6, 7, 8],       [44, 9, 10, 11, 12],    [44, 13, 14, 15, 16],
        [44, 17, 18, 19, 20],   [44, 21, 22, 23, 24],   [44, 25, 26, 23, 22],   [44, 27, 28, 29, 30],
        [44, 31, 32, 33, 34],   [44, 45, 46, 47, 48],   [44, 35, 36, 37, 38],   [44, 39, 40, 41, 42],
        [44, 43, 19, 18, 17],   [49, 9, 10, 11, 12],    [49, 21, 22, 23, 24],   [49, 39, 40, 41, 42],
        [50, 51, 52, 53, 54],   [0, 55, 56, 57, 58],    [59, 60, 61, 62, 63],   [0, 64, 65, 66, 67]
    ];
    
    struct Wall{
        uint8        turmite;
        uint8        pattern;
        string       background;
        string[4]    colors;
        uint8        fx;
        string       imageURL;
    }

    constructor() {}

    function setBaseURI(string memory _URI) public onlyOwner {
        baseURI = _URI;
    }
    
    function idToWall(uint _id) private view returns (Wall memory) {
        // Given any integer between 0 and 8191, there is a one way mapping to 
        // NiftyWall metadata.
        uint8 turmiteId = uint8(_id & 0x03);
        uint8 patternId = uint8( (_id >> 2)  & 0x07 );
        uint256 colorId = uint8( (_id >> 5)  & 0x1f );
        uint8 fxId      = uint8( (_id >> 10) & 0x07 );

        string memory background = color[colorDict[colorId][0]];
        string[4] memory colors = [
            color[colorDict[colorId][1]], color[colorDict[colorId][2]], color[colorDict[colorId][3]], color[colorDict[colorId][4]]
        ];

        if (patternId == 0) {
            // Block pattern has no empty space for background
            // We use -1 to indicate no value.
            background = '';
        }

        if (turmiteId <2) {
            // LRR and LRL only use 3 colors
            colors[3] = '';
        }

        if ( (turmiteId>1) && ( (fxId == 2) || (fxId == 6) ) ) {
            // LRRR and LRRL in FX3 and FX8 loose the 4th color.
            colors[3] = '';
        }

        return Wall(
            turmiteId,
            patternId,
            background,
            colors,
            fxId,
            ''
        );
    }
    function imageURI(uint _id) public view returns (string memory) {
        return( string( abi.encodePacked(baseURI, _id.toString(), '.png' )) );
    }
    function _traitToJson(string memory _type, string memory _value) private pure returns (string memory) {
        return( string(abi.encodePacked('{"trait_type":"', _type  ,'","value":"', _value, '"}')) );
    }
    function idToJson(uint _id) external view returns (string memory) {
        Wall memory w = idToWall(_id);        
        string memory turmite     = _traitToJson('Turmite', turmitesDict[w.turmite]);
        string memory pattern     = _traitToJson('Pattern', patternDict[w.pattern]);
        string memory fx          = _traitToJson('Effect', (w.fx+1).toString() );
        string memory background  = _traitToJson('background', bytes(w.background).length > 0 ? w.background : 'None');
        string memory colors;
        string memory image       = imageURI(_id);
        string memory id_to_str   = _id.toString();
        if (bytes(w.colors[3]).length > 0) {
            colors = string( abi.encodePacked(
                _traitToJson('color', w.colors[0]), ',',
                _traitToJson('color', w.colors[1]), ',',
                _traitToJson('color', w.colors[2]), ',',
                _traitToJson('color', w.colors[3])
            ));
        } else {
            colors = string( abi.encodePacked(
                _traitToJson('color', w.colors[0]), ',',
                _traitToJson('color', w.colors[1]), ',',
                _traitToJson('color', w.colors[2])
            ) );
        }
        string memory name = string(abi.encodePacked('NiftyWall #', id_to_str));
        string memory json = string(abi.encodePacked(
            '{"attributes":[', turmite, ',', pattern, ',', fx, ',', background, ',', colors, '],',
            '"description":"', 
                "Each NiftyWall is a unique, 3000x3000 algorithmically generated background. https://niftywalls.xyz/wall/",
                id_to_str,'",',
            '"image":"', image, '",',
            '"external_url":"https://niftywalls.xyz/wall/', id_to_str, '",',
            '"name":"', name ,'"}'
        ));
        return( json );
    }

    function shutdown() public onlyOwner {
        selfdestruct( payable(owner()) );
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