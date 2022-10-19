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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IStorage
 * @author gotbit
 */
import {IHasRouter} from '../utils/IHasRouter.sol';

interface IStorage is IHasRouter {
    function write(bytes32 field, bytes32 value) external;

    function read(bytes32 field) external view returns (bytes32);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Storage
 * @author gotbit
 */

import '@openzeppelin/contracts/access/Ownable.sol';

import {IStorage} from './IStorage.sol';

import {HasRouter} from '../utils/HasRouter.sol';

contract Storage is HasRouter, IStorage {
    mapping(bytes32 => bytes32) data;

    constructor(address superAdmin_) HasRouter(address(0), superAdmin_) {}

    function write(bytes32 field, bytes32 value) external onlyRouter {
        data[field] = value;
    }

    function read(bytes32 field) external view returns (bytes32) {
        return data[field];
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title HasRouter
 * @author gotbit
 */

import {IHasRouter} from './IHasRouter.sol';

contract HasRouter is IHasRouter {
    address public router;
    address public superAdmin;

    modifier onlyRouter() {
        require(
            msg.sender == router || _isSuperAdmin(msg.sender),
            'Only Router function'
        );
        _;
    }

    modifier onlySuperAdmin() {
        require(_isSuperAdmin(msg.sender), 'Only Super Admin function');
        _;
    }

    constructor(address router_, address superAdmin_) {
        router = router_;
        superAdmin = superAdmin_;
    }

    function setRouter(address router_) external onlySuperAdmin {
        router = router_;
    }

    function _isSuperAdmin(address user) internal view returns (bool) {
        return user == superAdmin;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IHasRouter
 * @author gotbit
 */

interface IHasRouter {
    function router() external view returns (address);

    function superAdmin() external view returns (address);

    function setRouter(address router_) external;
}