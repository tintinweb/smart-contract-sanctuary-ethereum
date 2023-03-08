// SPDX-License-Identifier: APACHE-2.0
pragma solidity 0.8.19;

import "./ICensorshipOracle.sol";

contract CensorshipOraclePOC is ICensorshipOracle {
    uint256 public constant BASE = 100; // 100%
    uint256 public constant POS_BLOCK_TIME = 12;
    mapping(bytes32 => TestInfo) public tests;

    error AlreadyFinished();
    error TooSoon();

    event TestStarted(bytes32 indexed testId, uint256 percentNoncensoringValidators, uint256 inverseConfidenceLevel);
    event TestFinished(bytes32 indexed testId, bool nonCensoredBlockWasIncluded);

    function testParameters(uint256 percentNoncensoringValidators, uint256 inverseConfidenceLevel)
        public
        pure
        returns (
            uint256, // test duration
            uint256 // max missing blocks allowing test to pass
        )
    {
        if (percentNoncensoringValidators == 10 && inverseConfidenceLevel == 1_000_000) {
            return (688, 34);
        } else if (percentNoncensoringValidators == 10 && inverseConfidenceLevel == 1_000_000) {
            return (225, 4);
        } else {
            revert("NOT_IMPLEMENTED");
        }
    }

    function startTest(uint256 percentNoncensoringValidators, uint256 inverseConfidenceLevel)
        external
        returns (bytes32, uint256, uint256)
    {
        (uint256 durationBlocks, uint256 maxMissBlock) =
            testParameters(percentNoncensoringValidators, inverseConfidenceLevel);
        bytes32 testId = keccak256(
            abi.encodePacked(block.number, block.timestamp, percentNoncensoringValidators, inverseConfidenceLevel)
        );
        tests[testId] = TestInfo({
            percentNoncensoringValidators: percentNoncensoringValidators,
            inverseConfidenceLevel: inverseConfidenceLevel,
            testStartTimestamp: block.timestamp,
            testResultAvailableTimestamp: block.timestamp + durationBlocks * POS_BLOCK_TIME,
            testHasFinished: false,
            nonCensoredBlockWasIncluded: false,
            testStartBlock: block.number
        });
        emit TestStarted(testId, percentNoncensoringValidators, inverseConfidenceLevel);
        return (testId, durationBlocks, maxMissBlock);
    }

    function getTestInfo(bytes32 testId)
        public
        view
        returns (
            uint256, // percent non-censoring validators
            uint256, // inverse confidence level
            uint256, // test start timestamp
            uint256, // test result available timestamp
            bool, // test has finished
            bool // (test has finished) && (non-censored block was included)
        )
    {
        return (
            tests[testId].percentNoncensoringValidators,
            tests[testId].inverseConfidenceLevel,
            tests[testId].testStartTimestamp,
            tests[testId].testResultAvailableTimestamp,
            tests[testId].testHasFinished,
            tests[testId].testHasFinished && tests[testId].nonCensoredBlockWasIncluded
        );
    }

    function finishAndGetTestInfo(bytes32 testId)
        external
        returns (
            uint256, // percent non-censoring validators
            uint256, // inverse confidence level
            uint256, // test start timestamp
            uint256, // test result available timestamp
            bool, // test has finished (will be false if result not available yet)
            bool // (test has finished) && (non-censored block was included)
        )
    {
        TestInfo storage test = tests[testId];
        if (test.testHasFinished) {
            revert AlreadyFinished();
        }
        if (block.timestamp < test.testResultAvailableTimestamp) {
            revert TooSoon();
        }
        (uint256 durationBlocks, uint256 maxMissBlock) =
            testParameters(test.percentNoncensoringValidators, test.inverseConfidenceLevel);
        uint256 numBlocks = block.number - test.testStartBlock;
        if (numBlocks + maxMissBlock >= durationBlocks) {
            test.nonCensoredBlockWasIncluded = true;
        }
        test.testHasFinished = true;
        emit TestFinished(testId, test.nonCensoredBlockWasIncluded);
        return getTestInfo(testId);
    }
}

// SPDX-License-Identifier: APACHE-2.0
pragma solidity 0.8.19;

struct TestInfo {
    uint256 percentNoncensoringValidators;
    uint256 inverseConfidenceLevel;
    uint256 testStartTimestamp;
    uint256 testResultAvailableTimestamp;
    bool testHasFinished;
    bool nonCensoredBlockWasIncluded;
    uint256 testStartBlock;
}

// https://ethresear.ch/t/reducing-challenge-times-in-rollups/14997
interface ICensorshipOracle {
    function testParameters(uint256 percentNoncensoringValidators, uint256 inverseConfidenceLevel)
        external
        pure
        returns (
            uint256, // test duration
            uint256
        ); // max missing blocks allowing test to pass

    function startTest(uint256 percentNoncensoringValidators, uint256 inverseConfidenceLevel)
        external
        returns (bytes32, uint256, uint256);

    function getTestInfo(bytes32 testId)
        external
        view
        returns (
            uint256, // percent non-censoring validators
            uint256, // inverse confidence level
            uint256, // test start timestamp
            uint256, // test result available timestamp
            bool, // test has finished
            bool
        ); // (test has finished) && (non-censored block was included)

    function finishAndGetTestInfo(bytes32 testId)
        external
        returns (
            uint256, // percent non-censoring validators
            uint256, // inverse confidence level
            uint256, // test start timestamp
            uint256, // test result available timestamp
            bool, // test has finished (will be false if result not available yet)
            bool
        ); // (test has finished) && (non-censored block was included)
}