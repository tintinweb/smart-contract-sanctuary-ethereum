// SPDX-License-Identifier: MIT License
pragma solidity ^0.8.15;

error notParty();
error notJudge();
error notJudgeOrParty();
error notValidWinner();
error notDecisionMaker();

contract Arbit {
    enum Status {
        Open,
        Closed,
        Judging,
        Rejected
    }
    enum DecisionMaker {
        Party1,
        Party2,
        Judge
    }

    struct Case {
        address party1;
        address party2;
        address judge;
        string description;
        string[] tags;
        DecisionMaker decisionMaker;
        mapping(address => bool) approvals;
        Status status;
        string caseRuling;
        address winner;
    }

    event CaseOpened(
        uint256 indexed caseId,
        address party1,
        address indexed party2,
        address indexed judge,
        string description,
        string[] tags
    );
    event CaseApproved(
        uint256 indexed caseId,
        address indexed approver,
        address indexed nextApprover
    );
    event CaseEdited(
        uint256 indexed caseId,
        address indexed editor,
        address indexed newJudge,
        string description,
        string[] tags
    );
    event CaseRejected(uint256 indexed caseId, address indexed rejecter);
    event CaseJudging(uint256 indexed caseId, address indexed judge);
    event CaseClosed(
        uint256 indexed caseId,
        address indexed winner,
        string indexed caseRuling
    );

    mapping(uint256 => Case) cases;
    uint256 internal caseIdCounter = 0;
    modifier isParty(uint256 caseId) {
        if (
            cases[caseId].party1 != msg.sender &&
            cases[caseId].party2 != msg.sender
        ) {
            revert notParty();
        }
        _;
    }
    modifier isJudge(uint256 caseId) {
        if (cases[caseId].judge != msg.sender) {
            revert notJudge();
        }
        _;
    }
    modifier isJudgeOrParty(uint256 caseId) {
        if (
            cases[caseId].judge != msg.sender &&
            cases[caseId].party1 != msg.sender &&
            cases[caseId].party2 != msg.sender
        ) {
            revert notJudgeOrParty();
        }
        _;
    }
    modifier isValidWinner(uint256 caseId, address winner) {
        if (cases[caseId].party1 != winner && cases[caseId].party2 != winner) {
            revert notValidWinner();
        }
        _;
    }
    modifier isDecisionMaker(uint256 caseId) {
        if (
            (cases[caseId].decisionMaker == DecisionMaker.Judge &&
                cases[caseId].judge != msg.sender) ||
            (cases[caseId].decisionMaker == DecisionMaker.Party1 &&
                cases[caseId].party1 != msg.sender) ||
            (cases[caseId].decisionMaker == DecisionMaker.Party2 &&
                cases[caseId].party2 != msg.sender)
        ) {
            revert notDecisionMaker();
        }
        _;
    }

    function openCase(
        address party2,
        address judge,
        string memory description,
        string[] memory tags
    ) public returns (uint256 caseId) {
        caseId = caseIdCounter;
        Case storage case_ = cases[caseId];
        case_.party1 = msg.sender;
        case_.party2 = party2;
        case_.judge = judge;
        case_.description = description;
        case_.tags = tags;
        case_.caseRuling = "";
        case_.approvals[msg.sender] = true;
        case_.status = Status.Open;
        case_.winner = address(0x0);
        emit CaseOpened(
            caseId,
            case_.party1,
            case_.party2,
            case_.judge,
            description,
            tags
        );
        caseIdCounter++;
        case_.decisionMaker = DecisionMaker.Party2;
        return caseId;
    }

    function closeCase(
        uint256 caseId,
        address caseWinner,
        string memory caseRuling
    ) public isJudge(caseId) isValidWinner(caseId, caseWinner) {
        Case storage case_ = cases[caseId];
        case_.status = Status.Closed;
        case_.winner = caseWinner;
        case_.caseRuling = caseRuling;
        emit CaseClosed(caseId, case_.winner, case_.caseRuling);
    }

    function editCase(
        uint256 caseId,
        address newJudge,
        string memory description,
        string[] memory tags
    ) public isParty(caseId) isDecisionMaker(caseId) {
        Case storage case_ = cases[caseId];
        case_.approvals[msg.sender] = true;
        if (case_.decisionMaker == DecisionMaker.Party1) {
            case_.decisionMaker = DecisionMaker.Party2;
            case_.approvals[case_.party2] = false;
        } else {
            case_.decisionMaker = DecisionMaker.Party1;
            case_.approvals[case_.party1] = false;
        }
        case_.description = description;
        case_.tags = tags;
        case_.judge = newJudge;
        case_.approvals[case_.judge] = false;
        emit CaseEdited(caseId, msg.sender, case_.judge, description, tags);
    }

    function approveCase(uint256 caseId)
        public
        isJudgeOrParty(caseId)
        isDecisionMaker(caseId)
    {
        Case storage case_ = cases[caseId];
        case_.approvals[msg.sender] = true;
        address nextApprover = address(0x0);
        if (case_.approvals[case_.party1] && case_.approvals[case_.party2]) {
            case_.decisionMaker = DecisionMaker.Judge;
            nextApprover = case_.judge;
        } else if (case_.decisionMaker == DecisionMaker.Party1) {
            case_.decisionMaker = DecisionMaker.Party2;
            nextApprover = case_.party2;
        } else {
            case_.decisionMaker = DecisionMaker.Party1;
            nextApprover = case_.party1;
        }
        emit CaseApproved(caseId, msg.sender, nextApprover);
    }

    function judgeCase(uint256 caseId)
        public
        isJudge(caseId)
        isDecisionMaker(caseId)
    {
        Case storage case_ = cases[caseId];
        if (
            case_.decisionMaker == DecisionMaker.Judge &&
            case_.approvals[case_.party1] &&
            case_.approvals[case_.party2]
        ) {
            case_.status = Status.Judging;
            case_.approvals[case_.judge] = true;
        }
        emit CaseJudging(caseId, msg.sender);
    }

    function rejectCase(uint256 caseId)
        public
        isJudgeOrParty(caseId)
        isDecisionMaker(caseId)
    {
        Case storage case_ = cases[caseId];
        if (case_.status == Status.Open) {
            case_.status = Status.Rejected;
            emit CaseRejected(caseId, msg.sender);
        }
    }

    function getCaseInfo(uint256 caseId)
        external
        view
        returns (
            address party1,
            address party2,
            address judge,
            string memory caseDescription,
            string[] memory tags,
            string memory caseRuling,
            address winner,
            Status,
            DecisionMaker,
            bool approvedByParty1,
            bool approvedByParty2,
            bool approvedByJudge
        )
    {
        Case storage case_ = cases[caseId];
        return (
            case_.party1,
            case_.party2,
            case_.judge,
            case_.description,
            case_.tags,
            case_.caseRuling,
            case_.winner,
            case_.status,
            case_.decisionMaker,
            case_.approvals[case_.party1],
            case_.approvals[case_.party2],
            case_.approvals[case_.judge]
        );
    }
}