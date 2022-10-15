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

library ERC721SupplyStorage {
    struct Layout {
        // The next token ID to be minted.
        uint256 currentIndex;
        // The number of tokens burned.
        uint256 burnCounter;
        // Maximum possible supply of tokens.
        uint256 maxSupply;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("v2.flair.contracts.storage.ERC721Supply");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../extensions/supply/ERC721SupplyStorage.sol";
import "../../../../access/ownable/OwnableInternal.sol";
import "./ERC721SupplyAdminStorage.sol";
import "./IERC721SupplyAdmin.sol";

abstract contract ERC721SupplyAdminInternal {
    using ERC721SupplyAdminStorage for ERC721SupplyAdminStorage.Layout;
    using ERC721SupplyStorage for ERC721SupplyStorage.Layout;

    function _setMaxSupply(uint256 newValue) internal virtual {
        if (ERC721SupplyAdminStorage.layout().maxSupplyFrozen) {
            revert IERC721SupplyAdmin.ErrMaxSupplyFrozen();
        }

        ERC721SupplyStorage.layout().maxSupply = newValue;
    }

    function _freezeMaxSupply() internal virtual {
        ERC721SupplyAdminStorage.layout().maxSupplyFrozen = true;
    }

    function _maxSupplyFrozen() internal view virtual returns (bool) {
        return ERC721SupplyAdminStorage.layout().maxSupplyFrozen;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

library ERC721SupplyAdminStorage {
    struct Layout {
        bool maxSupplyFrozen;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("v2.flair.contracts.storage.ERC721SupplyAdmin");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../extensions/supply/ERC721SupplyStorage.sol";
import "../../../../access/ownable/OwnableInternal.sol";
import "./ERC721SupplyAdminInternal.sol";
import "./IERC721SupplyAdmin.sol";

/**
 * @title ERC721 - Supply - Admin - Ownable
 * @notice Allows owner of a EIP-721 contract to change max supply of tokens.
 *
 * @custom:type eip-2535-facet
 * @custom:category NFTs
 * @custom:peer-dependencies IERC721SupplyExtension
 * @custom:provides-interfaces IERC721SupplyAdmin
 */
contract ERC721SupplyOwnable is IERC721SupplyAdmin, ERC721SupplyAdminInternal, OwnableInternal {
    function setMaxSupply(uint256 newValue) public virtual onlyOwner {
        _setMaxSupply(newValue);
    }

    function freezeMaxSupply() public virtual onlyOwner {
        _freezeMaxSupply();
    }

    function maxSupplyFrozen() public view virtual override returns (bool) {
        return _maxSupplyFrozen();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IERC721SupplyAdmin {
    error ErrMaxSupplyFrozen();

    function setMaxSupply(uint256 newValue) external;

    function freezeMaxSupply() external;

    function maxSupplyFrozen() external view returns (bool);
}