// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IConfigurationManager.sol";

/**
 * @title ConfigurationManager
 * @author Pods Finance
 * @notice Allows contracts to read protocol-wide settings
 */
contract ConfigurationManager is IConfigurationManager, Ownable {
    mapping(address => mapping(bytes32 => uint256)) private _parameters;
    address private immutable _global = address(0);

    /**
     * @dev Define a parameter
     * @param target The parameter name
     * @param name The parameter name
     * @param value The parameter value
     */
    function setParameter(
        address target,
        bytes32 name,
        uint256 value
    ) public override onlyOwner {
        _parameters[target][name] = value;
        emit ParameterSet(target, name, value);
    }

    /**
     * @dev Get the value of a defined parameter
     * @param name The parameter name
     */
    function getParameter(address target, bytes32 name) external view override returns (uint256) {
        return _parameters[target][name];
    }

    /**
     * @dev Get the value of a defined parameter
     * @param name The parameter name
     */
    function getGlobalParameter(bytes32 name) external view override returns (uint256) {
        return _parameters[_global][name];
    }

    /**
     * @dev Defines a cap value to a contract
     * @param target The contract address
     * @param value Cap amount
     */
    function setCap(address target, uint256 value) external override onlyOwner {
        if (target == address(0)) revert ConfigurationManager__InvalidCapTarget();
        setParameter(target, "CAP", value);
        emit SetCap(target, value);
    }

    /**
     * @dev Get the value of a defined cap
     * Note that 0 cap means that the contract is not capped
     * @param target The contract address
     */
    function getCap(address target) external view override returns (uint256) {
        return this.getParameter(target, "CAP");
    }
}

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

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.6;

interface IConfigurationManager {
    event SetCap(address indexed target, uint256 value);
    event ParameterSet(address indexed target, bytes32 indexed name, uint256 value);

    error ConfigurationManager__InvalidCapTarget();

    function setParameter(
        address target,
        bytes32 name,
        uint256 value
    ) external;

    function getParameter(address target, bytes32 name) external view returns (uint256);

    function getGlobalParameter(bytes32 name) external view returns (uint256);

    function setCap(address target, uint256 value) external;

    function getCap(address target) external view returns (uint256);
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