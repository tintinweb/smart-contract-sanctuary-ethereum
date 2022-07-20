// SPDX-License-Identifier: MIT

/**
 *******************************************************************************
 * Adminable access control
 *******************************************************************************
 * Creator: Sharkz
 * Author: Jason Hoi
 * Date: 2022-07-19
 *
 */
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Contract module which provides basic access control mechanism, multiple 
 * admins can be added or removed from the contract, admins are granted 
 * exclusive access to specific functions with the provided modifier.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {setAdmin}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyAdmin`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract AdminablePayTest is Context {
    event AdminCreated(address indexed addr);
    event AdminRemoved(address indexed addr);

    // Array of admin addresses
    address[] private _admins;

    // add the first admin with contract creator
    constructor() {
        _createAdmin(_msgSender());
    }

    function isAdmin(address addr) public view virtual returns (bool) {
        if (addr == address(0)) {
          return false;
        }
        for (uint256 i = 0; i < _admins.length; i++) {
          if (addr == _admins[i])
          {
            return true;
          }
        }
        return false;
    }

    modifier onlyAdmin() {
        require(isAdmin(_msgSender()), "Adminable: caller is not admin");
        _;
    }

    function setAdmin(address to, bool approved) public virtual onlyAdmin {
        if (approved) {
            // add new admin when `to` address is not existing admin
            require(!isAdmin(to), "Adminable: add admin for existing admin");
            _createAdmin(to);

        } else {
            // for safety, specifically prevent removing initial admin
            require(to != _admins[0], "Adminable: can not remove initial admin with setAdmin");

            // remove existing admin
            require(isAdmin(to), "Adminable: remove non-existent admin");
            uint256 total = _admins.length;

            // replace current array element with last element, and pop() remove last element
            if (to != _admins[total - 1]) {
                _admins[_adminIndex(to)] = _admins[total - 1];
                _admins.pop();
            } else {
                _admins.pop();
            }

            emit AdminRemoved(to);
        }
    }

    function _adminIndex(address addr) internal view virtual returns (uint256) {
        for (uint256 i = 0; i < _admins.length; i++) {
            if (addr == _admins[i]) {
                return i;
            }
        }
        revert("Adminable: admin index not found");
    }

    function _createAdmin(address addr) internal virtual {
        _admins.push(addr);
        emit AdminCreated(addr);
    }

    /**
     * @dev Leaves the contract without admin.
     *
     * NOTE: Renouncing the last admin will leave the contract without any admins,
     * thereby removing any functionality that is only available to admins.
     */
    function renounceLastAdmin() public virtual onlyAdmin {
        require(_admins.length == 1, "Adminable: can not renounce admin when there are more than one admins");
        delete _admins;
        emit AdminRemoved(_msgSender());
    }

    function publicMint(uint256 _qty) 
        external 
        payable
    {
        uint256 price = 0.001 ether;
        require(msg.value >= price * _qty, "Need to send more ether");
    }

    function withdraw(address payable _to) public onlyAdmin {
        // Call returns a boolean value indicating success or failure.
        uint256 balance = address(this).balance;
        (bool success, ) = _to.call{value: balance}("");
        require(success, "Withdraw failed");
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