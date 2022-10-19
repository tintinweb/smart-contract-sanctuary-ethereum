// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "solmate/auth/Owned.sol";
import "openzeppelin/utils/Strings.sol";
import "./interfaces/IMetadata.sol";
import "./interfaces/ITheGardenNFT.sol";

/**
 * @author Fount Gallery
 * @title  Off-chain token metadata module
 * @notice Separate contract for token metadata so it can be upgraded if necessary
 */
contract Metadata is IMetadata, Owned {
    using Strings for uint256;

    /// @notice Address of the NFT contract so it can query the active batch
    address private theGarden;

    /// @notice Base URI for each arrangement
    mapping(uint256 => string) public baseUriForArrangement;

    /* ------------------------------------------------------------------------
       I N I T
    ------------------------------------------------------------------------ */

    constructor(address owner_, string memory arrangementOneBaseUri_) Owned(owner_) {
        baseUriForArrangement[1] = arrangementOneBaseUri_;
    }

    /* ------------------------------------------------------------------------
       A D M I N
    ------------------------------------------------------------------------ */

    /**
     * @notice Admin function to set The Garden contract address
     * @dev Allows `tokenURI` to get the active arrangement from The Garden
     * @param theGarden_ The Garden contract address
     */
    function setTheGardenAddress(address theGarden_) external onlyOwner {
        theGarden = theGarden_;
    }

    /**
     * @notice Admin function to set base URI for a given arrangement
     * @param arrangement The arrangement number to set the base URI for
     * @param baseUri The base URI for the arrangement
     */
    function setBaseUriForArrangement(uint256 arrangement, string memory baseUri)
        external
        onlyOwner
    {
        baseUriForArrangement[arrangement] = baseUri;
    }

    /* ------------------------------------------------------------------------
       R E N D E R
    ------------------------------------------------------------------------ */

    /**
     * @notice Renders token metadata from a base URI
     * @dev Checks with The Garden contract to make sure the requested token id is in
     * a batch that has been released and reverts if not, for example:
     *   `id = 34` but only arrangement 1 has been released, then this will revert.
     *
     * TODO: Use a fallback base URI instead of reverting.
     *
     * @param id The token to get metadata for
     */
    function tokenURI(uint256 id) public view override returns (string memory) {
        // Check id is not zero
        require(id > 0, "INVALID_ID");

        // Get the current active arrangement
        uint256 activeArrangement = ITheGardenNFT(theGarden).activeBatch();

        // Hardcode arrangement size until rework of ITheGardenNFT to expose it
        uint256 arrangementSize = 33;

        // Get the arrangement number from the `id`
        uint256 arrangementFromId = ((id - 1) / arrangementSize) + 1;

        // Check that the arrangement for this token id has been released
        require(arrangementFromId <= activeArrangement, "ARRANGEMENT_NOT_RELEASED");

        return string.concat(baseUriForArrangement[arrangementFromId], id.toString());
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

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

interface IMetadata {
    function tokenURI(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

interface ITheGardenNFT {
    function activeBatch() external view returns (uint256);
}