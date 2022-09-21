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

pragma solidity 0.8.15;

/**
 * @title Contract ownership standard interface (event only)
 * @dev see https://eips.ethereum.org/EIPS/eip-173
 */
interface IERC173Events {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

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

pragma solidity 0.8.15;

library OwnableStorage {
    struct Layout {
        address owner;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("openzeppelin.contracts.storage.Ownable");

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

pragma solidity 0.8.15;

library ERC1155BurnableStorage {
    struct Layout {
        uint256 pausedUntil;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("v2.flair.contracts.storage.ERC1155Burnable");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "../../../../access/ownable/OwnableInternal.sol";
import "../../extensions/burnable/ERC1155BurnableStorage.sol";
import "./IERC1155BurnableAdmin.sol";

/**
 * @title ERC1155 - Burnable - Admin - Ownable
 * @notice Extension of ERC1155 to allow owner to manage burning mechanism.
 *
 * @custom:type eip-2535-facet
 * @custom:category NFTs
 * @custom:peer-dependencies 0xdc290004
 * @custom:provides-interfaces 0x710fb577
 */
contract ERC1155BurnableOwnable is IERC1155BurnableAdmin, OwnableInternal {
    using ERC1155BurnableStorage for ERC1155BurnableStorage.Layout;

    function setBurnablePausedUntil(uint256 newTimestamp) public onlyOwner {
        ERC1155BurnableStorage.layout().pausedUntil = newTimestamp;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IERC1155BurnableAdmin {
    function setBurnablePausedUntil(uint256 newTimestamp) external;
}