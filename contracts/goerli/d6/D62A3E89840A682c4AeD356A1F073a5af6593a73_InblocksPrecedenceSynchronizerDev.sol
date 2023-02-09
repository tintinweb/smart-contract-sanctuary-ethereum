// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./InblocksPrecedenceSynchronizer.sol";

contract InblocksPrecedenceSynchronizerDev is InblocksPrecedenceSynchronizer {

    event Reset();

    function reset() public onlyOwner {
        count = 0;
        emit Reset();
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

// https://github.com/frangio/openzeppelin-contracts/blob/3a237b4441c6aab8631f1e9988c959eaefce72c1/contracts/GSN/Context.sol
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/90ed1af972299070f51bf4665a85da56ac4d355e/contracts/access/Ownable.sol
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract InblocksPrecedenceSynchronizer is Ownable {

    struct Info {
        uint index;
        uint timestamp;
    }

    mapping(bytes32 => Info) internal byRoot;
    mapping(uint => bytes32) internal byIndex;
    uint internal count;

    event Synchronized(bytes32 root, uint index, uint timestamp);

    function getLast() public view returns (bool isSynchronized, bytes32 root, int index, int timestamp) {
        return getByIndex(count - 1);
    }

    function getByIndex(uint _index) public view returns (bool isSynchronized, bytes32 root, int index, int timestamp) {
        bytes32 _root;
        if (_index < count) {
            _root = byIndex[_index];
        }
        return getByRoot(_root);
    }

    function getByRoot(bytes32 _root) public view returns (bool isSynchronized, bytes32 root, int index, int timestamp) {
        if (byRoot[_root].timestamp == 0) {
            return (false, "", - 1, - 1);
        }
        return (true, _root, int(byRoot[_root].index), int(byRoot[_root].timestamp));
    }

    function synchronize(bytes32 root, uint index) public onlyOwner {
        require(index == count);
        byIndex[index] = root;
        byRoot[root] = Info({index : index, timestamp : block.timestamp});
        count++;
        emit Synchronized(root, byRoot[root].index, byRoot[root].timestamp);
    }

}