// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IdaoContract {
    function balanceOf(address, uint256) external view returns (uint256);
}

contract Dao {
    address public owner;
    uint256 nextProposal;
    uint256[] public validTokens;
    IdaoContract daoContract;

    constructor() {
        owner = msg.sender;
        nextProposal = 1;
        daoContract = IdaoContract(0x2953399124F0cBB46d2CbACD8A89cF0599974963);
        validTokens = [
            58538135596029509329456146620683606546470122578009882867137711145262073774130
        ];
    }

    struct proposal {
        uint256 id;
        bool exist;
        string description;
        uint256 deadLine;
        uint256 votesUp;
        uint256 votesDown;
        address[] canVote;
        uint256 maxVotes;
        mapping(address => bool) voteStatus;
        bool countConducted;
        bool passed;
    }

    mapping(uint256 => proposal) public Proposals;

    event proposalCreated(
        uint256 id,
        string description,
        uint256 maxVotes,
        address proposer
    );

    event proposalCount(uint256 id, bool passed);

    function checkProposalEligibility(address _proposalist)
        private
        view
        returns (bool)
    {
        for (uint256 i = 0; i < validTokens.length; i++) {
            if (daoContract.balanceOf(_proposalist, validTokens[i]) >= 1) {
                return true;
            }
        }
        return false;
    }

    function checkVoteEligibility(uint256 _id, address _voter)
        private
        view
        returns (bool)
    {
        for (uint256 i = 0; i < Proposals[_id].canVote.length; i++) {
            if (Proposals[_id].canVote[i] == _voter) {
                return true;
            }
        }
        return false;
    }

    function createProposal(
        string memory _description,
        address[] memory _canVote
    ) public {
        require(
            checkProposalEligibility(msg.sender),
            "Only Authentic DAO NFT holders can puth forth proposals"
        );

        proposal storage newProposal = Proposals[nextProposal];
        newProposal.id = nextProposal;
        newProposal.exist = true;
        newProposal.description = _description;
        newProposal.deadLine = block.number + 100;
        newProposal.canVote = _canVote;
        newProposal.maxVotes = _canVote.length;

        emit proposalCreated(
            nextProposal,
            _description,
            _canVote.length,
            msg.sender
        );
        nextProposal++;
    }

    function voteOnProposal(uint256 _id, bool _vote) public {
        require(Proposals[_id].exist, "This proposal does not exist");
        require(
            checkVoteEligibility(_id, msg.sender),
            "You can not vote on this proposal"
        );
        require(
            !Proposals[_id].voteStatus[msg.sender],
            "You hoca already voted on this proposal"
        );
        require(
            block.number <= Proposals[_id].deadLine,
            "The deadline has passed for this proposal"
        );

        proposal storage p = Proposals[_id];

        if (_vote) {
            p.votesUp++;
        } else {
            p.votesDown++;
        }

        p.voteStatus[msg.sender] = true;
    }

    function countVotes(uint256 _id) public {
        require(msg.sender == owner,"only owner can count votes");
        require(Proposals[_id].exist,"This proposal does not exist");
        require(block.number > Proposals[_id].deadLine,"The deadline has passed for this proposal");
        require(!Proposals[_id].countConducted,"Count already conducted");

        proposal storage p = Proposals[_id];

        if (Proposals[_id].votesDown < Proposals[_id].votesUp) {
            p.passed=true;
        } 
        p.countConducted = true;

        emit proposalCount(_id,p.passed);

    }

    function addTokenId(uint256 _tokenId) public {
        require(msg.sender==owner,"Only owner can add tokens");

        validTokens.push(_tokenId);
    }


}