// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import './SolidarityMetadataBase.sol';

/**
 * @title Solidarity Metadata wrapper contract
 */
contract SolidarityMetadata is SolidarityMetadataBase {
    constructor()
        SolidarityMetadataBase(
            'ipfs://',
            'QmT6Em9Dt7RzritFvrvW5CVwvZgp6GE94RxAsnGCuShyiz', // Valeriia Unfurling Final V1.0.0
            'QmXWdy9J7fh3cYDTdpYrLGxa9KXTHLMdNF2729PBmom2f4' // Valeriia Final V1.0.0
        )
    {
        // Implementation version: 1
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// NFTC Open Source Libraries See: https://github.com/NFTCulture/nftc-open-contracts
import {OnChainEncoding} from '@nftculture/nftc-open-contracts/contracts/utility/onchain/OnChainEncoding.sol';

// OZ Libraries
import '@openzeppelin/contracts/access/Ownable.sol';

/**
 * @title SolidarityMetadataBase
 * @author @NiftyMike, NFT Culture
 * @dev Companion contract to SolidarityNFTProjectForUkraine.
 *
 * Responsible for returning on-chain metadata. Built as a separate contract to allow
 * for corrections or improvements to the metadata.
 */
contract SolidarityMetadataBase is Ownable {
    using OnChainEncoding for uint8;

    uint256 public version;

    uint256 private constant TOKEN_TYPE_ONE = 1;
    uint256 private constant TOKEN_TYPE_TWO = 2;

    string private baseURI;
    string private tokenTypeOneURIPart;
    string private tokenTypeTwoURIPart;

    constructor(
        string memory __baseURI,
        string memory __tokenTypeOneURIPart,
        string memory __tokenTypeTwoURIPart
    ) {
        baseURI = __baseURI;
        tokenTypeOneURIPart = __tokenTypeOneURIPart;
        tokenTypeTwoURIPart = __tokenTypeTwoURIPart;
    }

    function setBaseURI(string memory __baseUri) external onlyOwner {
        baseURI = __baseUri;
    }

    function setTokenTypeURIs(
        string memory __tokenTypeOneURIPart,
        string memory __tokenTypeTwoURIPart
    ) external onlyOwner {
        tokenTypeOneURIPart = __tokenTypeOneURIPart;
        tokenTypeTwoURIPart = __tokenTypeTwoURIPart;
    }

    function getAsString(uint256 tokenId, uint256 tokenType) external view returns (string memory) {
        require(tokenType == TOKEN_TYPE_ONE || tokenType == TOKEN_TYPE_TWO, 'Invalid token type');

        if (tokenType == TOKEN_TYPE_ONE) {
            return _videoMetadataString(tokenId);
        } else if (tokenType == TOKEN_TYPE_TWO) {
            return _photoMetadataString(tokenId);
        }

        // unreachable.
        return '';
    }

    function getAsEncodedString(uint256 tokenId, uint256 tokenType)
        external
        view
        returns (string memory)
    {
        require(tokenType == TOKEN_TYPE_ONE || tokenType == TOKEN_TYPE_TWO, 'Invalid token type');

        if (tokenType == TOKEN_TYPE_ONE) {
            return _encode(_videoMetadataString(tokenId));
        } else if (tokenType == TOKEN_TYPE_TWO) {
            return _encode(_photoMetadataString(tokenId));
        }

        // unreachable.
        return '';
    }

    function _encode(string memory stringToEncode) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    OnChainEncoding.encode(bytes(stringToEncode))
                )
            );
    }

    function _photoMetadataString(uint256 tokenId) internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '{"name": "Valeriia #',
                    OnChainEncoding.toString(tokenId),
                    '", "description": "This image was taken in March 2022 in Lviv, Ukraine.  It represents Valeriia, a 5-year-old refugee fleeing the war and it was on the cover of Time Magazine.", "image": "',
                    _photoAsset(),
                    '","attributes": [',
                    _photoAttributes(),
                    '], "external_url": "https://jr-art.io/"}'
                )
            );
    }

    function _videoMetadataString(uint256 tokenId) internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '{"name": "Valeriia Unfurling #',
                    OnChainEncoding.toString(tokenId),
                    '", "description": "This video was taken in March 2022 in Lviv, Ukraine.  It represents Valeriia, a 5-year-old refugee fleeing the war and it was featured on Time.com.", "image": "',
                    _videoAsset(),
                    '","attributes": [',
                    _videoAttributes(),
                    '], "external_url": "https://jr-art.io/"}'
                )
            );
    }

    function _photoAttributes() internal pure virtual returns (string memory) {
        return
            '{"trait_type": "ARTIST", "value": "JR"}, {"trait_type": "FORMAT", "value": "Photo"}, {"trait_type": "LOCATION", "value": "Lviv, Ukraine"}, {"trait_type": "YEAR", "value": "2022"}';
    }

    function _photoAsset() internal view virtual returns (bytes memory) {
        require(bytes(baseURI).length > 0, 'Base unset');
        require(bytes(tokenTypeTwoURIPart).length > 0, 'Type2 unset');

        return abi.encodePacked(baseURI, tokenTypeTwoURIPart);
    }

    function _videoAttributes() internal pure virtual returns (string memory) {
        return
            '{"trait_type": "ARTIST", "value": "JR"}, {"trait_type": "FORMAT", "value": "Video"}, {"trait_type": "LOCATION", "value": "Lviv, Ukraine"}, {"trait_type": "YEAR", "value": "2022"}';
    }

    function _videoAsset() internal view virtual returns (bytes memory) {
        require(bytes(baseURI).length > 0, 'Base unset');
        require(bytes(tokenTypeOneURIPart).length > 0, 'Type1 unset');

        return abi.encodePacked(baseURI, tokenTypeOneURIPart);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/**
 * @title OnChainEncoding
 * @author @NiftyMike, NFT Culture
 * @dev Credit to the Anonymice Library.
 * See https://etherscan.io/address/0xbad6186e92002e312078b5a1dafd5ddf63d3f731#code
 *
 * Not sure who originated this code, but I am re-using many parts of the Anonymice work, appreciate them 
 * releasing it under the MIT license.
 *
 * If you know the original source of this code, please visit us on discord, and I will add a credit here.
 */
library OnChainEncoding {
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Encode data into a string.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

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
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
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