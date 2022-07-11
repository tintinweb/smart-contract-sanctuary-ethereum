// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IdaoContract {
    function balanceOf(address, uint256) external view returns (uint256);
}

contract Dao {
    struct Proposal {
        uint256 id;
        bool exists;
        string description;
        uint256 votes;
    }

    address public owner;
    uint256[] public validTokens;
    IdaoContract daoContract;
    mapping(address => address) public validVoters;
    Proposal[] public proposalsWin;
    Proposal[] public proposals;
    struct Voter {
        address voter;
        uint256 idProposal;
    }
    Voter[] public voters;
    uint256 public idProporsals;
    uint256 public idVoter;
    uint256 public countProporsals;
    uint256 public countProporsalsWinners;

    constructor() {
        owner = msg.sender;
        daoContract = IdaoContract(0x2953399124F0cBB46d2CbACD8A89cF0599974963);
        validTokens = [
            101832018425899375535984929954058092958993373949978081184254655161219363635201
        ];
        validVoters[msg.sender] = msg.sender;
        idProporsals = 1;
        idVoter = 1;
        emit voter(idVoter, msg.sender);
        countProporsals = 0;
        countProporsalsWinners = 0;
    }

    event proposalCreated(
        uint256 id,
        string description,
        uint256 votes,
        address proposer
    );

    event proposalWin(uint256 id, string description, uint256 votes);

    event newVote(address voter, uint256 proposal);

    event proposalCount(uint256 id, bool passed);

    event voter(uint256 id, address voter);

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

    function checkVoteEligibility(address _voter) private view returns (bool) {
        for (uint256 i = 0; i < voters.length; i++) {
            if (voters[i].voter == _voter) {
                return false;
            }
        }
        return true;
    }

    function checkProposalExists(uint256 _id) private view returns (bool) {
        for (uint256 i = 0; i < proposals.length; i++) {
            if (proposals[i].id == _id) {
                return true;
            }
        }
        return false;
    }

    function createProposal(string memory _description) public {
        require(
            checkProposalEligibility(msg.sender),
            "Solo usuarios duenos del NFT pueden crear una propuesta"
        );

        Proposal memory newProposal;
        newProposal.id = idProporsals;
        newProposal.exists = true;
        newProposal.description = _description;
        idProporsals++;
        newProposal.votes = 0;
        emit proposalCreated(
            newProposal.id,
            _description,
            newProposal.votes,
            msg.sender
        );
        proposals.push(newProposal);
        countProporsals = proposals.length;
    }

    function closeVotation() public {
        require(
            checkProposalEligibility(msg.sender),
            "Solo usuarios duenos del NFT pueden cerrar la votacion"
        );
        require(proposals.length > 0, "No hay propuestas creadas");

        uint256 votes = 0;
        for (uint256 i = 0; i < proposals.length; i++) {
            if (proposals[i].votes > votes) {
                votes = proposals[i].votes;
            }
        }
        for (uint256 i = 0; i < proposals.length; i++) {
            if (proposals[i].votes == votes) {
                proposalsWin.push(proposals[i]);
                emit proposalWin(
                    proposals[i].id,
                    proposals[i].description,
                    proposals[i].votes
                );
            }
        }

        delete voters;
        delete proposals;
        countProporsals = proposals.length;
        countProporsalsWinners = proposalsWin.length;
    }

    function deleteProposal(uint256 _id) public {
        require(
            checkProposalEligibility(msg.sender),
            "Solo usuarios duenos del NFT pueden eliminar una propuesta"
        );
        require(checkProposalExists(_id), "Esta propuesta no existe");

        for (uint256 i = 0; i < proposals.length; i++) {
            if (proposals[i].id == _id) {
                proposals[i] = proposals[proposals.length - 1];
                proposals.pop();
                break;
            }
        }

        for (uint256 i = 0; i < voters.length; i++) {
            if (voters[i].idProposal == _id) {
                voters[i] = voters[voters.length - 1];
                voters.pop();
            }
        }

        countProporsals = proposals.length;
    }

    function addTokenId(uint256 _tokenId) public {
        require(
            msg.sender == owner,
            "Solamente los que tienen el NFT pueden agregar tokens"
        );

        validTokens.push(_tokenId);
    }

    function addValidVoter(address[] memory newVoters) public {
        require(
            checkProposalEligibility(msg.sender),
            "Solo usuarios duenos del NFT pueden agregar votantes"
        );

        for (uint256 i = 0; i < newVoters.length; i++) {
            if (validVoters[newVoters[i]] != newVoters[i]) {
                validVoters[newVoters[i]] = newVoters[i];
                idVoter++;
                emit voter(idVoter, newVoters[i]);
            }
        }
    }

    function removeValidVoter(address[] memory oldVoters) public {
        require(
            checkProposalEligibility(msg.sender),
            "Solo usuarios duenos del NFT pueden eliminar votantes"
        );

        for (uint256 i = 0; i < oldVoters.length; i++) {
            if (validVoters[oldVoters[i]] == oldVoters[i]) {
                delete validVoters[oldVoters[i]];
            }
        }
    }

    function voteOnProposal(uint256 _id) public {
        require(
            validVoters[msg.sender] == msg.sender,
            "No tienes permisos para votar"
        );
        require(checkProposalExists(_id), "Esta propuesta no existe");
        require(checkVoteEligibility(msg.sender), "Ya votaste");

        for (uint256 i = 0; i < proposals.length; i++) {
            if (proposals[i].id == _id) {
                proposals[i].votes++;
            }
        }

        Voter memory newVoter;
        newVoter.idProposal = _id;
        newVoter.voter = msg.sender;

        voters.push(newVoter);

        emit newVote(msg.sender, _id);
    }
}