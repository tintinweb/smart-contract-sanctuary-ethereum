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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

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

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

uint256 constant EDITION_SIZE = 20;
uint256 constant EDITION_RELEASE_SCHEDULE = 24 hours;

uint256 constant PRESALE_PERIOD = 48 hours;
uint256 constant EDITION_SALE_PERIOD = EDITION_RELEASE_SCHEDULE * EDITION_SIZE;
uint256 constant UNSOLD_TIMELOCK = EDITION_SALE_PERIOD + 10 days;
uint256 constant PRINT_CLAIM_PERIOD = UNSOLD_TIMELOCK + 30 days;
uint256 constant REAL_ID_MULTIPLIER = 100;

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

interface IMetadata {
    function tokenURI(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

/**          

      `7MM"""Mq.                     mm           
        MM   `MM.                    MM           
        MM   ,M9  ,pW"Wq.   ,pW"Wq.mmMMmm ,pP"Ybd 
        MMmmdM9  6W'   `Wb 6W'   `Wb MM   8I   `" 
        MM  YM.  8M     M8 8M     M8 MM   `YMMMa. 
        MM   `Mb.YA.   ,A9 YA.   ,A9 MM   L.   I8 
      .JMML. .JMM.`Ybmd9'   `Ybmd9'  `MbmoM9mmmP' 

      E D I T I O N S
                
      https://roots.samking.photo/editions

*/

import {Owned} from "solmate/auth/Owned.sol";
import {Strings} from "openzeppelin/utils/Strings.sol";
import {REAL_ID_MULTIPLIER} from "./Constants.sol";
import {IMetadata} from "./IMetadata.sol";

/**
 * @author Sam King (samkingstudio.eth)
 * @title  Roots Editions Metadata
 * @notice A simple metadata contract that uses a base URI per ID
 */
contract Metadata is IMetadata, Owned {
    using Strings for uint256;

    /// @notice The base URI strings per ID
    mapping(uint256 => string) public baseURIs;

    constructor(address owner) Owned(owner) {}

    /**
     * @notice
     * Admin function to set a base URI for a given ID
     *
     * @param id The artwork id
     * @param baseURI The base URI to use
     */
    function setBaseURI(uint256 id, string memory baseURI) external onlyOwner {
        baseURIs[id] = baseURI;
    }

    /**
     * @notice
     * ERC-721-like token URI function to return the correct baseURI
     *
     * @dev
     * Reverts if there is no base URI set for the token
     *
     * @param realId The real token ID to render metadata for
     */
    function tokenURI(uint256 realId) public view override returns (string memory) {
        uint256 id = realId / REAL_ID_MULTIPLIER;

        string memory baseURI = baseURIs[id];
        require(bytes(baseURI).length > 0, "NO_BASE_URI_SET");

        return string(abi.encodePacked(baseURI, "/", realId.toString()));
    }
}