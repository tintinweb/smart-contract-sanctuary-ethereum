// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import '@ensdomains/ens-contracts/contracts/registry/ENS.sol'; // This is an interface...
import '@ensdomains/ens-contracts/contracts/resolvers/profiles/ITextResolver.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/abstract/JBOperatable.sol';
import '@openzeppelin/contracts/interfaces/IERC721.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import './interfaces/IJBProjectHandles.sol';
import './libraries/JBOperations2.sol';

/** 
  @title 
  JBProjectHandles

  @author 
  peri, jango, drgorilla

  @notice 
  Manages reverse records that point from JB project IDs to ENS nodes. If the reverse record of a project ID is pointed to an ENS node with a TXT record matching the ID of that project, then the ENS node will be considered the "handle" for that project.

  @dev
  Adheres to -
  IJBProjectHandles: General interface for the methods in this contract that interact with the blockchain's state according to the protocol's rules.

  @dev
  Inherits from -
  JBOperatable: Several functions in this contract can only be accessed by a project owner, or an address that has been preconfifigured to be an operator of the project.
*/
contract JBProjectHandles is IJBProjectHandles, JBOperatable {
  //*********************************************************************//
  // --------------------------- custom errors ------------------------- //
  //*********************************************************************//
  error EMPTY_NAME_PART();
  error NO_PARTS();

  //*********************************************************************//
  // --------------------- internal stored properties ------------------ //
  //*********************************************************************//

  /** 
    @notice
    Mapping of project ID to an array of strings that make up an ENS name and its subdomains.

    @dev
    ["jbx", "dao", "foo"] represents foo.dao.jbx.eth.

    _projectId The ID of the project to get an ENS name for.
  */
  mapping(uint256 => string[]) internal _ensNamePartsOf;

  //*********************************************************************//
  // ---------------- public constant stored properties ---------------- //
  //*********************************************************************//

  /** 
    @notice
    The key of the ENS text record.
  */
  string public constant override TEXT_KEY = 'juicebox_project_id';

  //*********************************************************************//
  // --------------- public immutable stored properties ---------------- //
  //*********************************************************************//

  /** 
    @notice
    A contract which mints ERC-721's that represent project ownership and transfers.
  */
  IJBProjects public immutable override projects;

  /** 
    @notice
    The previous JBProjectHandles version, to not loose previously set handles
  */
  IJBProjectHandles public immutable oldJbProjectHandles;

  /** 
    @notice
    The ENS registry contract address.

    @dev
    Same on every network
  */
  ENS public constant ensRegistry = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);

  //*********************************************************************//
  // ------------------------- external views -------------------------- //
  //*********************************************************************//

  /** 
    @notice 
    Returns the handle for a project.

    @dev 
    Requires a TXT record for the `TEXT_KEY` that matches the `_projectId`.
    As some handles were set in the previous version, try to retrieve it too
    (this version takes precedence on the previous version)

    @param _projectId The ID of the project to get the handle of.

    @return The project's handle.
  */
  function handleOf(uint256 _projectId) external view override returns (string memory) {
    // Get a reference to the project's ENS name parts.
    string[] memory _ensNameParts = _ensNamePartsOf[_projectId];

    // Is the ENS not set in this contract?
    if (_ensNameParts.length == 0) {
          // Retrieve a handle potentially stored in the previous JbProjectHandle contract
          _ensNameParts = oldJbProjectHandles.ensNamePartsOf(_projectId);

          // Return an empty string if no ENS set in both versions    
          if(_ensNameParts.length == 0) return '';
    }

    // Compute the hash of the handle
    bytes32 _hashedName = _namehash(_ensNameParts);

    // Get the resolver for this handle, returns address(0) if non-existing
    address textResolver = ensRegistry.resolver(_hashedName);

    // If the handle is not a registered ENS, return empty string
    if(textResolver == address(0)) return '';

    // Find the projectId that the text record of the ENS name is mapped to.
    string memory textRecordProjectId = ITextResolver(textResolver).text(_hashedName, TEXT_KEY);

    // Return empty string if text record from ENS name doesn't match projectId.
    if (keccak256(bytes(textRecordProjectId)) != keccak256(bytes(Strings.toString(_projectId))))
      return '';

    // Format the handle from the name parts.
    return _formatHandle(_ensNameParts);
  }

  /** 
    @notice 
    The parts of the stored ENS name of a project.

    @param _projectId The ID of the project to get the ENS name of.

    @return The parts of the ENS name parts of a project.
  */
  function ensNamePartsOf(uint256 _projectId) external view override returns (string[] memory) {
    return _ensNamePartsOf[_projectId];
  }

  //*********************************************************************//
  // ---------------------------- constructor -------------------------- //
  //*********************************************************************//

  /** 
    @param _projects A contract which mints ERC-721's that represent project ownership and transfers.
    @param _operatorStore A contract storing operator assignments.
  */
  constructor(
    IJBProjects _projects,
    IJBOperatorStore _operatorStore,
    IJBProjectHandles _oldJbProjectHandles
  ) JBOperatable(_operatorStore) {
    projects = _projects;
    oldJbProjectHandles = _oldJbProjectHandles;
  }

  //*********************************************************************//
  // --------------------- external transactions ----------------------- //
  //*********************************************************************//

  /** 
    @notice 
    Associate an ENS name with a project.

    @dev
    ["jbx", "dao", "foo"] represents foo.dao.jbx.eth.

    @dev
    Only a project's owner or a designated operator can set its ENS name parts.

    @param _projectId The ID of the project to set an ENS handle for.
    @param _parts The parts of the ENS domain to use as the project handle, excluding the trailing .eth.
  */
  function setEnsNamePartsFor(uint256 _projectId, string[] memory _parts)
    external
    override
    requirePermission(projects.ownerOf(_projectId), _projectId, JBOperations2.SET_ENS_NAME_FOR)
  {
    // Get a reference to the number of parts are in the ENS name.
    uint256 _partsLength = _parts.length;

    // Make sure there are ens name parts.
    if (_parts.length == 0) revert NO_PARTS();

    // Make sure no provided parts are empty.
    for (uint256 _i = 0; _i < _partsLength; ) {
      if (bytes(_parts[_i]).length == 0) revert EMPTY_NAME_PART();
      unchecked {
        ++_i;
      }
    }

    // Store the parts.
    _ensNamePartsOf[_projectId] = _parts;

    emit SetEnsNameParts(_projectId, _formatHandle(_parts), _parts, msg.sender);
  }

  //*********************************************************************//
  // ------------------------ internal functions ----------------------- //
  //*********************************************************************//

  /** 
    @notice 
    Formats ENS name parts into a handle.

    @param _ensNameParts The ENS name parts to format into a handle.

    @return _handle The formatted ENS handle.
  */
  function _formatHandle(string[] memory _ensNameParts)
    internal
    pure
    returns (string memory _handle)
  {
    // Get a reference to the number of parts are in the ENS name.
    uint256 _partsLength = _ensNameParts.length;

    // Concatenate each name part.
    for (uint256 _i = 1; _i <= _partsLength; ) {
      _handle = string(abi.encodePacked(_handle, _ensNameParts[_partsLength - _i]));

      // Add a dot if this part isn't the last.
      if (_i < _partsLength) _handle = string(abi.encodePacked(_handle, '.'));

      unchecked {
        ++_i;
      }
    }
  }

  /** 
    @notice 
    Returns a namehash for an ENS name.

    @dev 
    See https://eips.ethereum.org/EIPS/eip-137.

    @param _ensNameParts The parts of an ENS name to hash.

    @return namehash The namehash for an ENS name parts.
  */
  function _namehash(string[] memory _ensNameParts) internal pure returns (bytes32 namehash) {
    // Hash the trailing "eth" suffix.
    namehash = keccak256(abi.encodePacked(namehash, keccak256(abi.encodePacked('eth'))));

    // Get a reference to the number of parts are in the ENS name.
    uint256 _nameLength = _ensNameParts.length;

    // Hash each part.
    for (uint256 _i = 0; _i < _nameLength; ) {
      namehash = keccak256(
        abi.encodePacked(namehash, keccak256(abi.encodePacked(_ensNameParts[_i])))
      );
      unchecked {
        ++_i;
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import '@ensdomains/ens-contracts/contracts/resolvers/profiles/ITextResolver.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBProjects.sol';

interface IJBProjectHandles {
  event SetEnsNameParts(
    uint256 indexed projectId,
    string indexed handle,
    string[] parts,
    address caller
  );

  function setEnsNamePartsFor(uint256 _projectId, string[] memory _parts) external;

  function ensNamePartsOf(uint256 _projectId) external view returns (string[] memory);

  function TEXT_KEY() external view returns (string memory);

  function projects() external view returns (IJBProjects);

  function handleOf(uint256 _projectId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

library JBOperations2 {
  uint256 public constant SET_ENS_NAME_FOR = 19;
}

pragma solidity >=0.8.4;

interface ENS {

    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);

    // Logged when an operator is added or removed.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function setRecord(bytes32 node, address owner, address resolver, uint64 ttl) external virtual;
    function setSubnodeRecord(bytes32 node, bytes32 label, address owner, address resolver, uint64 ttl) external virtual;
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external virtual returns(bytes32);
    function setResolver(bytes32 node, address resolver) external virtual;
    function setOwner(bytes32 node, address owner) external virtual;
    function setTTL(bytes32 node, uint64 ttl) external virtual;
    function setApprovalForAll(address operator, bool approved) external virtual;
    function owner(bytes32 node) external virtual view returns (address);
    function resolver(bytes32 node) external virtual view returns (address);
    function ttl(bytes32 node) external virtual view returns (uint64);
    function recordExists(bytes32 node) external virtual view returns (bool);
    function isApprovedForAll(address owner, address operator) external virtual view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface ITextResolver {
    event TextChanged(bytes32 indexed node, string indexed indexedKey, string key);

    /**
     * Returns the text data associated with an ENS node and key.
     * @param node The ENS node to query.
     * @param key The text data key to query.
     * @return The associated text data.
     */
    function text(bytes32 node, string calldata key) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import './../interfaces/IJBOperatable.sol';

/** 
  @notice
  Modifiers to allow access to functions based on the message sender's operator status.

  @dev
  Adheres to -
  IJBOperatable: General interface for the methods in this contract that interact with the blockchain's state according to the protocol's rules.
*/
abstract contract JBOperatable is IJBOperatable {
  //*********************************************************************//
  // --------------------------- custom errors -------------------------- //
  //*********************************************************************//
  error UNAUTHORIZED();

  //*********************************************************************//
  // ---------------------------- modifiers ---------------------------- //
  //*********************************************************************//

  /** 
    @notice
    Only allows the speficied account or an operator of the account to proceed. 

    @param _account The account to check for.
    @param _domain The domain namespace to look for an operator within. 
    @param _permissionIndex The index of the permission to check for. 
  */
  modifier requirePermission(
    address _account,
    uint256 _domain,
    uint256 _permissionIndex
  ) {
    _requirePermission(_account, _domain, _permissionIndex);
    _;
  }

  /** 
    @notice
    Only allows the speficied account, an operator of the account to proceed, or a truthy override flag. 

    @param _account The account to check for.
    @param _domain The domain namespace to look for an operator within. 
    @param _permissionIndex The index of the permission to check for. 
    @param _override A condition to force allowance for.
  */
  modifier requirePermissionAllowingOverride(
    address _account,
    uint256 _domain,
    uint256 _permissionIndex,
    bool _override
  ) {
    _requirePermissionAllowingOverride(_account, _domain, _permissionIndex, _override);
    _;
  }

  //*********************************************************************//
  // ---------------- public immutable stored properties --------------- //
  //*********************************************************************//

  /** 
    @notice 
    A contract storing operator assignments.
  */
  IJBOperatorStore public immutable override operatorStore;

  //*********************************************************************//
  // -------------------------- constructor ---------------------------- //
  //*********************************************************************//

  /** 
    @param _operatorStore A contract storing operator assignments.
  */
  constructor(IJBOperatorStore _operatorStore) {
    operatorStore = _operatorStore;
  }

  //*********************************************************************//
  // -------------------------- internal views ------------------------- //
  //*********************************************************************//

  /** 
    @notice
    Require the message sender is either the account or has the specified permission.

    @param _account The account to allow.
    @param _domain The domain namespace within which the permission index will be checked.
    @param _permissionIndex The permission index that an operator must have within the specified domain to be allowed.
  */
  function _requirePermission(
    address _account,
    uint256 _domain,
    uint256 _permissionIndex
  ) internal view {
    if (
      msg.sender != _account &&
      !operatorStore.hasPermission(msg.sender, _account, _domain, _permissionIndex) &&
      !operatorStore.hasPermission(msg.sender, _account, 0, _permissionIndex)
    ) revert UNAUTHORIZED();
  }

  /** 
    @notice
    Require the message sender is either the account, has the specified permission, or the override condition is true.

    @param _account The account to allow.
    @param _domain The domain namespace within which the permission index will be checked.
    @param _domain The permission index that an operator must have within the specified domain to be allowed.
    @param _override The override condition to allow.
  */
  function _requirePermissionAllowingOverride(
    address _account,
    uint256 _domain,
    uint256 _permissionIndex,
    bool _override
  ) internal view {
    if (
      !_override &&
      msg.sender != _account &&
      !operatorStore.hasPermission(msg.sender, _account, _domain, _permissionIndex) &&
      !operatorStore.hasPermission(msg.sender, _account, 0, _permissionIndex)
    ) revert UNAUTHORIZED();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IJBOperatorStore.sol';

interface IJBOperatable {
  function operatorStore() external view returns (IJBOperatorStore);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './../structs/JBOperatorData.sol';

interface IJBOperatorStore {
  event SetOperator(
    address indexed operator,
    address indexed account,
    uint256 indexed domain,
    uint256[] permissionIndexes,
    uint256 packed
  );

  function permissionsOf(
    address _operator,
    address _account,
    uint256 _domain
  ) external view returns (uint256);

  function hasPermission(
    address _operator,
    address _account,
    uint256 _domain,
    uint256 _permissionIndex
  ) external view returns (bool);

  function hasPermissions(
    address _operator,
    address _account,
    uint256 _domain,
    uint256[] calldata _permissionIndexes
  ) external view returns (bool);

  function setOperator(JBOperatorData calldata _operatorData) external;

  function setOperators(JBOperatorData[] calldata _operatorData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import './../structs/JBProjectMetadata.sol';
import './IJBTokenUriResolver.sol';

interface IJBProjects is IERC721 {
  event Create(
    uint256 indexed projectId,
    address indexed owner,
    JBProjectMetadata metadata,
    address caller
  );

  event SetMetadata(uint256 indexed projectId, JBProjectMetadata metadata, address caller);

  event SetTokenUriResolver(IJBTokenUriResolver indexed resolver, address caller);

  function count() external view returns (uint256);

  function metadataContentOf(uint256 _projectId, uint256 _domain)
    external
    view
    returns (string memory);

  function tokenUriResolver() external view returns (IJBTokenUriResolver);

  function createFor(address _owner, JBProjectMetadata calldata _metadata)
    external
    returns (uint256 projectId);

  function setMetadataOf(uint256 _projectId, JBProjectMetadata calldata _metadata) external;

  function setTokenUriResolver(IJBTokenUriResolver _newResolver) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IJBTokenUriResolver {
  function getUri(uint256 _projectId) external view returns (string memory tokenUri);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** 
  @member operator The address of the operator.
  @member domain The domain within which the operator is being given permissions. A domain of 0 is a wildcard domain, which gives an operator access to all domains.
  @member permissionIndexes The indexes of the permissions the operator is being given.
*/
struct JBOperatorData {
  address operator;
  uint256 domain;
  uint256[] permissionIndexes;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** 
  @member content The metadata content.
  @member domain The domain within which the metadata applies.
*/
struct JBProjectMetadata {
  string content;
  uint256 domain;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

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