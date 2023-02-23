/**
 *Submitted for verification at Etherscan.io on 2023-02-23
*/

/**
 *Submitted for verification at Etherscan.io on 2022-10-28
*/

/**
 *Submitted for verification at Etherscan.io on 2021-01-20
*/

/**
 *Submitted for verification at Etherscan.io on 2020-12-30
*/

/**
 *Submitted for verification at Etherscan.io on 2019-12-19
*/

// File: contracts\ownership\Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () public {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
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
        return msg.sender == _owner;
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

contract IssuerRole is Ownable {
    using Roles for Roles.Role;

    event IssuerAdded(address indexed account);
    event IssuerRemoved(address indexed account);

    Roles.Role private _issuers;

    constructor () public {
        _addIssuer(msg.sender);
    }

    modifier onlyIssuer() {
        require(isIssuer(msg.sender), "IssuerRole: caller does not have the issuer role");
        _;
    }

    function isIssuer(address account) public view returns (bool) {
        return _issuers.has(account);
    }

    function addIssuer(address account) public onlyOwner {
        _addIssuer(account);
    }

    function removeIssuer(address account) public onlyOwner {
        _removeIssuer(account);
    }

    function renounceIssuer() public {
        _removeIssuer(msg.sender);
    }

    function _addIssuer(address account) internal {
        _issuers.add(account);
        emit IssuerAdded(account);
    }

    function _removeIssuer(address account) internal {
        _issuers.remove(account);
        emit IssuerRemoved(account);
    }
}

contract PostCert is Ownable, IssuerRole {
    event Posted(bytes32 hash);
    // Need state
    event CertState(bytes32 indexed certHash, uint state);

    function Post(bytes32 hash, uint state) public onlyIssuer {
        // TODO
        emit Posted(hash);
        emit CertState(hash,state);
    }

    function setState(bytes32 hash, uint state) public onlyIssuer {
        emit CertState(hash,state);
    }
}