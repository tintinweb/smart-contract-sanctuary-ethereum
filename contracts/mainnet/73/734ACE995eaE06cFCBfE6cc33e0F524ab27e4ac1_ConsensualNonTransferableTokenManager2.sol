// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "../utils/Ownable.sol";
import "./InterfaceSupportEditionsTokenManager.sol";
import "./interfaces/IPostTransfer.sol";
import "./interfaces/IPostBurn.sol";
import "./interfaces/ITokenManagerEditions.sol";

/**
 * @author [email protected]
 * @notice A basic token manager that prevents transfers unless 
        recipient is nft contract owner, and allows burns. Second version
 */
contract ConsensualNonTransferableTokenManager2 is
    ITokenManagerEditions,
    IPostTransfer,
    IPostBurn,
    InterfaceSupportEditionsTokenManager
{
    /**
     * @notice See {ITokenManager-canUpdateMetadata}
     */
    function canUpdateMetadata(
        address sender,
        uint256, /* id */
        bytes calldata /* newTokenImageUri */
    ) external view override returns (bool) {
        return Ownable(msg.sender).owner() == sender;
    }

    /**
     * @notice See {ITokenManagerEditions-canUpdateEditionsMetadata}
     */
    function canUpdateEditionsMetadata(
        address editionsAddress,
        address sender,
        uint256, /* editionId */
        bytes calldata, /* newTokenImageUri */
        FieldUpdated /* fieldUpdated */
    ) external view override returns (bool) {
        return Ownable(editionsAddress).owner() == sender;
    }

    /**
     * @notice See {ITokenManager-canSwap}
     */
    function canSwap(
        address sender,
        uint256, /* id */
        address /* newTokenManager */
    ) external view override returns (bool) {
        return Ownable(msg.sender).owner() == sender;
    }

    /**
     * @notice See {ITokenManager-canRemoveItself}
     */
    function canRemoveItself(
        address sender,
        uint256 /* id */
    ) external view override returns (bool) {
        return Ownable(msg.sender).owner() == sender;
    }

    /**
     * @notice See {IPostTransfer-postSafeTransferFrom}
     */
    function postSafeTransferFrom(
        address, /* operator */
        address, /* from */
        address to,
        uint256, /* id */
        bytes memory /* data */
    ) external view override {
        if (to != Ownable(msg.sender).owner()) {
            revert("Transfers disallowed");
        }
    }

    /**
     * @notice See {IPostTransfer-postTransferFrom}
     */
    function postTransferFrom(
        address, /* operator */
        address, /* from */
        address to,
        uint256 /* id */
    ) external view override {
        if (to != Ownable(msg.sender).owner()) {
            revert("Transfers disallowed");
        }
    }

    /* solhint-disable no-empty-blocks */
    /**
     * @notice See {IPostBurn-postBurn}
     */
    function postBurn(
        address, /* operator */
        address, /* sender */
        uint256 /* id */
    ) external pure override {}

    /* solhint-enable no-empty-blocks */

    /**
     * @notice See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(InterfaceSupportEditionsTokenManager)
        returns (bool)
    {
        return
            interfaceId == type(IPostTransfer).interfaceId ||
            interfaceId == type(IPostBurn).interfaceId ||
            InterfaceSupportEditionsTokenManager.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity 0.8.10;

import "@openzeppelin/contracts/utils/Context.sol";

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
/* solhint-disable */
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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./InterfaceSupportTokenManager.sol";
import "./interfaces/ITokenManagerEditions.sol";

/**
 * @author [email protected]
 * @notice Abstract contract to be inherited by all valid editions token managers
 */
abstract contract InterfaceSupportEditionsTokenManager is InterfaceSupportTokenManager {
    /**
     * @notice See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(InterfaceSupportTokenManager)
        returns (bool)
    {
        return
            interfaceId == type(ITokenManagerEditions).interfaceId ||
            InterfaceSupportTokenManager.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/**
 * @author [email protected]
 * @notice If token managers implement this, transfer actions will call
 *      postSafeTransferFrom or postTransferFrom on the token manager.
 */
interface IPostTransfer {
    /**
     * @notice Hook called by community after safe transfers, if token manager of transferred token implements this
     *      interface.
     * @param operator Operator transferring tokens
     * @param from Token(s) sender
     * @param to Token(s) recipient
     * @param id Transferred token's id
     * @param data Arbitrary data
     */
    function postSafeTransferFrom(
        address operator,
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) external;

    /**
     * @notice Hook called by community after transfers, if token manager of transferred token implements
     *         this interface.
     * @param operator Operator transferring tokens
     * @param from Token(s) sender
     * @param to Token(s) recipient
     * @param id Transferred token's id
     */
    function postTransferFrom(
        address operator,
        address from,
        address to,
        uint256 id
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/**
 * @author [email protected]
 * @notice If token managers implement this, transfer actions will call
 *      postBurn on the token manager.
 */
interface IPostBurn {
    /**
     * @notice Hook called by contract after burn, if token manager of burned token implements this
     *      interface.
     * @param operator Operator burning tokens
     * @param sender Msg sender
     * @param id Burned token's id
     */
    function postBurn(
        address operator,
        address sender,
        uint256 id
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./ITokenManager.sol";

/**
 * @title ITokenManager
 * @author [email protected]
 * @notice Enables interfacing with custom token managers for editions contracts
 */
interface ITokenManagerEditions is ITokenManager {
    /**
     * @notice The updated field in metadata updates
     */
    enum FieldUpdated {
        name,
        description,
        imageUrl,
        animationUrl,
        externalUrl,
        attributes,
        other
    }

    /**
     * @notice Returns whether metadata updater is allowed to update
     * @param editionsAddress Address of editions contract
     * @param sender Updater
     * @param editionId Token/edition who's uri is being updated
     *           If id is 0, implementation should decide behaviour for base uri update
     * @param newData Token's new uri if called by general contract, and any metadata field if called by editions
     * @param fieldUpdated Which metadata field was updated
     * @return If invocation can update metadata
     */
    function canUpdateEditionsMetadata(
        address editionsAddress,
        address sender,
        uint256 editionId,
        bytes calldata newData,
        FieldUpdated fieldUpdated
    ) external view returns (bool);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./interfaces/ITokenManager.sol";
import "../utils/ERC165/IERC165.sol";

/**
 * @author [email protected]
 * @notice Abstract contract to be inherited by all valid token managers
 */
abstract contract InterfaceSupportTokenManager {
    /**
     * @notice See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(ITokenManager).interfaceId || _supportsERC165Interface(interfaceId);
    }

    /**
     * @notice Used to show support for IERC165, without inheriting contract from IERC165 implementations
     */
    function _supportsERC165Interface(bytes4 interfaceId) internal pure returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

/**
 * @title ITokenManager
 * @author [email protected]
 * @notice Enables interfacing with custom token managers
 */
interface ITokenManager {
    /**
     * @notice Returns whether metadata updater is allowed to update
     * @param sender Updater
     * @param id Token/edition who's uri is being updated
     *           If id is 0, implementation should decide behaviour for base uri update
     * @param newData Token's new uri if called by general contract, and any metadata field if called by editions
     * @return If invocation can update metadata
     */
    function canUpdateMetadata(
        address sender,
        uint256 id,
        bytes calldata newData
    ) external view returns (bool);

    /**
     * @notice Returns whether token manager can be swapped for another one by invocator
     * @notice Default token manager implementations should ignore id
     * @param sender Swapper
     * @param id Token grouping id (token id or edition id)
     * @param newTokenManager New token manager being swapped to
     * @return If invocation can swap token managers
     */
    function canSwap(
        address sender,
        uint256 id,
        address newTokenManager
    ) external view returns (bool);

    /**
     * @notice Returns whether token manager can be removed
     * @notice Default token manager implementations should ignore id
     * @param sender Swapper
     * @param id Token grouping id (token id or edition id)
     * @return If invocation can remove token manager
     */
    function canRemoveItself(address sender, uint256 id) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity 0.8.10;

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