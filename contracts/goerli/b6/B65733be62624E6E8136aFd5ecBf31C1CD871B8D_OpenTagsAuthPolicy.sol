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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "./ITagsAuthPolicy.sol";

contract OpenTagsAuthPolicy is ITagsAuthPolicy, ERC165 {
    function supportsInterface(bytes4 interfaceID) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceID == type(ITagsAuthPolicy).interfaceId || super.supportsInterface(interfaceID);
    }

    function canClaimTag(bytes32, bytes32, address, address, bytes calldata) external virtual override returns (bool) {
        return true;
    }

    function onTagClaimed(
        bytes32,
        bytes32,
        address,
        address,
        bytes calldata
    ) external virtual override returns (bytes32 tagToRevoke) {
        return 0;
    }

    function tagCanBeRevoked(address, bytes32, bytes32, bytes calldata) external virtual override returns (bool) {
        return false;
    }
}