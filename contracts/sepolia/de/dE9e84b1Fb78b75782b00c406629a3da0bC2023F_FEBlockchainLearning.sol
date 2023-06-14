// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../interfaces/ITrainerManagement.sol";
import "../interfaces/IAdminControl.sol";

contract FEBlockchainLearning {
    // Sessions
    enum RoundStatus {
        Ready,
        Training,
        Scoring,
        Aggregating,
        End
    }
    struct trainUpdate {
        address trainerAddress;
        uint256 updateId;
    }

    struct scoreObject {
        uint256 accuracy;
        uint256 loss;
        uint256 precision;
        uint256 recall;
        uint256 f1;
    }

    struct scoreUpdate {
        address scorerAddress;
        mapping(address => scoreObject) candidateAddressToScoreObject;
    }
    struct aggregateUpdate {
        address aggregatorAddress;
        uint256 updateId;
    }

    struct sessionDetail {
        uint256 sessionId;
        uint256 round;
        uint256 currentRound;
        uint256 globalModelId;
        uint256 latestGlobalModelParamId;
        RoundStatus status;
        address[] trainerAddresses;
        mapping(uint256 => aggregateUpdate) roundToAggregatorAddress;
        mapping(uint256 => mapping(address => mapping(address => scoreObject))) roundToScorerToCandidateToScoreObj;
        mapping(uint256 => trainUpdate[]) roundToUpdateObject;
    }

    // Management System
    mapping(uint256 => sessionDetail) private _sessionIdToSessionDetail;

    ITrainerManagement private _trainerManagement;
    IAdminControl private _adminControl;

    modifier onlyAdmin(address account) {
        require(_adminControl.isAdmin(account) == true, "You are not admin");
        _;
    }

    constructor(address _trainerManagementAddress, address adminControl) {
        _trainerManagement = ITrainerManagement(_trainerManagementAddress);
        _adminControl = IAdminControl(adminControl);
    }

    // Utils
    function _isATrainerOfTheSession(
        address submiter,
        uint256 sessionId
    ) private view returns (bool) {
        return _trainerManagement.isAllowed(submiter, sessionId);
    }

    function _checkTrainerSubmitted(
        address submiter,
        uint256 sessionId
    ) private view returns (bool) {
        uint256 currentRound = _sessionIdToSessionDetail[sessionId]
            .currentRound;
        trainUpdate[] memory allUpdateThisRound = _sessionIdToSessionDetail[
            sessionId
        ].roundToUpdateObject[currentRound];
        for (uint256 i = 0; i < allUpdateThisRound.length; i++) {
            if (
                allUpdateThisRound[i].trainerAddress == submiter &&
                allUpdateThisRound[i].updateId != 0
            ) {
                return true;
            }
        }
        return false;
    }

    function _checkAllTrainerSubmitted(
        uint256 sessionId
    ) private view returns (bool) {
        uint256 currentRound = _sessionIdToSessionDetail[sessionId]
            .currentRound;
        trainUpdate[] memory allUpdateThisRound = _sessionIdToSessionDetail[
            sessionId
        ].roundToUpdateObject[currentRound];
        if (
            allUpdateThisRound.length ==
            _sessionIdToSessionDetail[sessionId].trainerAddresses.length
        ) {
            return true;
        }
        return false;
    }

    function _checkScorerSubmitted(
        address scorerAdrress,
        uint256 sessionId,
        address candidate
    ) private view returns (bool) {
        uint256 currentRound = _sessionIdToSessionDetail[sessionId]
            .currentRound;
        scoreObject memory _scoreObj = _sessionIdToSessionDetail[sessionId]
            .roundToScorerToCandidateToScoreObj[currentRound][scorerAdrress][
                candidate
            ];
        if (
            _scoreObj.accuracy != 0 ||
            _scoreObj.loss != 0 ||
            _scoreObj.precision != 0 ||
            _scoreObj.recall != 0 ||
            _scoreObj.f1 != 0
        ) {
            return true;
        }
        return false;
    }

    function scoreDecimals() external pure returns (uint8) {
        return 5;
    }

    // Management System
    function initializeSession(
        uint256 sessionId,
        uint256 round,
        uint256 globalModelId,
        uint256 latestGlobalModelParamId,
        address[] memory trainerAddresses
    ) external {
        for (uint256 i = 0; i < trainerAddresses.length; i++) {
            require(
                _trainerManagement.isBlocked(trainerAddresses[i]) == false,
                "Trainer is blocked"
            );
            require(
                _trainerManagement.isAllowed(trainerAddresses[i], sessionId) == true,
                "Trainer is not allowed"
            );
        }
        sessionDetail storage sDetail = _sessionIdToSessionDetail[sessionId];
        sDetail.sessionId = sessionId;
        sDetail.round = round;
        sDetail.currentRound = 0;
        sDetail.globalModelId = globalModelId;
        sDetail.latestGlobalModelParamId = latestGlobalModelParamId;
        sDetail.status = RoundStatus.Ready;
        sDetail.trainerAddresses = trainerAddresses;
    }

    // Session Implement
    function getStatusTrainer() external view returns(uint256, bool){
        (uint256 sessionId, bool isActive) = _trainerManagement.getTrainerDetail(msg.sender);
        return (sessionId, _sessionIdToSessionDetail[sessionId].status == RoundStatus.Training && isActive);
    }
    function startRound(uint256 sessionId) external {
        RoundStatus currentStatus = _sessionIdToSessionDetail[sessionId].status;
        require(
            currentStatus == RoundStatus.Ready,
            "Session is not ready to start"
        );
        _nextRound(sessionId);
        // emit event
    }

    function _nextRound(uint256 sessionId) internal {
        _sessionIdToSessionDetail[sessionId].currentRound++;
        _sessionIdToSessionDetail[sessionId].status = RoundStatus.Training;
    }

    function submitUpdate(uint256 sessionId, uint256 update_id) external {
        require(
            _sessionIdToSessionDetail[sessionId].status == RoundStatus.Training,
            "Cannot submit update when session is not in state training"
        );
        require(
            _isATrainerOfTheSession(msg.sender, sessionId),
            "You are not a trainer of this session"
        );
        require(
            !(_checkTrainerSubmitted(msg.sender, sessionId)),
            "You submitted before"
        );
        trainUpdate memory newUpdate = trainUpdate(msg.sender, update_id);
        uint256 currentRound = _sessionIdToSessionDetail[sessionId]
            .currentRound;
        _sessionIdToSessionDetail[sessionId]
            .roundToUpdateObject[currentRound]
            .push(newUpdate);
        if (_checkAllTrainerSubmitted(sessionId)) {
            _startScoring(sessionId);
        }
        // emit event
    }

    function _startScoring(uint256 sessionId) private {
        RoundStatus currentStatus = _sessionIdToSessionDetail[sessionId].status;
        require(
            currentStatus == RoundStatus.Training,
            "Session is not ready to score"
        );
        _sessionIdToSessionDetail[sessionId].status = RoundStatus.Scoring;
        // emit event
    }

    function submitScore(
        uint256 sessionId,
        uint256[] memory scores,
        address candidateAddress
    ) external {
        require(
            _sessionIdToSessionDetail[sessionId].status == RoundStatus.Scoring,
            "Cannot submit update when session is not in state Scoring"
        );
        require(
            _isATrainerOfTheSession(msg.sender, sessionId),
            "You are not a trainer of this session"
        );
        require(
            _isATrainerOfTheSession(candidateAddress, sessionId),
            "Candidate is not a trainer of this session"
        );
        require(
            !(_checkScorerSubmitted(msg.sender, sessionId, candidateAddress)),
            "Submited before"
        );
        uint256 currentRound = _sessionIdToSessionDetail[sessionId]
            .currentRound;
        // check submit before
        require(scores.length == 5, "Missing scores");
        scoreObject memory _scoreObj = scoreObject(
            scores[0],
            scores[1],
            scores[2],
            scores[3],
            scores[4]
        );
        _sessionIdToSessionDetail[sessionId].roundToScorerToCandidateToScoreObj[
            currentRound
        ][msg.sender][candidateAddress] = _scoreObj;
        // check all submitted scores
        if (_checkAllScorerSubmitted(sessionId)) {
            _startAggregate(sessionId, currentRound);
        }
    }

    function _checkAllScorerSubmitted(
        uint256 sessionId
    ) private view returns (bool) {
        address[] memory trainerAddresses = _sessionIdToSessionDetail[sessionId]
            .trainerAddresses;
        for (uint256 i = 0; i < trainerAddresses.length; i++) {
            for (uint256 j = 0; j < trainerAddresses.length; j++) {
                if (i == j) {
                    continue;
                }
                if (
                    _checkScorerSubmitted(
                        trainerAddresses[i],
                        sessionId,
                        trainerAddresses[j]
                    ) == false
                ) {
                    return false;
                }
            }
        }
        return true;
    }

    function _startAggregate(uint256 sessionId, uint256 currentRound) private {
        RoundStatus currentStatus = _sessionIdToSessionDetail[sessionId].status;
        require(
            currentStatus == RoundStatus.Scoring,
            "Session is not ready to score"
        );
        _sessionIdToSessionDetail[sessionId].status = RoundStatus.Aggregating;
        // choose aggregator (base on round)
        address aggregator = _sessionIdToSessionDetail[sessionId]
            .trainerAddresses[currentRound - 1];
        aggregateUpdate memory aggregateUpdateObj;
        aggregateUpdateObj.aggregatorAddress = aggregator;
        _sessionIdToSessionDetail[sessionId].roundToAggregatorAddress[
            currentRound
        ] = aggregateUpdateObj;
        // emit event
    }
    function _resetTrainerStatus(uint256 sessionId) private {
        for (uint256 i = 0; i < _sessionIdToSessionDetail[sessionId].trainerAddresses.length; i++){
            address trainer = _sessionIdToSessionDetail[sessionId].trainerAddresses[i];
            _trainerManagement.reset(trainer);
        }
    }
    function submitAggregate(uint256 sessionId, uint256 updateId) external {
        require(
            _sessionIdToSessionDetail[sessionId].status ==
                RoundStatus.Aggregating,
            "Cannot submit update when session is not in state Aggregating"
        );
        // check if this msg.sender is aggregator
        uint256 currentRound = _sessionIdToSessionDetail[sessionId]
            .currentRound;
        require(
            _sessionIdToSessionDetail[sessionId]
                .roundToAggregatorAddress[currentRound]
                .aggregatorAddress == msg.sender,
            "You are not aggregator"
        );
        _sessionIdToSessionDetail[sessionId]
            .roundToAggregatorAddress[currentRound]
            .updateId = updateId;
        // check end of session
        if (_sessionIdToSessionDetail[sessionId].round == currentRound) {
            _endSession(sessionId);
        } else {
            // next round
            _nextRound(sessionId);
        }
    }

    function _endSession(uint256 sessionId) private {
        RoundStatus currentStatus = _sessionIdToSessionDetail[sessionId].status;
        require(
            currentStatus == RoundStatus.Aggregating,
            "Session is not ready to end"
        );
        _sessionIdToSessionDetail[sessionId].status = RoundStatus.End;
        _resetTrainerStatus(sessionId);
        // emit event
    }

    function getCurrentRound(
        uint256 sessionId
    ) external view returns (uint256) {
        return _sessionIdToSessionDetail[sessionId].currentRound;
    }

    function getCurrentStatus(
        uint256 sessionId
    ) external view returns (RoundStatus) {
        return _sessionIdToSessionDetail[sessionId].status;
    }

    function getAggregator(uint256 sessionId) external view returns (address) {
        uint256 currentRound = _sessionIdToSessionDetail[sessionId]
            .currentRound;
        return
            _sessionIdToSessionDetail[sessionId]
                .roundToAggregatorAddress[currentRound]
                .aggregatorAddress;
    }

    function fetchRoundData(uint256 sessionId, uint256 round) external view {
        // TODO: handle logic here
    }

    function fetchSessionData(uint256 sessionId) external view {
        // TODO: handle logic here
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IAdminControl {
    function isAdmin(address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ITrainerManagement {
    function setFebl(address febd) external;
    function isBlocked(address trainer) external view returns (bool);
    function isAllowed(address trainer, uint256 sessionId) external view returns (bool);
    function getTrainerDetail(address trainer) external view returns(uint256, bool);
    function reset(address trainer) external;
}