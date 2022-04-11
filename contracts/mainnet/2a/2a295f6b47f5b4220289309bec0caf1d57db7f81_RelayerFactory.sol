/**
 *Submitted for verification at Etherscan.io on 2022-04-10
*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;
interface IRelayer {
    enum RelayerType {
        DiscountRate,
        SpotPrice,
        COUNT
    }

    function execute() external returns (bool);

    function executeWithRevert() external;
}interface IOracle {
    function value() external view returns (int256, bool);

    function update() external returns (bool);
}// Lightweight interface for Collybus
// Source: https://github.com/fiatdao/fiat-lux/blob/f49a9457fbcbdac1969c35b4714722f00caa462c/src/interfaces/ICollybus.sol
interface ICollybus {
    function updateDiscountRate(uint256 tokenId_, uint256 rate_) external;

    function updateSpot(address token_, uint256 spot_) external;
}/// @title Guarded
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
/// @notice The Relayer contract manages the relationship between an oracle and Collybus.
/// The Relayer manages an Oracle for which it controls the update flow and via execute() calls
/// pushes data to Collybus when it's needed
/// @dev The Relayer should be the single entity that updates the oracle so that the Relayer and the Oracle
/// are value synched. The same is true for the Relayer-Collybus relationship as we do not interrogate the Collybus
/// for the current value and use a storage cached last updated value.
contract Relayer is Guarded, IRelayer {
    /// @notice Emitter during executeWithRevert() if the oracle is not updated successfully
    error Relayer__executeWithRevert_noUpdate(RelayerType relayerType);

    /// @notice Emitted when trying to set a parameter that does not exist
    error Relayer__setParam_unrecognizedParam(bytes32 param);

    event SetParam(bytes32 param, uint256 value);
    event UpdateOracle(address oracle, int256 value, bool valid);
    event UpdatedCollybus(bytes32 tokenId, uint256 rate, RelayerType);

    /// ======== Storage ======== ///

    address public immutable collybus;
    RelayerType public immutable relayerType;
    address public immutable oracle;
    bytes32 public immutable encodedTokenId;

    uint256 public minimumPercentageDeltaValue;
    int256 private _lastUpdateValue;

    /// @param collybusAddress_ Address of the collybus
    /// @param type_ Relayer type, DiscountRate or SpotPrice
    /// @param oracleAddress_ The address of the oracle used by the Relayer
    /// @param encodedTokenId_ Encoded token Id that will be used to push values to Collybus
    /// uint256 for discount rate, address for spot price
    /// @param minimumPercentageDeltaValue_ Minimum delta value used to determine when to
    /// push data to Collybus
    constructor(
        address collybusAddress_,
        RelayerType type_,
        address oracleAddress_,
        bytes32 encodedTokenId_,
        uint256 minimumPercentageDeltaValue_
    ) {
        collybus = collybusAddress_;
        relayerType = type_;
        oracle = oracleAddress_;
        encodedTokenId = encodedTokenId_;
        minimumPercentageDeltaValue = minimumPercentageDeltaValue_;
        _lastUpdateValue = 0;
    }

    /// @notice Sets a Relayer parameter
    /// Supported parameters are:
    /// - minimumPercentageDeltaValue
    /// @param param_ The identifier of the parameter that should be updated
    /// @param value_ The new value
    /// @dev Reverts if parameter is not found
    function setParam(bytes32 param_, uint256 value_) public checkCaller {
        if (param_ == "minimumPercentageDeltaValue") {
            minimumPercentageDeltaValue = value_;
        } else revert Relayer__setParam_unrecognizedParam(param_);

        emit SetParam(param_, value_);
    }

    /// @notice Updates the oracle and pushes the updated data to Collybus if the
    /// delta change in value is bigger than the minimum threshold value.
    /// @return Whether the Collybus was updated or not
    function execute() public override(IRelayer) returns (bool) {
        // We always update the oracles before retrieving the rates
        bool oracleUpdated = IOracle(oracle).update();
        (int256 oracleValue, bool isValid) = IOracle(oracle).value();

        // If the oracle was not updated, the value is invalid or the delta condition is not met, we can exit early
        if (
            !oracleUpdated ||
            !isValid ||
            !checkDeviation(
                _lastUpdateValue,
                oracleValue,
                minimumPercentageDeltaValue
            )
        ) {
            // Collybus was not updated so we return false
            return false;
        }

        _lastUpdateValue = oracleValue;

        if (relayerType == RelayerType.DiscountRate) {
            ICollybus(collybus).updateDiscountRate(
                uint256(encodedTokenId),
                uint256(oracleValue)
            );
        } else if (relayerType == RelayerType.SpotPrice) {
            ICollybus(collybus).updateSpot(
                address(uint160(uint256(encodedTokenId))),
                uint256(oracleValue)
            );
        }

        emit UpdatedCollybus(encodedTokenId, uint256(oracleValue), relayerType);

        // Collybus was updated
        return true;
    }

    /// @notice The function will call `execute()` and will revert if the oracle was not updated
    /// @dev This method is needed for services that run on each block and only call the method if it doesn't fail
    function executeWithRevert() public override(IRelayer) {
        if (!execute()) {
            revert Relayer__executeWithRevert_noUpdate(relayerType);
        }
    }

    /// @notice Returns true if the percentage difference between the two values is bigger than the `percentage`
    /// @param baseValue_ The value that the percentage is based on
    /// @param newValue_ The new value
    /// @param percentage_ The percentage threshold value (100% = 100_00, 50% = 50_00, etc)
    function checkDeviation(
        int256 baseValue_,
        int256 newValue_,
        uint256 percentage_
    ) public pure returns (bool) {
        int256 deviation = (baseValue_ * int256(percentage_)) / 100_00;

        if (
            baseValue_ + deviation <= newValue_ ||
            baseValue_ - deviation >= newValue_
        ) return true;

        return false;
    }
}
contract StaticRelayer is IRelayer {
    /// @notice Emitted during executeWithRevert() if the Collybus was already updated
    error StaticRelayer__executeWithRevert_collybusAlreadyUpdated(
        IRelayer.RelayerType relayerType
    );

    /// ======== Events ======== ///

    event UpdatedCollybus(
        bytes32 tokenId,
        uint256 rate,
        IRelayer.RelayerType relayerType
    );

    /// ======== Storage ======== ///

    address public immutable collybus;
    IRelayer.RelayerType public immutable relayerType;
    bytes32 public immutable encodedTokenId;
    uint256 public immutable value;

    // Flag used to ensure that the value is pushed to Collybus only once
    bool private _updatedCollybus;

    /// @param collybusAddress_ Address of the collybus
    /// @param type_ Relayer type, DiscountRate or SpotPrice
    /// @param encodedTokenId_ Encoded token Id that will be used to push the value to Collybus
    /// uint256 for discount rate, address for spot price
    /// @param value_ The value that will be pushed to Collybus
    constructor(
        address collybusAddress_,
        IRelayer.RelayerType type_,
        bytes32 encodedTokenId_,
        uint256 value_
    ) {
        collybus = collybusAddress_;
        relayerType = type_;
        encodedTokenId = encodedTokenId_;
        value = value_;
        _updatedCollybus = false;
    }

    /// @notice Pushes the hardcoded value to Collybus for the hardcoded token id
    /// @dev The execute will exit early after the first update
    function execute() public override(IRelayer) returns (bool) {
        if (_updatedCollybus) return false;

        _updatedCollybus = true;
        if (relayerType == IRelayer.RelayerType.DiscountRate) {
            ICollybus(collybus).updateDiscountRate(
                uint256(encodedTokenId),
                value
            );
        } else if (relayerType == IRelayer.RelayerType.SpotPrice) {
            ICollybus(collybus).updateSpot(
                address(uint160(uint256(encodedTokenId))),
                value
            );
        }

        emit UpdatedCollybus(encodedTokenId, value, relayerType);
        return true;
    }

    /// @notice The function will call `execute()` and will revert if _updatedCollybus is true
    function executeWithRevert() public override(IRelayer) {
        if (!execute()) {
            revert StaticRelayer__executeWithRevert_collybusAlreadyUpdated(
                relayerType
            );
        }
    }
}

interface IRelayerFactory {
    function create(
        address collybus_,
        IRelayer.RelayerType relayerType_,
        address oracleAddress,
        bytes32 encodedTokenId,
        uint256 minimumPercentageDeltaValue
    ) external returns (address);

    function createStatic(
        address collybus_,
        IRelayer.RelayerType relayerType_,
        bytes32 encodedTokenId_,
        uint256 value_
    ) external returns (address);
}

contract RelayerFactory is IRelayerFactory {
    // Emitted when a Relayer is created
    event RelayerDeployed(
        address relayerAddress,
        IRelayer.RelayerType relayerType,
        address oracleAddress,
        bytes32 encodedTokenId,
        uint256 minimumPercentageDeltaValue
    );
    // Emitted when a Static Relayer is created
    event StaticRelayerDeployed(
        address relayerAddress,
        IRelayer.RelayerType relayerType,
        bytes32 encodedTokenId,
        uint256 value
    );

    /// @notice Creates a Relayer contract that manages an Oracle in order to push data to Collybus
    /// @param collybus_ The address of the Collybus where the Relayer will push data
    /// @param relayerType_ Relayer type, can be DiscountRate or SpotPrice
    /// @param oracleAddress_ The address of the oracle that will provide data
    /// @param encodedTokenId_ Encoded tokenId that will be used to push data to Collybus
    /// @param minimumPercentageDeltaValue_ Minimum delta value used to decide when to push data to Collybus
    function create(
        address collybus_,
        Relayer.RelayerType relayerType_,
        address oracleAddress_,
        bytes32 encodedTokenId_,
        uint256 minimumPercentageDeltaValue_
    ) public override(IRelayerFactory) returns (address) {
        Relayer relayer = new Relayer(
            collybus_,
            relayerType_,
            oracleAddress_,
            encodedTokenId_,
            minimumPercentageDeltaValue_
        );

        // Pass permissions to the intended contract owner
        relayer.allowCaller(relayer.ANY_SIG(), msg.sender);
        relayer.blockCaller(relayer.ANY_SIG(), address(this));

        emit RelayerDeployed(
            address(relayer),
            relayerType_,
            oracleAddress_,
            encodedTokenId_,
            minimumPercentageDeltaValue_
        );
        return address(relayer);
    }

    /// @notice Creates a Static Relayer contract that acts as a one time data provider.
    /// @param collybus_ The address of the Collybus where the StaticRelayer will push data
    /// @param relayerType_ Relayer type, can be DiscountRate or SpotPrice
    /// @param encodedTokenId_ Encoded tokenId that will be used to push data to Collybus
    /// @param value_ The value that will be pushed.
    /// @dev The contract will self-destruct after the rate is successfully pushed to Collybus
    function createStatic(
        address collybus_,
        Relayer.RelayerType relayerType_,
        bytes32 encodedTokenId_,
        uint256 value_
    ) public override(IRelayerFactory) returns (address) {
        // Create the Static Relayer contract
        StaticRelayer staticRelayer = new StaticRelayer(
            collybus_,
            relayerType_,
            encodedTokenId_,
            value_
        );

        emit StaticRelayerDeployed(
            address(staticRelayer),
            relayerType_,
            encodedTokenId_,
            value_
        );
        return address(staticRelayer);
    }
}