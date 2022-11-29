/*
 * Copyright 2018 ConsenSys AG.
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
 * an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations under the License.
 */
pragma solidity >=0.4.23;


/*
* Interface which all voting algorithms must implement.
*/
interface VotingAlgInterface {
    /**
     * Asses a vote.
     *
     * @param numParticipants Total number of participants.
     * @param numVotedFor     Number of participants who voted for the proposal.
     * @param numVotedAgainst Number of participants who voted against the proposal.
     * @return true if the result of the vote true. That is, given the voting algorithm
     *  the result of the vote is for what was being voted on.
     */
    function assess(uint64 numParticipants, uint64 numVotedFor, uint64 numVotedAgainst) external pure returns (bool);
}

/*
 * Copyright 2018 ConsenSys AG.
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
 * an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations under the License.
 */
pragma solidity >=0.4.23;

import "./VotingAlgInterface.sol";

/**
* The vote is assessed based on the total number of participants who voted.
*/
contract VotingAlgMajority is VotingAlgInterface {

    function assess(uint64 numParticipants, uint64 numVotedFor, uint64 /* numVotedAgainst */) external pure returns (bool) {
        return (numVotedFor * 2 > numParticipants);
    }
}