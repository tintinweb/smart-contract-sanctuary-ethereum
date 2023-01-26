// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

interface LaborMarketConfigurationInterface {
    struct LaborMarketConfiguration {
        string marketUri;
        Modules modules;
        BadgePair delegate;
        BadgePair maintainer;
        BadgePair reputation;
        uint256 signalStake;
        uint256 submitMin;
        uint256 submitMax;
    }

    struct Modules {
        address network;
        address enforcement;
        address payment;
        address reputation;
    }

    struct BadgePair {
        address token;
        uint256 tokenId;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import { LaborMarketConfigurationInterface } from "./LaborMarketConfigurationInterface.sol";

interface LaborMarketInterface is LaborMarketConfigurationInterface {
    struct ServiceRequest {
        address serviceRequester;
        address pToken;
        uint256 pTokenQ;
        uint256 rTokenQ;
        uint256 signalExp;
        uint256 submissionExp;
        uint256 enforcementExp;
        uint256 submissionCount;
        string uri;
    }

    struct ServiceSubmission {
        address serviceProvider;
        uint256 requestId;
        uint256 timestamp;
        string uri;
        uint256[] scores;
        bool reviewed;
    }

    struct ReviewPromise {
        uint256 total;
        uint256 remainder;
    }

    function initialize(LaborMarketConfiguration calldata _configuration)
        external;

    function getSubmission(uint256 submissionId)
        external
        view
        returns (ServiceSubmission memory);

    function getRequest(uint256 requestId)
        external
        view
        returns (ServiceRequest memory);

    function getConfiguration()
        external
        view
        returns (LaborMarketConfiguration memory);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import {LaborMarketInterface} from "src/LaborMarket/interfaces/LaborMarketInterface.sol";

contract LikertEnforcementCriteria {
    /// @dev Tracks the scores given to service submissions.
    mapping(address => mapping(uint256 => Scores)) private submissionToScores;

    /// @dev Tracks the amount of submitters per Likert scale score for a requestId.
    mapping(address => mapping(uint256 => mapping(Likert => uint256)))
        private bucketCount;

    /// @dev The scoring scale.
    enum Likert {
        SPAM,
        BAD,
        OK,
        GOOD,
        GREAT
    }

    /// @dev The scores given to a service submission.
    struct Scores {
        uint256[] scores;
        uint256 avg;
    }

    /// @dev The count and allocation per bucket
    struct ClaimableBucket {
        uint256 count;
        uint256 allocation;
    }

    /**
     * @notice Allows a maintainer to review a submission.
     * @param submissionId The submission to review.
     * @param score The score to give the submission.
     */
    function review(uint256 submissionId, uint256 score)
        external
        returns (uint256)
    {
        require(
            score <= uint256(Likert.GREAT),
            "EnforcementCriteria::review: invalid score"
        );

        uint256 requestId = getRid(submissionId);

        // Update the bucket count for old score
        if (submissionToScores[msg.sender][submissionId].scores.length != 0) {
            unchecked {
                --bucketCount[msg.sender][requestId][
                    Likert(submissionToScores[msg.sender][submissionId].avg)
                ];
            }
        }

        // Add the new score
        submissionToScores[msg.sender][submissionId].scores.push(score);

        // Calculate the average
        submissionToScores[msg.sender][submissionId].avg = _getAvg(
            submissionToScores[msg.sender][submissionId].scores
        );

        // Update the bucket count for new score
        unchecked {
            ++bucketCount[msg.sender][requestId][
                Likert(submissionToScores[msg.sender][submissionId].avg)
            ];
        }

        return uint256(Likert(score));
    }

    /**
     * @notice Returns the point on the payment curve for a submission.
     * @param submissionId The submission to calculate the point for.
     * @param total The total amount of tokens to be paid out.
     * @return The point on the payment curve.
     */
    function verify(uint256 submissionId, uint256 total) external view returns (uint256) {
        uint256 x;

        uint256 score = submissionToScores[msg.sender][submissionId].avg;

        uint256 alloc = (1e18 /
            getTotalBucket(msg.sender, Likert(score), getRid(submissionId)));

        // LaborMarketInterface market = LaborMarketInterface(msg.sender);
        // uint256 pTokens = market
        //     .getRequest(market.getSubmission(submissionId).requestId)
        //     .pTokenQ / 1e18;

        total = total / 1e18;

        if (score == uint256(Likert.SPAM)) {
            x = sqrt(alloc * (total * 0));
        }
        else if (score == uint256(Likert.BAD)) {
            x = sqrt(alloc * ((total * 5) / 100));
        }
        else if (score == uint256(Likert.OK)) {
            x = sqrt(alloc * ((total * 10) / 100));
        }
        else if (score == uint256(Likert.GOOD)) {
            x = sqrt(alloc * ((total * 25) / 100));
        }
        else {
            x = sqrt(alloc * ((total * 60) / 100));
        }

        return x;
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL GETTERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the total number of submissions for a given score.
    function getTotalBucket(
        address market,
        Likert score,
        uint256 requestId
    ) internal view returns (uint256) {
        return bucketCount[market][requestId][score];
    }

    /// @notice Returns the sqrt of a number.
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        // Stolen from prbmath
        if (x == 0) {
            return 0;
        }

        // Set the initial guess to the least power of two that is greater than or equal to sqrt(x).
        uint256 xAux = uint256(x);
        result = 1;
        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 0x4) {
            result <<= 1;
        }

        // The operations can never overflow because the result is max 2^127 when it enters this block.
        unchecked {
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1; // Seven iterations should be enough
            uint256 roundedDownResult = x / result;
            return result >= roundedDownResult ? roundedDownResult : result;
        }
    }

    /// @notice Returns the average of an array of numbers.
    function _getAvg(uint256[] memory scores) internal pure returns (uint256) {
        uint256 cumScore;
        uint256 qScores = scores.length;

        for (uint256 i; i < qScores; ++i) {
            cumScore += scores[i];
        }

        return cumScore / qScores;
    }

    /// @dev Gets a users requestId from submissionId
    function getRid(uint256 submissionId) internal view returns (uint256) {
        return
            LaborMarketInterface(msg.sender)
                .getSubmission(submissionId)
                .requestId;
    }

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the amount claimable for a service request.
    function getRemainder(uint256 requestId) public view returns (uint256) {
        uint256 claimable;

        LaborMarketInterface market = LaborMarketInterface(msg.sender);
        uint256 pTokens = market.getRequest(requestId).pTokenQ;

        ClaimableBucket[5] memory buckets = [
            ClaimableBucket({
                count: getTotalBucket(msg.sender, Likert.SPAM, requestId),
                allocation: ((pTokens * 0))
            }),
            ClaimableBucket({
                count: getTotalBucket(msg.sender, Likert.BAD, requestId),
                allocation: (((pTokens * 5) / 100))
            }),
            ClaimableBucket({
                count: getTotalBucket(msg.sender, Likert.OK, requestId),
                allocation: (((pTokens * 10) / 100))
            }),
            ClaimableBucket({
                count: getTotalBucket(msg.sender, Likert.GOOD, requestId),
                allocation: (((pTokens * 25) / 100))
            }),
            ClaimableBucket({
                count: getTotalBucket(msg.sender, Likert.GREAT, requestId),
                allocation: (((pTokens * 60) / 100))
            })
        ];

        for (uint256 i; i < buckets.length; ++i) {
            if (buckets[i].count > 0) {
                claimable += buckets[i].allocation;
            }
        }

        return (pTokens - claimable);
    }
}