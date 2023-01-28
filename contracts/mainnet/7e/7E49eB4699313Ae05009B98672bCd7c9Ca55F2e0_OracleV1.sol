//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./interfaces/IAdministrable.sol";

import "./libraries/LibAdministrable.sol";
import "./libraries/LibSanitize.sol";

/// @title Administrable
/// @author Kiln
/// @notice This contract handles the administration of the contracts
abstract contract Administrable is IAdministrable {
    /// @notice Prevents unauthorized calls
    modifier onlyAdmin() {
        if (msg.sender != LibAdministrable._getAdmin()) {
            revert LibErrors.Unauthorized(msg.sender);
        }
        _;
    }

    /// @notice Prevents unauthorized calls
    modifier onlyPendingAdmin() {
        if (msg.sender != LibAdministrable._getPendingAdmin()) {
            revert LibErrors.Unauthorized(msg.sender);
        }
        _;
    }

    /// @inheritdoc IAdministrable
    function getAdmin() external view returns (address) {
        return LibAdministrable._getAdmin();
    }

    /// @inheritdoc IAdministrable
    function getPendingAdmin() external view returns (address) {
        return LibAdministrable._getPendingAdmin();
    }

    /// @inheritdoc IAdministrable
    function proposeAdmin(address _newAdmin) external onlyAdmin {
        _setPendingAdmin(_newAdmin);
    }

    /// @inheritdoc IAdministrable
    function acceptAdmin() external onlyPendingAdmin {
        _setAdmin(LibAdministrable._getPendingAdmin());
        _setPendingAdmin(address(0));
    }

    /// @notice Internal utility to set the admin address
    /// @param _admin Address to set as admin
    function _setAdmin(address _admin) internal {
        LibSanitize._notZeroAddress(_admin);
        LibAdministrable._setAdmin(_admin);
        emit SetAdmin(_admin);
    }

    /// @notice Internal utility to set the pending admin address
    /// @param _pendingAdmin Address to set as pending admin
    function _setPendingAdmin(address _pendingAdmin) internal {
        LibAdministrable._setPendingAdmin(_pendingAdmin);
        emit SetPendingAdmin(_pendingAdmin);
    }

    /// @notice Internal utility to retrieve the address of the current admin
    /// @return The address of admin
    function _getAdmin() internal view returns (address) {
        return LibAdministrable._getAdmin();
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./state/shared/Version.sol";

/// @title Initializable
/// @author Kiln
/// @notice This contract ensures that initializers are called only once per version
contract Initializable {
    /// @notice An error occured during the initialization
    /// @param version The version that was attempting to be initialized
    /// @param expectedVersion The version that was expected
    error InvalidInitialization(uint256 version, uint256 expectedVersion);

    /// @notice Emitted when the contract is properly initialized
    /// @param version New version of the contracts
    /// @param cdata Complete calldata that was used during the initialization
    event Initialize(uint256 version, bytes cdata);

    /// @notice Use this modifier on initializers along with a hard-coded version number
    /// @param _version Version to initialize
    modifier init(uint256 _version) {
        if (_version != Version.get()) {
            revert InvalidInitialization(_version, Version.get());
        }
        Version.set(_version + 1); // prevents reentrency on the called method
        _;
        emit Initialize(_version, msg.data);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./interfaces/IRiver.1.sol";
import "./interfaces/IOracle.1.sol";

import "./Administrable.sol";
import "./Initializable.sol";

import "./state/shared/RiverAddress.sol";
import "./state/oracle/OracleMembers.sol";
import "./state/oracle/Quorum.sol";
import "./state/oracle/ExpectedEpochId.sol";
import "./state/oracle/LastEpochId.sol";
import "./state/oracle/ReportsPositions.sol";
import "./state/oracle/ReportsVariants.sol";

/// @title Oracle (v1)
/// @author Kiln
/// @notice This contract handles the input from the allowed oracle members. Highly inspired by Lido's implementation.
contract OracleV1 is IOracleV1, Initializable, Administrable {
    /// @notice One Year value
    uint256 internal constant ONE_YEAR = 365 days;

    /// @notice Received ETH input has only 9 decimals
    uint128 internal constant DENOMINATION_OFFSET = 1e9;

    /// @inheritdoc IOracleV1
    function initOracleV1(
        address _river,
        address _administratorAddress,
        uint64 _epochsPerFrame,
        uint64 _slotsPerEpoch,
        uint64 _secondsPerSlot,
        uint64 _genesisTime,
        uint256 _annualAprUpperBound,
        uint256 _relativeLowerBound
    ) external init(0) {
        _setAdmin(_administratorAddress);
        RiverAddress.set(_river);
        emit SetRiver(_river);
        CLSpec.set(
            CLSpec.CLSpecStruct({
                epochsPerFrame: _epochsPerFrame,
                slotsPerEpoch: _slotsPerEpoch,
                secondsPerSlot: _secondsPerSlot,
                genesisTime: _genesisTime
            })
        );
        emit SetSpec(_epochsPerFrame, _slotsPerEpoch, _secondsPerSlot, _genesisTime);
        ReportBounds.set(
            ReportBounds.ReportBoundsStruct({
                annualAprUpperBound: _annualAprUpperBound,
                relativeLowerBound: _relativeLowerBound
            })
        );
        emit SetBounds(_annualAprUpperBound, _relativeLowerBound);
        Quorum.set(0);
        emit SetQuorum(0);
    }

    /// @inheritdoc IOracleV1
    function getRiver() external view returns (address) {
        return RiverAddress.get();
    }

    /// @inheritdoc IOracleV1
    function getTime() external view returns (uint256) {
        return _getTime();
    }

    /// @inheritdoc IOracleV1
    function getExpectedEpochId() external view returns (uint256) {
        return ExpectedEpochId.get();
    }

    /// @inheritdoc IOracleV1
    function getMemberReportStatus(address _oracleMember) external view returns (bool) {
        int256 memberIndex = OracleMembers.indexOf(_oracleMember);
        return memberIndex != -1 && ReportsPositions.get(uint256(memberIndex));
    }

    /// @inheritdoc IOracleV1
    function getGlobalReportStatus() external view returns (uint256) {
        return ReportsPositions.getRaw();
    }

    /// @inheritdoc IOracleV1
    function getReportVariantsCount() external view returns (uint256) {
        return ReportsVariants.get().length;
    }

    /// @inheritdoc IOracleV1
    function getReportVariant(uint256 _idx)
        external
        view
        returns (uint64 _clBalance, uint32 _clValidators, uint16 _reportCount)
    {
        uint256 report = ReportsVariants.get()[_idx];
        (_clBalance, _clValidators) = _decodeReport(report);
        _reportCount = _getReportCount(report);
    }

    /// @inheritdoc IOracleV1
    function getLastCompletedEpochId() external view returns (uint256) {
        return LastEpochId.get();
    }

    /// @inheritdoc IOracleV1
    function getCurrentEpochId() external view returns (uint256) {
        CLSpec.CLSpecStruct memory clSpec = CLSpec.get();
        return _getCurrentEpochId(clSpec);
    }

    /// @inheritdoc IOracleV1
    function getQuorum() external view returns (uint256) {
        return Quorum.get();
    }

    /// @inheritdoc IOracleV1
    function getCLSpec() external view returns (CLSpec.CLSpecStruct memory) {
        return CLSpec.get();
    }

    /// @inheritdoc IOracleV1
    function getCurrentFrame() external view returns (uint256 _startEpochId, uint256 _startTime, uint256 _endTime) {
        CLSpec.CLSpecStruct memory clSpec = CLSpec.get();
        _startEpochId = _getFrameFirstEpochId(_getCurrentEpochId(clSpec), clSpec);
        uint256 secondsPerEpoch = clSpec.secondsPerSlot * clSpec.slotsPerEpoch;
        _startTime = clSpec.genesisTime + _startEpochId * secondsPerEpoch;
        _endTime = _startTime + secondsPerEpoch * clSpec.epochsPerFrame - 1;
    }

    /// @inheritdoc IOracleV1
    function getFrameFirstEpochId(uint256 _epochId) external view returns (uint256) {
        CLSpec.CLSpecStruct memory clSpec = CLSpec.get();
        return _getFrameFirstEpochId(_epochId, clSpec);
    }

    /// @inheritdoc IOracleV1
    function getReportBounds() external view returns (ReportBounds.ReportBoundsStruct memory) {
        return ReportBounds.get();
    }

    /// @inheritdoc IOracleV1
    function getOracleMembers() external view returns (address[] memory) {
        return OracleMembers.get();
    }

    /// @inheritdoc IOracleV1
    function isMember(address _memberAddress) external view returns (bool) {
        return OracleMembers.indexOf(_memberAddress) >= 0;
    }

    /// @inheritdoc IOracleV1
    function addMember(address _newOracleMember, uint256 _newQuorum) external onlyAdmin {
        int256 memberIdx = OracleMembers.indexOf(_newOracleMember);
        if (memberIdx >= 0) {
            revert AddressAlreadyInUse(_newOracleMember);
        }
        OracleMembers.push(_newOracleMember);
        uint256 previousQuorum = Quorum.get();
        _clearReportsAndSetQuorum(_newQuorum, previousQuorum);
        emit AddMember(_newOracleMember);
    }

    /// @inheritdoc IOracleV1
    function removeMember(address _oracleMember, uint256 _newQuorum) external onlyAdmin {
        int256 memberIdx = OracleMembers.indexOf(_oracleMember);
        if (memberIdx < 0) {
            revert LibErrors.InvalidCall();
        }
        OracleMembers.deleteItem(uint256(memberIdx));
        uint256 previousQuorum = Quorum.get();
        _clearReportsAndSetQuorum(_newQuorum, previousQuorum);
        emit RemoveMember(_oracleMember);
    }

    /// @inheritdoc IOracleV1
    function setMember(address _oracleMember, address _newAddress) external onlyAdmin {
        LibSanitize._notZeroAddress(_newAddress);
        if (OracleMembers.indexOf(_newAddress) >= 0) {
            revert AddressAlreadyInUse(_newAddress);
        }
        int256 memberIdx = OracleMembers.indexOf(_oracleMember);
        if (memberIdx < 0) {
            revert LibErrors.InvalidCall();
        }
        OracleMembers.set(uint256(memberIdx), _newAddress);
        emit SetMember(_oracleMember, _newAddress);
        _clearReports();
    }

    /// @inheritdoc IOracleV1
    function setCLSpec(uint64 _epochsPerFrame, uint64 _slotsPerEpoch, uint64 _secondsPerSlot, uint64 _genesisTime)
        external
        onlyAdmin
    {
        CLSpec.set(
            CLSpec.CLSpecStruct({
                epochsPerFrame: _epochsPerFrame,
                slotsPerEpoch: _slotsPerEpoch,
                secondsPerSlot: _secondsPerSlot,
                genesisTime: _genesisTime
            })
        );
        emit SetSpec(_epochsPerFrame, _slotsPerEpoch, _secondsPerSlot, _genesisTime);
    }

    /// @inheritdoc IOracleV1
    function setReportBounds(uint256 _annualAprUpperBound, uint256 _relativeLowerBound) external onlyAdmin {
        ReportBounds.set(
            ReportBounds.ReportBoundsStruct({
                annualAprUpperBound: _annualAprUpperBound,
                relativeLowerBound: _relativeLowerBound
            })
        );
        emit SetBounds(_annualAprUpperBound, _relativeLowerBound);
    }

    /// @inheritdoc IOracleV1
    function setQuorum(uint256 _newQuorum) external onlyAdmin {
        uint256 previousQuorum = Quorum.get();
        if (previousQuorum == _newQuorum) {
            revert LibErrors.InvalidArgument();
        }
        _clearReportsAndSetQuorum(_newQuorum, previousQuorum);
    }

    /// @inheritdoc IOracleV1
    function reportConsensusLayerData(uint256 _epochId, uint64 _clValidatorsBalance, uint32 _clValidatorCount)
        external
    {
        int256 memberIndex = OracleMembers.indexOf(msg.sender);
        if (memberIndex == -1) {
            revert LibErrors.Unauthorized(msg.sender);
        }

        CLSpec.CLSpecStruct memory clSpec = CLSpec.get();
        uint256 expectedEpochId = ExpectedEpochId.get();
        if (_epochId < expectedEpochId) {
            revert EpochTooOld(_epochId, expectedEpochId);
        }

        if (_epochId > expectedEpochId) {
            uint256 frameFirstEpochId = _getFrameFirstEpochId(_getCurrentEpochId(clSpec), clSpec);
            if (_epochId != frameFirstEpochId) {
                revert NotFrameFirstEpochId(_epochId, frameFirstEpochId);
            }
            _clearReportsAndUpdateExpectedEpochId(_epochId);
        }

        if (ReportsPositions.get(uint256(memberIndex))) {
            revert AlreadyReported(_epochId, msg.sender);
        }
        ReportsPositions.register(uint256(memberIndex));

        uint128 clBalanceEth1 = DENOMINATION_OFFSET * uint128(_clValidatorsBalance);
        emit CLReported(_epochId, clBalanceEth1, _clValidatorCount, msg.sender);

        uint256 report = _encodeReport(_clValidatorsBalance, _clValidatorCount);
        int256 reportIndex = ReportsVariants.indexOfReport(report);
        uint256 quorum = Quorum.get();

        if (reportIndex >= 0) {
            uint256 registeredReport = ReportsVariants.get()[uint256(reportIndex)];
            if (_getReportCount(registeredReport) + 1 >= quorum) {
                _pushToRiver(_epochId, clBalanceEth1, _clValidatorCount, clSpec);
            } else {
                ReportsVariants.set(uint256(reportIndex), registeredReport + 1);
            }
        } else {
            if (quorum == 1) {
                _pushToRiver(_epochId, clBalanceEth1, _clValidatorCount, clSpec);
            } else {
                ReportsVariants.push(report + 1);
            }
        }
    }

    /// @notice Internal utility to clear all the reports and edit the quorum if a new value is provided
    /// @dev Ensures that the quorum respects invariants
    /// @dev The admin is in charge of providing a proper quorum based on the oracle member count
    /// @dev The quorum value Q should respect the following invariant, where O is oracle member count
    /// @dev (O / 2) + 1 <= Q <= O
    /// @param _newQuorum New quorum value
    /// @param _previousQuorum The old quorum value
    function _clearReportsAndSetQuorum(uint256 _newQuorum, uint256 _previousQuorum) internal {
        uint256 memberCount = OracleMembers.get().length;
        if ((_newQuorum == 0 && memberCount > 0) || _newQuorum > memberCount) {
            revert LibErrors.InvalidArgument();
        }
        _clearReports();
        if (_newQuorum != _previousQuorum) {
            Quorum.set(_newQuorum);
            emit SetQuorum(_newQuorum);
        }
    }

    /// @notice Retrieve the block timestamp
    /// @return The block timestamp
    function _getTime() internal view returns (uint256) {
        return block.timestamp; // solhint-disable-line not-rely-on-time
    }

    /// @notice Retrieve the current epoch id based on block timestamp
    /// @param _clSpec CL spec parameters
    /// @return The current epoch id
    function _getCurrentEpochId(CLSpec.CLSpecStruct memory _clSpec) internal view returns (uint256) {
        return (_getTime() - _clSpec.genesisTime) / (_clSpec.slotsPerEpoch * _clSpec.secondsPerSlot);
    }

    /// @notice Retrieve the first epoch id of the frame of the provided epoch id
    /// @param _epochId Epoch id used to get the frame
    /// @param _clSpec CL spec parameters
    /// @return The epoch id at the beginning of the frame
    function _getFrameFirstEpochId(uint256 _epochId, CLSpec.CLSpecStruct memory _clSpec)
        internal
        pure
        returns (uint256)
    {
        return (_epochId / _clSpec.epochsPerFrame) * _clSpec.epochsPerFrame;
    }

    /// @notice Clear reporting data
    /// @param _epochId Next expected epoch id (first epoch of the next frame)
    function _clearReportsAndUpdateExpectedEpochId(uint256 _epochId) internal {
        _clearReports();
        ExpectedEpochId.set(_epochId);
        emit ExpectedEpochIdUpdated(_epochId);
    }

    /// @notice Internal utility to clear the reporting data
    function _clearReports() internal {
        ReportsPositions.clear();
        ReportsVariants.clear();
    }

    /// @notice Encode report into one slot. Last 16 bits are free to use for vote counting.
    /// @param _clBalance Total validator balance
    /// @param _clValidators Total validator count
    /// @return The encoded report value
    function _encodeReport(uint64 _clBalance, uint32 _clValidators) internal pure returns (uint256) {
        return (uint256(_clBalance) << 48) | (uint256(_clValidators) << 16);
    }

    /// @notice Decode report from one slot to two variables, ignoring the last 16 bits
    /// @param _value Encoded report
    function _decodeReport(uint256 _value) internal pure returns (uint64 _clBalance, uint32 _clValidators) {
        _clBalance = uint64(_value >> 48);
        _clValidators = uint32(_value >> 16);
    }

    /// @notice Retrieve the vote count from the encoded report (last 16 bits)
    /// @param _report Encoded report
    /// @return The report count
    function _getReportCount(uint256 _report) internal pure returns (uint16) {
        return uint16(_report);
    }

    /// @notice Compute the max allowed increase based on the previous total balance and the time elapsed
    /// @param _prevTotalEth The previous total balance
    /// @param _timeElapsed The time since last report
    /// @return The maximum increase in balance allowed
    function _maxIncrease(uint256 _prevTotalEth, uint256 _timeElapsed) internal view returns (uint256) {
        uint256 annualAprUpperBound = ReportBounds.get().annualAprUpperBound;
        return (_prevTotalEth * annualAprUpperBound * _timeElapsed) / (LibBasisPoints.BASIS_POINTS_MAX * ONE_YEAR);
    }

    /// @notice Performs sanity checks to prevent an erroneous update to the River system
    /// @param _postTotalEth Total validator balance after update
    /// @param _prevTotalEth Total validator balance before update
    /// @param _timeElapsed Time since last update
    function _sanityChecks(uint256 _postTotalEth, uint256 _prevTotalEth, uint256 _timeElapsed) internal view {
        if (_postTotalEth >= _prevTotalEth) {
            // increase                 = _postTotalPooledEther - _preTotalPooledEther,
            // relativeIncrease         = increase / _preTotalPooledEther,
            // annualRelativeIncrease   = relativeIncrease / (timeElapsed / 365 days),
            // annualRelativeIncreaseBp = annualRelativeIncrease * 10000, in basis points 0.01% (1e-4)
            uint256 annualAprUpperBound = ReportBounds.get().annualAprUpperBound;
            // check that annualRelativeIncreaseBp <= allowedAnnualRelativeIncreaseBp
            if (
                LibBasisPoints.BASIS_POINTS_MAX * ONE_YEAR * (_postTotalEth - _prevTotalEth)
                    > annualAprUpperBound * _prevTotalEth * _timeElapsed
            ) {
                revert TotalValidatorBalanceIncreaseOutOfBound(
                    _prevTotalEth, _postTotalEth, _timeElapsed, annualAprUpperBound
                );
            }
        } else {
            // decrease           = _preTotalPooledEther - _postTotalPooledEther
            // relativeDecrease   = decrease / _preTotalPooledEther
            // relativeDecreaseBp = relativeDecrease * 10000, in basis points 0.01% (1e-4)
            uint256 relativeLowerBound = ReportBounds.get().relativeLowerBound;
            // check that relativeDecreaseBp <= allowedRelativeDecreaseBp
            if (LibBasisPoints.BASIS_POINTS_MAX * (_prevTotalEth - _postTotalEth) > relativeLowerBound * _prevTotalEth)
            {
                revert TotalValidatorBalanceDecreaseOutOfBound(
                    _prevTotalEth, _postTotalEth, _timeElapsed, relativeLowerBound
                );
            }
        }
    }

    /// @notice Push the new cl data to the river system and performs sanity checks
    /// @dev At this point, the maximum increase allowed to the previous total asset balance is computed and
    /// @dev provided to River. It's then up to River to manage how extra funds are injected in the system
    /// @dev and make sure the limit is not crossed. If the _totalBalance is already crossing this limit,
    /// @dev then there is nothing River can do to prevent it.
    /// @dev These extra funds are:
    /// @dev - the execution layer fees
    /// @param _epochId Id of the epoch
    /// @param _totalBalance Total validator balance
    /// @param _validatorCount Total validator count
    /// @param _clSpec CL spec parameters
    function _pushToRiver(
        uint256 _epochId,
        uint128 _totalBalance,
        uint32 _validatorCount,
        CLSpec.CLSpecStruct memory _clSpec
    ) internal {
        _clearReportsAndUpdateExpectedEpochId(_epochId + _clSpec.epochsPerFrame);

        IRiverV1 river = IRiverV1(payable(RiverAddress.get()));
        uint256 prevTotalEth = river.totalUnderlyingSupply();
        uint256 timeElapsed = (_epochId - LastEpochId.get()) * _clSpec.slotsPerEpoch * _clSpec.secondsPerSlot;
        uint256 maxIncrease = _maxIncrease(prevTotalEth, timeElapsed);
        river.setConsensusLayerData(_validatorCount, _totalBalance, bytes32(_epochId), maxIncrease);
        uint256 postTotalEth = river.totalUnderlyingSupply();

        _sanityChecks(postTotalEth, prevTotalEth, timeElapsed);
        LastEpochId.set(_epochId);

        emit PostTotalShares(postTotalEth, prevTotalEth, timeElapsed, river.totalSupply());
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/// @title Administrable Interface
/// @author Kiln
/// @notice This interface exposes methods to handle the ownership of the contracts
interface IAdministrable {
    /// @notice The pending admin address changed
    /// @param pendingAdmin New pending admin address
    event SetPendingAdmin(address indexed pendingAdmin);

    /// @notice The admin address changed
    /// @param admin New admin address
    event SetAdmin(address indexed admin);

    /// @notice Retrieves the current admin address
    /// @return The admin address
    function getAdmin() external view returns (address);

    /// @notice Retrieve the current pending admin address
    /// @return The pending admin address
    function getPendingAdmin() external view returns (address);

    /// @notice Proposes a new address as admin
    /// @dev This security prevents setting an invalid address as an admin. The pending
    /// @dev admin has to claim its ownership of the contract, and prove that the new
    /// @dev address is able to perform regular transactions.
    /// @param _newAdmin New admin address
    function proposeAdmin(address _newAdmin) external;

    /// @notice Accept the transfer of ownership
    /// @dev Only callable by the pending admin. Resets the pending admin if succesful.
    function acceptAdmin() external;
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../state/oracle/CLSpec.sol";
import "../state/oracle/ReportBounds.sol";

/// @title Oracle Interface (v1)
/// @author Kiln
/// @notice This interface exposes methods to handle the input from the allowed oracle members.
/// @notice Highly inspired by Lido's implementation.
interface IOracleV1 {
    /// @notice Consensus Layer data has been reported by an oracle member
    /// @param epochId The epoch of the report
    /// @param newCLBalance The new consensus layer balance
    /// @param newCLValidatorCount The new consensus layer validator count
    /// @param oracleMember The oracle member that reported
    event CLReported(uint256 epochId, uint128 newCLBalance, uint32 newCLValidatorCount, address oracleMember);

    /// @notice The storage quorum value has been changed
    /// @param newQuorum The new quorum value
    event SetQuorum(uint256 newQuorum);

    /// @notice The expected epoch id has been changed
    /// @param epochId The new expected epoch id
    event ExpectedEpochIdUpdated(uint256 epochId);

    /// @notice The report has been submitted to river
    /// @param postTotalEth The new total ETH balance
    /// @param prevTotalEth The previous total ETH balance
    /// @param timeElapsed Time since last report
    /// @param totalShares The new total amount of shares
    event PostTotalShares(uint256 postTotalEth, uint256 prevTotalEth, uint256 timeElapsed, uint256 totalShares);

    /// @notice A member has been added to the oracle member list
    /// @param member The address of the member
    event AddMember(address indexed member);

    /// @notice A member has been removed from the oracle member list
    /// @param member The address of the member
    event RemoveMember(address indexed member);

    /// @notice A member address has been edited
    /// @param oldAddress The previous member address
    /// @param newAddress The new member address
    event SetMember(address indexed oldAddress, address indexed newAddress);

    /// @notice The storage river address value has been changed
    /// @param _river The new river address
    event SetRiver(address _river);

    /// @notice The consensus layer spec has been changed
    /// @param epochsPerFrame The number of epochs inside a frame (225 = 24 hours)
    /// @param slotsPerEpoch The number of slots inside an epoch (32 on ethereum mainnet)
    /// @param secondsPerSlot The time between two slots (12 seconds on ethereum mainnet)
    /// @param genesisTime The timestamp of block #0
    event SetSpec(uint64 epochsPerFrame, uint64 slotsPerEpoch, uint64 secondsPerSlot, uint64 genesisTime);

    /// @notice The report bounds have been changed
    /// @param annualAprUpperBound The maximum allowed apr. 10% means increases in balance extrapolated to a year should not exceed 10%.
    /// @param relativeLowerBound The maximum allowed balance decrease as a relative % of the total balance
    event SetBounds(uint256 annualAprUpperBound, uint256 relativeLowerBound);

    /// @notice The provided epoch is too old compared to the expected epoch id
    /// @param providedEpochId The epoch id provided as input
    /// @param minExpectedEpochId The minimum epoch id expected
    error EpochTooOld(uint256 providedEpochId, uint256 minExpectedEpochId);

    /// @notice The provided epoch is not at the beginning of its frame
    /// @param providedEpochId The epoch id provided as input
    /// @param expectedFrameFirstEpochId The frame first epoch id that was expected
    error NotFrameFirstEpochId(uint256 providedEpochId, uint256 expectedFrameFirstEpochId);

    /// @notice The member already reported on the given epoch id
    /// @param epochId The epoch id provided as input
    /// @param member The oracle member
    error AlreadyReported(uint256 epochId, address member);

    /// @notice The delta in balance is above the allowed upper bound
    /// @param prevTotalEth The previous total balance
    /// @param postTotalEth The new total balance
    /// @param timeElapsed The time since last report
    /// @param annualAprUpperBound The maximum apr allowed
    error TotalValidatorBalanceIncreaseOutOfBound(
        uint256 prevTotalEth, uint256 postTotalEth, uint256 timeElapsed, uint256 annualAprUpperBound
    );

    /// @notice The negative delta in balance is above the allowed lower bound
    /// @param prevTotalEth The previous total balance
    /// @param postTotalEth The new total balance
    /// @param timeElapsed The time since last report
    /// @param relativeLowerBound The maximum relative decrease allowed
    error TotalValidatorBalanceDecreaseOutOfBound(
        uint256 prevTotalEth, uint256 postTotalEth, uint256 timeElapsed, uint256 relativeLowerBound
    );

    /// @notice The address is already in use by an oracle member
    /// @param newAddress The address already in use
    error AddressAlreadyInUse(address newAddress);

    /// @notice Initializes the oracle
    /// @param _river Address of the River contract, able to receive oracle input data after quorum is met
    /// @param _administratorAddress Address able to call administrative methods
    /// @param _epochsPerFrame CL spec parameter. Number of epochs in a frame.
    /// @param _slotsPerEpoch CL spec parameter. Number of slots in one epoch.
    /// @param _secondsPerSlot CL spec parameter. Number of seconds between slots.
    /// @param _genesisTime CL spec parameter. Timestamp of the genesis slot.
    /// @param _annualAprUpperBound CL bound parameter. Maximum apr allowed for balance increase. Delta between updates is extrapolated on a year time frame.
    /// @param _relativeLowerBound CL bound parameter. Maximum relative balance decrease.
    function initOracleV1(
        address _river,
        address _administratorAddress,
        uint64 _epochsPerFrame,
        uint64 _slotsPerEpoch,
        uint64 _secondsPerSlot,
        uint64 _genesisTime,
        uint256 _annualAprUpperBound,
        uint256 _relativeLowerBound
    ) external;

    /// @notice Retrieve River address
    /// @return The address of River
    function getRiver() external view returns (address);

    /// @notice Retrieve the block timestamp
    /// @return The current timestamp from the EVM context
    function getTime() external view returns (uint256);

    /// @notice Retrieve expected epoch id
    /// @return The current expected epoch id
    function getExpectedEpochId() external view returns (uint256);

    /// @notice Retrieve member report status
    /// @param _oracleMember Address of member to check
    /// @return True if member has reported
    function getMemberReportStatus(address _oracleMember) external view returns (bool);

    /// @notice Retrieve member report status
    /// @return The raw report status value
    function getGlobalReportStatus() external view returns (uint256);

    /// @notice Retrieve report variants count
    /// @return The count of report variants
    function getReportVariantsCount() external view returns (uint256);

    /// @notice Retrieve decoded report at provided index
    /// @param _idx Index of report
    /// @return _clBalance The reported consensus layer balance sum of River's validators
    /// @return _clValidators The reported validator count
    /// @return _reportCount The number of similar reports
    function getReportVariant(uint256 _idx)
        external
        view
        returns (uint64 _clBalance, uint32 _clValidators, uint16 _reportCount);

    /// @notice Retrieve the last completed epoch id
    /// @return The last completed epoch id
    function getLastCompletedEpochId() external view returns (uint256);

    /// @notice Retrieve the current epoch id based on block timestamp
    /// @return The current epoch id
    function getCurrentEpochId() external view returns (uint256);

    /// @notice Retrieve the current quorum
    /// @return The current quorum
    function getQuorum() external view returns (uint256);

    /// @notice Retrieve the current cl spec
    /// @return The Consensus Layer Specification
    function getCLSpec() external view returns (CLSpec.CLSpecStruct memory);

    /// @notice Retrieve the current frame details
    /// @return _startEpochId The epoch at the beginning of the frame
    /// @return _startTime The timestamp of the beginning of the frame in seconds
    /// @return _endTime The timestamp of the end of the frame in seconds
    function getCurrentFrame() external view returns (uint256 _startEpochId, uint256 _startTime, uint256 _endTime);

    /// @notice Retrieve the first epoch id of the frame of the provided epoch id
    /// @param _epochId Epoch id used to get the frame
    /// @return The first epoch id of the frame containing the given epoch id
    function getFrameFirstEpochId(uint256 _epochId) external view returns (uint256);

    /// @notice Retrieve the report bounds
    /// @return The report bounds
    function getReportBounds() external view returns (ReportBounds.ReportBoundsStruct memory);

    /// @notice Retrieve the list of oracle members
    /// @return The oracle members
    function getOracleMembers() external view returns (address[] memory);

    /// @notice Returns true if address is member
    /// @dev Performs a naive search, do not call this on-chain, used as an off-chain helper
    /// @param _memberAddress Address of the member
    /// @return True if address is a member
    function isMember(address _memberAddress) external view returns (bool);

    /// @notice Adds new address as oracle member, giving the ability to push cl reports.
    /// @dev Only callable by the adminstrator
    /// @dev Modifying the quorum clears all the reporting data
    /// @param _newOracleMember Address of the new member
    /// @param _newQuorum New quorum value
    function addMember(address _newOracleMember, uint256 _newQuorum) external;

    /// @notice Removes an address from the oracle members.
    /// @dev Only callable by the adminstrator
    /// @dev Modifying the quorum clears all the reporting data
    /// @dev Remaining members that have already voted should vote again for the same frame.
    /// @param _oracleMember Address to remove
    /// @param _newQuorum New quorum value
    function removeMember(address _oracleMember, uint256 _newQuorum) external;

    /// @notice Changes the address of an oracle member
    /// @dev Only callable by the adminitrator
    /// @dev Cannot use an address already in use
    /// @dev This call will clear all the reporting data
    /// @param _oracleMember Address to change
    /// @param _newAddress New address for the member
    function setMember(address _oracleMember, address _newAddress) external;

    /// @notice Edits the cl spec parameters
    /// @dev Only callable by the adminstrator
    /// @param _epochsPerFrame Number of epochs in a frame.
    /// @param _slotsPerEpoch Number of slots in one epoch.
    /// @param _secondsPerSlot Number of seconds between slots.
    /// @param _genesisTime Timestamp of the genesis slot.
    function setCLSpec(uint64 _epochsPerFrame, uint64 _slotsPerEpoch, uint64 _secondsPerSlot, uint64 _genesisTime)
        external;

    /// @notice Edits the cl bounds parameters
    /// @dev Only callable by the adminstrator
    /// @param _annualAprUpperBound Maximum apr allowed for balance increase. Delta between updates is extrapolated on a year time frame.
    /// @param _relativeLowerBound Maximum relative balance decrease.
    function setReportBounds(uint256 _annualAprUpperBound, uint256 _relativeLowerBound) external;

    /// @notice Edits the quorum required to forward cl data to River
    /// @dev Modifying the quorum clears all the reporting data
    /// @param _newQuorum New quorum parameter
    function setQuorum(uint256 _newQuorum) external;

    /// @notice Report cl chain data
    /// @dev Only callable by an oracle member
    /// @dev The epoch id is expected to be >= to the expected epoch id stored in the contract
    /// @dev The epoch id is expected to be the first epoch of its frame
    /// @dev The Consensus Layer Validator count is the amount of running validators managed by River.
    /// @dev Until withdrawals are enabled, this count also takes into account any exited and slashed validator
    /// @dev as funds are still locked on the consensus layer.
    /// @param _epochId Epoch where the balance and validator count has been computed
    /// @param _clValidatorsBalance Total balance of River validators
    /// @param _clValidatorCount Total River validator count
    function reportConsensusLayerData(uint256 _epochId, uint64 _clValidatorsBalance, uint32 _clValidatorCount)
        external;
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./components/IConsensusLayerDepositManager.1.sol";
import "./components/IOracleManager.1.sol";
import "./components/ISharesManager.1.sol";
import "./components/IUserDepositManager.1.sol";

/// @title River Interface (v1)
/// @author Kiln
/// @notice The main system interface
interface IRiverV1 is IConsensusLayerDepositManagerV1, IUserDepositManagerV1, ISharesManagerV1, IOracleManagerV1 {
    /// @notice Funds have been pulled from the Execution Layer Fee Recipient
    /// @param amount The amount pulled
    event PulledELFees(uint256 amount);

    /// @notice The stored Execution Layer Fee Recipient has been changed
    /// @param elFeeRecipient The new Execution Layer Fee Recipient
    event SetELFeeRecipient(address indexed elFeeRecipient);

    /// @notice The stored Collector has been changed
    /// @param collector The new Collector
    event SetCollector(address indexed collector);

    /// @notice The stored Allowlist has been changed
    /// @param allowlist The new Allowlist
    event SetAllowlist(address indexed allowlist);

    /// @notice The stored Global Fee has been changed
    /// @param fee The new Global Fee
    event SetGlobalFee(uint256 fee);

    /// @notice The stored Operators Registry has been changed
    /// @param operatorRegistry The new Operators Registry
    event SetOperatorsRegistry(address indexed operatorRegistry);

    /// @notice The system underlying supply increased. This is a snapshot of the balances for accounting purposes
    /// @param _collector The address of the collector during this event
    /// @param _oldTotalUnderlyingBalance Old total ETH balance under management by River
    /// @param _oldTotalSupply Old total supply in shares
    /// @param _newTotalUnderlyingBalance New total ETH balance under management by River
    /// @param _newTotalSupply New total supply in shares
    event RewardsEarned(
        address indexed _collector,
        uint256 _oldTotalUnderlyingBalance,
        uint256 _oldTotalSupply,
        uint256 _newTotalUnderlyingBalance,
        uint256 _newTotalSupply
    );

    /// @notice The computed amount of shares to mint is 0
    error ZeroMintedShares();

    /// @notice The access was denied
    /// @param account The account that was denied
    error Denied(address account);

    /// @notice Initializes the River system
    /// @param _depositContractAddress Address to make Consensus Layer deposits
    /// @param _elFeeRecipientAddress Address that receives the execution layer fees
    /// @param _withdrawalCredentials Credentials to use for every validator deposit
    /// @param _oracleAddress The address of the Oracle contract
    /// @param _systemAdministratorAddress Administrator address
    /// @param _allowlistAddress Address of the allowlist contract
    /// @param _operatorRegistryAddress Address of the operator registry
    /// @param _collectorAddress Address receiving the the global fee on revenue
    /// @param _globalFee Amount retained when the ETH balance increases and sent to the collector
    function initRiverV1(
        address _depositContractAddress,
        address _elFeeRecipientAddress,
        bytes32 _withdrawalCredentials,
        address _oracleAddress,
        address _systemAdministratorAddress,
        address _allowlistAddress,
        address _operatorRegistryAddress,
        address _collectorAddress,
        uint256 _globalFee
    ) external;

    /// @notice Get the current global fee
    /// @return The global fee
    function getGlobalFee() external view returns (uint256);

    /// @notice Retrieve the allowlist address
    /// @return The allowlist address
    function getAllowlist() external view returns (address);

    /// @notice Retrieve the collector address
    /// @return The collector address
    function getCollector() external view returns (address);

    /// @notice Retrieve the execution layer fee recipient
    /// @return The execution layer fee recipient address
    function getELFeeRecipient() external view returns (address);

    /// @notice Retrieve the operators registry
    /// @return The operators registry address
    function getOperatorsRegistry() external view returns (address);

    /// @notice Changes the global fee parameter
    /// @param newFee New fee value
    function setGlobalFee(uint256 newFee) external;

    /// @notice Changes the allowlist address
    /// @param _newAllowlist New address for the allowlist
    function setAllowlist(address _newAllowlist) external;

    /// @notice Changes the collector address
    /// @param _newCollector New address for the collector
    function setCollector(address _newCollector) external;

    /// @notice Changes the execution layer fee recipient
    /// @param _newELFeeRecipient New address for the recipient
    function setELFeeRecipient(address _newELFeeRecipient) external;

    /// @notice Input for execution layer fee earnings
    function sendELFees() external payable;
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/// @title Consensys Layer Deposit Manager Interface (v1)
/// @author Kiln
/// @notice This interface exposes methods to handle the interactions with the official deposit contract
interface IConsensusLayerDepositManagerV1 {
    /// @notice A validator key got funded on the deposit contract
    /// @param publicKey BLS Public key that got funded
    event FundedValidatorKey(bytes publicKey);

    /// @notice The stored deposit contract address changed
    /// @param depositContract Address of the deposit contract
    event SetDepositContractAddress(address indexed depositContract);

    /// @notice The stored withdrawal credentials changed
    /// @param withdrawalCredentials The withdrawal credentials to use for deposits
    event SetWithdrawalCredentials(bytes32 withdrawalCredentials);

    /// @notice Not enough funds to deposit one validator
    error NotEnoughFunds();

    /// @notice The length of the BLS Public key is invalid during deposit
    error InconsistentPublicKeys();

    /// @notice The length of the BLS Signature is invalid during deposit
    error InconsistentSignatures();

    /// @notice The internal key retrieval returned no keys
    error NoAvailableValidatorKeys();

    /// @notice The received count of public keys to deposit is invalid
    error InvalidPublicKeyCount();

    /// @notice The received count of signatures to deposit is invalid
    error InvalidSignatureCount();

    /// @notice The withdrawal credentials value is null
    error InvalidWithdrawalCredentials();

    /// @notice An error occured during the deposit
    error ErrorOnDeposit();

    /// @notice Returns the amount of pending ETH
    /// @return The amount of pending ETH
    function getBalanceToDeposit() external view returns (uint256);

    /// @notice Retrieve the withdrawal credentials
    /// @return The withdrawal credentials
    function getWithdrawalCredentials() external view returns (bytes32);

    /// @notice Get the deposited validator count (the count of deposits made by the contract)
    /// @return The deposited validator count
    function getDepositedValidatorCount() external view returns (uint256);

    /// @notice Deposits current balance to the Consensus Layer by batches of 32 ETH
    /// @param _maxCount The maximum amount of validator keys to fund
    function depositToConsensusLayer(uint256 _maxCount) external;
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/// @title Oracle Manager (v1)
/// @author Kiln
/// @notice This interface exposes methods to handle the inputs provided by the oracle
interface IOracleManagerV1 {
    /// @notice The stored oracle address changed
    /// @param oracleAddress The new oracle address
    event SetOracle(address indexed oracleAddress);

    /// @notice The consensus layer data provided by the oracle has been updated
    /// @param validatorCount The new count of validators running on the consensus layer
    /// @param validatorTotalBalance The new total balance sum of all validators
    /// @param roundId Round identifier
    event ConsensusLayerDataUpdate(uint256 validatorCount, uint256 validatorTotalBalance, bytes32 roundId);

    /// @notice The reported validator count is invalid
    /// @param providedValidatorCount The received validator count value
    /// @param depositedValidatorCount The number of deposits performed by the system
    error InvalidValidatorCountReport(uint256 providedValidatorCount, uint256 depositedValidatorCount);

    /// @notice Get oracle address
    /// @return The oracle address
    function getOracle() external view returns (address);

    /// @notice Get CL validator total balance
    /// @return The CL Validator total balance
    function getCLValidatorTotalBalance() external view returns (uint256);

    /// @notice Get CL validator count (the amount of validator reported by the oracles)
    /// @return The CL validator count
    function getCLValidatorCount() external view returns (uint256);

    /// @notice Set the oracle address
    /// @param _oracleAddress Address of the oracle
    function setOracle(address _oracleAddress) external;

    /// @notice Sets the validator count and validator total balance sum reported by the oracle
    /// @dev Can only be called by the oracle address
    /// @dev The round id is a blackbox value that should only be used to identify unique reports
    /// @dev When a report is performed, River computes the amount of fees that can be pulled
    /// @dev from the execution layer fee recipient. This amount is capped by the max allowed
    /// @dev increase provided during the report.
    /// @dev If the total asset balance increases (from the reported total balance and the pulled funds)
    /// @dev we then compute the share that must be taken for the collector on the positive delta.
    /// @dev The execution layer fees are taken into account here because they are the product of
    /// @dev node operator's work, just like consensus layer fees, and both should be handled in the
    /// @dev same manner, as a single revenue stream for the users and the collector.
    /// @param _validatorCount The number of active validators on the consensus layer
    /// @param _validatorTotalBalance The balance sum of the active validators on the consensus layer
    /// @param _roundId An identifier for this update
    /// @param _maxIncrease The maximum allowed increase in the total balance
    function setConsensusLayerData(
        uint256 _validatorCount,
        uint256 _validatorTotalBalance,
        bytes32 _roundId,
        uint256 _maxIncrease
    ) external;
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/// @title Shares Manager Interface (v1)
/// @author Kiln
/// @notice This interface exposes methods to handle the shares of the depositor and the ERC20 interface
interface ISharesManagerV1 is IERC20 {
    /// @notice Balance too low to perform operation
    error BalanceTooLow();

    /// @notice Allowance too low to perform operation
    /// @param _from Account where funds are sent from
    /// @param _operator Account attempting the transfer
    /// @param _allowance Current allowance
    /// @param _value Requested transfer value in shares
    error AllowanceTooLow(address _from, address _operator, uint256 _allowance, uint256 _value);

    /// @notice Invalid empty transfer
    error NullTransfer();

    /// @notice Invalid transfer recipients
    /// @param _from Account sending the funds in the invalid transfer
    /// @param _to Account receiving the funds in the invalid transfer
    error UnauthorizedTransfer(address _from, address _to);

    /// @notice Retrieve the token name
    /// @return The token name
    function name() external pure returns (string memory);

    /// @notice Retrieve the token symbol
    /// @return The token symbol
    function symbol() external pure returns (string memory);

    /// @notice Retrieve the decimal count
    /// @return The decimal count
    function decimals() external pure returns (uint8);

    /// @notice Retrieve the total token supply
    /// @return The total supply in shares
    function totalSupply() external view returns (uint256);

    /// @notice Retrieve the total underlying asset supply
    /// @return The total underlying asset supply
    function totalUnderlyingSupply() external view returns (uint256);

    /// @notice Retrieve the balance of an account
    /// @param _owner Address to be checked
    /// @return The balance of the account in shares
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Retrieve the underlying asset balance of an account
    /// @param _owner Address to be checked
    /// @return The underlying balance of the account
    function balanceOfUnderlying(address _owner) external view returns (uint256);

    /// @notice Retrieve the underlying asset balance from an amount of shares
    /// @param _shares Amount of shares to convert
    /// @return The underlying asset balance represented by the shares
    function underlyingBalanceFromShares(uint256 _shares) external view returns (uint256);

    /// @notice Retrieve the shares count from an underlying asset amount
    /// @param _underlyingAssetAmount Amount of underlying asset to convert
    /// @return The amount of shares worth the underlying asset amopunt
    function sharesFromUnderlyingBalance(uint256 _underlyingAssetAmount) external view returns (uint256);

    /// @notice Retrieve the allowance value for a spender
    /// @param _owner Address that issued the allowance
    /// @param _spender Address that received the allowance
    /// @return The allowance in shares for a given spender
    function allowance(address _owner, address _spender) external view returns (uint256);

    /// @notice Performs a transfer from the message sender to the provided account
    /// @param _to Address receiving the tokens
    /// @param _value Amount of shares to be sent
    /// @return True if success
    function transfer(address _to, uint256 _value) external returns (bool);

    /// @notice Performs a transfer between two recipients
    /// @param _from Address sending the tokens
    /// @param _to Address receiving the tokens
    /// @param _value Amount of shares to be sent
    /// @return True if success
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);

    /// @notice Approves an account for future spendings
    /// @dev An approved account can use transferFrom to transfer funds on behalf of the token owner
    /// @param _spender Address that is allowed to spend the tokens
    /// @param _value The allowed amount in shares, will override previous value
    /// @return True if success
    function approve(address _spender, uint256 _value) external returns (bool);

    /// @notice Increase allowance to another account
    /// @param _spender Spender that receives the allowance
    /// @param _additionalValue Amount of shares to add
    /// @return True if success
    function increaseAllowance(address _spender, uint256 _additionalValue) external returns (bool);

    /// @notice Decrease allowance to another account
    /// @param _spender Spender that receives the allowance
    /// @param _subtractableValue Amount of shares to subtract
    /// @return True if success
    function decreaseAllowance(address _spender, uint256 _subtractableValue) external returns (bool);
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/// @title User Deposit Manager (v1)
/// @author Kiln
/// @notice This interface exposes methods to handle the inbound transfers cases or the explicit submissions
interface IUserDepositManagerV1 {
    /// @notice User deposited ETH in the system
    /// @param depositor Address performing the deposit
    /// @param recipient Address receiving the minted shares
    /// @param amount Amount in ETH deposited
    event UserDeposit(address indexed depositor, address indexed recipient, uint256 amount);

    /// @notice And empty deposit attempt was made
    error EmptyDeposit();

    /// @notice Explicit deposit method to mint on msg.sender
    function deposit() external payable;

    /// @notice Explicit deposit method to mint on msg.sender and transfer to _recipient
    /// @param _recipient Address receiving the minted LsETH
    function depositAndTransfer(address _recipient) external payable;

    /// @notice Implicit deposit method, when the user performs a regular transfer to the contract
    receive() external payable;

    /// @notice Invalid call, when the user sends a transaction with a data payload but no method matched
    fallback() external payable;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../state/shared/AdministratorAddress.sol";
import "../state/shared/PendingAdministratorAddress.sol";

/// @title Lib Administrable
/// @author Kiln
/// @notice This library handles the admin and pending admin storage vars
library LibAdministrable {
    /// @notice Retrieve the system admin
    /// @return The address of the system admin
    function _getAdmin() internal view returns (address) {
        return AdministratorAddress.get();
    }

    /// @notice Retrieve the pending system admin
    /// @return The adress of the pending system admin
    function _getPendingAdmin() internal view returns (address) {
        return PendingAdministratorAddress.get();
    }

    /// @notice Sets the system admin
    /// @param _admin New system admin
    function _setAdmin(address _admin) internal {
        AdministratorAddress.set(_admin);
    }

    /// @notice Sets the pending system admin
    /// @param _pendingAdmin New pending system admin
    function _setPendingAdmin(address _pendingAdmin) internal {
        PendingAdministratorAddress.set(_pendingAdmin);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/// @title Lib Basis Points
/// @notice Holds the basis points max value
library LibBasisPoints {
    /// @notice The max value for basis points (represents 100%)
    uint256 internal constant BASIS_POINTS_MAX = 10_000;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/// @title Lib Errors
/// @notice Library of common errors
library LibErrors {
    /// @notice The operator is unauthorized for the caller
    /// @param caller Address performing the call
    error Unauthorized(address caller);

    /// @notice The call was invalid
    error InvalidCall();

    /// @notice The argument was invalid
    error InvalidArgument();

    /// @notice The address is zero
    error InvalidZeroAddress();

    /// @notice The string is empty
    error InvalidEmptyString();

    /// @notice The fee is invalid
    error InvalidFee();
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./LibErrors.sol";
import "./LibBasisPoints.sol";

/// @title Lib Sanitize
/// @notice Utilities to sanitize input values
library LibSanitize {
    /// @notice Reverts if address is 0
    /// @param _address Address to check
    function _notZeroAddress(address _address) internal pure {
        if (_address == address(0)) {
            revert LibErrors.InvalidZeroAddress();
        }
    }

    /// @notice Reverts if string is empty
    /// @param _string String to check
    function _notEmptyString(string memory _string) internal pure {
        if (bytes(_string).length == 0) {
            revert LibErrors.InvalidEmptyString();
        }
    }

    /// @notice Reverts if fee is invalid
    /// @param _fee Fee to check
    function _validFee(uint256 _fee) internal pure {
        if (_fee > LibBasisPoints.BASIS_POINTS_MAX) {
            revert LibErrors.InvalidFee();
        }
    }
}

// SPDX-License-Identifier:    MIT

pragma solidity 0.8.10;

/// @title Lib Unstructured Storage
/// @notice Utilities to work with unstructured storage
library LibUnstructuredStorage {
    /// @notice Retrieve a bool value at a storage slot
    /// @param _position The storage slot to retrieve
    /// @return data The bool value
    function getStorageBool(bytes32 _position) internal view returns (bool data) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            data := sload(_position)
        }
    }

    /// @notice Retrieve an address value at a storage slot
    /// @param _position The storage slot to retrieve
    /// @return data The address value
    function getStorageAddress(bytes32 _position) internal view returns (address data) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            data := sload(_position)
        }
    }

    /// @notice Retrieve a bytes32 value at a storage slot
    /// @param _position The storage slot to retrieve
    /// @return data The bytes32 value
    function getStorageBytes32(bytes32 _position) internal view returns (bytes32 data) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            data := sload(_position)
        }
    }

    /// @notice Retrieve an uint256 value at a storage slot
    /// @param _position The storage slot to retrieve
    /// @return data The uint256 value
    function getStorageUint256(bytes32 _position) internal view returns (uint256 data) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            data := sload(_position)
        }
    }

    /// @notice Sets a bool value at a storage slot
    /// @param _position The storage slot to set
    /// @param _data The bool value to set
    function setStorageBool(bytes32 _position, bool _data) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(_position, _data)
        }
    }

    /// @notice Sets an address value at a storage slot
    /// @param _position The storage slot to set
    /// @param _data The address value to set
    function setStorageAddress(bytes32 _position, address _data) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(_position, _data)
        }
    }

    /// @notice Sets a bytes32 value at a storage slot
    /// @param _position The storage slot to set
    /// @param _data The bytes32 value to set
    function setStorageBytes32(bytes32 _position, bytes32 _data) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(_position, _data)
        }
    }

    /// @notice Sets an uint256 value at a storage slot
    /// @param _position The storage slot to set
    /// @param _data The uint256 value to set
    function setStorageUint256(bytes32 _position, uint256 _data) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(_position, _data)
        }
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/// @title Consensus Layer Spec Storage
/// @notice Utility to manage the Consensus Layer Spec in storage
library CLSpec {
    /// @notice Storage slot of the Consensus Layer Spec
    bytes32 internal constant CL_SPEC_SLOT = bytes32(uint256(keccak256("river.state.clSpec")) - 1);

    /// @notice The Consensus Layer Spec structure
    struct CLSpecStruct {
        /// @custom:attribute The count of epochs per frame, 225 means 24h
        uint64 epochsPerFrame;
        /// @custom:attribute The count of slots in an epoch (32 on mainnet)
        uint64 slotsPerEpoch;
        /// @custom:attribute The seconds in a slot (12 on mainnet)
        uint64 secondsPerSlot;
        /// @custom:attribute The block timestamp of the first consensus layer block
        uint64 genesisTime;
    }

    /// @notice The structure in storage
    struct Slot {
        /// @custom:attribute The structure in storage
        CLSpecStruct value;
    }

    /// @notice Retrieve the Consensus Layer Spec from storage
    /// @return The Consensus Layer Spec
    function get() internal view returns (CLSpecStruct memory) {
        bytes32 slot = CL_SPEC_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        return r.value;
    }

    /// @notice Set the Consensus Layer Spec value in storage
    /// @param _newCLSpec The new value to set in storage
    function set(CLSpecStruct memory _newCLSpec) internal {
        bytes32 slot = CL_SPEC_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        r.value = _newCLSpec;
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../libraries/LibUnstructuredStorage.sol";

/// @title Expected Epoch Id Storage
/// @notice Utility to manage the Expected Epoch Id in storage
library ExpectedEpochId {
    /// @notice Storage slot of the Expected Epoch Id
    bytes32 internal constant EXPECTED_EPOCH_ID_SLOT = bytes32(uint256(keccak256("river.state.expectedEpochId")) - 1);

    /// @notice Retrieve the Expected Epoch Id
    /// @return The Expected Epoch Id
    function get() internal view returns (uint256) {
        return LibUnstructuredStorage.getStorageUint256(EXPECTED_EPOCH_ID_SLOT);
    }

    /// @notice Sets the Expected Epoch Id
    /// @param _newValue New Expected Epoch Id
    function set(uint256 _newValue) internal {
        LibUnstructuredStorage.setStorageUint256(EXPECTED_EPOCH_ID_SLOT, _newValue);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../libraries/LibUnstructuredStorage.sol";

/// @title Last Epoch Id Storage
/// @notice Utility to manage the Last Epoch Id in storage
library LastEpochId {
    /// @notice Storage slot of the Last Epoch Id
    bytes32 internal constant LAST_EPOCH_ID_SLOT = bytes32(uint256(keccak256("river.state.lastEpochId")) - 1);

    /// @notice Retrieve the Last Epoch Id
    /// @return The Last Epoch Id
    function get() internal view returns (uint256) {
        return LibUnstructuredStorage.getStorageUint256(LAST_EPOCH_ID_SLOT);
    }

    /// @notice Sets the Last Epoch Id
    /// @param _newValue New Last Epoch Id
    function set(uint256 _newValue) internal {
        LibUnstructuredStorage.setStorageUint256(LAST_EPOCH_ID_SLOT, _newValue);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../libraries/LibSanitize.sol";

/// @title Oracle Members Storage
/// @notice Utility to manage the Oracle Members in storage
/// @dev There can only be up to 256 oracle members. This is due to how report statuses are stored in Reports Positions
library OracleMembers {
    /// @notice Storage slot of the Oracle Members
    bytes32 internal constant ORACLE_MEMBERS_SLOT = bytes32(uint256(keccak256("river.state.oracleMembers")) - 1);

    /// @notice The structure in storage
    struct Slot {
        /// @custom:attribute The array of oracle members
        address[] value;
    }

    /// @notice Retrieve the list of oracle members
    /// @return List of oracle members
    function get() internal view returns (address[] memory) {
        bytes32 slot = ORACLE_MEMBERS_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        return r.value;
    }

    /// @notice Add a new oracle member to the list
    /// @param _newOracleMember Address of the new oracle member
    function push(address _newOracleMember) internal {
        LibSanitize._notZeroAddress(_newOracleMember);

        bytes32 slot = ORACLE_MEMBERS_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        r.value.push(_newOracleMember);
    }

    /// @notice Set an address in the oracle member list
    /// @param _index The index to edit
    /// @param _newOracleAddress The new value of the oracle member
    function set(uint256 _index, address _newOracleAddress) internal {
        bytes32 slot = ORACLE_MEMBERS_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        r.value[_index] = _newOracleAddress;
    }

    /// @notice Retrieve the index of the oracle member
    /// @param _memberAddress The address to lookup
    /// @return The index of the member, -1 if not found
    function indexOf(address _memberAddress) internal view returns (int256) {
        bytes32 slot = ORACLE_MEMBERS_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        for (uint256 idx = 0; idx < r.value.length;) {
            if (r.value[idx] == _memberAddress) {
                return int256(idx);
            }
            unchecked {
                ++idx;
            }
        }

        return int256(-1);
    }

    /// @notice Delete the oracle member at the given index
    /// @param _idx The index of the member to remove
    function deleteItem(uint256 _idx) internal {
        bytes32 slot = ORACLE_MEMBERS_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        uint256 lastIdx = r.value.length - 1;
        if (lastIdx != _idx) {
            r.value[_idx] = r.value[lastIdx];
        }

        r.value.pop();
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../libraries/LibUnstructuredStorage.sol";

/// @title Quorum Storage
/// @notice Utility to manage the Quorum in storage
library Quorum {
    /// @notice Storage slot of the Quorum
    bytes32 internal constant QUORUM_SLOT = bytes32(uint256(keccak256("river.state.quorum")) - 1);

    /// @notice Retrieve the Quorum
    /// @return The Quorum
    function get() internal view returns (uint256) {
        return LibUnstructuredStorage.getStorageUint256(QUORUM_SLOT);
    }

    /// @notice Sets the Quorum
    /// @param _newValue New Quorum
    function set(uint256 _newValue) internal {
        return LibUnstructuredStorage.setStorageUint256(QUORUM_SLOT, _newValue);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/// @title Report Bounds Storage
/// @notice Utility to manage the Report Bounds in storage
library ReportBounds {
    /// @notice Storage slot of the Report Bounds
    bytes32 internal constant REPORT_BOUNDS_SLOT = bytes32(uint256(keccak256("river.state.reportBounds")) - 1);

    /// @notice The Report Bounds structure
    struct ReportBoundsStruct {
        /// @custom:attribute The maximum allowed annual apr, checked before submitting a report to River
        uint256 annualAprUpperBound;
        /// @custom:attribute The maximum allowed balance decrease, also checked before submitting a report to River
        uint256 relativeLowerBound;
    }

    /// @notice The structure in storage
    struct Slot {
        /// @custom:attribute The structure in storage
        ReportBoundsStruct value;
    }

    /// @notice Retrieve the Report Bounds from storage
    /// @return The Report Bounds
    function get() internal view returns (ReportBoundsStruct memory) {
        bytes32 slot = REPORT_BOUNDS_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        return r.value;
    }

    /// @notice Set the Report Bounds in storage
    /// @param _newReportBounds The new Report Bounds value
    function set(ReportBoundsStruct memory _newReportBounds) internal {
        bytes32 slot = REPORT_BOUNDS_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        r.value = _newReportBounds;
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../libraries/LibUnstructuredStorage.sol";

/// @title Reports Positions Storage
/// @notice Utility to manage the Reports Positions in storage
/// @dev Each bit in the stored uint256 value tells if the member at a given index has reported
library ReportsPositions {
    /// @notice Storage slot of the Reports Positions
    bytes32 internal constant REPORTS_POSITIONS_SLOT = bytes32(uint256(keccak256("river.state.reportsPositions")) - 1);

    /// @notice Retrieve the Reports Positions at index
    /// @param _idx The index to retrieve
    /// @return True if already reported
    function get(uint256 _idx) internal view returns (bool) {
        uint256 mask = 1 << _idx;
        return LibUnstructuredStorage.getStorageUint256(REPORTS_POSITIONS_SLOT) & mask == mask;
    }

    /// @notice Retrieve the raw Reports Positions from storage
    /// @return Raw Reports Positions
    function getRaw() internal view returns (uint256) {
        return LibUnstructuredStorage.getStorageUint256(REPORTS_POSITIONS_SLOT);
    }

    /// @notice Register an index as reported
    /// @param _idx The index to register
    function register(uint256 _idx) internal {
        uint256 mask = 1 << _idx;
        return LibUnstructuredStorage.setStorageUint256(
            REPORTS_POSITIONS_SLOT, LibUnstructuredStorage.getStorageUint256(REPORTS_POSITIONS_SLOT) | mask
        );
    }

    /// @notice Clears all the report positions in storage
    function clear() internal {
        return LibUnstructuredStorage.setStorageUint256(REPORTS_POSITIONS_SLOT, 0);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/// @title Reports Variants Storage
/// @notice Utility to manage the Reports Variants in storage
library ReportsVariants {
    /// @notice Storage slot of the Reports Variants
    bytes32 internal constant REPORTS_VARIANTS_SLOT = bytes32(uint256(keccak256("river.state.reportsVariants")) - 1);

    /// @notice Mask used to extra the report values from the variant
    /// @notice This is the packing done inside the variant in storage
    /// @notice
    /// @notice [ 0,  16) : <voteCount>           oracle member's total vote count for the numbers below (uint16, 2 bytes)
    /// @notice [16,  48) : <beaconValidators>    total number of beacon validators (uint32, 4 bytes)
    /// @notice [48, 112) : <beaconBalance>       total balance of all the beacon validators (uint64, 6 bytes)
    /// @notice
    /// @notice So applying this mask, we can extra the voteCount out to perform comparisons on the report values
    /// @notice
    /// @notice xx...xx <beaconBalance> <beaconValidators> xxxx & COUNT_OUTMASK  ==
    /// @notice 00...00 <beaconBalance> <beaconValidators> 0000
    uint256 internal constant COUNT_OUTMASK = 0xFFFFFFFFFFFFFFFFFFFFFFFF0000;

    /// @notice Structure in storage
    struct Slot {
        /// @custom:attribute The list of variants
        uint256[] value;
    }

    /// @notice Retrieve the Reports Variants from storage
    /// @return The Reports Variants
    function get() internal view returns (uint256[] memory) {
        bytes32 slot = REPORTS_VARIANTS_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        return r.value;
    }

    /// @notice Set the Reports Variants value at index
    /// @param _idx The index to set
    /// @param _val The value to set
    function set(uint256 _idx, uint256 _val) internal {
        bytes32 slot = REPORTS_VARIANTS_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        r.value[_idx] = _val;
    }

    /// @notice Add a new variant in the list
    /// @param _variant The new variant to add
    function push(uint256 _variant) internal {
        bytes32 slot = REPORTS_VARIANTS_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        r.value.push(_variant);
    }

    /// @notice Retrieve the index of a specific variant, ignoring the count field
    /// @param _variant Variant value to lookup
    /// @return The index of the variant, -1 if not found
    function indexOfReport(uint256 _variant) internal view returns (int256) {
        bytes32 slot = REPORTS_VARIANTS_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        for (uint256 idx = 0; idx < r.value.length;) {
            if (r.value[idx] & COUNT_OUTMASK == _variant) {
                return int256(idx);
            }
            unchecked {
                ++idx;
            }
        }

        return int256(-1);
    }

    /// @notice Clear all variants from storage
    function clear() internal {
        bytes32 slot = REPORTS_VARIANTS_SLOT;

        Slot storage r;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }

        delete r.value;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../../libraries/LibUnstructuredStorage.sol";
import "../../libraries/LibSanitize.sol";

/// @title Administrator Address Storage
/// @notice Utility to manage the Administrator Address in storage
library AdministratorAddress {
    /// @notice Storage slot of the Administrator Address
    bytes32 public constant ADMINISTRATOR_ADDRESS_SLOT =
        bytes32(uint256(keccak256("river.state.administratorAddress")) - 1);

    /// @notice Retrieve the Administrator Address
    /// @return The Administrator Address
    function get() internal view returns (address) {
        return LibUnstructuredStorage.getStorageAddress(ADMINISTRATOR_ADDRESS_SLOT);
    }

    /// @notice Sets the Administrator Address
    /// @param _newValue New Administrator Address
    function set(address _newValue) internal {
        LibSanitize._notZeroAddress(_newValue);
        LibUnstructuredStorage.setStorageAddress(ADMINISTRATOR_ADDRESS_SLOT, _newValue);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../../libraries/LibUnstructuredStorage.sol";

/// @title Pending Administrator Address Storage
/// @notice Utility to manage the Pending Administrator Address in storage
library PendingAdministratorAddress {
    /// @notice Storage slot of the Pending Administrator Address
    bytes32 public constant PENDING_ADMINISTRATOR_ADDRESS_SLOT =
        bytes32(uint256(keccak256("river.state.pendingAdministratorAddress")) - 1);

    /// @notice Retrieve the Pending Administrator Address
    /// @return The Pending Administrator Address
    function get() internal view returns (address) {
        return LibUnstructuredStorage.getStorageAddress(PENDING_ADMINISTRATOR_ADDRESS_SLOT);
    }

    /// @notice Sets the Pending Administrator Address
    /// @param _newValue New Pending Administrator Address
    function set(address _newValue) internal {
        LibUnstructuredStorage.setStorageAddress(PENDING_ADMINISTRATOR_ADDRESS_SLOT, _newValue);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../libraries/LibSanitize.sol";
import "../../libraries/LibUnstructuredStorage.sol";

/// @title River Address Storage
/// @notice Utility to manage the River Address in storage
library RiverAddress {
    /// @notice Storage slot of the River Address
    bytes32 internal constant RIVER_ADDRESS_SLOT = bytes32(uint256(keccak256("river.state.riverAddress")) - 1);

    /// @notice Retrieve the River Address
    /// @return The River Address
    function get() internal view returns (address) {
        return LibUnstructuredStorage.getStorageAddress(RIVER_ADDRESS_SLOT);
    }

    /// @notice Sets the River Address
    /// @param _newValue New River Address
    function set(address _newValue) internal {
        LibSanitize._notZeroAddress(_newValue);
        LibUnstructuredStorage.setStorageAddress(RIVER_ADDRESS_SLOT, _newValue);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../../libraries/LibUnstructuredStorage.sol";

/// @title Version Storage
/// @notice Utility to manage the Version in storage
library Version {
    /// @notice Storage slot of the Version
    bytes32 public constant VERSION_SLOT = bytes32(uint256(keccak256("river.state.version")) - 1);

    /// @notice Retrieve the Version
    /// @return The Version
    function get() internal view returns (uint256) {
        return LibUnstructuredStorage.getStorageUint256(VERSION_SLOT);
    }

    /// @notice Sets the Version
    /// @param _newValue New Version
    function set(uint256 _newValue) internal {
        LibUnstructuredStorage.setStorageUint256(VERSION_SLOT, _newValue);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}