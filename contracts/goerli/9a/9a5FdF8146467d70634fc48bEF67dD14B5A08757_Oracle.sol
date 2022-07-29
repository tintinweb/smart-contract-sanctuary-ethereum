// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

import "./interfaces/IOracle.sol";
import "./interfaces/ILightNode.sol";
import "./interfaces/IBeaconReportReceiver.sol";

import "./lib/UnstructuredStorage.sol";
import "./lib/ReportUtils.sol";

/**
 * @title Implementation of an ETH 2.0 -> ETH oracle
 *
 * The goal of the oracle is to inform other parts of the system about balances controlled by the
 * DAO on the ETH 2.0 side. The balances can go up because of reward accumulation and can go down
 * because of slashing.
 *
 * The timeline is divided into consecutive frames. Every oracle member may push its report once
 * per frame. When the equal reports reach the configurable 'quorum' value, this frame is
 * considered finalized and the resulting report is pushed to LghtNode.
 *
 * Not all frames may come to a quorum. Oracles may report only to the first epoch of the frame and
 * only if no quorum is reached for this epoch yet.
 */
contract Oracle is IOracle, AccessControl {
    using ReportUtils for uint256;
    using UnstructuredStorage for bytes32;

    struct BeaconSpec {
        uint64 epochsPerFrame;
        uint64 slotsPerEpoch;
        uint64 secondsPerSlot;
        uint64 genesisTime;
    }

    // Access Control List(ACL)
    bytes32 public constant MANAGE_MEMBERS = keccak256("MANAGE_MEMBERS");
    bytes32 public constant MANAGE_QUORUM = keccak256("MANAGE_QUORUM");
    bytes32 public constant SET_BEACON_SPEC = keccak256("SET_BEACON_SPEC");
    bytes32 public constant SET_REPORT_BOUNDARIES = keccak256("SET_REPORT_BOUNDARIES");
    bytes32 public constant SET_BEACON_REPORT_RECEIVER = keccak256("SET_BEACON_REPORT_RECEIVER");

    /// Maximum number of oracle committee members
    uint256 public constant MAX_MEMBERS = 256;

    // Eth1 denomination is 18 digits, while Eth2 has 9 digits. Because we work with Eth2
    // balances and to support old interfaces expecting eth1 format, we multiply by this
    // coefficient.
    uint128 internal constant DENOMINATION_OFFSET = 1e9;

    uint256 internal constant MEMBER_NOT_FOUND = type(uint256).max;

    // Number of exactly the same reports needed to finalize the epoch
    bytes32 internal constant QUORUM_POSITION =
        keccak256("lightNode.LightNode.quorum");

    // Address of the LightNode contract
    bytes32 internal constant LIGHT_NODE_POSITION =
        keccak256("lightNode.LightNode.node");

    // Storage for the actual beacon chain specification
    bytes32 internal constant BEACON_SPEC_POSITION =
        keccak256("lightNode.LightNode.beaconSpec");

    // Version of the initialized contract data, v1 is 0
    bytes32 internal constant CONTRACT_VERSION_POSITION =
        keccak256("lightNode.LightNode.contractVersion");

    // Epoch that we currently collect reports
    bytes32 internal constant EXPECTED_EPOCH_ID_POSITION =
        keccak256("lightNode.LightNode.expectedEpochId");

    // The bitmask of the oracle members that pushed their reports
    bytes32 internal constant REPORTS_BITMASK_POSITION =
        keccak256("lightNode.LightNode.reportsBitMask");

    // Historic data about 2 last completed reports and their times
    bytes32 internal constant POST_COMPLETED_TOTAL_POOLED_ETHER_POSITION =
        keccak256("lightNode.LightNode.postCompletedTotalPooledEther");
    bytes32 internal constant PRE_COMPLETED_TOTAL_POOLED_ETHER_POSITION =
        keccak256("lightNode.LightNode.preCompletedTotalPooledEther");
    bytes32 internal constant LAST_COMPLETED_EPOCH_ID_POSITION =
        keccak256("lightNode.LightNode.lastCompletedEpochId");
    bytes32 internal constant TIME_ELAPSED_POSITION =
        keccak256("lightNode.LightNode.timeElapsed");

    // Receiver address to be called when the report is pushed to LightNode
    bytes32 internal constant BEACON_REPORT_RECEIVER_POSITION =
        keccak256("lightNode.LightNode.beaconReportReceiver");

    // Upper bound of the reported balance possible increase in APR, controlled by the governance
    bytes32
        internal constant ALLOWED_BEACON_BALANCE_ANNUAL_RELATIVE_INCREASE_POSITION =
        keccak256(
            "lightNode.LightNode.allowedBeaconBalanceAnnualRelativeIncrease"
        );
    // Lower bound of the reported balance possible decrease, controlled by the governance
    // @notice When slashing happens, the balance may decrease at a much faster pace. Slashing are
    // one-time events that decrease the balance a fair amount - a few percent at a time in a
    // realistic scenario. Thus, instead of sanity check for an APR, we check if the plain relative
    // decrease is within bounds.  Note that it's not annual value, its just one-jump value.
    bytes32
        internal constant ALLOWED_BEACON_BALANCE_RELATIVE_DECREASE_POSITION =
        keccak256("lightNode.LightNode.allowedBeaconBalanceDecrease");

    // This variable is from v1: the last reported epoch, used only in the initializer
    bytes32 internal constant V1_LAST_REPORTED_EPOCH_ID_POSITION =
        keccak256("lightNode.LightNode.lastReportedEpochId");

    // Contract structured storage
    address[] private members; // slot 0: oracle committee members
    uint256[] private currentReportVariants; // slot 1: reporting storage

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
    
    /**
     * @notice Return the LightNode contract address
     */
    function getLightNode() public view override returns (ILightNode) {
        return ILightNode(LIGHT_NODE_POSITION.getStorageAddress());
    }

    /**
     * @notice Return the number of exactly the same reports needed to finalize the epoch
     */
    function getQuorum() public view override returns (uint256) {
        return QUORUM_POSITION.getStorageUint256();
    }

    /**
     * @notice Return the upper bound of the reported balance possible increase in APR
     */
    function getAllowedBeaconBalanceAnnualRelativeIncrease()
        external
        view
        override
        returns (uint256)
    {
        return
            ALLOWED_BEACON_BALANCE_ANNUAL_RELATIVE_INCREASE_POSITION
                .getStorageUint256();
    }

    /**
     * @notice Return the lower bound of the reported balance possible decrease
     */
    function getAllowedBeaconBalanceRelativeDecrease()
        external
        view
        override
        returns (uint256)
    {
        return
            ALLOWED_BEACON_BALANCE_RELATIVE_DECREASE_POSITION
                .getStorageUint256();
    }

    /**
     * @notice Set the upper bound of the reported balance possible increase in APR to `_value`
     */
    function setAllowedBeaconBalanceAnnualRelativeIncrease(uint256 _value)
        external
        override
        onlyRole(SET_REPORT_BOUNDARIES)
    {
        ALLOWED_BEACON_BALANCE_ANNUAL_RELATIVE_INCREASE_POSITION
            .setStorageUint256(_value);
        emit AllowedBeaconBalanceAnnualRelativeIncreaseSet(_value);
    }

    /**
     * @notice Set the lower bound of the reported balance possible decrease to `_value`
     */
    function setAllowedBeaconBalanceRelativeDecrease(uint256 _value)
        external
        override
        onlyRole(SET_REPORT_BOUNDARIES)
    {
        ALLOWED_BEACON_BALANCE_RELATIVE_DECREASE_POSITION.setStorageUint256(
            _value
        );
        emit AllowedBeaconBalanceRelativeDecreaseSet(_value);
    }

    /**
     * @notice Return the receiver contract address to be called when the report is pushed to LightNode
     */
    function getBeaconReportReceiver()
        external
        view
        override
        returns (address)
    {
        return
            address(
                uint160(BEACON_REPORT_RECEIVER_POSITION.getStorageUint256())
            );
    }

    /**
     * @notice Set the receiver contract address to `_addr` to be called when the report is pushed
     * @dev Specify 0 to disable this functionality
     */
    function setBeaconReportReceiver(address _addr)
        external
        override
        onlyRole(SET_BEACON_REPORT_RECEIVER)
    {
        BEACON_REPORT_RECEIVER_POSITION.setStorageUint256(uint160(_addr));
        emit BeaconReportReceiverSet(_addr);
    }

    /**
     * @notice Return the current reporting bitmap, representing oracles who have already pushed
     * their version of report during the expected epoch
     * @dev Every oracle bit corresponds to the index of the oracle in the current members list
     */
    function getCurrentOraclesReportStatus()
        external
        view
        override
        returns (uint256)
    {
        return REPORTS_BITMASK_POSITION.getStorageUint256();
    }

    /**
     * @notice Return the current reporting variants array size
     */
    function getCurrentReportVariantsSize()
        external
        view
        override
        returns (uint256)
    {
        return currentReportVariants.length;
    }

    /**
     * @notice Return the current reporting array element with index `_index`
     */
    function getCurrentReportVariant(uint256 _index)
        external
        view
        override
        returns (
            uint64 beaconBalance,
            uint32 beaconValidators,
            uint16 count
        )
    {
        return currentReportVariants[_index].decodeWithCount();
    }

    /**
     * @notice Returns epoch that can be reported by oracles
     */
    function getExpectedEpochId() external view override returns (uint256) {
        return EXPECTED_EPOCH_ID_POSITION.getStorageUint256();
    }

    /**
     * @notice Return the current oracle member committee list
     */
    function getOracleMembers()
        external
        view
        override
        returns (address[] memory)
    {
        return members;
    }

    /**
     * @notice Return the initialized version of this contract starting from 0
     */
    function getVersion() external view override returns (uint256) {
        return CONTRACT_VERSION_POSITION.getStorageUint256();
    }

    function getBeaconSpec()
        external
        view
        override
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
     * @notice Update beacon specification data
     */
    function setBeaconSpec(
        uint64 _epochsPerFrame,
        uint64 _slotsPerEpoch,
        uint64 _secondsPerSlot,
        uint64 _genesisTime
    ) external override onlyRole(SET_BEACON_SPEC) {
        _setBeaconSpec(
            _epochsPerFrame,
            _slotsPerEpoch,
            _secondsPerSlot,
            _genesisTime
        );
    }

    /**
     * @notice Return the epoch calculated from current timestamp
     */
    function getCurrentEpochId() external view override returns (uint256) {
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
        override
        returns (
            uint256 frameEpochId,
            uint256 frameStartTime,
            uint256 frameEndTime
        )
    {
        BeaconSpec memory beaconSpec = _getBeaconSpec();
        uint64 genesisTime = beaconSpec.genesisTime;
        uint64 secondsPerEpoch = beaconSpec.secondsPerSlot *
            beaconSpec.slotsPerEpoch;

        frameEpochId = _getFrameFirstEpochId(
            _getCurrentEpochId(beaconSpec),
            beaconSpec
        );
        frameStartTime = frameEpochId * secondsPerEpoch + genesisTime;
        frameEndTime =
            (frameEpochId + beaconSpec.epochsPerFrame) *
            secondsPerEpoch +
            genesisTime -
            1;
    }

    /**
     * @notice Return last completed epoch
     */
    function getLastCompletedEpochId()
        external
        view
        override
        returns (uint256)
    {
        return LAST_COMPLETED_EPOCH_ID_POSITION.getStorageUint256();
    }

    /**
     * @notice Report beacon balance and its change during the last frame
     */
    function getLastCompletedReportDelta()
        external
        view
        override
        returns (
            uint256 postTotalPooledEther,
            uint256 preTotalPooledEther,
            uint256 timeElapsed
        )
    {
        postTotalPooledEther = POST_COMPLETED_TOTAL_POOLED_ETHER_POSITION
            .getStorageUint256();
        preTotalPooledEther = PRE_COMPLETED_TOTAL_POOLED_ETHER_POSITION
            .getStorageUint256();
        timeElapsed = TIME_ELAPSED_POSITION.getStorageUint256();
    }

    /**
     * @notice Initialize the contract v2 data, with sanity check bounds
     * (`_allowedBeaconBalanceAnnualRelativeIncrease`, `_allowedBeaconBalanceRelativeDecrease`)
     * @dev Original initialize function removed from v2 because it is invoked only once
     */
    function initialize_v2(
        uint256 _allowedBeaconBalanceAnnualRelativeIncrease,
        uint256 _allowedBeaconBalanceRelativeDecrease
    ) external override {
        require(
            CONTRACT_VERSION_POSITION.getStorageUint256() == 0,
            "ALREADY_INITIALIZED"
        );
        CONTRACT_VERSION_POSITION.setStorageUint256(1);
        emit ContractVersionSet(1);

        ALLOWED_BEACON_BALANCE_ANNUAL_RELATIVE_INCREASE_POSITION
            .setStorageUint256(_allowedBeaconBalanceAnnualRelativeIncrease);
        emit AllowedBeaconBalanceAnnualRelativeIncreaseSet(
            _allowedBeaconBalanceAnnualRelativeIncrease
        );

        ALLOWED_BEACON_BALANCE_RELATIVE_DECREASE_POSITION.setStorageUint256(
            _allowedBeaconBalanceRelativeDecrease
        );
        emit AllowedBeaconBalanceRelativeDecreaseSet(
            _allowedBeaconBalanceRelativeDecrease
        );

        // set last completed epoch as V1's contract last reported epoch, in the vast majority of
        // cases this is true, in others the error is within a frame
        uint256 lastReportedEpoch = V1_LAST_REPORTED_EPOCH_ID_POSITION
            .getStorageUint256();
        LAST_COMPLETED_EPOCH_ID_POSITION.setStorageUint256(lastReportedEpoch);

        // set expected epoch to the first epoch for the next frame
        BeaconSpec memory beaconSpec = _getBeaconSpec();
        uint256 expectedEpoch = _getFrameFirstEpochId(
            lastReportedEpoch,
            beaconSpec
        ) + beaconSpec.epochsPerFrame;
        EXPECTED_EPOCH_ID_POSITION.setStorageUint256(expectedEpoch);
        emit ExpectedEpochIdUpdated(expectedEpoch);
    }

    /**
     * @notice Add `_member` to the oracle member committee list
     */
    function addOracleMember(address _member)
        external
        override
        onlyRole(MANAGE_MEMBERS)
    {
        require(address(0) != _member, "BAD_ARGUMENT");
        require(MEMBER_NOT_FOUND == _getMemberId(_member), "MEMBER_EXISTS");

        members.push(_member);
        require(members.length < MAX_MEMBERS, "TOO_MANY_MEMBERS");
        emit MemberAdded(_member);
    }

    /**
     * @notice Remove '_member` from the oracle member committee list
     */
    function removeOracleMember(address _member)
        external
        override
        onlyRole(MANAGE_MEMBERS)
    {
        uint256 index = _getMemberId(_member);
        require(index != MEMBER_NOT_FOUND, "MEMBER_NOT_FOUND");
        uint256 last = members.length - 1;
        if (index != last) members[index] = members[last];
        delete members[index];
        emit MemberRemoved(_member);

        // delete the data for the last epoch, let remained oracles report it again
        REPORTS_BITMASK_POSITION.setStorageUint256(0);
        delete currentReportVariants;
    }

    /**
     * @notice Set the number of exactly the same reports needed to finalize the epoch to `_quorum`
     */
    function setQuorum(uint256 _quorum)
        external
        override
        onlyRole(MANAGE_QUORUM)
    {
        require(0 != _quorum, "QUORUM_WONT_BE_MADE");
        uint256 oldQuorum = QUORUM_POSITION.getStorageUint256();
        QUORUM_POSITION.setStorageUint256(_quorum);
        emit QuorumChanged(_quorum);

        // If the quorum value lowered, check existing reports whether it is time to push
        if (oldQuorum > _quorum) {
            (bool isQuorum, uint256 report) = _getQuorumReport(_quorum);
            if (isQuorum) {
                (uint64 beaconBalance, uint32 beaconValidators) = report
                    .decode();
                _push(
                    EXPECTED_EPOCH_ID_POSITION.getStorageUint256(),
                    DENOMINATION_OFFSET * uint128(beaconBalance),
                    beaconValidators,
                    _getBeaconSpec()
                );
            }
        }
    }

    /**
     * @notice Accept oracle committee member reports from the ETH 2.0 side
     * @param _epochId Beacon chain epoch
     * @param _beaconBalance Balance in gwei on the ETH 2.0 side (9-digit denomination)
     * @param _beaconValidators Number of validators visible in this epoch
     */
    function reportBeacon(
        uint256 _epochId,
        uint64 _beaconBalance,
        uint32 _beaconValidators
    ) external override {
        BeaconSpec memory beaconSpec = _getBeaconSpec();
        uint256 expectedEpoch = EXPECTED_EPOCH_ID_POSITION.getStorageUint256();
        require(_epochId >= expectedEpoch, "EPOCH_IS_TOO_OLD");

        // if expected epoch has advanced, check that this is the first epoch of the current frame
        // and clear the last unsuccessful reporting
        if (_epochId > expectedEpoch) {
            require(
                _epochId ==
                    _getFrameFirstEpochId(
                        _getCurrentEpochId(beaconSpec),
                        beaconSpec
                    ),
                "UNEXPECTED_EPOCH"
            );
            _clearReportingAndAdvanceTo(_epochId);
        }

        uint128 beaconBalanceEth1 = DENOMINATION_OFFSET *
            uint128(_beaconBalance);
        emit BeaconReported(
            _epochId,
            beaconBalanceEth1,
            _beaconValidators,
            msg.sender
        );

        // make sure the oracle is from members list and has not yet voted
        uint256 index = _getMemberId(msg.sender);
        require(index != MEMBER_NOT_FOUND, "MEMBER_NOT_FOUND");
        uint256 bitMask = REPORTS_BITMASK_POSITION.getStorageUint256();
        uint256 mask = 1 << index;
        require(bitMask & mask == 0, "ALREADY_SUBMITTED");
        REPORTS_BITMASK_POSITION.setStorageUint256(bitMask | mask);

        // push this report to the matching kind
        uint256 report = ReportUtils.encode(_beaconBalance, _beaconValidators);
        uint256 quorum = getQuorum();
        uint256 i = 0;

        // iterate on all report variants we already have, limited by the oracle members maximum
        while (
            i < currentReportVariants.length &&
            currentReportVariants[i].isDifferent(report)
        ) ++i;
        if (i < currentReportVariants.length) {
            if (currentReportVariants[i].getCount() + 1 >= quorum) {
                _push(
                    _epochId,
                    beaconBalanceEth1,
                    _beaconValidators,
                    beaconSpec
                );
            } else {
                ++currentReportVariants[i]; // increment report counter, see ReportUtils for details
            }
        } else {
            if (quorum == 1) {
                _push(
                    _epochId,
                    beaconBalanceEth1,
                    _beaconValidators,
                    beaconSpec
                );
            } else {
                currentReportVariants.push(report + 1);
            }
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
     * @notice Return whether the `_quorum` is reached and the final report
     */
    function _getQuorumReport(uint256 _quorum)
        internal
        view
        returns (bool isQuorum, uint256 report)
    {
        // check most frequent cases first: all reports are the same or no reports yet
        if (currentReportVariants.length == 1) {
            return (
                currentReportVariants[0].getCount() >= _quorum,
                currentReportVariants[0]
            );
        } else if (currentReportVariants.length == 0) {
            return (false, 0);
        }

        // if more than 2 kind of reports exist, choose the most frequent
        uint256 maxind = 0;
        uint256 repeat = 0;
        uint16 maxval = 0;
        uint16 cur = 0;
        for (uint256 i = 0; i < currentReportVariants.length; ++i) {
            cur = currentReportVariants[i].getCount();
            if (cur >= maxval) {
                if (cur == maxval) {
                    ++repeat;
                } else {
                    maxind = i;
                    maxval = cur;
                    repeat = 0;
                }
            }
        }
        return (
            maxval >= _quorum && repeat == 0,
            currentReportVariants[maxind]
        );
    }

    /**
     * @notice Set beacon specification data
     */
    function _setBeaconSpec(
        uint64 _epochsPerFrame,
        uint64 _slotsPerEpoch,
        uint64 _secondsPerSlot,
        uint64 _genesisTime
    ) internal {
        require(_epochsPerFrame > 0, "BAD_EPOCHS_PER_FRAME");
        require(_slotsPerEpoch > 0, "BAD_SLOTS_PER_EPOCH");
        require(_secondsPerSlot > 0, "BAD_SECONDS_PER_SLOT");
        require(_genesisTime > 0, "BAD_GENESIS_TIME");

        uint256 data = ((uint256(_epochsPerFrame) << 192) |
            (uint256(_slotsPerEpoch) << 128) |
            (uint256(_secondsPerSlot) << 64) |
            uint256(_genesisTime));
        BEACON_SPEC_POSITION.setStorageUint256(data);
        emit BeaconSpecSet(
            _epochsPerFrame,
            _slotsPerEpoch,
            _secondsPerSlot,
            _genesisTime
        );
    }

    /**
     * @notice Push the given report to LightNode and performs accompanying accounting
     * @param _epochId Beacon chain epoch, proven to be >= expected epoch and <= current epoch
     * @param _beaconBalanceEth1 Validators balance in eth1 (18-digit denomination)
     * @param _beaconSpec current beacon specification data
     */
    function _push(
        uint256 _epochId,
        uint128 _beaconBalanceEth1,
        uint128 _beaconValidators,
        BeaconSpec memory _beaconSpec
    ) internal {
        emit Completed(_epochId, _beaconBalanceEth1, _beaconValidators);

        // now this frame is completed, so the expected epoch should be advanced to the first epoch
        // of the next frame
        _clearReportingAndAdvanceTo(_epochId + _beaconSpec.epochsPerFrame);

        // report to the Node and collect stats
        ILightNode lightNode = getLightNode();
        uint256 prevTotalPooledEther = lightNode.totalSupply();
        lightNode.handleOracleReport(_beaconValidators, _beaconBalanceEth1);
        uint256 postTotalPooledEther = lightNode.totalSupply();

        PRE_COMPLETED_TOTAL_POOLED_ETHER_POSITION.setStorageUint256(
            prevTotalPooledEther
        );
        POST_COMPLETED_TOTAL_POOLED_ETHER_POSITION.setStorageUint256(
            postTotalPooledEther
        );
        uint256 timeElapsed = (_epochId -
            LAST_COMPLETED_EPOCH_ID_POSITION.getStorageUint256()) *
            _beaconSpec.slotsPerEpoch *
            _beaconSpec.secondsPerSlot;
        TIME_ELAPSED_POSITION.setStorageUint256(timeElapsed);
        LAST_COMPLETED_EPOCH_ID_POSITION.setStorageUint256(_epochId);

        // rollback on boundaries violation
        _reportSanityChecks(
            postTotalPooledEther,
            prevTotalPooledEther,
            timeElapsed
        );

        // emit detailed statistics and call the quorum delegate with this data
        emit PostTotalShares(
            postTotalPooledEther,
            prevTotalPooledEther,
            timeElapsed,
            lightNode.getTotalShares()
        );
        
        IBeaconReportReceiver receiver = IBeaconReportReceiver(
            BEACON_REPORT_RECEIVER_POSITION.getStorageAddress()
        );
        if (address(receiver) != address(0)) {
            receiver.processOracleReport(
                postTotalPooledEther,
                prevTotalPooledEther,
                timeElapsed
            );
        }
    }

    /**
     * @notice Remove the current reporting progress and advances to accept the later epoch `_epochId`
     */
    function _clearReportingAndAdvanceTo(uint256 _epochId) internal {
        REPORTS_BITMASK_POSITION.setStorageUint256(0);
        EXPECTED_EPOCH_ID_POSITION.setStorageUint256(_epochId);
        delete currentReportVariants;
        emit ExpectedEpochIdUpdated(_epochId);
    }

    /**
     * @notice Performs logical consistency check of the LightNode changes as the result of reports push
     * @dev To make oracles less dangerous, we limit rewards report by 10% _annual_ increase and 5%
     * _instant_ decrease in stake, with both values configurable by the governance in case of
     * extremely unusual circumstances.
     **/
    function _reportSanityChecks(
        uint256 _postTotalPooledEther,
        uint256 _preTotalPooledEther,
        uint256 _timeElapsed
    ) internal view {
        if (_postTotalPooledEther >= _preTotalPooledEther) {
            // increase                 = _postTotalPooledEther - _preTotalPooledEther,
            // relativeIncrease         = increase / _preTotalPooledEther,
            // annualRelativeIncrease   = relativeIncrease / (timeElapsed / 365 days),
            // annualRelativeIncreaseBp = annualRelativeIncrease * 10000, in basis points 0.01% (1e-4)
            uint256 allowedAnnualRelativeIncreaseBp = ALLOWED_BEACON_BALANCE_ANNUAL_RELATIVE_INCREASE_POSITION
                    .getStorageUint256();
            // check that annualRelativeIncreaseBp <= allowedAnnualRelativeIncreaseBp
            require(
                uint256(10000 * 365 days) *
                    (_postTotalPooledEther - _preTotalPooledEther) <=
                    allowedAnnualRelativeIncreaseBp *
                        (_preTotalPooledEther) *
                        (_timeElapsed),
                "ALLOWED_BEACON_BALANCE_INCREASE"
            );
        } else {
            // decrease           = _preTotalPooledEther - _postTotalPooledEther
            // relativeDecrease   = decrease / _preTotalPooledEther
            // relativeDecreaseBp = relativeDecrease * 10000, in basis points 0.01% (1e-4)
            uint256 allowedRelativeDecreaseBp = ALLOWED_BEACON_BALANCE_RELATIVE_DECREASE_POSITION
                    .getStorageUint256();
            // check that relativeDecreaseBp <= allowedRelativeDecreaseBp
            require(
                uint256(10000) *
                    (_preTotalPooledEther - _postTotalPooledEther) <=
                    allowedRelativeDecreaseBp * (_preTotalPooledEther),
                "ALLOWED_BEACON_BALANCE_DECREASE"
            );
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

    /**
     * @notice Return the epoch calculated from current timestamp
     */
    function _getCurrentEpochId(BeaconSpec memory _beaconSpec)
        internal
        view
        returns (uint256)
    {
        return
            (_getTime() - _beaconSpec.genesisTime) /
            (_beaconSpec.slotsPerEpoch * _beaconSpec.secondsPerSlot);
    }

    /**
     * @notice Return the first epoch of the frame that `_epochId` belongs to
     */
    function _getFrameFirstEpochId(
        uint256 _epochId,
        BeaconSpec memory _beaconSpec
    ) internal pure returns (uint256) {
        return
            (_epochId / _beaconSpec.epochsPerFrame) *
            _beaconSpec.epochsPerFrame;
    }

    /**
     * @notice Return the current timestamp
     */
    function _getTime() internal view virtual returns (uint256) {
        return block.timestamp;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

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
        _checkRole(role);
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
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
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
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ILightNode.sol";

/**
 * @title ETH 2.0 -> ETH oracle
 *
 * The goal of the oracle is to inform other parts of the system about balances controlled by the
 * DAO on the ETH 2.0 side. The balances can go up because of reward accumulation and can go down
 * because of slashing.
 */
interface IOracle {
    event AllowedBeaconBalanceAnnualRelativeIncreaseSet(uint256 value);
    event AllowedBeaconBalanceRelativeDecreaseSet(uint256 value);
    event BeaconReportReceiverSet(address callback);
    event MemberAdded(address member);
    event MemberRemoved(address member);
    event QuorumChanged(uint256 quorum);
    event ExpectedEpochIdUpdated(uint256 epochId);
    event BeaconSpecSet(
        uint64 epochsPerFrame,
        uint64 slotsPerEpoch,
        uint64 secondsPerSlot,
        uint64 genesisTime
    );
    event BeaconReported(
        uint256 epochId,
        uint128 beaconBalance,
        uint128 beaconValidators,
        address caller
    );
    event Completed(
        uint256 epochId,
        uint128 beaconBalance,
        uint128 beaconValidators
    );
    event PostTotalShares(
        uint256 postTotalPooledEther,
        uint256 preTotalPooledEther,
        uint256 timeElapsed,
        uint256 totalShares
    );
    event ContractVersionSet(uint256 version);

    /**
     * @notice Return the Staking contract address
     */
    function getLightNode() external view returns (ILightNode);

    /**
     * @notice Return the number of exactly the same reports needed to finalize the epoch
     */
    function getQuorum() external view returns (uint256);

    /**
     * @notice Return the upper bound of the reported balance possible increase in APR
     */
    function getAllowedBeaconBalanceAnnualRelativeIncrease()
        external
        view
        returns (uint256);

    /**
     * @notice Return the lower bound of the reported balance possible decrease
     */
    function getAllowedBeaconBalanceRelativeDecrease()
        external
        view
        returns (uint256);

    /**
     * @notice Set the upper bound of the reported balance possible increase in APR to `_value`
     */
    function setAllowedBeaconBalanceAnnualRelativeIncrease(uint256 _value)
        external;

    /**
     * @notice Set the lower bound of the reported balance possible decrease to `_value`
     */
    function setAllowedBeaconBalanceRelativeDecrease(uint256 _value) external;

    /**
     * @notice Return the receiver contract address to be called when the report is pushed to LightNode
     */
    function getBeaconReportReceiver() external view returns (address);

    /**
     * @notice Set the receiver contract address to be called when the report is pushed to LightNode
     */
    function setBeaconReportReceiver(address _addr) external;

    /**
     * @notice Return the current reporting bitmap, representing oracles who have already pushed
     * their version of report during the expected epoch
     */
    function getCurrentOraclesReportStatus() external view returns (uint256);

    /**
     * @notice Return the current reporting array size
     */
    function getCurrentReportVariantsSize() external view returns (uint256);

    /**
     * @notice Return the current reporting array element with the given index
     */
    function getCurrentReportVariant(uint256 _index)
        external
        view
        returns (
            uint64 beaconBalance,
            uint32 beaconValidators,
            uint16 count
        );

    /**
     * @notice Return epoch that can be reported by oracles
     */
    function getExpectedEpochId() external view returns (uint256);

    /**
     * @notice Return the current oracle member committee list
     */
    function getOracleMembers() external view returns (address[] memory);

    /**
     * @notice Return the initialized version of this contract starting from 0
     */
    function getVersion() external view returns (uint256);

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
        );

    /**
     * Updates beacon specification data
     */
    function setBeaconSpec(
        uint64 _epochsPerFrame,
        uint64 _slotsPerEpoch,
        uint64 _secondsPerSlot,
        uint64 _genesisTime
    ) external;

    /**
     * Returns the epoch calculated from current timestamp
     */
    function getCurrentEpochId() external view returns (uint256);

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
        );

    /**
     * @notice Return last completed epoch
     */
    function getLastCompletedEpochId() external view returns (uint256);

    /**
     * @notice Report beacon balance and its change during the last frame
     */
    function getLastCompletedReportDelta()
        external
        view
        returns (
            uint256 postTotalPooledEther,
            uint256 preTotalPooledEther,
            uint256 timeElapsed
        );

    /**
     * @notice Initialize the contract v2 data, with sanity check bounds
     * (`_allowedBeaconBalanceAnnualRelativeIncrease`, `_allowedBeaconBalanceRelativeDecrease`)
     * @dev Original initialize function removed from v2 because it is invoked only once
     */
    function initialize_v2(
        uint256 _allowedBeaconBalanceAnnualRelativeIncrease,
        uint256 _allowedBeaconBalanceRelativeDecrease
    ) external;

    /**
     * @notice Add `_member` to the oracle member committee list
     */
    function addOracleMember(address _member) external;

    /**
     * @notice Remove '_member` from the oracle member committee list
     */
    function removeOracleMember(address _member) external;

    /**
     * @notice Set the number of exactly the same reports needed to finalize the epoch to `_quorum`
     */
    function setQuorum(uint256 _quorum) external;

    /**
     * @notice Accept oracle committee member reports from the ETH 2.0 side
     * @param _epochId Beacon chain epoch
     * @param _beaconBalance Balance in gwei on the ETH 2.0 side (9-digit denomination)
     * @param _beaconValidators Number of validators visible in this epoch
     */
    function reportBeacon(
        uint256 _epochId,
        uint64 _beaconBalance,
        uint32 _beaconValidators
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
  * @title Interface for Liquid staking pool
  *
  * For the high-level description of the pool operation please refer to the paper.
  * Pool manages withdrawal keys and fees. It receives ether submitted by users on the ETH 1 side
  * and stakes it via the deposit_contract.sol contract. It doesn't hold ether on it's balance,
  * only a small portion (buffer) of it.
  * It also mints new tokens for rewards generated at the ETH 2.0 side.
  *
  * At the moment withdrawals are not possible in the beacon chain and there's no workaround.
  * Pool will be upgraded to an actual implementation when withdrawals are enabled
  */
interface ILightNode {
    function totalSupply() external view returns (uint256);
    function getTotalShares() external view returns (uint256);

    /**
      * @notice Pause pool routine operations
      */
    function pause() external;

    /**
      * @notice Unpause pool routine operations
      */
    function unpause() external;

    /**
      * @notice Stops accepting new Ether to the protocol
      *
      * @dev While accepting new Ether is stopped, calls to the `submit` function,
      * as well as to the default payable function, will revert.
      *
      * Emits `StakingPaused` event.
      */
    function pauseStaking() external;

    /**
      * @notice Resumes accepting new Ether to the protocol (if `pauseStaking` was called previously)
      * NB: Staking could be rate-limited by imposing a limit on the stake amount
      * at each moment in time, see `setStakingLimit()` and `removeStakingLimit()`
      *
      * @dev Preserves staking limit if it was set previously
      *
      * Emits `StakingResumed` event
      */
    function resumeStaking() external;

    /**
      * @notice Sets the staking rate limit
      *
      * @dev Reverts if:
      * - `_maxStakeLimit` == 0
      * - `_maxStakeLimit` >= 2^96
      * - `_maxStakeLimit` < `_stakeLimitIncreasePerBlock`
      * - `_maxStakeLimit` / `_stakeLimitIncreasePerBlock` >= 2^32 (only if `_stakeLimitIncreasePerBlock` != 0)
      *
      * Emits `StakingLimitSet` event
      *
      * @param _maxStakeLimit max stake limit value
      * @param _stakeLimitIncreasePerBlock stake limit increase per single block
      */
    function setStakingLimit(uint256 _maxStakeLimit, uint256 _stakeLimitIncreasePerBlock) external;

    /**
      * @notice Removes the staking rate limit
      *
      * Emits `StakingLimitRemoved` event
      */
    function removeStakingLimit() external;

    /**
      * @notice Check staking state: whether it's paused or not
      */
    function isStakingPaused() external view returns (bool);

    /**
      * @notice Returns how much Ether can be staked in the current block
      * @dev Special return values:
      * - 2^256 - 1 if staking is unlimited;
      * - 0 if staking is paused or if limit is exhausted.
      */
    function getCurrentStakeLimit() external view returns (uint256);

    /**
      * @notice Returns full info about current stake limit params and state
      * @dev Might be used for the advanced integration requests.
      * @return isStakingPaused staking pause state (equivalent to return of isStakingPaused())
      * @return isStakingLimitSet whether the stake limit is set
      * @return currentStakeLimit current stake limit (equivalent to return of getCurrentStakeLimit())
      * @return maxStakeLimit max stake limit
      * @return maxStakeLimitGrowthBlocks blocks needed to restore max stake limit from the fully exhausted state
      * @return prevStakeLimit previously reached stake limit
      * @return prevStakeBlockNumber previously seen block number
      */
    function getStakeLimitFullInfo() external view returns (
        bool isStakingPaused,
        bool isStakingLimitSet,
        uint256 currentStakeLimit,
        uint256 maxStakeLimit,
        uint256 maxStakeLimitGrowthBlocks,
        uint256 prevStakeLimit,
        uint256 prevStakeBlockNumber
    );

    /* event Stopped();
    event Resumed();

    event StakingPaused();
    event StakingResumed();
    event StakingLimitSet(uint256 maxStakeLimit, uint256 stakeLimitIncreasePerBlock);
    event StakingLimitRemoved(); */

    /**
      * @notice Set LightNode protocol contracts (oracle, treasury, insurance fund).
      * @param _oracle oracle contract
      * @param _treasury treasury contract
      * @param _insuranceFund insurance fund contract
      */
    function setProtocolContracts(
        address _oracle,
        address _treasury,
        address _insuranceFund
    ) external;

    // event ProtocolContactsSet(address oracle, address treasury, address insuranceFund);

    /**
      * @notice Set fee rate to `_feeBasisPoints` basis points.
      * The fees are accrued when:
      * - oracles report staking results (beacon chain balance increase)
      * - validators gain execution layer rewards (priority fees and MEV)
      * @param _feeBasisPoints Fee rate, in basis points
      */
    function setFee(uint16 _feeBasisPoints) external;

    /**
      * @notice Set fee distribution
      * @param _treasuryFeeBasisPoints basis points go to the treasury,
      * @param _insuranceFeeBasisPoints basis points go to the insurance fund,
      * @param _operatorsFeeBasisPoints basis points go to node operators.
      * @dev The sum has to be 10 000.
      */
    function setFeeDistribution(
        uint16 _treasuryFeeBasisPoints,
        uint16 _insuranceFeeBasisPoints,
        uint16 _operatorsFeeBasisPoints
    ) external;

    /**
      * @notice Returns staking rewards fee rate
      */
    function getFee() external view returns (uint16 feeBasisPoints);

    /**
      * @notice Returns fee distribution proportion
      */
    function getFeeDistribution() external view returns (
        uint16 treasuryFeeBasisPoints,
        uint16 insuranceFeeBasisPoints,
        uint16 operatorsFeeBasisPoints
    );

    // event FeeSet(uint16 feeBasisPoints);

    // event FeeDistributionSet(uint16 treasuryFeeBasisPoints, uint16 insuranceFeeBasisPoints, uint16 operatorsFeeBasisPoints);

    /**
      * @notice A payable function supposed to be called only by ExecutionLayerRewardsVault contract
      * @dev We need a dedicated function because funds received by the default payable function
      * are treated as a user deposit
      */
    function receiveELRewards() external payable;

    // The amount of ETH withdrawn from ExecutionLayerRewardsVault contract to LightNode contract
    // event ELRewardsReceived(uint256 amount);

    /**
      * @dev Sets limit on amount of ETH to withdraw from execution layer rewards vault per Oracle report
      * @param _limitPoints limit in basis points to amount of ETH to withdraw per Oracle report
      */
    function setELRewardsWithdrawalLimit(uint16 _limitPoints) external;

    // Percent in basis points of total pooled ether allowed to withdraw from ExecutionLayerRewardsVault per Oracle report
    // event ELRewardsWithdrawalLimitSet(uint256 limitPoints);

    /**
      * @notice Set credentials to withdraw ETH on ETH 2.0 side after the phase 2 is launched to `_withdrawalCredentials`
      * @dev Note that setWithdrawalCredentials discards all unused signing keys as the signatures are invalidated.
      * @param _withdrawalCredentials withdrawal credentials field as defined in the Ethereum PoS consensus specs
      */
    function setWithdrawalCredentials(bytes32 _withdrawalCredentials) external;

    /**
      * @notice Returns current credentials to withdraw ETH on ETH 2.0 side after the phase 2 is launched
      */
    function getWithdrawalCredentials() external view returns (bytes32);

    // event WithdrawalCredentialsSet(bytes32 withdrawalCredentials);

    /**
      * @dev Sets the address of ExecutionLayerRewardsVault contract
      * @param _executionLayerRewardsVault Execution layer rewards vault contract address
      */
    function setELRewardsVault(address _executionLayerRewardsVault) external;

    // The `executionLayerRewardsVault` was set as the execution layer rewards vault for LightNode
    // event ELRewardsVaultSet(address executionLayerRewardsVault);

    /**
      * @notice Ether on the ETH 2.0 side reported by the oracle
      * @param _epoch Epoch id
      * @param _eth2balance Balance in wei on the ETH 2.0 side
      */
    function handleOracleReport(uint256 _epoch, uint256 _eth2balance) external;


    // User functions

    /**
      * @notice Adds eth to the pool
      * @return StETH Amount of StETH generated
      */
    function submit(address _referral) external payable returns (uint256 StETH);

    // Records a deposit made by a user
    // event Submitted(address indexed sender, uint256 amount, address referral);

    // The `amount` of ether was sent to the deposit_contract.deposit function
    // event Unbuffered(uint256 amount);

    // Requested withdrawal of `etherAmount` to `pubkeyHash` on the ETH 2.0 side, `tokenAmount` burned by `sender`,
    // `sentFromBuffer` was sent on the current Ethereum side.
    /* event Withdrawal(address indexed sender, uint256 tokenAmount, uint256 sentFromBuffer,
                     bytes32 indexed pubkeyHash, uint256 etherAmount); */


    // Info functions

    /**
      * @notice Gets the amount of Ether controlled by the system
      */
    function getTotalPooledEther() external view returns (uint256);

    /**
      * @notice Gets the amount of Ether temporary buffered on this contract balance
      */
    function getBufferedEther() external view returns (uint256);

    /**
      * @notice Returns the key values related to Beacon-side
      * @return depositedValidators - number of deposited validators
      * @return beaconValidators - number of LightNode's validators visible in the Beacon state, reported by oracles
      * @return beaconBalance - total amount of Beacon-side Ether (sum of all the balances of LightNode validators)
      */
    function getBeaconStat() external view returns (uint256 depositedValidators, uint256 beaconValidators, uint256 beaconBalance);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
  * @title Interface defining a callback that the quorum will call on every quorum reached
  */
interface IBeaconReportReceiver {
    /**
      * @notice Callback to be called by the oracle contract upon the quorum is reached
      * @param _postTotalPooledEther total pooled ether on LightNode right after the quorum value was reported
      * @param _preTotalPooledEther total pooled ether on LightNode right before the quorum value was reported
      * @param _timeElapsed time elapsed in seconds between the last and the previous quorum
      */
    function processOracleReport(
      uint256 _postTotalPooledEther, 
      uint256 _preTotalPooledEther, 
      uint256 _timeElapsed
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library UnstructuredStorage {
    function getStorageBool(bytes32 position)
        internal
        view
        returns (bool data)
    {
        assembly {
            data := sload(position)
        }
    }

    function getStorageAddress(bytes32 position)
        internal
        view
        returns (address data)
    {
        assembly {
            data := sload(position)
        }
    }

    function getStorageBytes32(bytes32 position)
        internal
        view
        returns (bytes32 data)
    {
        assembly {
            data := sload(position)
        }
    }

    function getStorageUint256(bytes32 position)
        internal
        view
        returns (uint256 data)
    {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * Utility functions for effectively storing reports within a single storage slot
 *
 * +00 | uint16 | count            | 0..256  | number of reports received exactly like this
 * +16 | uint32 | beaconValidators | 0..1e9  | number of LightNode's validators in beacon chain
 * +48 | uint64 | beaconBalance    | 0..1e18 | total amout of their balance
 *
 * Note that the 'count' is the leftmost field here. Thus it is possible to apply addition
 * operations to it when it is encoded, provided that you watch for the overflow.
 */
library ReportUtils {
    uint256 constant internal COUNT_OUTMASK = 0xFFFFFFFFFFFFFFFFFFFFFFFF0000;

    function encode(uint64 beaconBalance, uint32 beaconValidators) internal pure returns (uint256) {
        return uint256(beaconBalance) << 48 | uint256(beaconValidators) << 16;
    }

    function decode(uint256 value) internal pure returns (uint64 beaconBalance, uint32 beaconValidators) {
        beaconBalance = uint64(value >> 48);
        beaconValidators = uint32(value >> 16);
    }

    function decodeWithCount(uint256 value)
        internal pure
        returns (
            uint64 beaconBalance,
            uint32 beaconValidators,
            uint16 count
        ) {
        beaconBalance = uint64(value >> 48);
        beaconValidators = uint32(value >> 16);
        count = uint16(value);
    }

    /// @notice Check if the given reports are different, not considering the counter of the first
    function isDifferent(uint256 value, uint256 that) internal pure returns(bool) {
        return (value & COUNT_OUTMASK) != that;
    }

    function getCount(uint256 value) internal pure returns(uint16) {
        return uint16(value);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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