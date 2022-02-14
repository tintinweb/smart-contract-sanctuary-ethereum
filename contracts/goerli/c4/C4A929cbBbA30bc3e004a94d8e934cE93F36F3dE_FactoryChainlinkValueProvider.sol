/**
 *Submitted for verification at Etherscan.io on 2022-02-14
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/factory/FactoryChainlinkValueProvider.sol
// SPDX-License-Identifier: Apache-2.0 AND Unlicensed AND MIT
pragma solidity >=0.8.0 <0.9.0;

////// src/oracle/IOracle.sol
/* pragma solidity ^0.8.0; */

interface IOracle {
    function value() external view returns (int256, bool);

    function update() external;
}

////// src/guarded/Guarded.sol
/* pragma solidity ^0.8.0; */

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
    /// @param sig Method signature (4Byte)
    /// @param who Address of who should be able to call `sig`
    function allowCaller(bytes32 sig, address who) public callerIsRoot {
        _canCall[sig][who] = true;
        emit AllowCaller(sig, who);
    }

    /// @notice Revoke the right to call method `sig` from `who`
    /// @dev Only the root user (granted `ANY_SIG`) is able to call this method
    /// @param sig Method signature (4Byte)
    /// @param who Address of who should not be able to call `sig` anymore
    function blockCaller(bytes32 sig, address who) public callerIsRoot {
        _canCall[sig][who] = false;
        emit BlockCaller(sig, who);
    }

    /// @notice Returns if `who` can call `sig`
    /// @param sig Method signature (4Byte)
    /// @param who Address of who should be able to call `sig`
    function canCall(bytes32 sig, address who) public view returns (bool) {
        return (_canCall[sig][who] ||
            _canCall[ANY_SIG][who] ||
            _canCall[sig][ANY_CALLER]);
    }

    /// @notice Sets the root user (granted `ANY_SIG`)
    /// @param root Address of who should be set as root
    function _setRoot(address root) internal {
        _canCall[ANY_SIG][root] = true;
        emit AllowCaller(ANY_SIG, root);
    }
}

////// src/pausable/Pausable.sol
/* pragma solidity ^0.8.0; */

/// @notice Emitted when paused
error Pausable__whenNotPaused_paused();

/// @notice Emitted when not paused
error Pausable__whenPaused_notPaused();

/* import {Guarded} from "src/guarded/Guarded.sol"; */

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

////// src/oracle/Oracle.sol
/* pragma solidity ^0.8.0; */

/* import {IOracle} from "src/oracle/IOracle.sol"; */

/* import {Pausable} from "src/pausable/Pausable.sol"; */

abstract contract Oracle is Pausable, IOracle {
    /// ======== Events ======== ///

    event ValueInvalid();
    event ValueUpdated(int256 currentValue, int256 nextValue);
    event OracleReset();

    /// ======== Storage ======== ///

    uint256 public immutable timeUpdateWindow;

    uint256 public immutable maxValidTime;

    uint256 public lastTimestamp;

    // alpha determines how much influence
    // the new value has on the computed moving average
    // A commonly used value is 2 / (N + 1)
    int256 public immutable alpha;

    // next EMA value
    int256 public nextValue;

    // current EMA value and its validity
    int256 private _currentValue;
    bool private _validReturnedValue;

    constructor(
        uint256 timeUpdateWindow_,
        uint256 maxValidTime_,
        int256 alpha_
    ) {
        timeUpdateWindow = timeUpdateWindow_;
        maxValidTime = maxValidTime_;
        alpha = alpha_;
        _validReturnedValue = false;
    }

    /// @notice Get the current value of the oracle
    /// @return the current value of the oracle
    /// @return whether the value is valid
    function value()
        public
        view
        override(IOracle)
        whenNotPaused
        returns (int256, bool)
    {
        // Value is considered valid if the value provider successfully returned a value
        // and it was updated before maxValidTime ago
        bool valid = _validReturnedValue &&
            (block.timestamp < lastTimestamp + maxValidTime);
        return (_currentValue, valid);
    }

    function getValue() external virtual returns (int256);

    function update() public override(IOracle) {
        // Not enough time has passed since the last update
        if (lastTimestamp + timeUpdateWindow > block.timestamp) {
            // Exit early if no update is needed
            return;
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

                // Update the EMA and store it in the next value
                int256 newValue = returnedValue;
                // EMA = EMA(prev) + alpha * (Value - EMA(prev))
                // Scales down because of fixed number of decimals
                nextValue =
                    _currentValue +
                    (alpha * (newValue - _currentValue)) /
                    10**18;
            }

            // Save when the value was last updated
            lastTimestamp = block.timestamp;
            _validReturnedValue = true;

            emit ValueUpdated(_currentValue, nextValue);
        } catch {
            // When a value provider fails, we update the valid flag which will
            // invalidate the value instantly
            _validReturnedValue = false;
            emit ValueInvalid();
        }
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

////// src/oracle_implementations/discount_rate/utils/Convert.sol
/* pragma solidity ^0.8.0; */

contract Convert {
    function convert(
        int256 x,
        uint256 currentPrecision,
        uint256 targetPrecision
    ) internal pure returns (int256) {
        if (targetPrecision > currentPrecision)
            return x * int256(10**(targetPrecision - currentPrecision));

        return x / int256(10**(currentPrecision - targetPrecision));
    }

    function uconvert(
        uint256 x,
        uint256 currentPrecision,
        uint256 targetPrecision
    ) internal pure returns (uint256) {
        if (targetPrecision > currentPrecision)
            return x * 10**(targetPrecision - currentPrecision);

        return x / 10**(currentPrecision - targetPrecision);
    }
}

////// src/oracle_implementations/spot_price/Chainlink/ChainlinkAggregatorV3Interface.sol
/* pragma solidity ^0.8.0; */

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

////// src/oracle_implementations/spot_price/Chainlink/ChainLinkValueProvider.sol
/* pragma solidity ^0.8.0; */

/* import {Convert} from "src/oracle_implementations/discount_rate/utils/Convert.sol"; */
/* import {IChainlinkAggregatorV3Interface} from "src/oracle_implementations/spot_price/Chainlink/ChainlinkAggregatorV3Interface.sol"; */
/* import {Oracle} from "src/oracle/Oracle.sol"; */

contract ChainLinkValueProvider is Oracle, Convert {
    uint8 public immutable underlierDecimals;
    address public underlierAddress;
    address public chainlinkAggregatorAddress;

    /// @notice                             Constructs the Value provider contracts with the needed Chainlink.
    /// @param timeUpdateWindow_            Minimum time between updates of the value
    /// @param maxValidTime_                Maximum time for which the value is valid
    /// @param alpha_                       Alpha parameter for EMA
    /// @param chainlinkAggregatorAddress_  Address of the deployed chainlink aggregator contract.
    constructor(
        // Oracle parameters
        uint256 timeUpdateWindow_,
        uint256 maxValidTime_,
        int256 alpha_,
        //
        address chainlinkAggregatorAddress_
    ) Oracle(timeUpdateWindow_, maxValidTime_, alpha_) {
        chainlinkAggregatorAddress = chainlinkAggregatorAddress_;
        underlierDecimals = IChainlinkAggregatorV3Interface(
            chainlinkAggregatorAddress_
        ).decimals();
    }

    /// @notice Retrieves the price from the chainlink aggregator
    /// @return result The result as an signed 59.18-decimal fixed-point number.
    function getValue() external view override(Oracle) returns (int256) {
        // The returned annual rate is in 1e9 precision so we need to convert it to 1e18 precision.
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

////// src/factory/FactoryChainlinkValueProvider.sol
/* pragma solidity ^0.8.0; */

/* import {ChainLinkValueProvider} from "src/oracle_implementations/spot_price/Chainlink/ChainLinkValueProvider.sol"; */

interface IFactoryChainlinkValueProvider {
    function create(
        // Oracle parameters
        uint256 timeUpdateWindow_,
        uint256 maxValidTime_,
        int256 alpha_,
        //
        address chainlinkAggregatorAddress_
    ) external returns (address);
}

contract FactoryChainlinkValueProvider is IFactoryChainlinkValueProvider {
    function create(
        // Oracle parameters
        uint256 timeUpdateWindow_,
        uint256 maxValidTime_,
        int256 alpha_,
        //
        address chainlinkAggregatorAddress_
    ) public override(IFactoryChainlinkValueProvider) returns (address) {
        ChainLinkValueProvider chainlinkValueProvider = new ChainLinkValueProvider(
                timeUpdateWindow_,
                maxValidTime_,
                alpha_,
                chainlinkAggregatorAddress_
            );

        return address(chainlinkValueProvider);
    }
}