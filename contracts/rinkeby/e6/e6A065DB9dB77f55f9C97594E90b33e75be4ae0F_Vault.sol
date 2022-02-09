//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Vault {
    struct User {
        address ethAddress;
        address algoAddress;
        uint256 amount;
    }

    uint256 public userCount;
    mapping(uint256 => User) public users;
    mapping (address => uint256[]) public userIDsByETHAddress;

    event LockETH(address indexed ethAddress, address algoaddress, uint256 amount);
    
    // An address type variable is used to store ethereum accounts.
    address public owner;

    constructor() {}

    function lockETH(address _ethAddress, address _algoAddress) external payable returns (uint256 _id) {
        _id = userCount;

        users[_id].ethAddress = _ethAddress;
        users[_id].algoAddress = _algoAddress;
        users[_id].amount = msg.value;

        userIDsByETHAddress[_ethAddress].push(_id);
        emit LockETH(users[_id].ethAddress, users[_id].algoAddress, users[_id].amount);
        userCount ++;

        return _id;
    }

    function addAmount(uint256 _id)	public payable { 
        require(msg.sender == users[_id].ethAddress, "Not vault owner");
        users[_id].amount += msg.value;
        emit LockETH(users[_id].ethAddress, users[_id].algoAddress, users[_id].amount);
    }

    function unlockETH(uint256 _id, address _algoAddress, uint256 _amount) external {
        require(msg.sender == users[_id].ethAddress, 'You are not the withdrawer!');
        require(users[_id].algoAddress == _algoAddress, 'Algo address are not valid!');
        require(users[_id].amount > 0, 'balance is zero!');
        require(users[_id].amount >= _amount, 'balance is not enough to withdraw!');

        (bool sent, ) = msg.sender.call{value: _amount}("");
        require(sent, "Failed to send ETH");

        users[_id].amount -= _amount;
    }

    function getUserIdByETHAddress(address _ethAddress) view external returns (uint256[] memory) {
        return userIDsByETHAddress[_ethAddress];
    }

    function getUserById(uint256 _id) view external returns (User memory) {
        return users[_id];
    }

    function getBalanceById(uint256 _id) public view returns (uint256) {
        return users[_id].amount;
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