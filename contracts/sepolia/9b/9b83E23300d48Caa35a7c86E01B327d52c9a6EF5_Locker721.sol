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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import '../Utils/utils.sol';

contract Locker721 is OwnerOperator {
    struct ItemLock {
        uint256 start;
        uint256 end;
        bool isLock;
    }

    bool systemLock;
    address private contractAddress;
    mapping(uint256 => ItemLock) lockedItems;

    function setContractAddress(address _contractAddress) external operatorOrOwner {
        contractAddress = _contractAddress;
    }

    function lockTokenIds(uint256[] memory _tokenIds, uint256 duration) external operatorOrOwner {
        uint256 startTime = block.timestamp;
        uint256 endTime = duration;

        ItemLock memory itemLock = ItemLock({ start: startTime, end: endTime, isLock: false });

        for (uint256 i; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];
            lockedItems[_tokenId] = itemLock;
        }
    }

    function lockTokenIds(uint256[] memory _tokenIds) external operatorOrOwner {
        for (uint256 i; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];

            ItemLock memory itemLock = ItemLock({
                start: lockedItems[_tokenId].start,
                end: lockedItems[_tokenId].end,
                isLock: true
            });

            lockedItems[_tokenId] = itemLock;
        }
    }

    function unlockToken(uint256[] memory _tokenIds) external operatorOrOwner {
        ItemLock memory itemLock = ItemLock({ start: 0, end: 0, isLock: false });
        for (uint256 i; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];
            lockedItems[_tokenId] = itemLock;
        }
    }

    function setLockSystem(bool _isLock) external operatorOrOwner {
        systemLock = _isLock;
    }

    function isTokenLocked(uint256 _tokenId) public view returns (bool) {
        if (systemLock) {
            return true;
        }

        return
            lockedItems[_tokenId].isLock
                ? true
                : block.timestamp >= lockedItems[_tokenId].end && lockedItems[_tokenId].end > 0
                ? false
                : block.timestamp >= lockedItems[_tokenId].end && lockedItems[_tokenId].end == 0
                ? false
                : true;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract OwnerOperator is Ownable {
    mapping(address => bool) public operators;

    modifier operatorOrOwner() {
        require(
            operators[msg.sender] || owner() == msg.sender,
            "OwnerOperator: !operator, !owner"
        );
        _;
    }

    modifier onlyOperator() {
        require(operators[msg.sender], "OwnerOperator: !operator");
        _;
    }

    function addOperator(address operator) external virtual onlyOwner {
        require(
            operator != address(0),
            "OwnerOperator: operator is the zero address"
        );
        operators[operator] = true;
    }

    function removeOperator(address operator) external virtual onlyOwner {
        require(
            operator != address(0),
            "OwnerOperator: operator is the zero address"
        );
        operators[operator] = false;
    }

}

abstract contract Lockable {
    mapping(address => bool) public lockers;

    constructor() {
        lockers[msg.sender] = true;
    }

    modifier onlyLocker() {
        require(lockers[msg.sender], "Lockable: caller is not locker");
        _;
    }

    function setLocker(address newLocker, bool lockable) public virtual onlyLocker {
        require(
            newLocker != address(0),
            "newLocker: new locker is the zero address"
        );
        lockers[newLocker] = lockable;
    }
}

abstract contract Mintable {
    mapping(address => bool) public minters;

    constructor() {
        minters[msg.sender] = true;
    }

    modifier onlyMinter() {
        require(minters[msg.sender], "Mintable: caller is not minter");
        _;
    }

    function setMinter(address newMinter, bool mintable) public virtual onlyMinter {
        require(
            newMinter != address(0),
            "Mintable: new minter is the zero address"
        );
        minters[newMinter] = mintable;
    }
}

abstract contract Burnable {
    mapping(address => bool) public burners;

    constructor() {
        burners[msg.sender] = true;
    }

    modifier onlyBurner() {
        require(burners[msg.sender], "Burnable: caller is not burner");
        _;
    }

    function isBurner(address addr) public view returns(bool) {
        return burners[addr];
    }

    function setBurner(address newBurner, bool burnable) public virtual onlyBurner {
        require(
            newBurner != address(0),
            "Burnable: new burner is the zero address"
        );
        burners[newBurner] = burnable;
    }
}