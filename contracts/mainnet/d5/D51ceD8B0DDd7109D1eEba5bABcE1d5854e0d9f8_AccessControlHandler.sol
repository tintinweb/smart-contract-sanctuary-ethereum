// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// import "hardhat/console.sol";

interface IAccessControl {
    function grantRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}


contract AccessControlHandler is Ownable {

    address[] public contractsAccessControl;

    constructor(address[] memory _contractsAccessControl) {
        addAccessControlAddressBath(_contractsAccessControl);
    }

    function addAccessControlAddressBath(address[] memory _accessContracts) public onlyOwner {
        for(uint256 contractItem = 0; contractItem < _accessContracts.length; contractItem++) {
            contractsAccessControl.push(_accessContracts[contractItem]);
        }
    }


    function removeAccessControlAddressBath(address accessContract) external onlyOwner {
        for(uint256 index = 0; index < contractsAccessControl.length; index++) {
            if (contractsAccessControl[index] == accessContract) {
                for(uint i = index; i < contractsAccessControl.length-1; i++){
                    contractsAccessControl[i] = contractsAccessControl[i+1];
                }
                contractsAccessControl.pop();
            }
        }
    }

    // @dev Grant role for meny contracts
    function grantRole(bytes32 role, address account) public onlyOwner {
        IAccessControl accessControl;

        for(uint256 contractItem = 0; contractItem < contractsAccessControl.length; contractItem++) {
            accessControl = IAccessControl(contractsAccessControl[contractItem]);
            accessControl.grantRole(role, account);
        }
    }

    // @dev Renounce role for meny contracts
    function renounceRole(bytes32 role, address account) public onlyOwner {
        IAccessControl accessControl;

        for(uint256 contractItem = 0; contractItem < contractsAccessControl.length; contractItem++) {
            accessControl = IAccessControl(contractsAccessControl[contractItem]);
            accessControl.renounceRole(role, account);
        }
    }

    // @dev Bath Grant role for meny contracts
    function grantRoleBath(bytes32[] calldata roles, address[] memory accounts) external onlyOwner {
        require(roles.length == accounts.length, "ACH: Wrong data");

        for(uint256 i = 0; i < accounts.length; i++) {
            grantRole(roles[i], accounts[i]);
        }
    }

    // @dev Bath renounce role for meny contracts
    function renounceRoleBath(bytes32[] calldata roles, address[] memory accounts) external onlyOwner {
        require(roles.length == accounts.length, "ACH: Wrong data");

        for(uint256 i = 0; i < accounts.length; i++) {
            renounceRole(roles[i], accounts[i]);
        }
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