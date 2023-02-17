/**
 *Submitted for verification at Etherscan.io on 2023-02-17
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

/*
    This contract is an example of a very simple decentralized oracle implementation. Note that it is designed purely
    for an educational example and should not be used in production. There are many gas inefficiencies and obvious
    potential attack vectors, including a trivial Sybil attack.

    The oracle works as follows:
        - The oracle value is updated once every round, where each round is at least UPDATE_INTERVAL blocks long
        - Anyone can call reportValue() to report a value for the next round must pay REQUIRED_PAYMENT to do so
        - Anyone can call processUpdate() after UPDATE_INTERVAL has passed since the last update
            - The caller receives 10% of all payments in the round as an incentive
            - The median value of all reported values is chosen as the oracle value
            - All accounts that reported the chosen value split the remaining 90% of funds
*/
contract Oracle {
    // Used to keep track of who reported what values
    struct ValueReport {
        address reporter;
        uint256 value;
    }

    uint256 public constant REQUIRED_PAYMENT = 0.01 ether; // Require all value reports to include a small payment
    uint256 public constant UPDATE_INTERVAL = 15; // Require at least 15 blocks between updates (roughly 3 minutes)

    ValueReport[] reports; // Keeps track of reports in this round
    uint256 latestValue; // Value from the last round
    uint256 lastUpdateBlock; // Block number of the last value update

    // This is the function other contracts will interact with to get the oracle value
    function readValue() external view returns (uint256, uint256) {
        return (latestValue, lastUpdateBlock);
    }

    // This is the function used to report a value for the current round
    function reportValue(uint256 value) external payable {
        require(
            msg.value == REQUIRED_PAYMENT,
            "Must send REQUIRED_PAYMENT ether"
        );

        // Ensure no one reports multiple values per round
        // Gas-inefficient and vulnerable to Sybil attacks
        for (uint256 i = 0; i < reports.length; i++) {
            require(
                msg.sender != reports[i].reporter,
                "Can only report one value per round"
            );
        }

        reports.push(ValueReport(msg.sender, value));
    }

    // This is the function that determines the oracle value for the current round
    // Value is chosen from the median of all reports in the round
    function processUpdate() external {
        require(
            block.number - lastUpdateBlock >= UPDATE_INTERVAL,
            "Must wait at least UPDATE_INTERVAL blocks since previous update"
        );
        require(reports.length >= 1, "No new reports in this round");

        latestValue = median(reports, reports.length);

        // Send 10% of all funds from this round to the caller (incentive for calling)
        msg.sender.call{value: address(this).balance / 10}("");

        // Count the number of people who reported the median value
        uint256 numCorrect = 0;
        for (uint256 i = 0; i < reports.length; i++) {
            if (reports[i].value == latestValue) {
                numCorrect++;
            }
        }

        // Distribute the remaining funds equally among everyone who was correct (incentive for reporting correct value)
        uint256 reward = address(this).balance / numCorrect;
        for (uint256 i = 0; i < reports.length; i++) {
            if (reports[i].value == latestValue) {
                reports[i].reporter.call{value: reward}("");
            }
        }

        lastUpdateBlock = block.number;
        delete reports;
    }

    // Internal helper function for finding the median
    // Very gas inefficient
    // Adapted from: https://github.com/OpenZeppelin/openzeppelin-contracts/issues/1548#issuecomment-779249419

    function swap(
        ValueReport[] memory array,
        uint256 i,
        uint256 j
    ) internal pure {
        (array[i], array[j]) = (array[j], array[i]);
    }

    function sort(
        ValueReport[] memory array,
        uint256 begin,
        uint256 end
    ) internal pure {
        if (begin < end) {
            uint256 j = begin;
            uint256 pivot = array[j].value;
            for (uint256 i = begin + 1; i < end; ++i) {
                if (array[i].value < pivot) {
                    swap(array, i, ++j);
                }
            }
            swap(array, begin, j);
            sort(array, begin, j);
            sort(array, j + 1, end);
        }
    }

    function median(ValueReport[] memory array, uint256 length)
        internal
        pure
        returns (uint256)
    {
        sort(array, 0, length);
        return array[length / 2].value; // We take the larger value in the even case just to make it simple
    }
}