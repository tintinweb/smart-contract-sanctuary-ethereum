/*
SubscriptionFactory

https://github.com/passage-protocol/toll-booth

SPDX-License-Identifier: UNLICENSED
*/

import "../interfaces/ITollbooth.sol";
import "../interfaces/IEvents.sol";
import "../interfaces/IMembership.sol";
import "../interfaces/IOwnable.sol";
import "../interfaces/IMembershipFactory.sol";
import "../interfaces/ISuperfluidPluginFactory.sol";
import "../interfaces/ITrialPluginFactory.sol";

pragma solidity 0.8.9;

contract SubscriptionFactory is IEvents {
  // members
  address public immutable tollbooth;

  /**
   * @param tollbooth_ address to tollbooth protocol contract
   */
  constructor(address tollbooth_) {
    require(tollbooth_ != address(0));
    tollbooth = tollbooth_;
  }

  /**
   * @param name membership program name
   * @param cost subscription cost in USD/second
   * @param trial optional duration of free trial in seconds (set to zero to disable)
   * @param tokens optional override of accepted tokens (leave empty for default)
   * @param params optional override of metadata params (leave null for default)
   */
  function create(
    string calldata name,
    uint256 cost,
    uint256 trial,
    address[] calldata tokens,
    bytes calldata params
  ) external returns (address) {
    require(cost > 0, "SubscriptionFactory: cost is zero");

    ITollbooth t = ITollbooth(tollbooth);

    // create membership
    address membership = IMembershipFactory(
      t.getAddress(keccak256("passage.tollbooth.factory.membership"))
    ).create(
        name,
        t.getAddress(keccak256("passage.tollbooth.metadata.text")),
        params
      );

    // setup subscription plugin classes
    uint256 n = tokens.length > 0 ? tokens.length : 2;
    address[] memory plugins = new address[](n + (trial > 0 ? 1 : 0));
    uint256[] memory pclasses = new uint256[](n + (trial > 0 ? 1 : 0));

    // create superfluid plugin
    {
      address superfluidPlugin = ISuperfluidPluginFactory(
        t.getAddress(keccak256("passage.tollbooth.factory.superfluid"))
      ).create(tokens, msg.sender, membership);
      IOwnable(superfluidPlugin).transferOwnership(msg.sender);

      for (uint256 i = 0; i < n; i++) {
        plugins[i] = superfluidPlugin;
        pclasses[i] = i + 1;
      }
    }

    // create free trial plugin if requested
    if (trial > 0) {
      address trialPlugin = ITrialPluginFactory(
        t.getAddress(keccak256("passage.tollbooth.factory.trial"))
      ).create(trial, cost, msg.sender, membership);

      IOwnable(trialPlugin).transferOwnership(msg.sender);

      plugins[n] = trialPlugin;
      pclasses[n] = 1;
    }

    // setup chained resolver w/ sum -> cost thresh
    {
      address resolver = t.getAddress(
        keccak256("passage.tollbooth.resolver.chained")
      );

      address[] memory a = new address[](2);
      a[0] = t.getAddress(keccak256("passage.tollbooth.resolver.sum"));
      a[1] = t.getAddress(keccak256("passage.tollbooth.resolver.threshold"));

      bytes[] memory b = new bytes[](2);
      b[0] = "";
      b[1] = abi.encode(cost);

      // register subscription class
      IMembership(membership).register(
        1,
        plugins,
        pclasses,
        resolver,
        abi.encode(a, b)
      );
    }

    // return membership
    IOwnable(membership).transferOwnership(msg.sender);
    emit PrebuiltCreated(membership, msg.sender);
    return membership;
  }
}

/*
ITollbooth

https://github.com/passage-protocol/toll-booth

SPDX-License-Identifier: UNLICENSED
*/

pragma solidity 0.8.9;

interface ITollbooth {
  /**
   * @notice get protocol parameter
   * @param key param key
   * @return param value
   */
  function get(bytes32 key) external view returns (uint256);

  /**
   * @notice set protocol parameter
   * @param key param key
   * @param value param value
   */
  function set(bytes32 key, uint256 value) external;

  /**
   * @notice get protocol parameter as address
   * @param key param key
   * @return param value
   */
  function getAddress(bytes32 key) external view returns (address);

  /**
   * @notice set protocol parameter as address
   * @param key param key
   * @param value param value
   */
  function setAddress(bytes32 key, address value) external;
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
IOwnable

https://github.com/passage-protocol/toll-booth

SPDX-License-Identifier: UNLICENSED
*/

pragma solidity 0.8.9;

interface IOwnable {
  /**
   * @notice transfer contract ownership
   */
  function transferOwnership(address newOwner) external;
}

/*
IMembershipFactory

https://github.com/passage-protocol/toll-booth

SPDX-License-Identifier: UNLICENSED
*/

pragma solidity 0.8.9;

interface IMembershipFactory {
  /**
   * @notice create new membership contract
   * @param name membership program name
   * @param metadata address of metadata provider
   * @param params encoded params for metadata provider
   */
  function create(
    string calldata name,
    address metadata,
    bytes calldata params
  ) external returns (address);
}

/*
ISuperfluidPluginFactory

https://github.com/passage-protocol/toll-booth

SPDX-License-Identifier: UNLICENSED
*/

pragma solidity 0.8.9;

interface ISuperfluidPluginFactory {
  /**
   * @notice create new superfluid plugin contract
   * @param tokens optional override of accepted tokens (leave empty for default)
   * @param receiver address to route incoming funds
   * @param membership address of membership program
   */
  function create(
    address[] calldata tokens,
    address receiver,
    address membership
  ) external returns (address);
}

/*
ITrialPluginFactory

https://github.com/passage-protocol/toll-booth

SPDX-License-Identifier: UNLICENSED
*/

pragma solidity 0.8.9;

interface ITrialPluginFactory {
  /**
   * @notice create new trial plugin contract
   * @param duration free trial period in seconds (set 0 to disable public enrollment)
   * @param amount free trial shares amount
   * @param controller address of controller to issue trial credits
   * @param membership address of membership program
   */
  function create(
    uint256 duration,
    uint256 amount,
    address controller,
    address membership
  ) external returns (address);
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