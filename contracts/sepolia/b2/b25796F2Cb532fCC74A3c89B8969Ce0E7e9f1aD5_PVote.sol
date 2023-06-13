/**
 *Submitted for verification at Etherscan.io on 2023-06-12
*/

// SPDX-License-Identifier: no-license

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title PreferentialVote
 * @dev Implements voting process along with vote delegation
 */

contract PVote {
    struct Proposal {
        // If you can limit the length to a certain number of bytes,
        // always use one of bytes1 to bytes32 because they are much cheaper
        bytes32 name; // short name (up to 32 bytes)
        uint256 voteCountForMajority; // number of accumulated votes for majority
    }

    struct Voter {
        uint256 timestamp;
        uint256[] votes; // rank of the proposals
    }

    address public chairperson;

    mapping(uint256 => Voter) public voters;

    bytes32 public title;
    Proposal[] public proposals;

    uint256 public max_voters;
    uint256 public current_number_of_voters;
    uint256 public start_time;
    uint256 public end_time;
    bool public vote_counting_in_progress;


    /**
     * @dev Create a new ballot to choose one of 'proposalNames'.
     * @param proposalNames names of proposals
     */
    constructor(bytes32 _title, bytes32[] memory proposalNames, uint256 _start_time, uint256 _end_time, uint256 _max_voters, bool _vote_counting_in_progress) {
        chairperson = msg.sender;
        title = _title;

        proposals.push(Proposal({
            name: 0x0000000000000000000000000000000000000000000000000000000000000000,
            voteCountForMajority: 0
        }));

        for (uint256 i = 0; i < proposalNames.length; i++) {
            // 'Proposal({...})' creates a temporary
            // Proposal object and 'proposals.push(...)'
            // appends it to the end of 'proposals'.
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCountForMajority: 0
            }));
        }

        max_voters = _max_voters;

        if (_start_time == 0) {
            start_time = block.timestamp;
        } else {
            start_time = _start_time;
        }

        end_time = _end_time;
        vote_counting_in_progress = _vote_counting_in_progress;
    }

    // modifier to check if results can be shown before voting is over (i.e. the maximum number of voters reached or vote is ended)
    modifier checkResultsCanBeShown() {
        if (vote_counting_in_progress == true || (max_voters == 0 && end_time == 0)) {
            _;
        } else {
            require(
                voteOver() == true,
                "Voting is still active. Results cannot be shown."
            );
            _;
        }
    }

    modifier checkTime() {
        require(
            block.timestamp >= start_time && block.timestamp <= end_time,
            "Voting is not active."
        );
        _;
    }

    // function to show the vote is over
    function voteOver() public view returns (bool _voteOver) {
        // check if the maximum number of voters reached or vote is ended
        if (max_voters == 0 && end_time == 0) {
            _voteOver = false;
            return _voteOver;
        } else if (max_voters == 0) {
            if (block.timestamp > end_time) {
                _voteOver = true;
                return _voteOver;
            } else {
                _voteOver = false;
                return _voteOver;
            }
        } else if (end_time == 0) {
            if (current_number_of_voters >= max_voters) {
                _voteOver = true;
                return _voteOver;
            } else {
                _voteOver = false;
                return _voteOver;
            }
        } else {
            if (
                current_number_of_voters >= max_voters ||
                block.timestamp > end_time
            ) {
                _voteOver = true;
                return _voteOver;
            } else {
                _voteOver = false;
                return _voteOver;
            }
        }
    }


    /**
     * @dev Give your vote (including votes delegated to you) to proposal 'proposals[v]'.
     * @param _votes vote amount array
     */
    function vote(uint256[] memory _votes) public {
        require(
            msg.sender == chairperson,
            "Only chairperson can give right to vote."
        );
        require(
            _votes.length == proposals.length - 1, // 1 indexed
            "The number of votes must be equal to the number of proposals."
        );

        // record the voter's vote to voters array
        voters[current_number_of_voters] = Voter({
            timestamp: block.timestamp,
            votes: _votes
        });

        // count the votes for first stage
        proposals[_votes[0]].voteCountForMajority += 1;

        current_number_of_voters++;
    }

    /**
     * @dev Computes the winning proposal taking all previous votes into account.
     * @return _winningProposal index of winning proposal in the proposals array
     */
    function winningProposal()
        public
        view
        checkResultsCanBeShown
        returns (uint256 _winningProposal)
    {
        // declare a two-dimensional array to store each stage's result
        uint256[][] memory stage_results = new uint256[][](proposals.length);

        // declare an array for storing each stage's highest / lowest proposal index
        uint256[] memory highest_proposal_index = new uint256[](proposals.length);
        uint256[] memory lowest_proposal_index = new uint256[](proposals.length);

        // start to count votes for each stage
        for (uint256 i = 1; i < proposals.length; i++) {
            // fast path for stage 1
            if (i == 1) {
                for (uint256 p = 0; p < proposals.length; p++) {
                    stage_results[i][p] = proposals[p].voteCountForMajority;
                }

            // stage 2 and above
            } else {
                // init stage_results array
                stage_results[i] = new uint256[](proposals.length);
                for (uint256 p = 0; p < proposals.length; p++) {
                    stage_results[i][p] = stage_results[i - 1][p];
                }
                stage_results[i][lowest_proposal_index[i - 1]] = 0;

                // distribute the eliminated proposal's next ranked votes to other proposals
                for (uint256 v = 0; v < current_number_of_voters; v++) {
                    // if the voter's vote on previous stages is the lowest proposal
                    for (uint256 s = 0; s <= i; s++) {

                        if (s < i && voters[v].votes[s] != lowest_proposal_index[s]) {
                            break;
                        } else if (s == i) {
                            stage_results[i][voters[v].votes[i]] += 1;
                        }
                    }
                }
            }

            // find the highest / lowest proposal index
            for (uint256 p = 0; p < proposals.length; p++) {
                if (stage_results[i][p] > stage_results[i][highest_proposal_index[i]]) {
                    highest_proposal_index[i] = p;
                }
                if (stage_results[i][p] < stage_results[i][lowest_proposal_index[i]]) {
                    lowest_proposal_index[i] = p;
                }
            }

            // check if the stage's result is tie or not
            if (stage_results[i][highest_proposal_index[i]] > current_number_of_voters / 2) {
                _winningProposal = highest_proposal_index[i];
                return _winningProposal;
            }
            // else, start next stage

        }

        // if no winner found, return the last stage's highest proposal index
        // should not happen
        return highest_proposal_index[proposals.length - 1];
    }

    /**
     * @dev Calls winningProposal() function to get the index of the winner contained in the proposals array and then
     * @return _winnerName the name of the winner
     */
    function winnerName()
        public
        view
        checkResultsCanBeShown
        returns (bytes32 _winnerName)
    {
        _winnerName = proposals[winningProposal()].name;
        return _winnerName;
    }

    /**
     * @dev Computes the winning proposal taking all previous votes into account.
     * @return _winningProposalForMajority index of winning proposal in the proposals array
     */
    function winningProposalForMajority()
        public
        view
        checkResultsCanBeShown
        returns (uint256 _winningProposalForMajority)
    {
        uint256 winningVoteCount = 0;
        for (uint256 p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCountForMajority > winningVoteCount) {
                winningVoteCount = proposals[p].voteCountForMajority;
                _winningProposalForMajority = p;
            }
        }
        return _winningProposalForMajority;
    }

    /**
     * @dev Calls winningProposal() function to get the index of the winner contained in the proposals array and then
     * @return _winnerNameForMajority the name of the winner
     */
    function winnerNameForMajority()
        public
        view
        checkResultsCanBeShown
        returns (bytes32 _winnerNameForMajority)
    {
        _winnerNameForMajority = proposals[winningProposalForMajority()].name;
        return _winnerNameForMajority;
    }
}