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

import "./TagsAuthPolicy.sol";

contract OpenTagsAuthPolicy is TagsAuthPolicy {
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

    function tagCanBeRevoked(bytes32, bytes32, bytes calldata) external virtual override returns (bool) {
        return false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

abstract contract TagsAuthPolicy is ERC165 {
    function supportsInterface(bytes4 interfaceID) public view virtual override(ERC165) returns (bool) {
        return interfaceID == type(TagsAuthPolicy).interfaceId || super.supportsInterface(interfaceID);
    }

    function canClaimTag(
        bytes32 guildHash,
        bytes32 tagHash,
        address claimant,
        address recipient,
        bytes calldata extraClaimArgs
    ) external virtual returns (bool);

    function onTagClaimed(
        bytes32 guildHash,
        bytes32 tagHash,
        address claimant,
        address recipient,
        bytes calldata extraClaimArgs
    ) external virtual returns (bytes32 tagToRevoke);

    function tagCanBeRevoked(
        bytes32 guildHash,
        bytes32 tagHash,
        bytes calldata extraRevokeArgs
    ) external virtual returns (bool);
}