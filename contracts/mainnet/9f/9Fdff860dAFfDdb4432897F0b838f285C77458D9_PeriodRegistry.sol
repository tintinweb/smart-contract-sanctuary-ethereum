// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import './interfaces/IPeriodRegistry.sol';

/**
 * @title PeriodRegistry
 * @notice PeriodRegistry is a contract for management of period definitions
 */
contract PeriodRegistry is IPeriodRegistry, Ownable {
    /// @notice struct to store the definition of a period
    struct PeriodDefinition {
        bool initialized;
        uint256[] starts;
        uint256[] ends;
    }

    /// @notice (periodType=>PeriodDefinition) period definitions by period type
    /// @dev period types are hourly / weekly / biWeekly / monthly / yearly
    mapping(PeriodType => PeriodDefinition) public periodDefinitions;

    /**
     * @notice event to log that a period is initialized
     * @param periodType 1. period type i.e. Hourly, Daily, Weekly, BiWeekly, Monthly, Yearly
     * @param periodsAdded 2. amount of periods added
     */
    event PeriodInitialized(PeriodType periodType, uint256 periodsAdded);

    /**
     * @dev event to log that a period is modified
     * @param periodType 1. period type i.e. Hourly, Daily, Weekly, BiWeekly, Monthly, Yearly
     * @param periodsAdded 2. amount of periods added
     */
    event PeriodModified(PeriodType periodType, uint256 periodsAdded);

    /**
     * @notice External function for creating canonical service level agreements
     * @param _periodType 1. period type i.e. Hourly, Daily, Weekly, BiWeekly, Monthly, Yearly
     * @param _periodStarts 2. array of the starts of the period
     * @param _periodEnds 3. array of the ends of the period
     */
    function initializePeriod(
        PeriodType _periodType,
        uint256[] memory _periodStarts,
        uint256[] memory _periodEnds
    ) external onlyOwner {
        _addPeriods(false, _periodType, _periodStarts, _periodEnds);
        emit PeriodInitialized(_periodType, _periodStarts.length);
    }

    /**
     * @notice External function to add a new period definition
     * @dev only owner can call this function
     * @param _periodType type of period to add
     * @param _periodStarts array of the period starting timestamps to add
     * @param _periodEnds 3. array of the period ending timestamps to add
     */
    function addPeriodsToPeriodType(
        PeriodType _periodType,
        uint256[] memory _periodStarts,
        uint256[] memory _periodEnds
    ) external onlyOwner {
        _addPeriods(true, _periodType, _periodStarts, _periodEnds);
        emit PeriodModified(_periodType, _periodStarts.length);
    }

    /**
     * @notice Internal function that add or update a period definition
     * @param _periodType type of period
     * @param _periodStarts array of the period starting timestamps
     * @param _periodEnds array of the period ending timestamps
     */
    function _addPeriods(
        bool _initialized,
        PeriodType _periodType,
        uint256[] memory _periodStarts,
        uint256[] memory _periodEnds
    ) internal {
        require(_periodStarts.length > 0, "Period length can't be 0");
        require(
            _periodStarts.length == _periodEnds.length,
            'Period length in start and end arrays should match'
        );
        PeriodDefinition storage periodDefinition = periodDefinitions[
            _periodType
        ];
        if (_initialized)
            require(
                periodDefinition.initialized,
                'Period was not initialized yet'
            );
        else
            require(
                !periodDefinition.initialized,
                'Period type already initialized'
            );

        for (uint256 index = 0; index < _periodStarts.length; index++) {
            require(
                _periodStarts[index] < _periodEnds[index],
                'Start should be before end'
            );
            if (index < _periodStarts.length - 1) {
                require(
                    _periodStarts[index + 1] - _periodEnds[index] == 1,
                    'Start of a period should be 1 second after the end of the previous period'
                );
            }
            periodDefinition.starts.push(_periodStarts[index]);
            periodDefinition.ends.push(_periodEnds[index]);
        }
        periodDefinition.initialized = true;
    }

    /**
     * @notice public function to get the start and end of a period
     * @param _periodType type of period to check
     * @param _periodId id of period to check
     * @return start starting timestamp
     * @return end ending timestamp
     */
    function getPeriodStartAndEnd(PeriodType _periodType, uint256 _periodId)
        external
        view
        override
        returns (uint256 start, uint256 end)
    {
        require(
            _periodId < periodDefinitions[_periodType].starts.length,
            'Invalid period id'
        );
        start = periodDefinitions[_periodType].starts[_periodId];
        end = periodDefinitions[_periodType].ends[_periodId];
    }

    /**
     * @notice public function to check if the period definition is initialized by period type
     * @param _periodType type of period to check
     * @return initialized if initialized or not
     */
    function isInitializedPeriod(PeriodType _periodType)
        external
        view
        override
        returns (bool initialized)
    {
        initialized = periodDefinitions[_periodType].initialized;
    }

    /**
     * @notice public function to check if a period id is valid i.e. it belongs to the added id array
     * @param _periodType type of period to check
     * @param _periodId id of period to check
     * @return valid if valid or invalid
     */
    function isValidPeriod(PeriodType _periodType, uint256 _periodId)
        public
        view
        override
        returns (bool valid)
    {
        valid = periodDefinitions[_periodType].starts.length - 1 >= _periodId;
    }

    /**
     * @notice public function to check if a period has finished
     * @param _periodType type of period to check
     * @param _periodId id of period to check
     * @return finished if finished or not
     */
    function periodIsFinished(PeriodType _periodType, uint256 _periodId)
        external
        view
        override
        returns (bool finished)
    {
        require(
            isValidPeriod(_periodType, _periodId),
            'Period data is not valid'
        );
        finished =
            periodDefinitions[_periodType].ends[_periodId] < block.timestamp;
    }

    /**
     * @notice public function to check if a period has started
     * @param _periodType type of period to check
     * @param _periodId id of period to check
     * @return started if started or not
     */
    function periodHasStarted(PeriodType _periodType, uint256 _periodId)
        external
        view
        override
        returns (bool started)
    {
        require(
            isValidPeriod(_periodType, _periodId),
            'Period data is not valid'
        );
        started =
            periodDefinitions[_periodType].starts[_periodId] < block.timestamp;
    }

    /**
     * @notice public function to get the definitions of period for all period types
     * @return array of period definitions
     */
    function getPeriodDefinitions()
        public
        view
        returns (PeriodDefinition[] memory)
    {
        // 6 period types
        PeriodDefinition[] memory periodDefinition = new PeriodDefinition[](6);
        periodDefinition[0] = periodDefinitions[PeriodType.Hourly];
        periodDefinition[1] = periodDefinitions[PeriodType.Daily];
        periodDefinition[2] = periodDefinitions[PeriodType.Weekly];
        periodDefinition[3] = periodDefinitions[PeriodType.BiWeekly];
        periodDefinition[4] = periodDefinitions[PeriodType.Monthly];
        periodDefinition[5] = periodDefinitions[PeriodType.Yearly];
        return periodDefinition;
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

interface IPeriodRegistry {
    enum PeriodType {
        Hourly,
        Daily,
        Weekly,
        BiWeekly,
        Monthly,
        Yearly
    }

    function getPeriodStartAndEnd(PeriodType _periodType, uint256 _periodId)
        external
        view
        returns (uint256, uint256);

    function isValidPeriod(PeriodType _periodType, uint256 _periodId)
        external
        view
        returns (bool);

    function isInitializedPeriod(PeriodType _periodType)
        external
        view
        returns (bool);

    function periodHasStarted(PeriodType _periodType, uint256 _periodId)
        external
        view
        returns (bool);

    function periodIsFinished(PeriodType _periodType, uint256 _periodId)
        external
        view
        returns (bool);
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