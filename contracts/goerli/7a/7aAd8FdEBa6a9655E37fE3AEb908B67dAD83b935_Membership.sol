/*
Membership

https://github.com/passage-protocol/toll-booth

SPDX-License-Identifier: UNLICENSED
*/

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./interfaces/IMembership.sol";
import "./interfaces/IPlugin.sol";
import "./interfaces/IResolver.sol";
import "./interfaces/IMetadata.sol";
import "./interfaces/IEvents.sol";

pragma solidity 0.8.9;

contract Membership is IMembership, IEvents, ERC165, Ownable {
  using Strings for uint256;

  // data structures
  struct Plugin {
    address plugin;
    uint64 pclass;
  }
  struct Resolver {
    address resolver;
    bytes params;
  }
  struct Class {
    Plugin[] plugins;
    Resolver resolver;
  }

  // constants
  uint256 private constant MAX_CLASSES = 16;

  // members
  mapping(uint256 => Class) private _registry;
  uint256[] private _classes;
  string private _name;
  mapping(address => mapping(uint256 => uint256)) private _balances;
  address private _metadata;
  bytes private _metadataParams;

  /**
   * @param name_ membership program name
   */
  constructor(
    string memory name_,
    address metadata_,
    bytes memory metadataParams_
  ) {
    require(metadata_ != address(0), "Membership: metadata is zero address");
    _name = name_;
    _metadata = metadata_;
    _metadataParams = metadataParams_;
  }

  /**
   * @inheritdoc IERC165
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC165, IERC165)
    returns (bool)
  {
    return
      interfaceId == type(IERC1155).interfaceId ||
      interfaceId == type(IERC1155MetadataURI).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  // ---------- IERC1155 ----------

  /**
   * @inheritdoc IERC1155
   */
  function balanceOf(address account, uint256 id)
    external
    view
    virtual
    override
    returns (uint256)
  {
    return _membership(account, id);
  }

  /**
   * @inheritdoc IERC1155
   */
  function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
    external
    view
    virtual
    override
    returns (uint256[] memory)
  {
    require(
      accounts.length == ids.length,
      "Membership: number of accounts and ids are not equal"
    );
    uint256[] memory arr = new uint256[](2);
    for (uint256 i = 0; i < accounts.length; i++) {
      arr[i] = _membership(accounts[i], ids[i]);
    }
    return arr;
  }

  /**
   * @inheritdoc IERC1155
   */
  function setApprovalForAll(address, bool) external virtual override {
    revert("Membership: approvals not implemented");
  }

  /**
   * @inheritdoc IERC1155
   */
  function isApprovedForAll(address, address)
    external
    view
    virtual
    override
    returns (bool)
  {
    revert("Membership: approvals not implemented");
  }

  /**
   * @inheritdoc IERC1155
   */
  function safeTransferFrom(
    address,
    address,
    uint256,
    uint256,
    bytes memory
  ) external virtual override {
    revert("Membership: transfers not implemented");
  }

  /**
   * @inheritdoc IERC1155
   */
  function safeBatchTransferFrom(
    address,
    address,
    uint256[] memory,
    uint256[] memory,
    bytes memory
  ) external virtual override {
    revert("Membership: transfers not implemented");
  }

  /**
   * @inheritdoc IERC1155MetadataURI
   */
  function uri(uint256 id)
    external
    view
    virtual
    override
    returns (string memory)
  {
    // validate
    require(_registry[id].plugins.length > 0, "Membership: invalid class id");

    // delegate to metadata provider
    return IMetadata(_metadata).uri(address(this), id, _metadataParams);
  }

  // ---------- IMembership ----------

  /**
   * @inheritdoc IMembership
   */
  function name() external view override returns (string memory) {
    return _name;
  }

  /**
   * @inheritdoc IMembership
   */
  function classes() external view returns (uint256[] memory) {
    return _classes;
  }

  /**
   * @inheritdoc IMembership
   */
  function membership(address user, uint256 class)
    external
    view
    returns (uint256)
  {
    return _membership(user, class);
  }

  /**
   * @inheritdoc IMembership
   */
  function update(address user) external {
    for (uint256 i; i < _classes.length; i++) {
      uint256 class = _classes[i];
      uint256 last = _balances[user][class];
      uint256 current = _membership(user, class);
      if (current > last) {
        // mint
        _balances[user][class] = current;
        emit TransferSingle(
          address(this),
          address(0),
          user,
          class,
          current - last
        );
      } else if (current < last) {
        // burn
        _balances[user][class] = current;
        emit TransferSingle(
          address(this),
          user,
          address(0),
          class,
          last - current
        );
      }
    }
  }

  /**
   * @inheritdoc IMembership
   */
  function history(
    uint256 timestamp,
    address user,
    uint256 class,
    uint256 amount,
    bytes32[] calldata proof
  ) external view returns (bool) {
    // TODO
  }

  // ---------- Membership ----------

  /**
   * @inheritdoc IMembership
   */
  function register(
    uint256 class,
    address[] calldata plugins,
    uint256[] calldata pclasses,
    address resolver,
    bytes calldata params
  ) external onlyOwner {
    // validate
    require(class > 0, "Membership: class id is zero");
    require(
      plugins.length == pclasses.length,
      "Membership: number of plugins and classes are not equal"
    );
    require(resolver != address(0), "Membership: resolver is zero address");

    // add class to index if new
    if (_registry[class].plugins.length == 0) {
      require(_classes.length < MAX_CLASSES, "Membership: exceeds max classes");
      _classes.push(class);
    }

    // build class entry
    Class storage c = _registry[class];
    delete c.plugins;
    for (uint256 i; i < plugins.length; i++) {
      require(pclasses[i] > 0, "Membership: plugin class id is zero");
      c.plugins.push(Plugin(plugins[i], uint64(pclasses[i])));
    }
    c.resolver = Resolver(resolver, params);

    // emit
    emit ClassUpdated(class, plugins, pclasses, resolver, params);
  }

  /**
   * @notice update membership metadata provider
   * @param metadata address of new metadata provider
   * @param params arbitrary bytes data for additional metadata parameters
   */
  function setMetadata(address metadata, bytes calldata params)
    external
    onlyOwner
  {
    // validate
    require(metadata != address(0), "Membership: metadata is zero address");

    // update
    _metadata = metadata;
    _metadataParams = params;

    // emit
    emit MetadataUpdated(metadata, params);
  }

  /**
   * @inheritdoc IMembership
   */
  function plugin(uint256 class, uint256 index)
    external
    view
    returns (address plugin, uint256 pclass)
  {
    return (
      _registry[class].plugins[index].plugin,
      _registry[class].plugins[index].pclass
    );
  }

  /**
   * @inheritdoc IMembership
   */
  function pluginCount(uint256 class) external view returns (uint256) {
    return _registry[class].plugins.length;
  }

  /**
   * @inheritdoc IMembership
   */
  function resolver(uint256 class)
    external
    view
    returns (address resolver, bytes memory params)
  {
    return (
      _registry[class].resolver.resolver,
      _registry[class].resolver.params
    );
  }

  /**
   * @inheritdoc IMembership
   */
  function metadata()
    external
    view
    returns (address metadata, bytes memory params)
  {
    return (_metadata, _metadataParams);
  }

  /**
   * @notice internal implementation of membership method
   * @param user address of user
   * @param class id of membership class
   */
  function _membership(address user, uint256 class)
    internal
    view
    returns (uint256)
  {
    Class storage c = _registry[class];

    // validate
    require(c.plugins.length > 0, "Membership: invalid class id");

    // collect shares from each plugin class
    uint256 sz = c.plugins.length;
    uint256[] memory shares = new uint256[](sz);
    for (uint256 i = 0; i < sz; i++) {
      Plugin storage p = c.plugins[i];
      shares[i] = IPlugin(p.plugin).shares(user, p.pclass);
    }

    // hit resolver
    return IResolver(c.resolver.resolver).resolve(shares, c.resolver.params);
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
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

/*
IMembership

https://github.com/passage-protocol/toll-booth

SPDX-License-Identifier: UNLICENSED
*/

import "@openzeppelin/contracts/interfaces/IERC1155.sol";
import "@openzeppelin/contracts/interfaces/IERC1155MetadataURI.sol";

pragma solidity 0.8.9;

interface IMembership is IERC1155, IERC1155MetadataURI {
  /**
   * @notice get name of membership program
   */
  function name() external view returns (string memory);

  /**
   * @notice get list of all class ids associated with membership program
   */
  function classes() external view returns (uint256[] memory);

  /**
   * @notice get membership of user
   * @param user address of user
   * @param class id of membership class
   */
  function membership(address user, uint256 class)
    external
    view
    returns (uint256);

  /**
   * @notice update cached user balance and emit any associated mint or burn events
   * @param user address of user
   */
  function update(address user) external;

  /**
   * @notice prove historical user membership using a merkle proof and stored snapshot root
   * @param timestamp membership snapshot timestamp
   * @param user address of user
   * @param class id of membership class
   * @param amount user membership shares
   * @param proof merkle proof
   */
  function history(
    uint256 timestamp,
    address user,
    uint256 class,
    uint256 amount,
    bytes32[] calldata proof
  ) external view returns (bool);

  /**
   * @notice register class definition for membership program
   * @param class membership class id
   * @param plugins list of plugin addresses
   * @param pclasses list of plugin class ids
   * @param resolver address of resolver library
   * @param params arbitrary bytes data for additional resolver parameters
   */
  function register(
    uint256 class,
    address[] calldata plugins,
    uint256[] calldata pclasses,
    address resolver,
    bytes calldata params
  ) external;

  /**
   * @notice getter for registered class plugin data
   */
  function plugin(uint256 class, uint256 index)
    external
    view
    returns (address plugin, uint256 pclass);

  /**
   * @notice getter for registered class plugin count
   */
  function pluginCount(uint256 class) external view returns (uint256);

  /**
   * @notice getter for registered class resolver data
   */
  function resolver(uint256 class)
    external
    view
    returns (address resolver, bytes memory params);

  /**
   * @notice getter for metadata provider and params
   */
  function metadata()
    external
    view
    returns (address metadata, bytes memory params);
}

/*
IPlugin

https://github.com/passage-protocol/toll-booth

SPDX-License-Identifier: UNLICENSED
*/

pragma solidity 0.8.9;

interface IPlugin {
  /**
   * @notice get metadata about plugin class
   * @param pclass id of membership class
   */
  function metadata(uint256 pclass) external view returns (string memory);

  /**
   * @notice get membership shares for user
   * @param user address of user
   * @param pclass id of membership class
   */
  function shares(address user, uint256 pclass) external view returns (uint256);
}

/*
IResolver

https://github.com/passage-protocol/toll-booth

SPDX-License-Identifier: UNLICENSED
*/

pragma solidity 0.8.9;

interface IResolver {
  /**
   * @notice resolve class membership from underlying plugin shares
   * @param shares list of shares from plugin classes
   * @param params additional encoded data needed by resolver
   */
  function resolve(uint256[] calldata shares, bytes calldata params)
    external
    pure
    returns (uint256);

  /**
   * @notice get a metadata string about the resolver
   * @param params encoded data
   */
  function metadata(bytes calldata params)
    external
    pure
    returns (string memory);
}

/*
IMetadata

https://github.com/passage-protocol/toll-booth

SPDX-License-Identifier: UNLICENSED
*/

pragma solidity 0.8.9;

interface IMetadata {
  /**
   * @notice provide the metadata URI for a membership token class
   * @param membership address of membership contract
   * @param id identifier for membership class
   * @param params additional encoded data needed by metadata provider
   */
  function uri(
    address membership,
    uint256 id,
    bytes calldata params
  ) external view returns (string memory);
}

/*
IEvents

https://github.com/passage-protocol/toll-booth

SPDX-License-Identifier: UNLICENSED
*/

pragma solidity 0.8.9;

interface IEvents {
  event ClassUpdated(
    uint256 indexed class,
    address[] plugins,
    uint256[] pclasses,
    address resolver,
    bytes params
  );

  event MetadataUpdated(address metadata, bytes params);

  event MembershipCreated(address membership, address owner);

  event PluginCreated(address plugin, address membership, address owner);

  event PrebuiltCreated(address membership, address owner);
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/extensions/IERC1155MetadataURI.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}