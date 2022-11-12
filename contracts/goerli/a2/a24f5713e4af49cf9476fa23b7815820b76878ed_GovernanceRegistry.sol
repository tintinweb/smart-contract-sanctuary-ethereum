// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IGovernanceRegistry.sol";

/** @dev A very simple registry
 */
contract GovernanceRegistry is IGovernanceRegistry, Ownable {
    //----- Storage variables -----
    address public override governanceToken;
    address public override governanceCharity;
    address public override governanceVoter;
    address public override governanceTreasury;
    address public override tokenRegistry;


    function init(address token, address charity, address voter, address treasury, address registry) external onlyOwner {
        // Set contract addresses
        governanceToken = token;
        governanceCharity = charity;
        governanceVoter = voter;
        governanceTreasury = treasury;
        tokenRegistry = registry;
    }

    function setGovernanceToken(address token) external override onlyOwner {
        governanceToken = token;
    }

    function setGovernanceCharity(address charity) external override onlyOwner {
        governanceCharity = charity;
    }

    function setGovernanceVoter(address voter) external override onlyOwner {
        governanceVoter = voter;
    }

    function setGovernanceTreasury(address treasury) external override onlyOwner {
        governanceTreasury = treasury;
    }

    function setTokenRegistry(address registry) external override onlyOwner {
        tokenRegistry = registry;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IGovernanceRegistry {
    function governanceToken() external view returns (address token);

    function setGovernanceToken(address token) external;

    function governanceCharity() external view returns (address charity);

    function setGovernanceCharity(address charity) external;

    function governanceVoter() external view returns (address voting);

    function setGovernanceVoter(address voting) external;

    function governanceTreasury() external view returns (address treasury);

    function setGovernanceTreasury(address treasury) external;

    function tokenRegistry() external view returns (address);

    function setTokenRegistry(address registry) external;
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