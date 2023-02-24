// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
pragma solidity ^0.8.0;

interface IModuleMetadata {
    function moduleId() external pure returns (string memory);
    function moduleVersion() external pure returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import {Ownable} from "openzeppelin/access/Ownable.sol";
import {IModuleMetadata} from "../bases/interfaces/IModuleMetadata.sol";

uint256 constant LATEST_VERSION = type(uint256).max;

contract UpgradeableModuleProxyFactory is Ownable {
    error ProxyAlreadyDeployedForNonce();
    error FailedInitialization();
    error ModuleVersionAlreadyRegistered();
    error UnexistentModuleVersion();

    event ModuleRegistered(IModuleMetadata indexed implementation, string moduleId, uint256 version);
    event ModuleProxyCreated(address indexed proxy, IModuleMetadata indexed implementation);

    mapping(string => mapping(uint256 => IModuleMetadata)) internal modules;
    mapping(string => uint256) public latestModuleVersion;

    function register(IModuleMetadata implementation) external onlyOwner {
        string memory moduleId = implementation.moduleId();
        uint256 version = implementation.moduleVersion();

        if (address(modules[moduleId][version]) != address(0)) {
            revert ModuleVersionAlreadyRegistered();
        }

        modules[moduleId][version] = implementation;

        if (version > latestModuleVersion[moduleId]) {
            latestModuleVersion[moduleId] = version;
        }

        emit ModuleRegistered(implementation, moduleId, version);
    }

    function getImplementation(string memory moduleId, uint256 version)
        public
        view
        returns (IModuleMetadata implementation)
    {
        if (version == LATEST_VERSION) {
            version = latestModuleVersion[moduleId];
        }
        implementation = modules[moduleId][version];
        if (address(implementation) == address(0)) {
            revert UnexistentModuleVersion();
        }
    }

    function deployUpgradeableModule(string memory moduleId, uint256 version, bytes memory initializer, uint256 salt)
        public
        returns (address proxy)
    {
        return deployUpgradeableModule(getImplementation(moduleId, version), initializer, salt);
    }

    function deployUpgradeableModule(IModuleMetadata implementation, bytes memory initializer, uint256 salt)
        public
        returns (address proxy)
    {
        proxy = createProxy(implementation, keccak256(abi.encodePacked(keccak256(initializer), salt)));

        (bool success,) = proxy.call(initializer);
        if (!success) {
            revert FailedInitialization();
        }
    }
    
    /**
     * @dev Proxy EVM code from factory/proxy-asm generated with ETK
     */
    function createProxy(IModuleMetadata implementation, bytes32 salt) internal returns (address proxy) {
        bytes memory initcode = abi.encodePacked(
            hex"73",
            implementation,
            hex"7f360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc55603b8060403d393df3363d3d3760393d3d3d3d3d363d7f360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc545af4913d913e3d9257fd5bf3"
        );

        assembly {
            proxy := create2(0, add(initcode, 0x20), mload(initcode), salt)
        }

        if (proxy == address(0)) {
            revert ProxyAlreadyDeployedForNonce();
        }

        emit ModuleProxyCreated(proxy, implementation);
    }
}