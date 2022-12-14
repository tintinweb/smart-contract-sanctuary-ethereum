// SPDX-FileCopyrightText: 2022 Lido <[email protected]>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import { ERC165Checker } from "@openzeppelin/contracts-v4.4/utils/introspection/ERC165Checker.sol";
import { AccessControlEnumerable } from "@openzeppelin/contracts-v4.4/access/AccessControlEnumerable.sol";

import "./CommitteeQuorum.sol";
import "./ReportEpochChecker.sol";
import "./interfaces/ILido.sol";
import "./interfaces/IBeaconReportReceiver.sol";


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
contract LidoOracleNew is CommitteeQuorum, AccessControlEnumerable, ReportEpochChecker {
    using ERC165Checker for address;
    using UnstructuredStorage for bytes32;

    event AllowedBeaconBalanceAnnualRelativeIncreaseSet(uint256 value);
    event AllowedBeaconBalanceRelativeDecreaseSet(uint256 value);
    event BeaconReportReceiverSet(address callback);

    event CommitteeMemberReported(
        uint256 epochId,
        uint256 beaconBalance,
        uint256 beaconValidators,
        address caller,
        uint256 wcBufferedEther,
        uint256[] requestIdToFinalizeUpTo,
        uint256[] finalizationPooledEtherAmount,
        uint256[] finalizationSharesAmount
    );

    event ConsensusReached(
        uint256 epochId,
        uint256 beaconBalance,
        uint256 beaconValidators,
        uint256 wcBufferedEther,
        uint256[] requestIdToFinalizeUpTo,
        uint256[] finalizationPooledEtherAmount,
        uint256[] finalizationSharesAmount
    );

    event PostTotalShares(
         uint256 postTotalPooledEther,
         uint256 preTotalPooledEther,
         uint256 timeElapsed,
         uint256 totalShares
    );

    event ContractVersionSet(uint256 version);


    struct MemberReport {
        // Consensus info
        uint256 epochId;
        // CL values
        uint256 beaconValidators;
        uint64 beaconBalanceGwei;
        uint256[] stakingModuleIds;
        uint256[] nodeOperatorsWithExitedValidators;
        uint64[] exitedValidatorsNumbers;
        // EL values
        uint256 wcBufferedEther;
        // decision
        uint256 newDepositBufferWithdrawalsReserve;
        uint256[] requestIdToFinalizeUpTo;
        uint256[] finalizationPooledEtherAmount;
        uint256[] finalizationSharesAmount;
    }

    /// ACL
    bytes32 constant public MANAGE_MEMBERS_ROLE = keccak256("MANAGE_MEMBERS_ROLE");
    bytes32 constant public MANAGE_QUORUM_ROLE = keccak256("MANAGE_QUORUM_ROLE");
    bytes32 constant public SET_BEACON_SPEC_ROLE = keccak256("SET_BEACON_SPEC_ROLE");
    bytes32 constant public SET_REPORT_BOUNDARIES_ROLE = keccak256("SET_REPORT_BOUNDARIES_ROLE");
    bytes32 constant public SET_BEACON_REPORT_RECEIVER_ROLE = keccak256("SET_BEACON_REPORT_RECEIVER_ROLE");

    /// Eth1 denomination is 18 digits, while Eth2 has 9 digits. Because we work with Eth2
    /// balances and to support old interfaces expecting eth1 format, we multiply by this
    /// coefficient.
    uint128 internal constant DENOMINATION_OFFSET = 1e9;

    /// Historic data about 2 last completed reports and their times
    bytes32 internal constant POST_COMPLETED_TOTAL_POOLED_ETHER_POSITION =
        0xaa8433b13d2b111d4f84f6f374bc7acbe20794944308876aa250fa9a73dc7f53; // keccak256("lido.LidoOracle.postCompletedTotalPooledEther")
    bytes32 internal constant PRE_COMPLETED_TOTAL_POOLED_ETHER_POSITION =
        0x1043177539af09a67d747435df3ff1155a64cd93a347daaac9132a591442d43e; // keccak256("lido.LidoOracle.preCompletedTotalPooledEther")
    bytes32 internal constant LAST_COMPLETED_EPOCH_ID_POSITION =
        0xdad15c0beecd15610092d84427258e369d2582df22869138b4c5265f049f574c; // keccak256("lido.LidoOracle.lastCompletedEpochId")
    bytes32 internal constant TIME_ELAPSED_POSITION =
        0x8fe323f4ecd3bf0497252a90142003855cc5125cee76a5b5ba5d508c7ec28c3a; // keccak256("lido.LidoOracle.timeElapsed")

    /// Address of the Lido contract
    bytes32 internal constant LIDO_POSITION =
        0xf6978a4f7e200f6d3a24d82d44c48bddabce399a3b8ec42a480ea8a2d5fe6ec5; // keccak256("lido.LidoOracle.lido")

    /// Version of the initialized contract data
    /// NB: Contract versioning starts from 1.
    /// The version stored in CONTRACT_VERSION_POSITION equals to
    /// - 0 right after deployment when no initializer is invoked yet
    /// - N after calling initialize() during deployment from scratch, where N is the current contract version
    /// - N after upgrading contract from the previous version (after calling finalize_vN())
    bytes32 internal constant CONTRACT_VERSION_POSITION =
        0x75be19a3f314d89bd1f84d30a6c84e2f1cd7afc7b6ca21876564c265113bb7e4; // keccak256("lido.LidoOracle.contractVersion")

    /// Receiver address to be called when the report is pushed to Lido
    bytes32 internal constant BEACON_REPORT_RECEIVER_POSITION =
        0xb59039ed37776bc23c5d272e10b525a957a1dfad97f5006c84394b6b512c1564; // keccak256("lido.LidoOracle.beaconReportReceiver")

    /// Upper bound of the reported balance possible increase in APR, controlled by the governance
    bytes32 internal constant ALLOWED_BEACON_BALANCE_ANNUAL_RELATIVE_INCREASE_POSITION =
        0x613075ab597bed8ce2e18342385ce127d3e5298bc7a84e3db68dc64abd4811ac; // keccak256("lido.LidoOracle.allowedBeaconBalanceAnnualRelativeIncrease")

    /// Lower bound of the reported balance possible decrease, controlled by the governance
    ///
    /// @notice When slashing happens, the balance may decrease at a much faster pace. Slashing are
    /// one-time events that decrease the balance a fair amount - a few percent at a time in a
    /// realistic scenario. Thus, instead of sanity check for an APR, we check if the plain relative
    /// decrease is within bounds.  Note that it's not annual value, its just one-jump value.
    bytes32 internal constant ALLOWED_BEACON_BALANCE_RELATIVE_DECREASE_POSITION =
        0x92ba7776ed6c5d13cf023555a94e70b823a4aebd56ed522a77345ff5cd8a9109; // keccak256("lido.LidoOracle.allowedBeaconBalanceDecrease")


    /**
     * @notice Initialize the contract (version 3 for now) from scratch
     * @dev For details see https://github.com/lidofinance/lido-improvement-proposals/blob/develop/LIPS/lip-10.md
     * @param _admin Admin which can modify OpenZeppelin role holders
     * @param _lido Address of Lido contract
     * @param _epochsPerFrame Number of epochs per frame
     * @param _slotsPerEpoch Number of slots per epoch
     * @param _secondsPerSlot Number of seconds per slot
     * @param _genesisTime Genesis time
     * @param _allowedBeaconBalanceAnnualRelativeIncrease Allowed beacon balance annual relative increase (e.g. 1000 means 10% increase)
     * @param _allowedBeaconBalanceRelativeDecrease Allowed beacon balance instantaneous decrease (e.g. 500 means 5% decrease)
     */
    function initialize(
        address _admin,
        address _lido,
        uint64 _epochsPerFrame,
        uint64 _slotsPerEpoch,
        uint64 _secondsPerSlot,
        uint64 _genesisTime,
        uint256 _allowedBeaconBalanceAnnualRelativeIncrease,
        uint256 _allowedBeaconBalanceRelativeDecrease
    )
        external
    {
        assert(1 == ((1 << (MAX_MEMBERS - 1)) >> (MAX_MEMBERS - 1)));  // static assert

        // We consider storage state right after deployment (no initialize() called yet) as version 0

        // Initializations for v0 --> v1
        if (CONTRACT_VERSION_POSITION.getStorageUint256() != 0) {
            revert CanInitializeOnlyOnZeroVersion();
        }
        if (_admin == address(0)) { revert ZeroAdminAddress(); }

        CONTRACT_VERSION_POSITION.setStorageUint256(1);
        emit ContractVersionSet(1);

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);

        LIDO_POSITION.setStorageAddress(_lido);

        _setQuorum(1);

        ALLOWED_BEACON_BALANCE_ANNUAL_RELATIVE_INCREASE_POSITION
            .setStorageUint256(_allowedBeaconBalanceAnnualRelativeIncrease);
        emit AllowedBeaconBalanceAnnualRelativeIncreaseSet(_allowedBeaconBalanceAnnualRelativeIncrease);

        ALLOWED_BEACON_BALANCE_RELATIVE_DECREASE_POSITION
            .setStorageUint256(_allowedBeaconBalanceRelativeDecrease);
        emit AllowedBeaconBalanceRelativeDecreaseSet(_allowedBeaconBalanceRelativeDecrease);

        _setBeaconSpec(_epochsPerFrame, _slotsPerEpoch, _secondsPerSlot, _genesisTime);

        // set expected epoch to the first epoch for the next frame
        _setExpectedEpochToFirstOfNextFrame();
    }

    /**
     * @notice Return the Lido contract address
     */
    function getLido() public view returns (ILido) {
        return ILido(LIDO_POSITION.getStorageAddress());
    }

    /**
     * @notice Return the upper bound of the reported balance possible increase in APR
     */
    function getAllowedBeaconBalanceAnnualRelativeIncrease() external view returns (uint256) {
        return ALLOWED_BEACON_BALANCE_ANNUAL_RELATIVE_INCREASE_POSITION.getStorageUint256();
    }

    /**
     * @notice Return the lower bound of the reported balance possible decrease
     */
    function getAllowedBeaconBalanceRelativeDecrease() external view returns (uint256) {
        return ALLOWED_BEACON_BALANCE_RELATIVE_DECREASE_POSITION.getStorageUint256();
    }

    /**
     * @notice Set the upper bound of the reported balance possible increase in APR to `_value`
     */
    function setAllowedBeaconBalanceAnnualRelativeIncrease(uint256 _value)
        external onlyRole(SET_BEACON_REPORT_RECEIVER_ROLE)
    {
        ALLOWED_BEACON_BALANCE_ANNUAL_RELATIVE_INCREASE_POSITION.setStorageUint256(_value);
        emit AllowedBeaconBalanceAnnualRelativeIncreaseSet(_value);
    }

    /**
     * @notice Set the lower bound of the reported balance possible decrease to `_value`
     */
    function setAllowedBeaconBalanceRelativeDecrease(uint256 _value)
        external onlyRole(SET_REPORT_BOUNDARIES_ROLE)
    {
        ALLOWED_BEACON_BALANCE_RELATIVE_DECREASE_POSITION.setStorageUint256(_value);
        emit AllowedBeaconBalanceRelativeDecreaseSet(_value);
    }

    /**
     * @notice Return the receiver contract address to be called when the report is pushed to Lido
     */
    function getBeaconReportReceiver() external view returns (address) {
        return BEACON_REPORT_RECEIVER_POSITION.getStorageAddress();
    }

    /**
     * @notice Return the current reporting array element with index `_index`
     */
    function getMemberReport(uint256 _index)
        external
        view
        returns (
            MemberReport memory report
        )
    {
        report = _decodeReport(distinctReports[_index]);
    }

    /**
     * @notice Set the receiver contract address to `_addr` to be called when the report is pushed
     * @dev Specify 0 to disable this functionality
     */
    function setBeaconReportReceiver(address _addr)
        external onlyRole(SET_BEACON_REPORT_RECEIVER_ROLE)
    {
        if(_addr != address(0)) {
            IBeaconReportReceiver iBeacon;
            if (!_addr.supportsInterface(iBeacon.processLidoOracleReport.selector)) {
                revert BadBeaconReportReceiver();
            }
        }

        BEACON_REPORT_RECEIVER_POSITION.setStorageAddress(_addr);
        emit BeaconReportReceiverSet(_addr);
    }

    /**
     * @notice Return the initialized version of this contract starting from 0
     */
    function getVersion() external view returns (uint256) {
        return CONTRACT_VERSION_POSITION.getStorageUint256();
    }

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
        )
    {
        postTotalPooledEther = POST_COMPLETED_TOTAL_POOLED_ETHER_POSITION.getStorageUint256();
        preTotalPooledEther = PRE_COMPLETED_TOTAL_POOLED_ETHER_POSITION.getStorageUint256();
        timeElapsed = TIME_ELAPSED_POSITION.getStorageUint256();
    }

    /**
     * @notice Return last completed epoch
     */
    function getLastCompletedEpochId() external view returns (uint256) {
        return LAST_COMPLETED_EPOCH_ID_POSITION.getStorageUint256();
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

    function handleCommitteeMemberReport(
        MemberReport calldata _report
    ) external {
        BeaconSpec memory beaconSpec = _getBeaconSpec();
        bool hasEpochAdvanced = _validateAndUpdateExpectedEpoch(_report.epochId, beaconSpec);
        if (hasEpochAdvanced) {
            _clearReporting();
        }

        if (_handleMemberReport(msg.sender, _encodeReport(_report))) {
            _handleConsensusReport(_report, beaconSpec);
        }

        uint128 beaconBalance = DENOMINATION_OFFSET * uint128(_report.beaconBalanceGwei);
        emit CommitteeMemberReported(
            _report.epochId,
            beaconBalance,
            _report.beaconValidators,
            msg.sender,
            _report.wcBufferedEther,
            _report.requestIdToFinalizeUpTo,
            _report.finalizationPooledEtherAmount,
            _report.finalizationSharesAmount
        );
    }

    function _decodeReport(bytes memory _reportData) internal pure returns (
        MemberReport memory report
    ) {
        report = abi.decode(_reportData, (MemberReport));
    }

    function _encodeReport(MemberReport memory _report) internal pure returns (
        bytes memory reportData
    ) {
        reportData = abi.encode(_report);
    }

    /**
     * @notice Set the number of exactly the same reports needed to finalize the epoch to `_quorum`
     */
    function updateQuorum(uint256 _quorum)
        external onlyRole(MANAGE_QUORUM_ROLE)
    {
        (bool isQuorum, uint256 reportIndex) = _updateQuorum(_quorum);
        if (isQuorum) {
            MemberReport memory report = _decodeReport(distinctReports[reportIndex]);
            _handleConsensusReport(report, _getBeaconSpec());
        }
    }

    /**
     * @notice Update beacon specification data
     */
    function setBeaconSpec(
        uint64 _epochsPerFrame,
        uint64 _slotsPerEpoch,
        uint64 _secondsPerSlot,
        uint64 _genesisTime
    )
        external onlyRole(SET_BEACON_SPEC_ROLE)
    {
        _setBeaconSpec(
            _epochsPerFrame,
            _slotsPerEpoch,
            _secondsPerSlot,
            _genesisTime
        );
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
        _grantRole(SET_REPORT_BOUNDARIES_ROLE, _rolesHolder);
        _grantRole(SET_BEACON_REPORT_RECEIVER_ROLE, _rolesHolder);
    }


    // /**
    //  * @notice Push the given report to Lido and performs accompanying accounting
    //  * @param _epochId Beacon chain epoch, proven to be >= expected epoch and <= current epoch
    //  * @param _beaconBalanceEth1 Validators balance in eth1 (18-digit denomination)
    //  * @param _beaconSpec current beacon specification data
    //  */
    function _handleConsensusReport(
        MemberReport memory _report,
        BeaconSpec memory _beaconSpec
    )
        internal
    {
        uint128 beaconBalance = DENOMINATION_OFFSET * uint128(_report.beaconBalanceGwei);

        // TODO: maybe add additional report validity sanity checks

        emit ConsensusReached(
            _report.epochId,
            beaconBalance,
            _report.beaconValidators,
            _report.wcBufferedEther,
            _report.requestIdToFinalizeUpTo,
            _report.finalizationPooledEtherAmount,
            _report.finalizationSharesAmount
        );

        // now this frame is completed, so the expected epoch should be advanced to the first epoch
        // of the next frame
        _advanceExpectedEpoch(_report.epochId + _beaconSpec.epochsPerFrame);
        _clearReporting();

        ILido lido = getLido();
        INodeOperatorsRegistry registry = lido.getOperators();
        for (uint256 i = 0; i < _report.exitedValidatorsNumbers.length; ++i) {
            registry.reportStoppedValidators(
                _report.nodeOperatorsWithExitedValidators[i],
                _report.exitedValidatorsNumbers[i]
            );
        }

        // report to the Lido and collect stats
        uint256 prevTotalPooledEther = lido.totalSupply();

        // TODO: report other values from MemberReport
        lido.handleOracleReport(
            _report.beaconValidators,
            beaconBalance,
            _report.wcBufferedEther,
            _report.newDepositBufferWithdrawalsReserve,
            _report.requestIdToFinalizeUpTo,
            _report.finalizationPooledEtherAmount,
            _report.finalizationSharesAmount
        );
        uint256 postTotalPooledEther = lido.totalSupply();

        _doWorkAfterReportingToLido(
            prevTotalPooledEther,
            postTotalPooledEther,
            _report.epochId,
            _beaconSpec
        );
    }


    function _doWorkAfterReportingToLido(
        uint256 _prevTotalPooledEther,
        uint256 _postTotalPooledEther,
        uint256 _epochId,
        BeaconSpec memory _beaconSpec
    ) internal {
        PRE_COMPLETED_TOTAL_POOLED_ETHER_POSITION.setStorageUint256(_prevTotalPooledEther);
        POST_COMPLETED_TOTAL_POOLED_ETHER_POSITION.setStorageUint256(_postTotalPooledEther);
        uint256 timeElapsed = (_epochId - LAST_COMPLETED_EPOCH_ID_POSITION.getStorageUint256()) *
            _beaconSpec.slotsPerEpoch * _beaconSpec.secondsPerSlot;
        TIME_ELAPSED_POSITION.setStorageUint256(timeElapsed);
        LAST_COMPLETED_EPOCH_ID_POSITION.setStorageUint256(_epochId);

        // rollback on boundaries violation
        _reportSanityChecks(_postTotalPooledEther, _prevTotalPooledEther, timeElapsed);

        // emit detailed statistics and call the quorum delegate with this data
        emit PostTotalShares(_postTotalPooledEther, _prevTotalPooledEther, timeElapsed, getLido().getTotalShares());
        IBeaconReportReceiver receiver = IBeaconReportReceiver(BEACON_REPORT_RECEIVER_POSITION.getStorageAddress());
        if (address(receiver) != address(0)) {
            receiver.processLidoOracleReport(_postTotalPooledEther, _prevTotalPooledEther, timeElapsed);
        }
    }

    /**
     * @notice Performs logical consistency check of the Lido changes as the result of reports push
     * @dev To make oracles less dangerous, we limit rewards report by 10% _annual_ increase and 5%
     * _instant_ decrease in stake, with both values configurable by the governance in case of
     * extremely unusual circumstances.
     **/
    function _reportSanityChecks(
        uint256 _postTotalPooledEther,
        uint256 _preTotalPooledEther,
        uint256 _timeElapsed)
        internal
        view
    {
        // TODO: update sanity checks
        if (_postTotalPooledEther >= _preTotalPooledEther) {
            // increase                 = _postTotalPooledEther - _preTotalPooledEther,
            // relativeIncrease         = increase / _preTotalPooledEther,
            // annualRelativeIncrease   = relativeIncrease / (timeElapsed / 365 days),
            // annualRelativeIncreaseBp = annualRelativeIncrease * 10000, in basis points 0.01% (1e-4)
            uint256 allowedAnnualRelativeIncreaseBp =
                ALLOWED_BEACON_BALANCE_ANNUAL_RELATIVE_INCREASE_POSITION.getStorageUint256();
            // check that annualRelativeIncreaseBp <= allowedAnnualRelativeIncreaseBp
            if (uint256(10000 * 365 days) * (_postTotalPooledEther - _preTotalPooledEther) >
                allowedAnnualRelativeIncreaseBp * _preTotalPooledEther * _timeElapsed)
            {
                revert AllowedBeaconBalanceIncreaseExceeded();
            }
        } else {
            // decrease           = _preTotalPooledEther - _postTotalPooledEther
            // relativeDecrease   = decrease / _preTotalPooledEther
            // relativeDecreaseBp = relativeDecrease * 10000, in basis points 0.01% (1e-4)
            uint256 allowedRelativeDecreaseBp =
                ALLOWED_BEACON_BALANCE_RELATIVE_DECREASE_POSITION.getStorageUint256();
            // check that relativeDecreaseBp <= allowedRelativeDecreaseBp
            if (uint256(10000) * (_preTotalPooledEther - _postTotalPooledEther) >
                allowedRelativeDecreaseBp * _preTotalPooledEther)
            {
                revert AllowedBeaconBalanceDecreaseExceeded();
            }
        }
    }

    error CanInitializeOnlyOnZeroVersion();
    error ZeroAdminAddress();
    error BadBeaconReportReceiver();
    error AllowedBeaconBalanceIncreaseExceeded();
    error AllowedBeaconBalanceDecreaseExceeded();

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
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

// SPDX-FileCopyrightText: 2020 Lido <[email protected]>

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;

interface INodeOperatorsRegistry {
    /**
      * @notice Report `_stoppedIncrement` more stopped validators of the node operator #`_id`
      */
    function reportStoppedValidators(uint256 _id, uint64 _stoppedIncrement) external;
}

/**
  * @title Liquid staking pool
  *
  * For the high-level description of the pool operation please refer to the paper.
  * Pool manages withdrawal keys and fees. It receives ether submitted by users on the ETH 1 side
  * and stakes it via the deposit_contract.sol contract. It doesn't hold ether on it's balance,
  * only a small portion (buffer) of it.
  * It also mints new tokens for rewards generated at the ETH 2.0 side.
  *
  * At the moment withdrawals are not possible in the beacon chain and there's no workaround.
  * Pool will be upgraded to an actual implementation when withdrawals are enabled
  * (Phase 1.5 or 2 of Eth2 launch, likely late 2022 or 2023).
  */
interface ILido {
    function totalSupply() external view returns (uint256);
    function getTotalShares() external view returns (uint256);

    /**
      * @notice Stop pool routine operations
      */
    function stop() external;

    /**
      * @notice Resume pool routine operations
      */
    function resume() external;

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

    event Stopped();
    event Resumed();

    event StakingPaused();
    event StakingResumed();
    event StakingLimitSet(uint256 maxStakeLimit, uint256 stakeLimitIncreasePerBlock);
    event StakingLimitRemoved();

    /**
      * @notice Set Lido protocol contracts (oracle, treasury, insurance fund).
      * @param _oracle oracle contract
      * @param _treasury treasury contract
      * @param _insuranceFund insurance fund contract
      */
    function setProtocolContracts(
        address _oracle,
        address _treasury,
        address _insuranceFund
    ) external;

    event ProtocolContactsSet(address oracle, address treasury, address insuranceFund);

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

    event FeeSet(uint16 feeBasisPoints);

    event FeeDistributionSet(uint16 treasuryFeeBasisPoints, uint16 insuranceFeeBasisPoints, uint16 operatorsFeeBasisPoints);

    /**
      * @notice A payable function supposed to be called only by LidoExecutionLayerRewardsVault contract
      * @dev We need a dedicated function because funds received by the default payable function
      * are treated as a user deposit
      */
    function receiveELRewards() external payable;

    // The amount of ETH withdrawn from LidoExecutionLayerRewardsVault contract to Lido contract
    event ELRewardsReceived(uint256 amount);

    /**
      * @dev Sets limit on amount of ETH to withdraw from execution layer rewards vault per LidoOracle report
      * @param _limitPoints limit in basis points to amount of ETH to withdraw per LidoOracle report
      */
    function setELRewardsWithdrawalLimit(uint16 _limitPoints) external;

    // Percent in basis points of total pooled ether allowed to withdraw from LidoExecutionLayerRewardsVault per LidoOracle report
    event ELRewardsWithdrawalLimitSet(uint256 limitPoints);

    /**
      * @notice Set credentials to withdraw ETH on ETH 2.0 side after the phase 2 is launched to `_withdrawalCredentials`
      * @dev Note that setWithdrawalCredentials discards all unused signing keys as the signatures are invalidated.
      * @param _withdrawalCredentials withdrawal credentials field as defined in the Ethereum PoS consensus specs
      */
    function setWithdrawalCredentials(bytes32 _withdrawalCredentials) external;

    /**
      * @notice Returns current credentials to withdraw ETH on ETH 2.0 side after the phase 2 is launched
      */
    function getWithdrawalCredentials() external view returns (bytes memory);

    event WithdrawalCredentialsSet(bytes32 withdrawalCredentials);

    /**
      * @dev Sets the address of LidoExecutionLayerRewardsVault contract
      * @param _executionLayerRewardsVault Execution layer rewards vault contract address
      */
    function setELRewardsVault(address _executionLayerRewardsVault) external;

    // The `executionLayerRewardsVault` was set as the execution layer rewards vault for Lido
    event ELRewardsVaultSet(address executionLayerRewardsVault);

    /**
     * @notice Ether on the ETH 2.0 side reported by the oracle
     */
    function handleOracleReport(
        // CL values
        uint256 _beaconValidators,
        uint256 _beaconBalance,
        // EL values
        uint256 _wcBufferedEther,
        // decision
        uint256 _withdrawalsReserveAmount,
        uint256[] calldata _requestIdToFinalizeUpTo,
        uint256[] calldata _finalizationPooledEtherAmount,
        uint256[] calldata _finalizationSharesAmount
    ) external;

    // User functions

    /**
      * @notice Adds eth to the pool
      * @return StETH Amount of StETH generated
      */
    function submit(address _referral) external payable returns (uint256 StETH);

    // Records a deposit made by a user
    event Submitted(address indexed sender, uint256 amount, address referral);

    // The `amount` of ether was sent to the deposit_contract.deposit function
    event Unbuffered(uint256 amount);

    // Withdrawal functions
    function requestWithdrawal(uint256 _amountOfStETH) external returns (uint256 requestId);

    function claimWithdrawal(uint256 _requestId, uint256 _priceIndexHint) external;

    function withdrawalRequestStatus(uint _requestId) external view returns (
        address recipient,
        uint256 requestBlockNumber,
        uint256 etherToWithdraw,
        bool isFinalized,
        bool isClaimed
    );

    function setBufferWithdrawalsReserve(uint256 _withdrawalsReserveAmount) external;

    event WithdrawalRequested(address indexed receiver, uint256 amountOfStETH, uint256 amountOfShares, uint256 requestId);

    event WithdrawalClaimed(uint256 indexed requestId, address indexed receiver, address initiator);

    event WithdrawalRestaked(uint256 amount);

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
      * @return beaconValidators - number of Lido's validators visible in the Beacon state, reported by oracles
      * @return beaconBalance - total amount of Beacon-side Ether (sum of all the balances of Lido validators)
      */
    function getBeaconStat() external view returns (uint256 depositedValidators, uint256 beaconValidators, uint256 beaconBalance);

    function getOperators() external view returns (INodeOperatorsRegistry);
}

// SPDX-FileCopyrightText: 2021 Lido <[email protected]>

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;

/**
  * @title Interface defining a callback that the quorum will call on every quorum reached
  */
interface IBeaconReportReceiver {
    /**
      * @notice Callback to be called by the oracle contract upon the quorum is reached
      * @param _postTotalPooledEther total pooled ether on Lido right after the quorum value was reported
      * @param _preTotalPooledEther total pooled ether on Lido right before the quorum value was reported
      * @param _timeElapsed time elapsed in seconds between the last and the previous quorum
      */
    function processLidoOracleReport(uint256 _postTotalPooledEther,
                                     uint256 _preTotalPooledEther,
                                     uint256 _timeElapsed) external;
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