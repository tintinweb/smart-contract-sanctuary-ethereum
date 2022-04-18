// SPDX-License-Identifier: MIT

pragma solidity >=0.6.6;

contract Leaderboard {
    // lists top 10 users
    uint256 leaderboardLength = 10;

    // create an array of Users
    mapping(uint256 => User) public leaderboard;

    // each user has a username and score
    struct User {
        string user;
        uint256 score;
    }

    // calls to update leaderboard
    function addScore(string memory user, uint256 score)
        public
        returns (bool result)
    {
        // if the score is too low, don't update
        if (leaderboard[leaderboardLength - 1].score >= score) return false;

        // loop through the leaderboard
        for (uint256 i = 0; i < leaderboardLength; i++) {
            // find where to insert the new score
            if (leaderboard[i].score < score) {
                // shift leaderboard
                User memory currentUser = leaderboard[i];
                for (uint256 j = i + 1; j < leaderboardLength + 1; j++) {
                    User memory nextUser = leaderboard[j];
                    leaderboard[j] = currentUser;
                    currentUser = nextUser;
                }

                // insert
                leaderboard[i] = User({user: user, score: score});

                // delete last from list
                delete leaderboard[leaderboardLength];

                return true;
            }
        }
    }
}