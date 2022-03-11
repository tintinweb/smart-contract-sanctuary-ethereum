// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IPoolFactory.sol";

/// @dev Custom Errors
error InvalidBarFee();
error ZeroAddress();
error NotWhitelisted();

/// @notice Trident pool deployer contract with template factory whitelist.
/// @author Mudit Gupta.
contract MasterDeployer is Ownable {
    event DeployPool(address indexed factory, address indexed pool, bytes deployData);
    event AddToWhitelist(address indexed factory);
    event RemoveFromWhitelist(address indexed factory);
    event BarFeeUpdated(uint256 indexed barFee);

    uint256 public barFee;
    address public immutable barFeeTo;
    address public immutable bento;

    uint256 internal constant MAX_FEE = 10000; // @dev 100%.

    mapping(address => bool) public pools;
    mapping(address => bool) public whitelistedFactories;

    constructor(
        uint256 _barFee,
        address _barFeeTo,
        address _bento
    ) {
        if (_barFee > MAX_FEE) revert InvalidBarFee();
        if (_barFeeTo == address(0)) revert ZeroAddress();
        if (_bento == address(0)) revert ZeroAddress();

        barFee = _barFee;
        barFeeTo = _barFeeTo;
        bento = _bento;
    }

    function deployPool(address _factory, bytes calldata _deployData) external returns (address pool) {
        if (!whitelistedFactories[_factory]) revert NotWhitelisted();
        pool = IPoolFactory(_factory).deployPool(_deployData);
        pools[pool] = true;
        emit DeployPool(_factory, pool, _deployData);
    }

    function addToWhitelist(address _factory) external onlyOwner {
        whitelistedFactories[_factory] = true;
        emit AddToWhitelist(_factory);
    }

    function removeFromWhitelist(address _factory) external onlyOwner {
        whitelistedFactories[_factory] = false;
        emit RemoveFromWhitelist(_factory);
    }

    function setBarFee(uint256 _barFee) external onlyOwner {
        if (_barFee > MAX_FEE) revert InvalidBarFee();
        barFee = _barFee;
        emit BarFeeUpdated(_barFee);
    }
}

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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

/// @notice Trident pool deployment interface.
interface IPoolFactory {
    function deployPool(bytes calldata _deployData) external returns (address pool);

    function configAddress(bytes32 data) external returns (address pool);
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