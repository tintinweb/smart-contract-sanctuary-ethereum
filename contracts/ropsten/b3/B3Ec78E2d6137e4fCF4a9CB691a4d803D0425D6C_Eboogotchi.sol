// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Eboogotchi is Ownable {
    event Loved(address indexed caretaker);

    uint256 dampening = 50;

    uint256 feedBlock;
    uint256 cleanBlock;
    uint256 playBlock;
    uint256 sleepBlock;

    uint8 internal hungry;
    uint8 internal dirty;
    uint8 internal bored;
    uint8 internal tired;

    mapping(address => uint256) public love;

    constructor() {
        feedBlock = block.number;
        cleanBlock = block.number;
        playBlock = block.number;
        sleepBlock = block.number;

        hungry = 0;
        dirty = 0;
        bored = 0;
        tired = 0;
    }

    function getHungry() public view returns (uint256) {
        return hungry + ((block.number - feedBlock) / dampening);
    }

    function getDirty() public view returns (uint256) {
        return dirty + ((block.number - cleanBlock) / dampening);
    }

    function getBored() public view returns (uint256) {
        return bored + ((block.number - playBlock) / dampening);
    }

    function getTired() public view returns (uint256) {
        return tired + ((block.number - sleepBlock) / dampening);
    }

    function addLove(address caretaker) internal {
        love[caretaker] += 1;
        emit Loved(caretaker);
    }

    function feed() public {
        require(getAlive(), "already dead");
        require(getHungry() > 20, "not hungry");
        require(getTired() < 80, "too tired to feed");
        require(getDirty() < 80, "too dirty to feed");

        feedBlock = block.number;

        hungry = 0;

        tired += 10;
        dirty += 5;

        addLove(msg.sender);
    }

    function clean() public {
        require(getAlive(), "already dead");
        require(getDirty() > 20, "not dirty");

        cleanBlock = block.number;

        dirty = 0;

        addLove(msg.sender);
    }

    function play() public {
        require(getAlive(), "already dead");
        require(getBored() > 20, "not bored");
        require(getHungry() < 80, "too hungry to play");
        require(getTired() < 80, "too tired to play");
        require(getDirty() < 80, "too dirty to play");

        playBlock = block.number;

        bored = 0;

        hungry += 10;
        tired += 10;
        dirty += 5;

        addLove(msg.sender);
    }

    function sleep() public {
        require(getAlive(), "already dead");
        require(getTired() > 0, "not tired");
        require(getDirty() < 80, "too dirty to sleep");

        sleepBlock = block.number;

        tired = 0;

        dirty += 5;

        addLove(msg.sender);
    }

    function getAlive() public view returns (bool) {
        return
            getHungry() < 101 &&
            getDirty() < 101 &&
            getTired() < 101 &&
            getBored() < 101;
    }

    function setDampening(uint256 _dampening) public onlyOwner {
        require(_dampening > 0, "dampening needs to be strictly positive");
        dampening = _dampening;
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