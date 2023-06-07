/**
 *Submitted for verification at Etherscan.io on 2023-06-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

interface ID4ADrb {
    event CheckpointSet(uint256 startDrb, uint256 startBlock, uint256 blocksPerDrbX18);

    function getCheckpointsLength() external view returns (uint256);

    function getStartBlock(uint256 drb) external view returns (uint256);

    function getDrb(uint256 blockNumber) external view returns (uint256);

    function currentRound() external view returns (uint256);

    function setNewCheckpoint(uint256 startDrb, uint256 startBlock, uint256 blocksPerDrbE18) external;

    function modifyLastCheckpoint(uint256 startDrb, uint256 startBlock, uint256 blocksPerDrbE18) external;
}

contract D4ADrb is ID4ADrb, Ownable {
    struct Checkpoint {
        uint256 startDrb;
        uint256 startBlock;
        uint256 blocksPerDrbE18;
    }

    Checkpoint[] public checkpoints;

    constructor(uint256 startBlock, uint256 blocksPerDrbE18) {
        checkpoints.push(Checkpoint({startDrb: 0, startBlock: startBlock, blocksPerDrbE18: blocksPerDrbE18}));
        emit CheckpointSet(0, startBlock, blocksPerDrbE18);
    }

    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function getCheckpointsLength() public view returns (uint256) {
        return checkpoints.length;
    }

    function getStartBlock(uint256 drb) public view returns (uint256) {
        uint256 index = checkpoints.length - 1;
        while (checkpoints[index].startDrb > drb) {
            --index;
        }
        return ((drb - checkpoints[index].startDrb) * checkpoints[index].blocksPerDrbE18 / 1e18)
            + checkpoints[index].startBlock;
    }

    function getDrb(uint256 blockNumber) public view returns (uint256) {
        uint256 length = checkpoints.length;
        uint256 index = length - 1;
        while (checkpoints[index].startBlock > blockNumber) {
            --index;
        }

        return length == index + 1
            // new checkpoint not set
            ? ((blockNumber - checkpoints[index].startBlock) * 1e18) / checkpoints[index].blocksPerDrbE18
                + checkpoints[index].startDrb
            // already set new checkpoint
            : _min(
                ((blockNumber - checkpoints[index].startBlock) * 1e18) / checkpoints[index].blocksPerDrbE18
                    + checkpoints[index].startDrb,
                checkpoints[index + 1].startDrb - 1
            );
    }

    function currentRound() public view returns (uint256) {
        return getDrb(block.number);
    }

    function setNewCheckpoint(uint256 startDrb, uint256 startBlock, uint256 blocksPerDrbE18) public onlyOwner {
        checkpoints.push(Checkpoint({startDrb: startDrb, startBlock: startBlock, blocksPerDrbE18: blocksPerDrbE18}));
        emit CheckpointSet(startDrb, startBlock, blocksPerDrbE18);
    }

    function modifyLastCheckpoint(uint256 startDrb, uint256 startBlock, uint256 blocksPerDrbE18) public onlyOwner {
        checkpoints[checkpoints.length - 1] =
            Checkpoint({startDrb: startDrb, startBlock: startBlock, blocksPerDrbE18: blocksPerDrbE18});
        emit CheckpointSet(startDrb, startBlock, blocksPerDrbE18);
    }
}