// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface ITokenisedVotes {
    function getPastVotes(address account, uint256 referenceBlock)
        external
        view
        returns (uint256 votingPower_);
}

contract TokenisedBallot {
    uint256 public referenceBlock;
    ITokenisedVotes public tokenContract;

    struct Proposal {
        bytes32 name; /// Short name (up to 32 bytes)
        uint256 voteCount; /// Number of accumulated votes
    }

    Proposal[] public proposals;

    mapping(address => uint256) public votePowerSpent;

    event Voted(
        address indexed voter,
        uint256 indexed proposal,
        uint256 weight
    );

    constructor(
        bytes32[] memory _proposalNames,
        address _tokenContract,
        uint256 _referenceBlock
    ) {
        for (uint256 i = 0; i < _proposalNames.length; i++) {
            proposals.push(Proposal({name: _proposalNames[i], voteCount: 0}));
        }
        tokenContract = ITokenisedVotes(_tokenContract);
        referenceBlock = _referenceBlock;
    }

    function votePower(address account)
        public
        view
        returns (uint256 votePower_)
    {
        votePower_ = tokenContract.getPastVotes(account, referenceBlock);
    }

    function vote(uint256 proposal, uint256 amount) public {
        uint256 votingPower_ = votePower(msg.sender);

        require(
            votePowerSpent[msg.sender] < votingPower_,
            "User has used up all voting power"
        );
        require(amount <= votingPower_, "Not enough Voting Power");

        // If proposal is out of the rage of the array,
        // this will throw automatically and revert all changes
        proposals[proposal].voteCount += amount;

        votePowerSpent[msg.sender] += amount;

        emit Voted(msg.sender, proposal, amount);
    }

    function winningProposal() public view returns (uint256 winningProposal_) {
        uint256 winningVoteCount = 0;
        for (uint256 p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

    function winnerName() external view returns (bytes32 winnerName_) {
        winnerName_ = proposals[winningProposal()].name;
    }
}