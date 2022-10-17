// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

error Clients__WithdrawalFailed();
error Clients__ClientAlreadyAdded();

contract GlobalWebThreeClients is Ownable {
    address private immutable i_partnerAccount;
    address[] private s_clients;
    mapping(address => uint256) private s_clientIndex;

    event clientAdd(address indexed client);
    event clientRemove(uint256 indexed index);

    constructor() {
        i_partnerAccount = 0x3C67F48c548738Bda7EDD74213e8AD1820c3DD2a;
        s_clients.push(0x0000000000000000000000000000000000000000);
    }

    function addClient(address client) public onlyOwner {
        if (s_clientIndex[client] != 0) {
            revert Clients__ClientAlreadyAdded();
        }

        s_clients.push(client);
        s_clientIndex[client] = (s_clients.length) - 1;

        emit clientAdd(client);
    }

    function removeClient(uint256 index) public onlyOwner {
        delete s_clientIndex[s_clients[index]];
        delete s_clients[index];

        emit clientRemove(index);
    }

    receive() external payable {}

    function withdrawFunds() public onlyOwner {
        (bool success, ) = i_partnerAccount.call{value: address(this).balance}("");
        if (!success) {
            revert Clients__WithdrawalFailed();
        }
    }

    function getClientsIndex(address clientAddress) public view returns (uint256) {
        return s_clientIndex[clientAddress];
    }

    function getClients(uint256 index) public view returns (address) {
        return s_clients[index];
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
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