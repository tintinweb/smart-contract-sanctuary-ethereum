// SPDX-FileCopyrightText: 2022 Lido <[email protected]>
// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import { AccessControlEnumerable } from "@openzeppelin/contracts-v4.4/access/AccessControlEnumerable.sol";

import "./lib/RateLimitUtils.sol";
import "./ReportEpochChecker.sol";
import "./CommitteeQuorum.sol";


contract ValidatorExitBus is CommitteeQuorum, AccessControlEnumerable,  ReportEpochChecker {
    using UnstructuredStorage for bytes32;
    using RateLimitUtils for LimitState.Data;
    using LimitUnstructuredStorage for bytes32;

    event ValidatorExitRequest(
        address indexed stakingModule,
        uint256 indexed nodeOperatorId,
        uint256 indexed validatorId,
        bytes validatorPubkey
    );

    event RateLimitSet(
        uint256 maxLimit,
        uint256 limitIncreasePerBlock
    );

    event CommitteeMemberReported(
        address[] stakingModules,
        uint256[] nodeOperatorIds,
        uint256[] validatorIds,
        bytes[] validatorPubkeys,
        uint256 indexed epochId
    );

    event ConsensusReached(
        address[] stakingModules,
        uint256[] nodeOperatorIds,
        uint256[] validatorIds,
        bytes[] validatorPubkeys,
        uint256 indexed epochId
    );

    event ContractVersionSet(uint256 version);

    // ACL
    bytes32 constant public MANAGE_MEMBERS_ROLE = keccak256("MANAGE_MEMBERS_ROLE");
    bytes32 constant public MANAGE_QUORUM_ROLE = keccak256("MANAGE_QUORUM_ROLE");
    bytes32 constant public SET_BEACON_SPEC_ROLE = keccak256("SET_BEACON_SPEC_ROLE");

    bytes32 internal constant RATE_LIMIT_STATE_POSITION = keccak256("lido.ValidatorExitBus.rateLimitState");

    /// Version of the initialized contract data
    /// NB: Contract versioning starts from 1.
    /// The version stored in CONTRACT_VERSION_POSITION equals to
    /// - 0 right after deployment when no initializer is invoked yet
    /// - N after calling initialize() during deployment from scratch, where N is the current contract version
    /// - N after upgrading contract from the previous version (after calling finalize_vN())
    bytes32 internal constant CONTRACT_VERSION_POSITION =
        0x75be19a3f314d89bd1f84d30a6c84e2f1cd7afc7b6ca21876564c265113bb7e4; // keccak256("lido.LidoOracle.contractVersion")

    bytes32 internal constant TOTAL_EXIT_REQUESTS_POSITION = keccak256("lido.ValidatorExitBus.totalExitRequests");

    /// (stakingModuleAddress, nodeOperatorId) => lastRequestedValidatorId
    mapping(address => mapping (uint256 => uint256)) public lastRequestedValidatorIds;

    function initialize(
        address _admin,
        uint256 _maxRequestsPerDayE18,
        uint256 _numRequestsLimitIncreasePerBlockE18,
        uint64 _epochsPerFrame,
        uint64 _slotsPerEpoch,
        uint64 _secondsPerSlot,
        uint64 _genesisTime
    ) external
    {
        // Initializations for v0 --> v1
        if (CONTRACT_VERSION_POSITION.getStorageUint256() != 0) {
            revert CanInitializeOnlyOnZeroVersion();
        }
        if (_admin == address(0)) { revert ZeroAdminAddress(); }

        CONTRACT_VERSION_POSITION.setStorageUint256(1);
        emit ContractVersionSet(1);

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);

        LimitState.Data memory limitData = RATE_LIMIT_STATE_POSITION.getStorageLimitStruct();
        limitData.setLimit(_maxRequestsPerDayE18, _numRequestsLimitIncreasePerBlockE18);
        limitData.setPrevBlockNumber(block.number);
        RATE_LIMIT_STATE_POSITION.setStorageLimitStruct(limitData);
        emit RateLimitSet(_maxRequestsPerDayE18, _numRequestsLimitIncreasePerBlockE18);

        _setQuorum(1);

        _setBeaconSpec(_epochsPerFrame, _slotsPerEpoch, _secondsPerSlot, _genesisTime);

        // set expected epoch to the first epoch for the next frame
        _setExpectedEpochToFirstOfNextFrame();
    }

    /**
     * @notice Return the initialized version of this contract starting from 0
     */
    function getVersion() external view returns (uint256) {
        return CONTRACT_VERSION_POSITION.getStorageUint256();
    }

    function getTotalExitRequests() external view returns (uint256) {
        return TOTAL_EXIT_REQUESTS_POSITION.getStorageUint256();
    }


    function handleCommitteeMemberReport(
        address[] calldata _stakingModules,
        uint256[] calldata _nodeOperatorIds,
        uint256[] calldata _validatorIds,
        bytes[] calldata _validatorPubkeys,
        uint256 _epochId
    ) external {
        if (_nodeOperatorIds.length != _validatorPubkeys.length) { revert ArraysMustBeSameSize(); }
        if (_stakingModules.length != _validatorPubkeys.length) { revert ArraysMustBeSameSize(); }
        if (_validatorIds.length != _validatorPubkeys.length) { revert ArraysMustBeSameSize(); }
        if (_validatorPubkeys.length == 0) { revert EmptyArraysNotAllowed(); }

        // TODO: maybe check length of bytes pubkeys

        BeaconSpec memory beaconSpec = _getBeaconSpec();
        bool hasEpochAdvanced = _validateAndUpdateExpectedEpoch(_epochId, beaconSpec);
        if (hasEpochAdvanced) {
            _clearReporting();
        }

        bytes memory reportBytes = _encodeReport(_stakingModules, _nodeOperatorIds, _validatorIds, _validatorPubkeys, _epochId);
        if (_handleMemberReport(msg.sender, reportBytes)) {
            _reportKeysToEject(_stakingModules, _nodeOperatorIds, _validatorIds, _validatorPubkeys, _epochId, beaconSpec);
        }

        emit CommitteeMemberReported(_stakingModules, _nodeOperatorIds, _validatorIds, _validatorPubkeys, _epochId);
    }


    /**
     * @notice Super admin has all roles (can change committee members etc)
     */
    function testnet_setAdmin(address _newAdmin)
        external onlyRole(DEFAULT_ADMIN_ROLE)
    {
        // TODO: remove this temporary function
        _grantRole(DEFAULT_ADMIN_ROLE, _newAdmin);
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }


    function testnet_addAdmin(address _newAdmin)
        external onlyRole(DEFAULT_ADMIN_ROLE)
    {
        // TODO: remove this temporary function
        _grantRole(DEFAULT_ADMIN_ROLE, _newAdmin);
    }


    function testnet_assignAllNonAdminRolesTo(address _rolesHolder)
        external onlyRole(DEFAULT_ADMIN_ROLE)
    {
        // TODO: remove this temporary function
        _grantRole(MANAGE_MEMBERS_ROLE, _rolesHolder);
        _grantRole(MANAGE_QUORUM_ROLE, _rolesHolder);
        _grantRole(SET_BEACON_SPEC_ROLE, _rolesHolder);
    }


    function setRateLimit(uint256 _maxLimit, uint256 _limitIncreasePerBlock) external {
        _setRateLimit(_maxLimit, _limitIncreasePerBlock);
    }


    function getMaxLimit() external view returns (uint96) {
        LimitState.Data memory state = RATE_LIMIT_STATE_POSITION.getStorageLimitStruct();
        return state.maxLimit;
    }


    function getLimitState() external view returns (LimitState.Data memory) {
        return RATE_LIMIT_STATE_POSITION.getStorageLimitStruct();
    }


    function getCurrentLimit() external view returns (uint256) {
        return RATE_LIMIT_STATE_POSITION.getStorageLimitStruct().calculateCurrentLimit();
    }

    function getLastRequestedValidatorId(address _stakingModule, uint256 _nodeOperatorId)
        external view returns (uint256)
    {
        return lastRequestedValidatorIds[_stakingModule][_nodeOperatorId];
    }

    /**
     * @notice Set the number of exactly the same reports needed to finalize the epoch to `_quorum`
     */
    function updateQuorum(uint256 _quorum)
        external onlyRole(MANAGE_QUORUM_ROLE)
    {
        (bool isQuorumReached, uint256 reportIndex) = _updateQuorum(_quorum);
        if (isQuorumReached) {
            (
                address[] memory stakingModules,
                uint256[] memory nodeOperatorIds,
                uint256[] memory validatorIds,
                bytes[] memory validatorPubkeys,
                uint256 epochId
            ) = _decodeReport(distinctReports[reportIndex]);
            _reportKeysToEject(stakingModules, nodeOperatorIds, validatorIds, validatorPubkeys, epochId, _getBeaconSpec());
        }
    }

    /**
     * @notice Add `_member` to the oracle member committee list
     */
    function addOracleMember(address _member)
        external onlyRole(MANAGE_MEMBERS_ROLE)
    {
        _addOracleMember(_member);
    }


    /**
     * @notice Remove '_member` from the oracle member committee list
     */
    function removeOracleMember(address _member)
        external onlyRole(MANAGE_MEMBERS_ROLE)
    {
        _removeOracleMember(_member);
    }


    function _reportKeysToEject(
        address[] memory _stakingModules,
        uint256[] memory _nodeOperatorIds,
        uint256[] memory _validatorIds,
        bytes[] memory _validatorPubkeys,
        uint256 _epochId,
        BeaconSpec memory _beaconSpec
    ) internal {
        emit ConsensusReached(_stakingModules, _nodeOperatorIds, _validatorIds, _validatorPubkeys, _epochId);

        _advanceExpectedEpoch(_epochId + _beaconSpec.epochsPerFrame);
        _clearReporting();

        uint256 numKeys = _validatorPubkeys.length;
        LimitState.Data memory limitData = RATE_LIMIT_STATE_POSITION.getStorageLimitStruct();
        uint256 currentLimit = limitData.calculateCurrentLimit();
        uint256 numKeysE18 = numKeys * 10**18;
        if (numKeysE18 > currentLimit) { revert RateLimitExceeded(); }
        limitData.updatePrevLimit(currentLimit - numKeysE18);
        RATE_LIMIT_STATE_POSITION.setStorageLimitStruct(limitData);

        // TODO: maybe do some additional report validity sanity checks

        for (uint256 i = 0; i < numKeys; i++) {
            emit ValidatorExitRequest(
                _stakingModules[i],
                _nodeOperatorIds[i],
                _validatorIds[i],
                _validatorPubkeys[i]
            );

            lastRequestedValidatorIds[_stakingModules[i]][_nodeOperatorIds[i]] = _validatorIds[i];
        }

        TOTAL_EXIT_REQUESTS_POSITION.setStorageUint256(
            TOTAL_EXIT_REQUESTS_POSITION.getStorageUint256() + numKeys
        );
    }

    function _setRateLimit(uint256 _maxLimit, uint256 _limitIncreasePerBlock) internal {
        LimitState.Data memory limitData = RATE_LIMIT_STATE_POSITION.getStorageLimitStruct();
        limitData.setLimit(_maxLimit, _limitIncreasePerBlock);
        RATE_LIMIT_STATE_POSITION.setStorageLimitStruct(limitData);

        emit RateLimitSet(_maxLimit, _limitIncreasePerBlock);
    }

    function _decodeReport(bytes memory _reportData) internal pure returns (
        address[] memory stakingModules,
        uint256[] memory nodeOperatorIds,
        uint256[] memory validatorIds,
        bytes[] memory validatorPubkeys,
        uint256 epochId
    ) {
        (stakingModules, nodeOperatorIds, validatorIds, validatorPubkeys, epochId)
            = abi.decode(_reportData, (address[], uint256[], uint256[], bytes[], uint256));
    }


    function _encodeReport(
        address[] calldata _stakingModules,
        uint256[] calldata _nodeOperatorIds,
        uint256[] calldata _validatorIds,
        bytes[] calldata _validatorPubkeys,
        uint256 _epochId
    ) internal pure returns (
        bytes memory reportData
    ) {
        reportData = abi.encode(_stakingModules, _nodeOperatorIds, _validatorIds, _validatorPubkeys, _epochId);
    }

    error CanInitializeOnlyOnZeroVersion();
    error ZeroAdminAddress();
    error RateLimitExceeded();
    error ArraysMustBeSameSize();
    error EmptyArraysNotAllowed();

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-FileCopyrightText: 2022 Lido <[email protected]>
// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;


import "./AragonUnstructuredStorage.sol";

//
// We need to pack four variables into the same 256bit-wide storage slot
// to lower the costs per each staking request.
//
// As a result, slot's memory aligned as follows:
//
// MSB ------------------------------------------------------------------------------> LSB
// 256____________160_________________________128_______________32_____________________ 0
// |_______________|___________________________|________________|_______________________|
// | maxLimit | maxLimitGrowthBlocks | prevLimit | prevBlockNumber  |
// |<-- 96 bits -->|<---------- 32 bits ------>|<-- 96 bits --->|<----- 32 bits ------->|
//
//
// NB: Internal representation conventions:
//
// - the `maxLimitGrowthBlocks` field above represented as follows:
// `maxLimitGrowthBlocks` = `maxLimit` / `limitIncreasePerBlock`
//           32 bits                 96 bits               96 bits
//
//

/**
* @notice Library for the internal structs definitions
* @dev solidity <0.6 doesn't support top-level structs
* using the library to have a proper namespace
*/
library LimitState {
    /**
      * @dev Internal representation struct (slot-wide)
      */
    struct Data {
        uint32 prevBlockNumber;
        uint96 prevLimit;
        uint32 maxLimitGrowthBlocks;
        uint96 maxLimit;
    }
}


library LimitUnstructuredStorage {
    using UnstructuredStorage for bytes32;

    /// @dev Storage offset for `maxLimit` (bits)
    uint256 internal constant MAX_LIMIT_OFFSET = 160;
    /// @dev Storage offset for `maxLimitGrowthBlocks` (bits)
    uint256 internal constant MAX_LIMIT_GROWTH_BLOCKS_OFFSET = 128;
    /// @dev Storage offset for `prevLimit` (bits)
    uint256 internal constant PREV_LIMIT_OFFSET = 32;
    /// @dev Storage offset for `prevBlockNumber` (bits)
    uint256 internal constant PREV_BLOCK_NUMBER_OFFSET = 0;

    /**
    * @dev Read limit state from the unstructured storage position
    * @param _position storage offset
    */
    function getStorageLimitStruct(bytes32 _position) internal view returns (LimitState.Data memory rateLimit) {
        uint256 slotValue = _position.getStorageUint256();

        rateLimit.prevBlockNumber = uint32(slotValue >> PREV_BLOCK_NUMBER_OFFSET);
        rateLimit.prevLimit = uint96(slotValue >> PREV_LIMIT_OFFSET);
        rateLimit.maxLimitGrowthBlocks = uint32(slotValue >> MAX_LIMIT_GROWTH_BLOCKS_OFFSET);
        rateLimit.maxLimit = uint96(slotValue >> MAX_LIMIT_OFFSET);
    }

     /**
    * @dev Write limit state to the unstructured storage position
    * @param _position storage offset
    * @param _data limit state structure instance
    */
    function setStorageLimitStruct(bytes32 _position, LimitState.Data memory _data) internal {
        _position.setStorageUint256(
            uint256(_data.prevBlockNumber) << PREV_BLOCK_NUMBER_OFFSET
                | uint256(_data.prevLimit) << PREV_LIMIT_OFFSET
                | uint256(_data.maxLimitGrowthBlocks) << MAX_LIMIT_GROWTH_BLOCKS_OFFSET
                | uint256(_data.maxLimit) << MAX_LIMIT_OFFSET
        );
    }
}

/**
* @notice Interface library with helper functions to deal with take limit struct in a more high-level approach.
*/
library RateLimitUtils {
    /**
    * @notice Calculate limit for the current block.
    */
    function calculateCurrentLimit(LimitState.Data memory _data)
        internal view returns(uint256 limit)
    {
        uint256 limitIncPerBlock = 0;
        if (_data.maxLimitGrowthBlocks != 0) {
            limitIncPerBlock = _data.maxLimit / _data.maxLimitGrowthBlocks;
        }

        limit = _data.prevLimit + ((block.number - _data.prevBlockNumber) * limitIncPerBlock);
        if (limit > _data.maxLimit) {
            limit = _data.maxLimit;
        }
    }

    /**
    * @notice Update limit repr with the desired limits
    * @dev Input `_data` param is mutated and the func returns effectively the same pointer
    * @param _data limit state struct
    * @param _maxLimit limit max value
    * @param _limitIncreasePerBlock limit increase (restoration) per block
    */
    function setLimit(
        LimitState.Data memory _data,
        uint256 _maxLimit,
        uint256 _limitIncreasePerBlock
    ) internal view {
        if (_maxLimit == 0) { revert ZeroMaxLimit(); }
        if (_maxLimit >= type(uint96).max) { revert TooLargeMaxLimit(); }
        if (_maxLimit < _limitIncreasePerBlock) { revert TooLargeLimitIncrease(); }
        if (
            (_limitIncreasePerBlock != 0)
            && (_maxLimit / _limitIncreasePerBlock >= type(uint32).max)
        ) {
            revert TooSmallLimitIncrease();
        }

        // if no limit was set previously,
        // or new limit is lower than previous, then
        // reset prev limit to the new max limit
        if ((_data.maxLimit == 0) || (_maxLimit < _data.prevLimit)) {
            _data.prevLimit = uint96(_maxLimit);
        }
        _data.maxLimitGrowthBlocks = _limitIncreasePerBlock != 0 ? uint32(_maxLimit / _limitIncreasePerBlock) : 0;

        _data.maxLimit = uint96(_maxLimit);

        if (_data.prevBlockNumber != 0) {
            _data.prevBlockNumber = uint32(block.number);
        }
    }


    /**
    * @notice Update limit repr after submitting user's eth
    * @dev Input `_data` param is mutated and the func returns effectively the same pointer
    * @param _data limit state struct
    * @param _newPrevLimit new value for the `prevLimit` field
    */
    function updatePrevLimit(
        LimitState.Data memory _data,
        uint256 _newPrevLimit
    ) internal view {
        assert(_newPrevLimit < type(uint96).max);
        assert(_data.prevBlockNumber != 0);

        _data.prevLimit = uint96(_newPrevLimit);
        _data.prevBlockNumber = uint32(block.number);
    }

    function setPrevBlockNumber(
        LimitState.Data memory _data,
        uint256 _blockNumber
    ) internal pure {
        _data.prevBlockNumber = uint32(_blockNumber);
    }

    error ZeroMaxLimit();
    error TooLargeMaxLimit();
    error TooLargeLimitIncrease();
    error TooSmallLimitIncrease();
}

// SPDX-FileCopyrightText: 2022 Lido <[email protected]>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "./lib/AragonUnstructuredStorage.sol";


contract ReportEpochChecker {
    using UnstructuredStorage for bytes32;

    event ExpectedEpochIdUpdated(
        uint256 epochId
    );

    event BeaconSpecSet(
        uint64 epochsPerFrame,
        uint64 slotsPerEpoch,
        uint64 secondsPerSlot,
        uint64 genesisTime
    );

    struct BeaconSpec {
        uint64 epochsPerFrame;
        uint64 slotsPerEpoch;
        uint64 secondsPerSlot;
        uint64 genesisTime;
    }

    /// Storage for the actual beacon chain specification
    bytes32 internal constant BEACON_SPEC_POSITION =
        0x805e82d53a51be3dfde7cfed901f1f96f5dad18e874708b082adb8841e8ca909; // keccak256("lido.LidoOracle.beaconSpec")

    /// Epoch that we currently collect reports
    bytes32 internal constant EXPECTED_EPOCH_ID_POSITION =
        0x65f1a0ee358a8a4000a59c2815dc768eb87d24146ca1ac5555cb6eb871aee915; // keccak256("lido.LidoOracle.expectedEpochId")


    /**
     * @notice Returns epoch that can be reported by oracles
     */
    function getExpectedEpochId() external view returns (uint256) {
        return EXPECTED_EPOCH_ID_POSITION.getStorageUint256();
    }

    /**
     * @notice Return beacon specification data
     */
    function getBeaconSpec()
        external
        view
        returns (
            uint64 epochsPerFrame,
            uint64 slotsPerEpoch,
            uint64 secondsPerSlot,
            uint64 genesisTime
        )
    {
        BeaconSpec memory beaconSpec = _getBeaconSpec();
        return (
            beaconSpec.epochsPerFrame,
            beaconSpec.slotsPerEpoch,
            beaconSpec.secondsPerSlot,
            beaconSpec.genesisTime
        );
    }


    /**
     * @notice Return the epoch calculated from current timestamp
     */
    function getCurrentEpochId() external view returns (uint256) {
        BeaconSpec memory beaconSpec = _getBeaconSpec();
        return _getCurrentEpochId(beaconSpec);
    }

    /**
     * @notice Return currently reportable epoch (the first epoch of the current frame) as well as
     * its start and end times in seconds
     */
    function getCurrentFrame()
        external
        view
        returns (
            uint256 frameEpochId,
            uint256 frameStartTime,
            uint256 frameEndTime
        )
    {
        BeaconSpec memory beaconSpec = _getBeaconSpec();
        uint64 genesisTime = beaconSpec.genesisTime;
        uint64 secondsPerEpoch = beaconSpec.secondsPerSlot * beaconSpec.slotsPerEpoch;

        frameEpochId = _getFrameFirstEpochId(_getCurrentEpochId(beaconSpec), beaconSpec);
        frameStartTime = frameEpochId * secondsPerEpoch + genesisTime;
        frameEndTime = (frameEpochId + beaconSpec.epochsPerFrame) * secondsPerEpoch + genesisTime - 1;
    }

    function _validateAndUpdateExpectedEpoch(uint256 _epochId, BeaconSpec memory _beaconSpec)
        internal returns (bool hasEpochAdvanced)
    {
        uint256 expectedEpoch = EXPECTED_EPOCH_ID_POSITION.getStorageUint256();
        if (_epochId < expectedEpoch) { revert EpochIsTooOld(); }

        // if expected epoch has advanced, check that this is the first epoch of the current frame
        if (_epochId > expectedEpoch) {
            if (_epochId != _getFrameFirstEpochId(_getCurrentEpochId(_beaconSpec), _beaconSpec)) {
                revert UnexpectedEpoch();
            }
            hasEpochAdvanced = true;
            _advanceExpectedEpoch(_epochId);
        }
    }

    /**
     * @notice Return beacon specification data
     */
    function _getBeaconSpec()
        internal
        view
        returns (BeaconSpec memory beaconSpec)
    {
        uint256 data = BEACON_SPEC_POSITION.getStorageUint256();
        beaconSpec.epochsPerFrame = uint64(data >> 192);
        beaconSpec.slotsPerEpoch = uint64(data >> 128);
        beaconSpec.secondsPerSlot = uint64(data >> 64);
        beaconSpec.genesisTime = uint64(data);
        return beaconSpec;
    }

    /**
     * @notice Set beacon specification data
     */
    function _setBeaconSpec(
        uint64 _epochsPerFrame,
        uint64 _slotsPerEpoch,
        uint64 _secondsPerSlot,
        uint64 _genesisTime
    )
        internal
    {
        if (_epochsPerFrame == 0) { revert BadEpochsPerFrame(); }
        if (_slotsPerEpoch == 0) { revert BadSlotsPerEpoch(); }
        if (_secondsPerSlot == 0) { revert BadSecondsPerSlot(); }
        if (_genesisTime == 0) { revert BadGenesisTime(); }

        uint256 data = (
            uint256(_epochsPerFrame) << 192 |
            uint256(_slotsPerEpoch) << 128 |
            uint256(_secondsPerSlot) << 64 |
            uint256(_genesisTime)
        );
        BEACON_SPEC_POSITION.setStorageUint256(data);
        emit BeaconSpecSet(
            _epochsPerFrame,
            _slotsPerEpoch,
            _secondsPerSlot,
            _genesisTime);
    }

    function _setExpectedEpochToFirstOfNextFrame() internal {
        BeaconSpec memory beaconSpec = _getBeaconSpec();
        uint256 expectedEpoch = _getFrameFirstEpochId(0, beaconSpec) + beaconSpec.epochsPerFrame;
        EXPECTED_EPOCH_ID_POSITION.setStorageUint256(expectedEpoch);
        emit ExpectedEpochIdUpdated(expectedEpoch);
    }

    /**
     * @notice Remove the current reporting progress and advances to accept the later epoch `_epochId`
     */
    function _advanceExpectedEpoch(uint256 _epochId) internal {
        EXPECTED_EPOCH_ID_POSITION.setStorageUint256(_epochId);
        emit ExpectedEpochIdUpdated(_epochId);
    }

    /**
     * @notice Return the epoch calculated from current timestamp
     */
    function _getCurrentEpochId(BeaconSpec memory _beaconSpec) internal view returns (uint256) {
        return (_getTime() - _beaconSpec.genesisTime) / (_beaconSpec.slotsPerEpoch * _beaconSpec.secondsPerSlot);
    }

    /**
     * @notice Return the first epoch of the frame that `_epochId` belongs to
     */
    function _getFrameFirstEpochId(uint256 _epochId, BeaconSpec memory _beaconSpec) internal pure returns (uint256) {
        return _epochId / _beaconSpec.epochsPerFrame * _beaconSpec.epochsPerFrame;
    }

    /**
     * @notice Return the current timestamp
     */
    function _getTime() internal virtual view returns (uint256) {
        return block.timestamp; // solhint-disable-line not-rely-on-time
    }

    error EpochIsTooOld();
    error UnexpectedEpoch();
    error BadEpochsPerFrame();
    error BadSlotsPerEpoch();
    error BadSecondsPerSlot();
    error BadGenesisTime();
}

// SPDX-FileCopyrightText: 2022 Lido <[email protected]>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "./lib/AragonUnstructuredStorage.sol";


/**
 * @title Implementation of an ETH 2.0 -> ETH oracle
 *
 * The goal of the oracle is to inform other parts of the system about balances controlled by the
 * DAO on the ETH 2.0 side. The balances can go up because of reward accumulation and can go down
 * because of slashing.
 *
 * The timeline is divided into consecutive frames. Every oracle member may push its report once
 * per frame. When the equal reports reach the configurable 'quorum' value, this frame is
 * considered finalized and the resulting report is pushed to Lido.
 *
 * Not all frames may come to a quorum. Oracles may report only to the first epoch of the frame and
 * only if no quorum is reached for this epoch yet.
 */
contract CommitteeQuorum {
    using UnstructuredStorage for bytes32;

    event MemberAdded(address indexed member);
    event MemberRemoved(address indexed member);
    event QuorumChanged(uint256 quorum);

    /// Maximum number of oracle committee members
    uint256 public constant MAX_MEMBERS = 256;

    /// Contract structured storage
    address[] internal members;
    bytes[] internal distinctReports;
    bytes32[] internal distinctReportHashes;
    uint16[] internal distinctReportCounters;

    /// Number of exactly the same reports needed to finalize the epoch
    bytes32 internal constant QUORUM_POSITION =
        0xd43b42c1ba05a1ab3c178623a49b2cdb55f000ec70b9ccdba5740b3339a7589e; // keccak256("lido.LidoOracle.quorum")

    uint256 internal constant MEMBER_NOT_FOUND = type(uint256).max;

    /// The bitmask of the oracle members that pushed their reports
    bytes32 internal constant REPORTS_BITMASK_POSITION =
        0xea6fa022365e4737a3bb52facb00ddc693a656fb51ffb2b4bd24fb85bdc888be; // keccak256("lido.LidoOracle.reportsBitMask")

    /**
     * @notice Return the current reporting bitmap, representing oracles who have already pushed
     * their version of report during the expected epoch
     * @dev Every oracle bit corresponds to the index of the oracle in the current members list
     */
    function getCurrentOraclesReportStatus() external view returns (uint256) {
        return REPORTS_BITMASK_POSITION.getStorageUint256();
    }

    /**
     * @notice Return the current reporting variants array size
     * TODO: rename
     */
    function getDistinctMemberReportsCount() external view returns (uint256) {
        return distinctReports.length;
    }

    /**
     * @notice Return the current oracle member committee list
     */
    function getOracleMembers() external view returns (address[] memory) {
        return members;
    }

    /**
     * @notice Return the number of exactly the same reports needed to finalize the epoch
     */
    function getQuorum() public view returns (uint256) {
        return QUORUM_POSITION.getStorageUint256();
    }

    function _addOracleMember(address _member) internal {
        if (_member == address(0)) { revert ZeroMemberAddress(); }
        if (MEMBER_NOT_FOUND != _getMemberId(_member)) { revert MemberExists(); }
        if (members.length >= MAX_MEMBERS) { revert TooManyMembers(); }

        members.push(_member);

        emit MemberAdded(_member);
    }


    function _removeOracleMember(address _member) internal {
        uint256 index = _getMemberId(_member);
        if (index == MEMBER_NOT_FOUND) { revert MemberNotFound(); }

        uint256 last = members.length - 1;
        if (index != last) members[index] = members[last];
        members.pop();
        emit MemberRemoved(_member);

        // delete the data for the last epoch, let remained oracles report it again
        REPORTS_BITMASK_POSITION.setStorageUint256(0);
        delete distinctReports;
    }

    function _getQuorumReport(uint256 _quorum) internal view
        returns (bool isQuorumReached, uint256 reportIndex)
    {
        // check most frequent cases first: all reports are the same or no reports yet
        if (distinctReports.length == 0) {
            return (false, 0);
        } else if (distinctReports.length == 1) {
            return (distinctReportCounters[0] >= _quorum, 0);
        }

        // If there are multiple reports with the same count above quorum number we consider
        // the quorum not reached
        reportIndex = 0;
        bool areMultipleMaxReports = false;
        uint16 maxCount = 0;
        uint16 currentCount = 0;
        for (uint256 i = 0; i < distinctReports.length; ++i) {
            currentCount = distinctReportCounters[i];
            if (currentCount >= maxCount) {
                if (currentCount == maxCount) {
                    areMultipleMaxReports = true;
                } else {
                    reportIndex = i;
                    maxCount = currentCount;
                    areMultipleMaxReports = false;
                }
            }
        }
        isQuorumReached = maxCount >= _quorum && !areMultipleMaxReports;
    }

    function _setQuorum(uint256 _quorum) internal {
        QUORUM_POSITION.setStorageUint256(_quorum);
        emit QuorumChanged(_quorum);
    }

    function _updateQuorum(uint256 _quorum) internal
        returns (bool isQuorumReached, uint256 reportIndex)
    {
        if (0 == _quorum) { revert QuorumWontBeMade(); }
        uint256 oldQuorum = QUORUM_POSITION.getStorageUint256();

        _setQuorum(_quorum);

        if (_quorum < oldQuorum) {
            return _getQuorumReport(_quorum);
        }
    }

    /**
     * @notice Return `_member` index in the members list or MEMBER_NOT_FOUND
     */
    function _getMemberId(address _member) internal view returns (uint256) {
        uint256 length = members.length;
        for (uint256 i = 0; i < length; ++i) {
            if (members[i] == _member) {
                return i;
            }
        }
        return MEMBER_NOT_FOUND;
    }

    function _clearReporting() internal {
        REPORTS_BITMASK_POSITION.setStorageUint256(0);
        delete distinctReports;
        delete distinctReportHashes;
        delete distinctReportCounters;
    }


    function _handleMemberReport(address _reporter, bytes memory _report)
        internal returns (bool isQuorumReached)
    {
        // make sure the oracle is from members list and has not yet voted
        uint256 index = _getMemberId(_reporter);
        if (index == MEMBER_NOT_FOUND) { revert NotMemberReported(); }

        uint256 bitMask = REPORTS_BITMASK_POSITION.getStorageUint256();
        uint256 mask = 1 << index;
        if (bitMask & mask != 0) { revert MemberAlreadyReported(); }
        REPORTS_BITMASK_POSITION.setStorageUint256(bitMask | mask);

        bytes32 reportHash = keccak256(_report);
        isQuorumReached = false;

        uint256 i = 0;
        bool isFound = false;
        while (i < distinctReports.length && distinctReportHashes[i] != reportHash) {
            ++i;
        }
        while (i < distinctReports.length) {
            if (distinctReportHashes[i] == reportHash) {
                isFound = true;
                break;
            }
            ++i;
        }

        if (isFound && i < distinctReports.length) {
            distinctReportCounters[i] += 1;
        } else {
            distinctReports.push(_report);
            distinctReportHashes.push(reportHash);
            distinctReportCounters.push(1);
        }

        // Check is quorum reached
        if (distinctReportCounters[i] >= QUORUM_POSITION.getStorageUint256()) {
            isQuorumReached = true;
        }
    }

    error NotMemberReported();
    error ZeroMemberAddress();
    error MemberNotFound();
    error TooManyMembers();
    error MemberExists();
    error MemberAlreadyReported();
    error QuorumWontBeMade();

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity 0.8.9;


library UnstructuredStorage {
    function getStorageBool(bytes32 position) internal view returns (bool data) {
        assembly {
            data := sload(position)
        }
    }

    function getStorageAddress(bytes32 position) internal view returns (address data) {
        assembly {
            data := sload(position)
        }
    }

    function getStorageBytes32(bytes32 position) internal view returns (bytes32 data) {
        assembly {
            data := sload(position)
        }
    }

    function getStorageUint256(bytes32 position) internal view returns (uint256 data) {
        assembly {
            data := sload(position)
        }
    }

    function setStorageBool(bytes32 position, bool data) internal {
        assembly {
            sstore(position, data)
        }
    }

    function setStorageAddress(bytes32 position, address data) internal {
        assembly {
            sstore(position, data)
        }
    }

    function setStorageBytes32(bytes32 position, bytes32 data) internal {
        assembly {
            sstore(position, data)
        }
    }

    function setStorageUint256(bytes32 position, uint256 data) internal {
        assembly {
            sstore(position, data)
        }
    }
}