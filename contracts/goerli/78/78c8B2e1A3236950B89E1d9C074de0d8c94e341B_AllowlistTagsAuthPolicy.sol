// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/**
 * Interface for the legacy (ETH-only) addr function.
 */
interface IAddrResolver {
    event AddrChanged(bytes32 indexed node, address a);

    /**
     * Returns the address associated with an ENS node.
     * @param node The ENS node to query.
     * @return The associated address.
     */
    function addr(bytes32 node) external view returns (address payable);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/**
 * Interface for the new (multicoin) addr function.
 */
interface IAddressResolver {
    event AddressChanged(
        bytes32 indexed node,
        uint256 coinType,
        bytes newAddress
    );

    function addr(bytes32 node, uint256 coinType)
        external
        view
        returns (bytes memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface.
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/profiles/IAddrResolver.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/profiles/IAddressResolver.sol";

interface IENSGuilds is IAddrResolver, IAddressResolver, IERC1155MetadataURI {
    /** Events */
    event Registered(bytes32 indexed guildHash);
    event Deregistered(bytes32 indexed guildHash);
    event TagClaimed(bytes32 indexed guildId, bytes32 indexed tagHash, address recipient);
    event TagRevoked(bytes32 indexed guildId, bytes32 indexed tagHash);
    event FeePolicyUpdated(bytes32 indexed guildId, address feePolicy);
    event TagsAuthPolicyUpdated(bytes32 indexed guildId, address tagsAuthPolicy);
    event AdminTransferred(bytes32 indexed guildId, address newAdmin);
    event SetActive(bytes32 indexed guildId, bool active);
    event TokenUriTemplateSet(bytes32 indexed guildId, string uriTemplate);

    /* Functions */

    /**
     * @notice Registers a new guild from an existing ENS domain.
     * Caller must be the ENS node's owner and ENSGuilds must have been designated an "operator" for the caller.
     * @param guildHash The ENS namehash of the guild's domain
     * @param guildAdmin The address that will administrate this guild
     * @param feePolicy The address of an implementation of FeePolicy to use for minting new tags within this guild
     * @param tagsAuthPolicy The address of an implementaition of TagsAuthPolicy to use for minting new tags within this guild
     */
    function registerGuild(bytes32 guildHash, address guildAdmin, address feePolicy, address tagsAuthPolicy) external;

    /**
     * @notice Deregisters a registered guild.
     * Designates guild as inactive and marks all tags previously minted for that guild as eligible for revocation.
     * @param guildHash The ENS namehash of the guild's domain
     */
    function deregisterGuild(bytes32 guildHash) external;

    /**
     * @notice Claims a guild tag
     * @param guildHash The namehash of the guild for which the tag should be claimed (e.g. namehash('my-guild.eth'))
     * @param tagHash The ENS namehash of the tag being claimed (e.g. keccak256('foo') for foo.my-guild.eth)
     * @param recipient The address that will receive this guild tag (usually same as the caller)
     * @param extraClaimArgs [Optional] Any additional arguments necessary for guild-specific logic,
     *  such as authorization
     */
    function claimGuildTag(
        bytes32 guildHash,
        bytes32 tagHash,
        address recipient,
        bytes calldata extraClaimArgs
    ) external payable;

    /**
     * @notice Claims multiple tags for a guild at once
     * @param guildHash The ENS namehash of the guild's domain
     * @param tagHashes Namehashes of each tag to be claimed
     * @param recipients Recipients of each tag to be claimed
     * @param extraClaimArgs Per-tag extra arguments required for guild-specific logic, such as authorization.
     * Must have same length as array of tagHashes, even if each array element is itself empty bytes
     */
    function claimGuildTagsBatch(
        bytes32 guildHash,
        bytes32[] calldata tagHashes,
        address[] calldata recipients,
        bytes[] calldata extraClaimArgs
    ) external payable;

    /**
     * @notice Returns the current owner of the given guild tag.
     * Returns address(0) if no such guild or tag exists, or if the guild has been deregistered.
     * @param guildHash The ENS namehash of the guild's domain
     * @param tagHash The ENS namehash of the tag (e.g. keccak256('foo') for foo.my-guild.eth)
     */
    function tagOwner(bytes32 guildHash, bytes32 tagHash) external view returns (address);

    /**
     * @notice Attempts to revoke an existing guild tag, if authorized by the guild's AuthPolicy.
     * Deregistered guilds will bypass auth checks for revocation of all tags.
     * @param guildHash The ENS namehash of the guild's domain
     * @param tagHash The ENS namehash of the tag (e.g. keccak256('foo') for foo.my-guild.eth)
     * @param extraData [Optional] Any additional arguments necessary for assessing whether a tag may be revoked
     */
    function revokeGuildTag(bytes32 guildHash, bytes32 tagHash, bytes calldata extraData) external;

    /**
     * @notice Attempts to revoke multiple guild tags
     * @param guildHash The ENS namehash of the guild's domain
     * @param tagHashes ENS namehashes of all tags to revoke
     * @param extraData Additional arguments necessary for assessing whether a tag may be revoked
     */
    function revokeGuildTagsBatch(bytes32 guildHash, bytes32[] calldata tagHashes, bytes[] calldata extraData) external;

    /**
     * @notice Updates the FeePolicy for an existing guild. May only be called by the guild's registered admin.
     * @param guildHash The ENS namehash of the guild's domain
     * @param feePolicy The address of an implementation of FeePolicy to use for minting new tags within this guild
     */
    function updateGuildFeePolicy(bytes32 guildHash, address feePolicy) external;

    /**
     * @notice Updates the TagsAuthPolicy for an existing guild. May only be called by the guild's registered admin.
     * @param guildHash The ENS namehash of the guild's domain
     * @param tagsAuthPolicy The address of an implementaition of TagsAuthPolicy to use for minting new tags within this guild
     */
    function updateGuildTagsAuthPolicy(bytes32 guildHash, address tagsAuthPolicy) external;

    /**
     * @notice Sets the metadata URI template string for fetching metadata for a guild's tag NFTs.
     * May only be called by the guild's registered admin.
     * @param guildHash The ENS namehash of the guild's domain
     * @param uriTemplate The ERC1155 metadata URL template
     */
    function setGuildTokenUriTemplate(bytes32 guildHash, string calldata uriTemplate) external;

    /**
     * @notice Sets a guild as active or inactive. May only be called by the guild's registered admin.
     * @param guildHash The ENS namehash of the guild's domain
     * @param active The new status
     */
    function setGuildActive(bytes32 guildHash, bool active) external;

    /**
     * @notice Returns the current admin registered for the given guild.
     * @param guildHash The ENS namehash of the guild's domain
     */
    function guildAdmin(bytes32 guildHash) external view returns (address);

    /**
     * @notice Transfers the role of guild admin to the given address. May only be called by the guild's registered admin.
     * @param guildHash The ENS namehash of the guild's domain
     * @param newAdmin The new admin
     */
    function transferGuildAdmin(bytes32 guildHash, address newAdmin) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./BaseTagsAuthPolicy.sol";

/**
 * @title AllowlistTagsAuthPolicy
 * @notice A common implementation of TagsAuthPolicy that can be used to restrict minting guild tags to only allowlisted addresses.
 * A separate allowlist is maintained per each guild, and may only be updated by that guild's registered admin.
 */
contract AllowlistTagsAuthPolicy is BaseTagsAuthPolicy {
    mapping(bytes32 => mapping(address => bool)) public guildAllowlists;

    constructor(IENSGuilds ensGuilds) BaseTagsAuthPolicy(ensGuilds) {}

    modifier onlyGuildAdmin(bytes32 guildHash) {
        // solhint-disable-next-line reason-string
        require(_ensGuilds.guildAdmin(guildHash) == _msgSender());
        _;
    }

    function allowMint(bytes32 guildHash, address minter) external onlyGuildAdmin(guildHash) {
        guildAllowlists[guildHash][minter] = true;
    }

    function disallowMint(bytes32 guildHash, address minter) external onlyGuildAdmin(guildHash) {
        guildAllowlists[guildHash][minter] = false;
    }

    /**
     * @inheritdoc ITagsAuthPolicy
     */
    function canClaimTag(
        bytes32 guildHash,
        bytes32,
        address claimant,
        address,
        bytes calldata
    ) external virtual override returns (bool) {
        return guildAllowlists[guildHash][claimant];
    }

    /**
     * @dev removes the claimant from the guild's allowlist
     */
    function _onTagClaimed(
        bytes32 guildHash,
        bytes32,
        address claimant,
        address,
        bytes calldata
    ) internal virtual override returns (bytes32 tagToRevoke) {
        guildAllowlists[guildHash][claimant] = false;
        return 0;
    }

    /**
     * @inheritdoc ITagsAuthPolicy
     */
    function tagCanBeRevoked(address, bytes32, bytes32, bytes calldata) external virtual override returns (bool) {
        return false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./ITagsAuthPolicy.sol";
import "../ensGuilds/interfaces/IENSGuilds.sol";

/**
 * @title BaseTagsAuthPolicy
 * @notice An base implementation of ITagsAuthPolicy
 */
abstract contract BaseTagsAuthPolicy is ITagsAuthPolicy, ERC165, Context, ReentrancyGuard {
    using ERC165Checker for address;

    IENSGuilds internal _ensGuilds;

    constructor(IENSGuilds ensGuilds) {
        require(ensGuilds.supportsInterface(type(IENSGuilds).interfaceId));
        _ensGuilds = ensGuilds;
    }

    function supportsInterface(bytes4 interfaceID) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceID == type(ITagsAuthPolicy).interfaceId || super.supportsInterface(interfaceID);
    }

    /**
     * @inheritdoc ITagsAuthPolicy
     * @dev protects against reentrancy and checks that caller is the Guilds contract. Updating any state
     * is deferred to the implementation.
     */
    function onTagClaimed(
        bytes32 guildHash,
        bytes32 tagHash,
        address claimant,
        address recipient,
        bytes calldata extraClaimArgs
    ) external override nonReentrant returns (bytes32 tagToRevoke) {
        // caller must be guild admin
        // solhint-disable-next-line reason-string
        require(_msgSender() == address(_ensGuilds));

        return _onTagClaimed(guildHash, tagHash, claimant, recipient, extraClaimArgs);
    }

    /**
     * @dev entrypoint for implementations of BaseTagsAuthPolicy that need to update any state
     */
    function _onTagClaimed(
        bytes32 guildHash,
        bytes32 tagHash,
        address claimant,
        address recipient,
        bytes calldata extraClaimArgs
    ) internal virtual returns (bytes32 tagToRevoke);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title TagsAuthPolicy
 * @notice An interface for Guilds to implement that will control authorization for minting tags within that guild
 */
interface ITagsAuthPolicy is IERC165 {
    /**
     * @notice Checks whether a certain address (claimant) may claim a given guild tag
     * @param guildHash The ENS namehash of the guild's domain
     * @param tagHash The ENS namehash of the tag being claimed (e.g. keccak256('foo') for foo.my-guild.eth)
     * @param claimant The address attempting to claim the tag (not necessarily the address that will receive it)
     * @param recipient The address that would receive the tag
     * @param extraClaimArgs [Optional] Any guild-specific additional arguments required
     */
    function canClaimTag(
        bytes32 guildHash,
        bytes32 tagHash,
        address claimant,
        address recipient,
        bytes calldata extraClaimArgs
    ) external returns (bool);

    /**
     * @dev Called by ENSGuilds once a tag has been claimed.
     * Provided for auth policies to update local state, such as erasing an address from an allowlist after that
     * address has successfully minted a tag.
     * @param guildHash The ENS namehash of the guild's domain
     * @param tagHash The ENS namehash of the tag being claimed (e.g. keccak256('foo') for foo.my-guild.eth)
     * @param claimant The address that claimed the tag (not necessarily the address that received it)
     * @param recipient The address that received receive the tag
     * @param extraClaimArgs [Optional] Any guild-specific additional arguments required
     */
    function onTagClaimed(
        bytes32 guildHash,
        bytes32 tagHash,
        address claimant,
        address recipient,
        bytes calldata extraClaimArgs
    ) external returns (bytes32 tagToRevoke);

    /**
     * @notice Checks whether a given guild tag is elligible to be revoked
     * @param revokedBy The address that would attempt to revoke it
     * @param guildHash The ENS namehash of the guild's domain
     * @param tagHash The ENS namehash of the tag being claimed (e.g. keccak256('foo') for foo.my-guild.eth)
     * @param extraRevokeArgs Any additional arguments necessary for assessing whether a tag may be revoked
     */
    function tagCanBeRevoked(
        address revokedBy,
        bytes32 guildHash,
        bytes32 tagHash,
        bytes calldata extraRevokeArgs
    ) external returns (bool);
}