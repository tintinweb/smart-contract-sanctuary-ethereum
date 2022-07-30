// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IExamContract.sol";

contract ExamContract is IExamContract {
    address public immutable admin;

    //SubjectID -> Subject
    mapping(uint256 => Subject) public subjects;

    //StudentAddress -> StudentId
    mapping(address => uint256) public studentIds;

    //StudentID -> (SubjectID, subjectCareer)
    mapping(uint256 => StudentCareer) public careers;

    constructor() {
        admin = msg.sender;
    }

    //region modifiers
    modifier onlyAdmin() {
        if (msg.sender != admin) revert UnauthorizedAdminError(admin, msg.sender);
        _;
    }

    modifier isAuthorizedProf(uint256 subjectId) {
        if (!subjects[subjectId].authorizedProf[msg.sender])
            revert UnauthorizedProfessorError(subjectId, msg.sender);
        _;
    }

    modifier testExists(uint256 subjectId, uint8 testIdx) {
        if (testIdx >= subjects[subjectId].tests.length)
            revert TestDoesNotExistsError(subjectId, testIdx);
        _;
    }

    //endregion

    function isProfAuthorized(uint256 subjectId, address profAddr) external view returns (bool) {
        return subjects[subjectId].authorizedProf[profAddr];
    }

    //region onlyAdmin methods
    function addStudent(address addr, uint256 id) external onlyAdmin {
        if (studentIds[addr] != 0) {
            revert AddressAlreadyInUseError(addr);
        }
        studentIds[addr] = id;
    }

    function deleteStudent(address addr) external onlyAdmin {
        studentIds[addr] = 0;
    }

    function addSubject(
        uint256 subjectId,
        string calldata name,
        uint8 cfu,
        uint8 requiredCount,
        uint256[] calldata subjectIdToUnlock
    ) external onlyAdmin {
        Subject storage subject = subjects[subjectId];
        subject.name = name;
        subject.cfu = cfu;
        subject.requiredCount = requiredCount;
        subject.subjectIdToUnlock = subjectIdToUnlock;
    }

    function addAuthorizedProf(uint256 subjectId, address profAddr) external onlyAdmin {
        if (!subjects[subjectId].authorizedProf[profAddr]) {
            subjects[subjectId].authorizedProf[profAddr] = true;
            emit AuthorizedProfAdded(subjectId, profAddr);
        }
    }

    function removeAuthorizedProf(uint256 subjectId, address profAddr) external onlyAdmin {
        subjects[subjectId].authorizedProf[profAddr] = false;
        emit AuthorizedProfRemoved(subjectId, profAddr);
    }

    //endregion

    //region getters
    function getTestResult(
        uint256 studentId,
        uint256 subjectId,
        uint8 testIdx
    ) private view returns (TestResult storage) {
        return careers[studentId].subjectResults[subjectId].testResults[testIdx];
    }

    function getTestMark(
        uint256 subjectId,
        uint8 testIdx,
        uint256 studentId
    ) external view testExists(subjectId, testIdx) returns (uint8, Status) {
        TestResult storage result = getTestResult(studentId, subjectId, testIdx);
        return (result.mark, result.testStatus);
    }

    function getSubjectMark(uint256 subjectId, uint256 studentId)
        external
        view
        returns (uint8, Status)
    {
        return (
            careers[studentId].subjectResults[subjectId].mark,
            careers[studentId].subjectResults[subjectId].subjectStatus
        );
    }

    function getSubjectTests(uint256 subjectId) external view returns (Test[] memory) {
        return subjects[subjectId].tests;
    }

    //endregion

    //region test methods
    function checkTestDependencies(
        uint256 subjectId,
        uint8 testIdx,
        uint256 studentId
    ) private returns (bool) {
        uint8[][] storage deps = subjects[subjectId].tests[testIdx].testIdxRequired;
        if (
            careers[studentId].subjectResults[subjectId].testResults[testIdx].testStatus ==
            Status.Accepted
        ) return false;

        if (deps.length == 0) return true;

        for (uint256 i = 0; i < deps.length; i++) {
            bool valid = true;
            for (uint256 j = 0; j < deps[i].length; j++) {
                uint8 dep = deps[i][j];
                TestResult storage depResult = getTestResult(studentId, subjectId, dep);
                if (
                    depResult.testStatus == Status.NoVote || block.timestamp > depResult.expiration
                ) {
                    valid = false;
                    break;
                }
                if (depResult.testStatus == Status.Passed) {
                    depResult.testStatus = Status.Accepted;
                    emit TestAccepted(subjectId, dep, studentId, depResult.mark);
                }
            }
            if (valid) return true;
        }
        return false;
    }

    function failTest(
        uint256 subjectId,
        uint8 testIdx,
        uint256 studentId
    ) private {
        TestResult storage test = getTestResult(studentId, subjectId, testIdx);
        test.mark = 0;
        test.testStatus = Status.NoVote;
        uint8[] storage reset = subjects[subjectId].tests[testIdx].testIdxReset;
        for (uint8 i = 0; i < reset.length; i++) {
            TestResult storage testToReset = getTestResult(studentId, subjectId, reset[i]);
            testToReset.testStatus = Status.NoVote;
        }
    }

    function resetTestOnTake(
        uint256 subjectId,
        uint8 testIdx,
        uint256 studentId
    ) private {
        uint8[] storage reset = subjects[subjectId].tests[testIdx].testIdxResetOnTake;
        for (uint8 i = 0; i < reset.length; i++) {
            TestResult storage t = getTestResult(studentId, subjectId, reset[i]);
            t.testStatus = Status.NoVote;
        }
    }

    function passTest(
        uint256 subjectId,
        uint8 testIdx,
        uint256 studentId,
        uint8 mark
    ) private {
        uint256 expiration = block.timestamp + subjects[subjectId].tests[testIdx].expiresIn;
        TestResult storage result = getTestResult(studentId, subjectId, testIdx);
        result.mark = mark;
        result.testStatus = Status.Passed;
        result.expiration = expiration;
    }

    function registerTestResults(
        uint256 subjectId,
        uint8 testIdx,
        StudentMark[] calldata testResults
    ) external isAuthorizedProf(subjectId) testExists(subjectId, testIdx) {
        uint8 minMark = subjects[subjectId].tests[testIdx].minMark;
        for (uint256 i = 0; i < testResults.length; i++) {
            resetTestOnTake(subjectId, testIdx, testResults[i].studentId);
            if (testResults[i].mark < minMark) {
                failTest(subjectId, testIdx, testResults[i].studentId);
                emit TestFailed(subjectId, testIdx, testResults[i].studentId, testResults[i].mark);
            } else if (checkTestDependencies(subjectId, testIdx, testResults[i].studentId)) {
                passTest(subjectId, testIdx, testResults[i].studentId, testResults[i].mark);
                emit TestPassed(subjectId, testIdx, testResults[i].studentId, testResults[i].mark);
            } else {
                emit MissingTestRequirements(subjectId, testIdx, testResults[i].studentId);
            }
        }
    }

    function rejectTestResult(uint256 subjectId, uint8 testIdx)
        external
        testExists(subjectId, testIdx)
    {
        uint256 studentId = studentIds[msg.sender];
        if (
            careers[studentId].subjectResults[subjectId].testResults[testIdx].testStatus ==
            Status.Accepted
        ) {
            revert TestAlreadyAcceptedError(subjectId, testIdx, studentId);
        }
        failTest(subjectId, testIdx, studentId);
        emit TestRejected(subjectId, testIdx, studentId);
    }

    //endregion

    function setSubjectTests(uint256 subjectId, Test[] calldata tests)
        external
        isAuthorizedProf(subjectId)
    {
        Subject storage subject = subjects[subjectId];
        delete subject.tests;
        for (uint256 i = 0; i < tests.length; i++) {
            subject.tests.push(tests[i]);
        }
    }

    //region subject methods

    function checkSubjectDependencies(uint256 subjectId, uint256 studentId)
        private
        view
        returns (bool)
    {
        return (careers[studentId].subjectResults[subjectId].unlockCounter >=
            subjects[subjectId].requiredCount &&
            careers[studentId].subjectResults[subjectId].subjectStatus != Status.Accepted);
    }

    function registerSubjectResults(uint256 subjectId, StudentMark[] calldata subjectResults)
        external
        isAuthorizedProf(subjectId)
    {
        for (uint256 i = 0; i < subjectResults.length; i++) {
            bool valid = checkSubjectDependencies(subjectId, subjectResults[i].studentId);
            if (!valid) {
                emit MissingSubjectRequrements(subjectId, subjectResults[i].studentId);
                continue;
            }
            SubjectResults storage result = careers[subjectResults[i].studentId].subjectResults[
                subjectId
            ];
            result.mark = subjectResults[i].mark;
            result.subjectStatus = Status.Passed;
            emit SubjectPassed(subjectId, subjectResults[i].studentId, subjectResults[i].mark);
        }
    }

    function acceptSubjectResult(uint256 subjectId) external {
        uint256 studentId = studentIds[msg.sender];
        SubjectResults storage subjectResult = careers[studentId].subjectResults[subjectId];
        if (subjectResult.subjectStatus == Status.NoVote) {
            revert SubjectNotAcceptableError(subjectId, studentId);
        }
        if (subjectResult.subjectStatus == Status.Accepted) {
            revert SubjectAlreadyAcceptedError(subjectId, studentId);
        }

        uint256[] storage toUnlock = subjects[subjectId].subjectIdToUnlock;
        for (uint256 i = 0; i < toUnlock.length; i++) {
            careers[studentId].subjectResults[toUnlock[i]].unlockCounter++;
        }
        subjectResult.subjectStatus = Status.Accepted;
        emit SubjectAccepted(subjectId, studentId, subjectResult.mark);
    }

    function resetSubjectResults(uint256 subjectId) internal {
        uint256 studentId = studentIds[msg.sender];
        for (uint8 i = 0; i < subjects[subjectId].tests.length; i++) {
            delete careers[studentId].subjectResults[subjectId].testResults[i];
        }
        delete careers[studentId].subjectResults[subjectId];
    }

    function resetSubject(uint256 subjectId) external {
        uint256 studentId = studentIds[msg.sender];
        SubjectResults storage subjectResult = careers[studentId].subjectResults[subjectId];

        if (subjectResult.subjectStatus == Status.Accepted) {
            revert SubjectAlreadyAcceptedError(subjectId, studentId);
        }
        resetSubjectResults(subjectId);
        emit SubjectResetted(subjectId, studentId);
    }
    //endregion
}