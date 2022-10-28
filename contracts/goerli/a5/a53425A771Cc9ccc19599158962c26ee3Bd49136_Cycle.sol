// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

//                   @
//                 @@@@@
//              @  @@@@@@@@                       @@@@@@@@@@@@@@@@@@                          @@@@@@@@@@@@@@
//           [email protected]@@@@@ @@@@@@@@                  @@@@@@@@@@@@@@@@@@@@@                       @@@@@@@@@@@@@@@@@@@@
//         @@@@@@@@ @@& @@@@@@@@               @@@@                   @@@@          @@@#   @@@              @@@@   @@@@@@@@@@@@@@@#
//      @@@@@@@@@ @@@@@@@ @@@@@@@ .            @@@@                   @@@@          @@@#   @@@              @@@@   @@@@@@@@@@@@@@@@@
//    @@@@@@@@ @@@@@@@@      @ @@@@@@          @@@@                   @@@@          @@@#   @@@              @@@@   @@@@         @@@@
//    @@@@@@@@  @@@@@@@@     @@@@@@@@          @@@@                   @@@@          @@@#   @@@              @@@@   @@@@         @@@@
//      /@@@@@@@@ @@@@@@@@@@@@@@@@             @@@@                   @@@@          @@@#   @@@              @@@@   @@@@         @@@@
//         @@@@@@@@  @@@@@@@@@@@               @@@@@@@@@@@@@@@@@@@@@  @@@@@@@@@@@@@@@@@#   @@@@@@@@@@@@@@@@@@@@@   @@@@@@@@@@@@@@@@@
//            @@@@@@ @@@@@@@@                   @@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@#    @@@@@@@@@@@@@@@@@@     @@@@@@@@@@@@@@@
//              @  @@@@@@@@                                                         @@@#                           @@@@
//                 @@@@@                                                 @@@@@@@@@@@@@@                            @@@@
//                   @

// Import libraries.
import "@openzeppelin/contracts/access/Ownable.sol"; // Access control mechanism for smart contract functions.
import "@openzeppelin/contracts/security/Pausable.sol"; // An emergency stop mechanism.

/**
 * @title The interface for the Distributor smart contract.
 * @dev The following interface is used to properly call functions of the Distributor smart contract.
 */
interface IDistributor {
    /**
     * @notice Collects, converts, and operates with funds.
     * @param cycleIndex The index of the cycle to manage funds of.
     */
    function manageFunds(uint256 cycleIndex) external;
}

/**
 * @title The Cycle smart contract.
 * @notice This is a Cycle smart contract that operates with the additional smart contracts and manages cycles and gatheres and distributes funds between entities.
 * @dev The following smart contract is responsible for voting cycle management and transferring funds from the CyOp smart contract to the Vault and the Distributor.
 */
contract Cycle is Context, Ownable, Pausable {
    /**
     * @notice The struct describes the Cycle concept.
     */
    struct CycleDetails {
        /// @notice The height of the block when the cycle has started.
        uint256 startBlock;
        /// @notice The height of the block when the cycle has ended.
        uint256 endBlock;
        /// @notice The timestamp (in UNIX) when the cycle should end.
        uint256 endTime;
        /// @notice The flag indicates if the cycle has been ended or not.
        bool isFinished;
    }

    /// @notice The Distributor contract.
    IDistributor public distributor;
    /// @notice The collection of all cycles.
    mapping(uint256 => CycleDetails) public cycles;
    /// @notice The index of the current cycle;
    uint256 public currentCycleIndex;
    /// @notice The period of the cycles in seconds. Defaults to one week.
    uint256 public cyclePeriod;

    /**
     * @notice Events that are fired when owners are making changes to the current smart contract.
     * @param funcName The name of the function that has changed the state of the smart contract.
     */
    event ConfigurationChanged(string funcName);
    /**
     * @notice Events that are fired when owners start cycles.
     */
    event CycleStarted(uint256 cycleIndex);

    /**
     * @notice The constructor that initializes the current smart contract.
     * @param distributorAddress The address of the Distributor.
     */
    constructor(address distributorAddress) {
        // Set the state variables.
        distributor = IDistributor(distributorAddress);
        cyclePeriod = 7 days;
    }

    /**
     * @notice Ends the current cycle and starts a new one if conditions are met.
     */
    function endCycle() external {
        // Check if the current cycle has already been finished.
        require(!cycles[currentCycleIndex].isFinished, "CYCLE_ALREADY_FINISHED");
        // Check if the current cycle is elapsed.
        require(isCycleElapsed(currentCycleIndex), "CYCLE_NOT_ELAPSED");
        // End the cycle, manage funds, and start a new cycle.
        cycles[currentCycleIndex].endBlock = block.number;
        cycles[currentCycleIndex].isFinished = true;
        distributor.manageFunds(currentCycleIndex);
        _startNextCycle();
    }

    /**
     * @notice Starts a new voting cycle.
     * @dev Is used by the owner to start the very first cycle.
     */
    function startCycle() external onlyOwner {
        require(currentCycleIndex == 0, "CYCLES_ALREADY_STARTED");
        // Sets the parameters for the new cycle and starts it.
        _startNextCycle();
    }

    /**
     * @notice Sets new end timestamp of the current cycle.
     * @param endTime The end time of the voting cycle.
     */
    function setCycleEndTime(uint256 endTime) external onlyOwner {
        // Set the new parameters for the active cycle.
        cycles[currentCycleIndex].endTime = endTime;
        emit ConfigurationChanged("setCycleEndTime");
    }

    /**
     * @notice Sets a new Distributor address.
     * @param distributorAddress The address of the new Distributor to set.
     */
    function setDistributorAddress(address distributorAddress) external onlyOwner {
        require(distributorAddress != address(0), "ZERO_ADDRESS_NOT_ALLOWED");
        distributor = IDistributor(distributorAddress);
        emit ConfigurationChanged("setDistributorAddress");
    }

    /**
     * @notice Sets new cycle period.
     * @param cyclePeriod_ The new cycle period in seconds.
     */
    function setCyclePeriod(uint256 cyclePeriod_) external onlyOwner {
        cyclePeriod = cyclePeriod_;
        emit ConfigurationChanged("setCyclePeriod");
    }

    /**
     * @notice Checks if a cycle has ended.
     * @param cycleIndex The index of the cycle to check.
     * @return True if the cycle has finished, otherwise false.
     */
    function isCycleFinished(uint256 cycleIndex) external view returns (bool) {
        return cycles[cycleIndex].isFinished;
    }

    /**
     * @notice Gets the end time of a cycle by its index.
     * @param cycleIndex The index of the cycle to check.
     * @return The end time of a cycle.
     */
    function getCycleEndTime(uint256 cycleIndex) external view returns (uint256) {
        return cycles[cycleIndex].endTime;
    }

    /**
     * @notice Checks if a cycle has been elapsed.
     * @param cycleIndex The index of the cycle to check.
     * @return True if the cycle has already finished, false otherwise.
     */
    function isCycleElapsed(uint256 cycleIndex) public view returns (bool) {
        return cycles[cycleIndex].endTime > 0 && block.timestamp > cycles[cycleIndex].endTime;
    }

    /**
     * @notice Starts a new voting cycle.
     * @dev Is automatically called after the end of the previous cycle.
     */
    function _startNextCycle() internal {
        if (currentCycleIndex > 0) {
            // Check if the current cycle is finished. Skip checking for the first cycle.
            require(cycles[currentCycleIndex].isFinished, "CURRENT_CYCLE_NOT_FINISHED");
        }
        // Set the parameters for the new cycle.
        currentCycleIndex++;
        cycles[currentCycleIndex].endTime = block.timestamp + cyclePeriod;
        cycles[currentCycleIndex].startBlock = block.number;
        emit CycleStarted(currentCycleIndex);
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../contracts/Cycle.sol";

abstract contract $IDistributor is IDistributor {
    constructor() {}

    receive() external payable {}
}

contract $Cycle is Cycle {
    constructor(address distributorAddress) Cycle(distributorAddress) {}

    function $_startNextCycle() external {
        return super._startNextCycle();
    }

    function $_requireNotPaused() external view {
        return super._requireNotPaused();
    }

    function $_requirePaused() external view {
        return super._requirePaused();
    }

    function $_pause() external {
        return super._pause();
    }

    function $_unpause() external {
        return super._unpause();
    }

    function $_checkOwner() external view {
        return super._checkOwner();
    }

    function $_transferOwnership(address newOwner) external {
        return super._transferOwnership(newOwner);
    }

    function $_msgSender() external view returns (address) {
        return super._msgSender();
    }

    function $_msgData() external view returns (bytes memory) {
        return super._msgData();
    }

    receive() external payable {}
}