// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

/**

   ◊◊◊◊◊◊◊◊◊◊ ◊◊◊◊ ◊◊◊◊  ◊◊◊◊◊◊◊◊◊       ◊◊◊◊◊◊◊    ◊◊◊◊◊◊◊   ◊◊◊◊◊◊◊◊    ◊◊◊◊◊◊◊◊    ◊◊◊◊◊◊◊◊◊  ◊◊◊◊  ◊◊◊◊
   ◊◊◊◊◊◊◊◊◊◊ ◊◊◊◊ ◊◊◊◊  ◊◊◊◊◊◊◊◊◊      ◊◊◊◊◊◊◊◊◊  ◊◊◊◊◊◊◊◊◊  ◊◊◊◊◊◊◊◊◊   ◊◊◊◊◊◊◊◊◊   ◊◊◊◊◊◊◊◊◊  ◊◊◊◊  ◊◊◊◊
      ◊◊◊◊    ◊◊◊◊ ◊◊◊◊  ◊◊◊◊          ◊◊◊◊  ◊◊◊◊  ◊◊◊◊◊◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊       ◊◊◊◊  ◊◊◊◊
      ◊◊◊◊    ◊◊◊◊ ◊◊◊◊  ◊◊◊◊          ◊◊◊◊  ◊◊◊◊  ◊◊◊◊◊◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊       ◊◊◊◊  ◊◊◊◊
      ◊◊◊◊    ◊◊◊◊ ◊◊◊◊  ◊◊◊◊          ◊◊◊◊  ◊◊◊◊  ◊◊◊◊ ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊       ◊◊◊◊◊ ◊◊◊◊
      ◊◊◊◊    ◊◊◊◊◊◊◊◊◊  ◊◊◊◊◊◊◊       ◊◊◊◊        ◊◊◊◊ ◊◊◊◊  ◊◊◊◊ ◊◊◊◊   ◊◊◊◊  ◊◊◊◊  ◊◊◊◊◊◊◊    ◊◊◊◊◊◊◊◊◊◊
      ◊◊◊◊    ◊◊◊◊◊◊◊◊◊  ◊◊◊◊◊◊◊       ◊◊◊◊ ◊◊◊◊◊  ◊◊◊◊◊◊◊◊◊  ◊◊◊◊◊◊◊◊◊   ◊◊◊◊  ◊◊◊◊  ◊◊◊◊◊◊◊    ◊◊◊◊◊◊◊◊◊◊
      ◊◊◊◊    ◊◊◊◊ ◊◊◊◊  ◊◊◊◊          ◊◊◊◊ ◊◊◊◊◊  ◊◊◊◊◊◊◊◊◊  ◊◊◊◊◊◊◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊       ◊◊◊◊ ◊◊◊◊◊
      ◊◊◊◊    ◊◊◊◊ ◊◊◊◊  ◊◊◊◊          ◊◊◊◊  ◊◊◊◊  ◊◊◊◊ ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊       ◊◊◊◊  ◊◊◊◊
      ◊◊◊◊    ◊◊◊◊ ◊◊◊◊  ◊◊◊◊          ◊◊◊◊  ◊◊◊◊  ◊◊◊◊ ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊       ◊◊◊◊  ◊◊◊◊
      ◊◊◊◊    ◊◊◊◊ ◊◊◊◊  ◊◊◊◊◊◊◊◊◊      ◊◊◊◊◊◊◊◊◊  ◊◊◊◊ ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊◊◊◊◊◊   ◊◊◊◊◊◊◊◊◊  ◊◊◊◊  ◊◊◊◊
      ◊◊◊◊    ◊◊◊◊ ◊◊◊◊  ◊◊◊◊◊◊◊◊◊       ◊◊◊◊◊◊◊   ◊◊◊◊ ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊◊◊◊◊    ◊◊◊◊◊◊◊◊◊  ◊◊◊◊  ◊◊◊◊

 */

import "fount-contracts/auth/Auth.sol";
import "openzeppelin/utils/Strings.sol";
import "./interfaces/IMetadata.sol";
import "./interfaces/ITheGardenNFT.sol";

/**
 * @author Fount Gallery
 * @title  Off-chain token metadata module
 * @notice Separate contract for token metadata so it can be upgraded if necessary
 */
contract Metadata is IMetadata, Auth {
    using Strings for uint256;

    /// @notice Address of the NFT contract so it can query the active batch
    address public theGarden;

    /// @notice Base URI for each arrangement
    mapping(uint256 => string) public baseUriForArrangement;

    /// @dev Error for when there's no base URI set for an arrangement
    error NoUriForArrangement();

    /* ------------------------------------------------------------------------
       I N I T
    ------------------------------------------------------------------------ */

    constructor(address owner_, address admin_) Auth(owner_, admin_) {}

    /* ------------------------------------------------------------------------
       A D M I N
    ------------------------------------------------------------------------ */

    /**
     * @notice Admin function to set The Garden contract address
     * @dev Allows `tokenURI` to get the active arrangement from The Garden
     * @param theGarden_ The Garden contract address
     */
    function setTheGardenAddress(address theGarden_) external onlyOwnerOrAdmin {
        theGarden = theGarden_;
    }

    /**
     * @notice Admin function to set base URI for a given arrangement
     * @param arrangement The arrangement number to set the base URI for
     * @param baseUri The base URI for the arrangement
     */
    function setBaseUriForArrangement(uint256 arrangement, string memory baseUri)
        external
        onlyOwnerOrAdmin
    {
        baseUriForArrangement[arrangement] = baseUri;
    }

    /* ------------------------------------------------------------------------
       R E N D E R
    ------------------------------------------------------------------------ */

    /**
     * @notice Renders token metadata from a base URI
     * @dev Checks with The Garden contract to get the arrangement that the token
     * is from. It then looks up the base URI in this contract. If it's not been set
     * for the arrangement, then it will revert, else it concats the token id
     * on to the base URI for the arrangement.
     *
     * @param id The token to get metadata for
     */
    function tokenURI(uint256 id) public view override returns (string memory) {
        uint256 arrangement = ITheGardenNFT(theGarden).arrangementForToken(id);
        bytes memory uri = bytes(baseUriForArrangement[arrangement]);
        if (!(uri.length > 0)) revert NoUriForArrangement();
        return string.concat(string(uri), id.toString());
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

/**
 * @author Sam King (samkingstudio.eth) for Fount Gallery
 * @title  Simple owner and admin authentication
 * @notice Allows the management of a contract by using simple ownership and admin modifiers.
 */
abstract contract Auth {
    /* ------------------------------------------------------------------------
                                   S T O R A G E
    ------------------------------------------------------------------------ */

    /// @notice Current owner of the contract
    address public owner;

    /// @notice Current admins of the contract
    mapping(address => bool) public admins;

    /* ------------------------------------------------------------------------
                                    E V E N T S
    ------------------------------------------------------------------------ */

    /**
     * @notice When the contract owner is updated
     * @param user The account that updated the new owner
     * @param newOwner The new owner of the contract
     */
    event OwnerUpdated(address indexed user, address indexed newOwner);

    /**
     * @notice When an admin is added to the contract
     * @param user The account that added the new admin
     * @param newAdmin The admin that was added
     */
    event AdminAdded(address indexed user, address indexed newAdmin);

    /**
     * @notice When an admin is removed from the contract
     * @param user The account that removed an admin
     * @param prevAdmin The admin that got removed
     */
    event AdminRemoved(address indexed user, address indexed prevAdmin);

    /* ------------------------------------------------------------------------
                                 M O D I F I E R S
    ------------------------------------------------------------------------ */

    /**
     * @dev Only the owner can call
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "UNAUTHORIZED");
        _;
    }

    /**
     * @dev Only an admin can call
     */
    modifier onlyAdmin() {
        require(admins[msg.sender], "UNAUTHORIZED");
        _;
    }

    /**
     * @dev Only the owner or an admin can call
     */
    modifier onlyOwnerOrAdmin() {
        require((msg.sender == owner || admins[msg.sender]), "UNAUTHORIZED");
        _;
    }

    /* ------------------------------------------------------------------------
                                      I N I T
    ------------------------------------------------------------------------ */

    /**
     * @dev Sets the initial owner and a first admin upon creation.
     * @param owner_ The initial owner of the contract
     * @param admin_ An initial admin of the contract
     */
    constructor(address owner_, address admin_) {
        owner = owner_;
        emit OwnerUpdated(address(0), owner_);

        admins[admin_] = true;
        emit AdminAdded(address(0), admin_);
    }

    /* ------------------------------------------------------------------------
                                     A D M I N
    ------------------------------------------------------------------------ */

    /**
     * @notice Transfers ownership of the contract to `newOwner`
     * @dev Can only be called by the current owner or an admin
     * @param newOwner The new owner of the contract
     */
    function setOwner(address newOwner) public virtual onlyOwnerOrAdmin {
        owner = newOwner;
        emit OwnerUpdated(msg.sender, newOwner);
    }

    /**
     * @notice Adds `newAdmin` as an amdin of the contract
     * @dev Can only be called by the current owner or an admin
     * @param newAdmin A new admin of the contract
     */
    function addAdmin(address newAdmin) public virtual onlyOwnerOrAdmin {
        admins[newAdmin] = true;
        emit AdminAdded(address(0), newAdmin);
    }

    /**
     * @notice Removes `prevAdmin` as an amdin of the contract
     * @dev Can only be called by the current owner or an admin
     * @param prevAdmin The admin to remove
     */
    function removeAdmin(address prevAdmin) public virtual onlyOwnerOrAdmin {
        admins[prevAdmin] = false;
        emit AdminRemoved(address(0), prevAdmin);
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
    function latestArrangement() external view returns (uint256);

    function arrangementForToken(uint256 id) external view returns (uint256);

    function hasTokenBeenReleased(uint256) external view returns (bool);
}