/**
 *Submitted for verification at Etherscan.io on 2022-04-04
*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IOracle {
    function value() external view returns (int256, bool);

    function update() external returns (bool);
}
/// @notice Emitted when paused
error Pausable__whenNotPaused_paused();

/// @notice Emitted when not paused
error Pausable__whenPaused_notPaused();

/// @title Guarded
/// @notice Mixin implementing an authentication scheme on a method level
abstract contract Guarded {
    /// ======== Custom Errors ======== ///

    error Guarded__notRoot();
    error Guarded__notGranted();

    /// ======== Storage ======== ///

    /// @notice Wildcard for granting a caller to call every guarded method
    bytes32 public constant ANY_SIG = keccak256("ANY_SIG");
    /// @notice Wildcard for granting a caller to call every guarded method
    address public constant ANY_CALLER =
        address(uint160(uint256(bytes32(keccak256("ANY_CALLER")))));

    /// @notice Mapping storing who is granted to which method
    /// @dev Method Signature => Caller => Bool
    mapping(bytes32 => mapping(address => bool)) private _canCall;

    /// ======== Events ======== ///

    event AllowCaller(bytes32 sig, address who);
    event BlockCaller(bytes32 sig, address who);

    constructor() {
        // set root
        _setRoot(msg.sender);
    }

    /// ======== Auth ======== ///

    modifier callerIsRoot() {
        if (_canCall[ANY_SIG][msg.sender]) {
            _;
        } else revert Guarded__notRoot();
    }

    modifier checkCaller() {
        if (canCall(msg.sig, msg.sender)) {
            _;
        } else revert Guarded__notGranted();
    }

    /// @notice Grant the right to call method `sig` to `who`
    /// @dev Only the root user (granted `ANY_SIG`) is able to call this method
    /// @param sig_ Method signature (4Byte)
    /// @param who_ Address of who should be able to call `sig`
    function allowCaller(bytes32 sig_, address who_) public callerIsRoot {
        _canCall[sig_][who_] = true;
        emit AllowCaller(sig_, who_);
    }

    /// @notice Revoke the right to call method `sig` from `who`
    /// @dev Only the root user (granted `ANY_SIG`) is able to call this method
    /// @param sig_ Method signature (4Byte)
    /// @param who_ Address of who should not be able to call `sig` anymore
    function blockCaller(bytes32 sig_, address who_) public callerIsRoot {
        _canCall[sig_][who_] = false;
        emit BlockCaller(sig_, who_);
    }

    /// @notice Returns if `who` can call `sig`
    /// @param sig_ Method signature (4Byte)
    /// @param who_ Address of who should be able to call `sig`
    function canCall(bytes32 sig_, address who_) public view returns (bool) {
        return (_canCall[sig_][who_] ||
            _canCall[ANY_SIG][who_] ||
            _canCall[sig_][ANY_CALLER]);
    }

    /// @notice Sets the root user (granted `ANY_SIG`)
    /// @param root_ Address of who should be set as root
    function _setRoot(address root_) internal {
        _canCall[ANY_SIG][root_] = true;
        emit AllowCaller(ANY_SIG, root_);
    }
}
contract Pausable is Guarded {
    event Paused(address who);
    event Unpaused(address who);

    bool private _paused;

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        // If the contract is paused, throw an error
        if (_paused) {
            revert Pausable__whenNotPaused_paused();
        }
        _;
    }

    modifier whenPaused() {
        // If the contract is not paused, throw an error
        if (_paused == false) {
            revert Pausable__whenPaused_notPaused();
        }
        _;
    }

    function _pause() internal whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    function _unpause() internal whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}
abstract contract Oracle is Pausable, IOracle {
    /// @notice Emitted when a method is reentered
    error Oracle__nonReentrant();

    /// ======== Events ======== ///

    event ValueInvalid();
    event ValueUpdated(int256 currentValue, int256 nextValue);
    event OracleReset();

    /// ======== Storage ======== ///
    // Time interval between the value updates
    uint256 public immutable timeUpdateWindow;

    // Timestamp of the current value
    uint256 public lastTimestamp;

    // The next value that will replace the current value once the timeUpdateWindow has passed
    int256 public nextValue;

    // Current value that will be returned by the Oracle
    int256 private _currentValue;

    // Flag that tells if the value provider returned successfully
    bool private _validReturnedValue;

    // Reentrancy constants
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    // Reentrancy guard flag
    uint256 private _reentrantGuard = _NOT_ENTERED;

    /// ======== Modifiers ======== ///

    modifier nonReentrant() {
        // Check if the guard is set
        if (_reentrantGuard != _NOT_ENTERED) {
            revert Oracle__nonReentrant();
        }

        // Set the guard
        _reentrantGuard = _ENTERED;

        // Allow execution
        _;

        // Reset the guard
        _reentrantGuard = _NOT_ENTERED;
    }

    constructor(uint256 timeUpdateWindow_) {
        timeUpdateWindow = timeUpdateWindow_;
        _validReturnedValue = false;
    }

    /// @notice Get the current value of the oracle
    /// @return The current value of the oracle
    /// @return Whether the value is valid
    function value()
        public
        view
        override(IOracle)
        whenNotPaused
        returns (int256, bool)
    {
        // Value is considered valid if the value provider successfully returned a value
        return (_currentValue, _validReturnedValue);
    }

    function getValue() external virtual returns (int256);

    function update()
        public
        override(IOracle)
        checkCaller
        nonReentrant
        returns (bool)
    {
        // Not enough time has passed since the last update
        if (lastTimestamp + timeUpdateWindow > block.timestamp) {
            // Exit early if no update is needed
            return false;
        }

        // Oracle update should not fail even if the value provider fails to return a value
        try this.getValue() returns (int256 returnedValue) {
            // Update the value using an exponential moving average
            if (_currentValue == 0) {
                // First update takes the current value
                nextValue = returnedValue;
                _currentValue = nextValue;
            } else {
                // Update the current value with the next value
                _currentValue = nextValue;
                // Set the returnedValue as the next value
                nextValue = returnedValue;
            }

            // Save when the value was last updated
            lastTimestamp = block.timestamp;
            _validReturnedValue = true;

            emit ValueUpdated(_currentValue, nextValue);

            return true;
        } catch {
            // When a value provider fails, we update the valid flag which will
            // invalidate the value instantly
            _validReturnedValue = false;
            emit ValueInvalid();
        }

        return false;
    }

    function pause() public checkCaller {
        _pause();
    }

    function unpause() public checkCaller {
        _unpause();
    }

    function reset() public whenPaused checkCaller {
        _currentValue = 0;
        nextValue = 0;
        lastTimestamp = 0;
        _validReturnedValue = false;

        emit OracleReset();
    }
}
contract Convert {
    function convert(
        int256 x_,
        uint256 currentPrecision_,
        uint256 targetPrecision_
    ) internal pure returns (int256) {
        if (targetPrecision_ > currentPrecision_)
            return x_ * int256(10**(targetPrecision_ - currentPrecision_));

        return x_ / int256(10**(currentPrecision_ - targetPrecision_));
    }

    function uconvert(
        uint256 x_,
        uint256 currentPrecision_,
        uint256 targetPrecision_
    ) internal pure returns (uint256) {
        if (targetPrecision_ > currentPrecision_)
            return x_ * 10**(targetPrecision_ - currentPrecision_);

        return x_ / 10**(currentPrecision_ - targetPrecision_);
    }
}
// Chainlink Aggregator v3 interface
// https://github.com/smartcontractkit/chainlink/blob/6fea3ccd275466e082a22be690dbaf1609f19dce/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol
interface IChainlinkAggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

contract ChainlinkValueProvider is Oracle, Convert {
    uint8 public immutable underlierDecimals;
    address public chainlinkAggregatorAddress;

    /// @notice Constructs the Value provider contracts with the needed Chainlink.
    /// @param timeUpdateWindow_ Minimum time between updates of the value
    /// @param chainlinkAggregatorAddress_ Address of the deployed chainlink aggregator contract.
    constructor(
        // Oracle parameters
        uint256 timeUpdateWindow_,
        // Chainlink specific parameter
        address chainlinkAggregatorAddress_
    ) Oracle(timeUpdateWindow_) {
        chainlinkAggregatorAddress = chainlinkAggregatorAddress_;
        underlierDecimals = IChainlinkAggregatorV3Interface(
            chainlinkAggregatorAddress_
        ).decimals();
    }

    /// @notice Retrieves the price from the chainlink aggregator
    /// @return result The result as an signed 59.18-decimal fixed-point number.
    function getValue() external view override(Oracle) returns (int256) {
        // Convert the annual rate to 1e18 precision.
        (, int256 answer, , , ) = IChainlinkAggregatorV3Interface(
            chainlinkAggregatorAddress
        ).latestRoundData();

        return convert(answer, underlierDecimals, 18);
    }

    /// @notice returns the description of the chainlink aggregator the proxy points to.
    function description() external view returns (string memory) {
        return
            IChainlinkAggregatorV3Interface(chainlinkAggregatorAddress)
                .description();
    }
}