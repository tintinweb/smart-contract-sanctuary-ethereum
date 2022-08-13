//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface storageI {
    function get(uint _id) external view returns (uint);
}

interface namesI {
    function names(uint _id) external view returns (string memory);
}

interface jobsI {
    function minted(uint _id) external view returns (bool);
}

contract MetadataParser is AccessControl {
    using Strings for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // mainet
    address public jobsAddr = 0x878ADc4eF1948180434005D6f2Eb91f0AF3E0d15; 
    address public namesAddr = 0x1FFE4026573cEad0F49355b9D1B276a78F79924F;  
    address public storageAddr = 0x277E820Ff978326831CFF29F431bcd7DeF93511F; 

    struct TraitType {
      string trait_type;
      uint8 index;
    }

    struct Trait {
      string trait_type;
      uint256 trait_index;
      string value;
    }

    struct Metadata {
      string name;
      string description;
      string external_url;
      string image_base_uri;
      string image_extension;
      string image_base_full_uri_1;
      string image_base_full_uri_2;
      string image_full_extension;
    }

    TraitType[] public traits;
    mapping(uint256 => mapping(uint256 => string)) public traitValues;    // trait_type => index => value
    Metadata public metadata;
    storageI private storageContract;
    namesI   private namesContract;
    jobsI    private jobsContract;
    bool private showJobMinted = true;

    // 8 bits per trait
    // 255 = 1111 1111
    uint256 constant TRAIT_MASK = 255;

// constructor

    constructor() {
	    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
	    _grantRole(MINTER_ROLE, msg.sender);

      storageContract = storageI(storageAddr);
      namesContract = namesI(namesAddr);
      jobsContract = jobsI(jobsAddr);

      Metadata memory _metadata = Metadata({
        name : "Regular",
        description : "An extra-ordinary collection by @p0pps",
        external_url : "https:://regular.world/regular/",
        image_base_uri : "ipfs://QmPPeD8vEWmJkqz4pVqkMiJxzrXTZnkR5kqPF7tXBzQron/",
        image_extension : ".jpg",
        image_base_full_uri_1 : "ipfs://QmWnXeqt4goxe7FiUaBsRrg4C75byJLSixzYKPZyD77Wm1/",
        image_base_full_uri_2 : "ipfs://QmNfweKw3p1T2BGqenUnuKefsFzfkd9uGgCN2UUVC2xtk5/",
        image_full_extension : ".png"
      });
      setMetadata(_metadata);
    }

// Setting traits

    // Set all high level trait types
    function writeTraitTypes(string[] memory trait_types) public onlyRole(MINTER_ROLE)  {
      for (uint8 index = 0; index < trait_types.length; index++) {
        traits.push(TraitType(trait_types[index], index));
      }
    }

    function setTraitType(uint8 trait_type_idx, string memory trait_type) public onlyRole(MINTER_ROLE) {
      traits[trait_type_idx] = TraitType(trait_type, trait_type_idx);
    }

    function setTrait(uint8 trait_type, uint8 trait_idx, string memory value) public onlyRole(MINTER_ROLE) {
      traitValues[trait_type][trait_idx] = value;
    }

    // Set all possible values for each trait type
    function writeTraitData(uint8 trait_type, uint8 start, uint256 length, string[] memory trait_values) public onlyRole(MINTER_ROLE) {
      for (uint8 index = 0; index < length; index++) {
        setTrait(trait_type, start+index, trait_values[index]);
      }
    }

// Global Admin

    function setMetadata(Metadata memory _metadata) public onlyRole(MINTER_ROLE) {
      metadata = _metadata;
    }

    function setDescription(string memory description) public onlyRole(MINTER_ROLE) {
      metadata.description = description;
    }

    function setExternalUrl(string memory external_url) public onlyRole(MINTER_ROLE) {
      metadata.external_url = external_url;
    }

    function setImage(string memory image_base_uri, string memory image_extension) public onlyRole(MINTER_ROLE) {
      metadata.image_base_uri = image_base_uri;
      metadata.image_extension = image_extension;
    }

    function setFullImage(string memory _uri, string memory full_image_extension, uint _batch) public onlyRole(MINTER_ROLE) {
      require(_batch == 1 || _batch == 2, "only two batches");
      if (_batch == 1)
        metadata.image_base_full_uri_1 = _uri;
      else
        metadata.image_base_full_uri_2 = _uri;
      metadata.image_full_extension = full_image_extension;
    }

    function setStorageAddr(address _addr) public onlyRole(MINTER_ROLE) {
      storageContract = storageI(_addr);
    }

    function setNamesAddr(address _addr) public onlyRole(MINTER_ROLE) {
      namesContract = namesI(_addr);
    }

    function setShowJobMinted(bool _value) public onlyRole(MINTER_ROLE) {
      showJobMinted = _value;
    }
    
// View
    function traitsById(uint tokenId) public view returns (Trait[] memory) {
      uint256 dna = storageContract.get(tokenId);
      uint256 trait_count = traits.length;
      Trait[] memory tValues = new Trait[](trait_count);
      for (uint256 i = 0; i < trait_count; i++) {
        uint256 bitMask = TRAIT_MASK << (8 * i);
        uint256 trait_index = (dna & bitMask) >> (8 * i);
        string memory value = traitValues[ traits[i].index ][trait_index];
        tValues[i] = Trait(traits[i].trait_type, trait_index, value);
      }
      return tValues;
    }

    function dnaToTraits(uint256 dna) public view returns (Trait[] memory) {
      uint256 trait_count = traits.length;
      Trait[] memory tValues = new Trait[](trait_count);
      for (uint256 i = 0; i < trait_count; i++) {
        uint256 bitMask = TRAIT_MASK << (8 * i);
        uint256 trait_index = (dna & bitMask) >> (8 * i);
        string memory value = traitValues[ traits[i].index ][trait_index];
        tValues[i] = Trait(traits[i].trait_type, trait_index, value);
      }
      return tValues;
    }

    function getAttributesJson(uint tokenId, uint256 dna) internal view returns (string memory) {
      Trait[] memory _traits = dnaToTraits(dna);
      uint8 trait_count = uint8(traits.length);
      string memory attributes = '[\n';
      for (uint8 i = 0; i < trait_count; i++) {
        if (keccak256(abi.encodePacked(_traits[i].value)) != keccak256(abi.encodePacked("None"))){
          attributes = string(abi.encodePacked(attributes,
            '\t{ "trait_type" : "', _traits[i].trait_type, '", "value": "', _traits[i].value,'" }', ',','\n'
          ));
        }
      }
      if (!jobsContract.minted(tokenId) && showJobMinted) {
        attributes = string( abi.encodePacked(attributes,
          '{ "trait_type": "Job", "value" : "Not Minted" }\n'
        ));
      }
      return string(abi.encodePacked(attributes, ']'));
    }

    function getMetadataJson(uint256 tokenId) public view returns (string memory){
      uint256 dna = storageContract.get(tokenId);
      string memory attributes = getAttributesJson(tokenId, dna);
      string memory customName = namesContract.names(tokenId);
      string memory name = bytes(customName).length > 0 ? 
          string(abi.encodePacked("#",tokenId.toString(),", ", capitalize(customName))) : string(abi.encodePacked(metadata.name, " #",tokenId.toString()));
      string memory _fulluri = tokenId < 5000 ? metadata.image_base_full_uri_1 : metadata.image_base_full_uri_2;
      _fulluri = string(abi.encodePacked(_fulluri, tokenId.toString(), metadata.image_full_extension));

      string memory meta = string(
        abi.encodePacked(
          '{\n"name": "', name,
          '",\n"description": "', metadata.description,
          '",\n"attributes":', attributes,
          ',\n"external_url": "', metadata.external_url, tokenId.toString(),'"',
          ',\n"image": "', metadata.image_base_uri, tokenId.toString(), metadata.image_extension,'"',
          ',\n"image-full": "', _fulluri
        )
      );
      return string( abi.encodePacked(meta,'"\n}'));
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
      string memory json = Base64.encode(bytes(getMetadataJson(tokenId)));
      string memory output = string(
        abi.encodePacked("data:application/json;base64,", json)
      );
      return output;
    }

    function capitalize(string memory str) internal pure returns (string memory){
        bytes memory bStr = bytes(str);
        bytes memory bCapitalized = new bytes(bStr.length);
        bCapitalized[0] = bytes1(uint8(bStr[0]) - 32);
        for (uint i = 1; i < bStr.length; i++) {
            if ((uint8(bStr[i]) != 32) && (uint8(bStr[i-1]) == 32)) 
                bCapitalized[i] = bytes1(uint8(bStr[i]) - 32);
            else 
                bCapitalized[i] = bStr[i];
        }
        return string(bCapitalized);
    }

}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

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
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
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
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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