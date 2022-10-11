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

pragma solidity ^0.8.15;

/**
 * @title Contract ownership standard interface (event only)
 * @dev see https://eips.ethereum.org/EIPS/eip-173
 */
interface IERC173Events {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Context.sol";

import "./OwnableStorage.sol";
import "./IERC173Events.sol";

abstract contract OwnableInternal is IERC173Events, Context {
    using OwnableStorage for OwnableStorage.Layout;

    modifier onlyOwner() {
        require(_msgSender() == _owner(), "Ownable: sender must be owner");
        _;
    }

    function _owner() internal view virtual returns (address) {
        return OwnableStorage.layout().owner;
    }

    function _transferOwnership(address account) internal virtual {
        OwnableStorage.layout().setOwner(account);
        emit OwnershipTransferred(_msgSender(), account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

library OwnableStorage {
    struct Layout {
        address owner;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("openzeppelin.contracts.storage.Ownable");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function setOwner(Layout storage l, address owner) internal {
        l.owner = owner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/**
 * The caller must be the current contract itself.
 */
error ErrSenderIsNotSelf();

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IERC5192 {
    /// @notice Returns the locking status of an Soulbound Token
    /// @dev SBTs assigned to zero address are considered invalid, and queries
    /// about them do throw.
    /// @param tokenId The identifier for an SBT.
    function locked(uint256 tokenId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./IERC5192.sol";
import "./IERC721LockableInternal.sol";

/**
 * @dev Based on EIP-5192, extension of {ERC721} that allows other facets from the diamond to lock the tokens.
 */
interface IERC721LockableExtension is IERC5192, IERC721LockableInternal {
    /**
     * @dev Locks `amount` of tokens of `account`, of token type `id`.
     *
     * Requirements:
     *
     * - the caller must be diamond itself (other facets).
     */
    function lockByFacet(uint256 id) external;

    function lockByFacet(uint256[] memory ids) external;

    /**
     * @dev Un-locks `amount` of tokens of `account`, of token type `id`.
     *
     * Requirements:
     *
     * - the caller must be diamond itself (other facets).
     */
    function unlockByFacet(uint256 id) external;

    function unlockByFacet(uint256[] memory ids) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IERC721LockableInternal {
    error ErrTokenLocked(uint256 tokenId);

    /// @notice Emitted when the locking status is changed to locked.
    /// @dev If a token is minted and the status is locked, this event should be emitted.
    /// @param tokenId The identifier for a token.
    event Locked(uint256 tokenId);

    /// @notice Emitted when the locking status is changed to unlocked.
    /// @dev If a token is minted and the status is unlocked, this event should be emitted.
    /// @param tokenId The identifier for a token.
    event Unlocked(uint256 tokenId);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../../../common/Errors.sol";
import "../../../../access/ownable/OwnableInternal.sol";
import "../../extensions/lockable/IERC721LockableExtension.sol";
import "./IERC721LockableOwnable.sol";

/**
 * @title ERC721 - Lock as owner
 * @notice Allow locking tokens as the contract owner.
 *
 * @custom:type eip-2535-facet
 * @custom:category NFTs
 * @custom:required-dependencies IERC721LockableExtension
 * @custom:provides-interfaces IERC721LockableOwnable
 */
contract ERC721LockableOwnable is IERC721LockableOwnable, OwnableInternal {
    /**
     * @inheritdoc IERC721LockableOwnable
     */
    function lockByOwner(uint256 id) public virtual onlyOwner {
        IERC721LockableExtension(address(this)).lockByFacet(id);
    }

    /**
     * @inheritdoc IERC721LockableOwnable
     */
    function lockByOwner(uint256[] memory ids) public virtual onlyOwner {
        IERC721LockableExtension(address(this)).lockByFacet(ids);
    }

    /**
     * @inheritdoc IERC721LockableOwnable
     */
    function unlockByOwner(uint256 id) public virtual onlyOwner {
        IERC721LockableExtension(address(this)).unlockByFacet(id);
    }

    /**
     * @inheritdoc IERC721LockableOwnable
     */
    function unlockByOwner(uint256[] memory ids) public virtual onlyOwner {
        IERC721LockableExtension(address(this)).unlockByFacet(ids);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/**
 * @dev Extension of {ERC721} that allows diamond owner to lock tokens.
 */
interface IERC721LockableOwnable {
    function lockByOwner(uint256 id) external;

    function lockByOwner(uint256[] memory ids) external;

    function unlockByOwner(uint256 id) external;

    function unlockByOwner(uint256[] memory ids) external;
}