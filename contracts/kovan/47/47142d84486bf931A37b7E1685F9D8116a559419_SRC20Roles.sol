pragma solidity ^0.5.0;

import "Ownable.sol";

//import "Ownable.sol";
import "DelegateRole.sol";
import "AuthorityRole.sol";
import "Managed.sol";
import "ISRC20Roles.sol";

/*
 * @title SRC20Roles contract
 * @dev Roles wrapper contract around all roles needed for SRC20 contract.
 */
contract SRC20Roles is ISRC20Roles, DelegateRole, AuthorityRole, Managed, Ownable {
    constructor(address owner, address manager, address rules) public
        Managed(manager)
    {
        _transferOwnership(owner);
        if (rules != address(0)) {
            _addAuthority(rules);
        }
    }

    function addAuthority(address account) external onlyOwner returns (bool) {
        _addAuthority(account);
        return true;
    }

    function removeAuthority(address account) external onlyOwner returns (bool) {
        _removeAuthority(account);
        return true;
    }

    function isAuthority(address account) external view returns (bool) {
        return _hasAuthority(account);
    }

    function addDelegate(address account) external onlyOwner returns (bool) {
        _addDelegate(account);
        return true;
    }

    function removeDelegate(address account) external onlyOwner returns (bool) {
        _removeDelegate(account);
        return true;
    }

    function isDelegate(address account) external view returns (bool) {
        return _hasDelegate(account);
    }

    /**
    * @return the address of the manager.
    */
    function manager() external view returns (address) {
        return _manager;
    }

    function isManager(address account) external view returns (bool) {
        return _isManager(account);
    }

    function renounceManagement() external onlyManager returns (bool) {
        _renounceManagement();
        return true;
    }

    function transferManagement(address newManager) external onlyManager returns (bool) {
        _transferManagement(newManager);
        return true;
    }
}

pragma solidity ^0.5.0;

import "Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.5.0;

import "Roles.sol";

//import "Roles.sol";

/**
 * @title DelegateRole
 * @dev Delegate is accounts allowed to do certain operations on
 * contract, apart from owner.
 */
contract DelegateRole {
    using Roles for Roles.Role;

    event DelegateAdded(address indexed account);
    event DelegateRemoved(address indexed account);

    Roles.Role private _delegates;

    function _addDelegate(address account) internal {
        _delegates.add(account);
        emit DelegateAdded(account);
    }

    function _removeDelegate(address account) internal {
        _delegates.remove(account);
        emit DelegateRemoved(account);
    }

    function _hasDelegate(address account) internal view returns (bool) {
        return _delegates.has(account);
    }
}

pragma solidity ^0.5.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

pragma solidity ^0.5.0;

import "Roles.sol";
import "Ownable.sol";

//import "Roles.sol";
//import "Ownable.sol";


/**
 * @title AuthorityRole
 * @dev Authority is roles responsible for signing/approving token transfers
 * on-chain & off-chain
 */
contract AuthorityRole {
    using Roles for Roles.Role;

    event AuthorityAdded(address indexed account);
    event AuthorityRemoved(address indexed account);

    Roles.Role private _authorities;

    function _addAuthority(address account) internal {
        _authorities.add(account);
        emit AuthorityAdded(account);
    }

    function _removeAuthority(address account) internal {
        _authorities.remove(account);
        emit AuthorityRemoved(account);
    }

    function _hasAuthority(address account) internal view returns (bool) {
        return _authorities.has(account);
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Manager is responsible for minting and burning tokens in
 * response to SWM token staking changes.
 */
contract Managed {
    address internal _manager;

    event ManagementTransferred(address indexed previousManager, address indexed newManager);

    /**
     * @dev The Managed constructor sets the original `manager` of the contract to the sender
     * account.
     */
    constructor (address manager) internal {
        _manager = manager;
        emit ManagementTransferred(address(0), _manager);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyManager() {
        require(_isManager(msg.sender), "Caller not manager");
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function _isManager(address account) internal view returns (bool) {
        return account == _manager;
    }

    /**
     * @dev Allows the current manager to relinquish control of the contract.
     * It will not be possible to call the functions with the `onlyManager`
     * modifier anymore.
     * @notice Renouncing management will leave the contract without an manager,
     * thereby removing any functionality that is only available to the manager.
     */
    function _renounceManagement() internal returns (bool) {
        emit ManagementTransferred(_manager, address(0));
        _manager = address(0);

        return true;
    }

    /**
     * @dev Allows the current manager to transfer control of the contract to a newManager.
     * @param newManager The address to transfer management to.
     */
    function _transferManagement(address newManager) internal returns (bool) {
        require(newManager != address(0));

        emit ManagementTransferred(_manager, newManager);
        _manager = newManager;

        return true;
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Contract module which allows children to implement access managements
 * with multiple roles.
 *
 * `Authority` the one how is authorized by token owner/issuer to authorize transfers
 * either on-chain or off-chain.
 *
 * `Delegate` the person who person responsible for updating KYA document
 *
 * `Manager` the person who is responsible for minting and burning the tokens. It should be
 * be registry contract where staking->minting is executed.
 */
contract ISRC20Roles {
    function isAuthority(address account) external view returns (bool);
    function removeAuthority(address account) external returns (bool);
    function addAuthority(address account) external returns (bool);

    function isDelegate(address account) external view returns (bool);
    function addDelegate(address account) external returns (bool);
    function removeDelegate(address account) external returns (bool);

    function manager() external view returns (address);
    function isManager(address account) external view returns (bool);
    function transferManagement(address newManager) external returns (bool);
    function renounceManagement() external returns (bool);
}