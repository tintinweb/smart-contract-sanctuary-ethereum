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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract CronJobRunner is Ownable {
    struct Job {
        address contractAddress;
        bytes callData;
        uint256 frequency;
        bool paused;
        uint256 initTime;
        uint256 nextExecutionTime;
        uint256 lastExecutionTime;
        uint256 retryTime;
        bool lastExecutionCompleted;
        bool lastExecutionSuccess;
    }
    /*=================== VARIABLES ======================*/
    mapping(address => bool) public executors;
    address[] public executorAddresses;
    Job[] public jobs;

    modifier onlyExecutors() {
        require(executors[msg.sender], "CronJobRunner::onlyExecutors: Not allowed");
        _;
    }

    /*======================== CONSTRUCTOR ========================*/
    constructor() {
        executors[owner()] = true;
        executorAddresses.push(owner());
    }

    /*======================== VIEWS ==========================*/

    function getExecutableJobs() external view returns (uint256[] memory _jobIds) {
        uint256[] memory tempJobIds = new uint256[](jobs.length);
        uint256 index = 0;
        for (uint256 i = 0; i < jobs.length; i++) {
            if (_executable(i)) {
                tempJobIds[index] = i;
                index += 1;
            }
        }
        if (index > 0 && index < jobs.length) {
            _jobIds = new uint256[](index);
            for (uint256 i = 0; i < index; i++) {
                _jobIds[i] = tempJobIds[i];
            }
        }
        if (index == jobs.length) {
            _jobIds = tempJobIds;
        }
    }

    /*======================== MUTATIVE =======================*/
    function addExecutor(address _addr) external onlyOwner {
        if (!executors[_addr]) {
            executorAddresses.push(_addr);
        }
        executors[_addr] = true;
    }

    function removeExecutor(address _addr) external onlyOwner {
        if (executors[_addr]) {
            int256 index = -1;
            for (uint256 i = 0; i < executorAddresses.length; i++) {
                if (executorAddresses[i] == _addr) {
                    index = int256(i);
                    break;
                }
            }
            if (index >= 0) {
                executorAddresses[uint256(index)] = executorAddresses[executorAddresses.length - 1];
                executorAddresses.pop();
            }
        }
        executors[_addr] = false;
    }

    function addJob(
        address _contractAddress,
        bytes memory _callData,
        uint256 startTime,
        uint256 _frequency,
        uint256 _retryTime
    ) external onlyOwner {
        jobs.push(
            Job({
                contractAddress: _contractAddress,
                callData: _callData,
                frequency: _frequency,
                paused: false,
                initTime: block.timestamp,
                nextExecutionTime: startTime,
                lastExecutionTime: 0,
                lastExecutionCompleted: false,
                lastExecutionSuccess: false,
                retryTime: _retryTime
            })
        );
        emit JobAdded(_contractAddress, _frequency, _retryTime);
    }

    function pauseJob(uint256 _jobId, bool _paused) external onlyExecutors {
        jobs[_jobId].paused = _paused;
    }

    function setJob(
        uint256 _jobId,
        uint256 _frequency,
        uint256 _retryTime
    ) external onlyOwner {
        Job storage job = jobs[_jobId];
        job.frequency = _frequency;
        job.retryTime = _retryTime;
        emit JobUpdated(_jobId, _frequency, _retryTime);
    }

    function removeJob(uint256 _jobId) external onlyOwner {
        delete jobs[_jobId];
        emit JobRemoved(_jobId);
    }

    function execute(uint256[] memory _jobIds) external onlyExecutors {
        for (uint256 i = 0; i < _jobIds.length; i++) {
            if (_jobIds[i] < jobs.length) {
                if (_executable(_jobIds[i])) {
                    Job storage job = jobs[_jobIds[i]];
                    job.lastExecutionTime = block.timestamp;
                    (bool success, ) = job.contractAddress.call(job.callData);
                    job.lastExecutionCompleted = true;
                    job.lastExecutionSuccess = success;
                    if (!success && job.retryTime > 0) {
                        job.nextExecutionTime = block.timestamp + job.retryTime;
                    } else {
                        job.nextExecutionTime = block.timestamp + job.frequency;
                    }
                }
            }
        }
        emit Executed(msg.sender, _jobIds, block.timestamp);
    }

    function _executable(uint256 jobId) internal view returns (bool) {
        return !jobs[jobId].paused && block.timestamp >= jobs[jobId].nextExecutionTime;
    }

    /*====================== EVENTS =====================*/

    event Executed(address indexed executor, uint256[] jobIds, uint256 time);
    event JobRemoved(uint256 index);
    event JobUpdated(uint256 index, uint256 _frequency, uint256 _retryTime);
    event JobAdded(address indexed _address, uint256 _frequency, uint256 _retryTime);
}