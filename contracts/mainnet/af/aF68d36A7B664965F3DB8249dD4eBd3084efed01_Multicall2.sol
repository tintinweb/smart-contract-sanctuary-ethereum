// SPDX-License-Identifier: GNU GPLv3

// OpenZeppelin Contracts v4.3.2 (access/Ownable.sol)

pragma solidity =0.8.9;

import {Context} from '../utils/Context.sol';

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner
 */
abstract contract Ownable is Context {
    address private _owner;
    address private _master;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner
     */
    constructor(address masterAddress) {
        _transferOwnership(_msgSender());
        _master = masterAddress;
    }

    /**
     * @dev Returns the address of the current owner
     * @return _owner - owner address
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), 'ONA');
        _;
    }

    /**
     * @dev Throws if called by any account other than the master
     */
    modifier onlyMaster() {
        require(owner() == _msgSender(), 'ONA');
        _;
    }

    /**
     * @dev Transfering the owner ship to master role in case of emergency
     *
     * NOTE: Renouncing ownership will transfer the contract ownership to master role
     */

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(_master);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`)
     * Can only be called by the current owner
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), 'OCNZA');
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`)
     * Internal function without access restriction
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;
pragma abicoder v2;

/// @title Multicall2 - Aggregate results from multiple read-only function calls
/// @author Michael Elliot <[email protected]>
/// @author Joshua Levine <[email protected]>
/// @author Nick Johnson <[email protected]>

import '../access/Ownable.sol';

contract Multicall2 is Ownable {
    /**
     * @dev initialize multicall and set master as owner on the contract
     */
    constructor(address master) Ownable(master) {}

    /**
     * @dev Call stores of calling data - target and callData
     */
    struct Call {
        address target;
        bytes callData;
    }

    /**
     * @dev Result stores status and return data
     */
    struct Result {
        bool success;
        bytes returnData;
    }

    /**
     * @dev aggregate the multiple calls.
     * @param calls - call details
     * @return blockNumber - block number
     * @return returnData - return data
     */
    function aggregate(Call[] memory calls) public onlyOwner returns (uint256 blockNumber, bytes[] memory returnData) {
        blockNumber = block.number;
        returnData = new bytes[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = calls[i].target.call(calls[i].callData);
            require(success, 'MACF');
            returnData[i] = ret;
        }
    }

    /**
     * @dev block and aggregate calls
     * @param calls - call data
     * @return blockNumber - block number
     * @return blockHash - block hash
     * @return returnData - return Data
     */
    function blockAndAggregate(Call[] memory calls)
        public
        onlyOwner
        returns (
            uint256 blockNumber,
            bytes32 blockHash,
            Result[] memory returnData
        )
    {
        (blockNumber, blockHash, returnData) = tryBlockAndAggregate(true, calls);
    }

    /**
     * @dev returns block hash of the current block
     * @return blockHash - current block hash
     */
    function getBlockHash(uint256 blockNumber) public view returns (bytes32 blockHash) {
        blockHash = blockhash(blockNumber);
    }

    /**
     * @dev returns block number of the current block
     * @return blockNumber - current block number
     */
    function getBlockNumber() public view returns (uint256 blockNumber) {
        blockNumber = block.number;
    }

    /**
     * @dev returns the miner's address of current block
     * @return coinbase - miner
     */
    function getCurrentBlockCoinbase() public view returns (address coinbase) {
        coinbase = block.coinbase;
    }

    /**
     * @dev returns the current block difficulty
     * @return difficulty - block difficulty
     */
    function getCurrentBlockDifficulty() public view returns (uint256 difficulty) {
        difficulty = block.difficulty;
    }

    /**
     * @dev returns the current block gaslimit
     * @return gaslimit - gas limit
     */
    function getCurrentBlockGasLimit() public view returns (uint256 gaslimit) {
        gaslimit = block.gaslimit;
    }

    /**
     * @dev returns the current block timestamp
     * @return timestamp - current time stamp
     */
    function getCurrentBlockTimestamp() public view returns (uint256 timestamp) {
        timestamp = block.timestamp;
    }

    /**
     * @dev returns the balance of address in parent chain token
     * @return balance - address balance
     */
    function getEthBalance(address addr) public view returns (uint256 balance) {
        balance = addr.balance;
    }

    /**
     * @dev returns the previous block hash
     * @return blockHash - last block hash
     */
    function getLastBlockHash() public view returns (bytes32 blockHash) {
        blockHash = blockhash(block.number - 1);
    }

    /**
     * @dev returns the aggregated calls
     * @param requireSuccess - reuires success only
     * @param calls - need call data
     * @return returnData - it has status and return data
     */
    function tryAggregate(bool requireSuccess, Call[] memory calls) public onlyOwner returns (Result[] memory returnData) {
        returnData = new Result[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = calls[i].target.call(calls[i].callData);

            if (requireSuccess) {
                require(success, 'M2ACF');
            }

            returnData[i] = Result(success, ret);
        }
    }

    /**
     * @dev block calls blockNumberwise and aggregate.
     * @param requireSuccess - only successed call
     * @param calls - multi calls
     * @return blockNumber - block number
     * @return blockHash - block hash
     * @return returnData - aggregater data
     */
    function tryBlockAndAggregate(bool requireSuccess, Call[] memory calls)
        public
        onlyOwner
        returns (
            uint256 blockNumber,
            bytes32 blockHash,
            Result[] memory returnData
        )
    {
        blockNumber = block.number;
        blockHash = blockhash(block.number);
        returnData = tryAggregate(requireSuccess, calls);
    }
}

// SPDX-License-Identifier: GNU GPLv3

// OpenZeppelin Contracts v4.3.2 (utils/Context.sol)

pragma solidity =0.8.9;

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
    /**
     * @dev returns the caller address
     */
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev returns the caller message data
     */
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}