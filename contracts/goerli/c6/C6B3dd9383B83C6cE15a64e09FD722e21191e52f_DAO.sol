//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "./INftMarketplace.sol";

contract DAO {
    event TransactionExecuted(address target, uint value, bytes data, bytes returnData);
    event RewardPaid(address payee, uint256 reward);
    event MembershipAwarded(address member, uint256 joinDate);
    event MemberVoted(address member, uint256 votingPower, bool vote, uint256 proposalId);
    event ProposalExecuted(address executor, uint256 proposalId);
    event ProposalSubmitted(address member, uint256 proposalId, address[] targets, uint[] values, bytes[] data, uint256 voteStart, uint256 voteEnd);
    event NFTPurchased(address nftContract, uint256 nftId, uint256 price);

    uint256 constant public MEMBERSHIP_PURCHASE_COST = 1 ether;
    uint256 constant public PROPOSAL_DURATION = 7 days;
    uint constant public PROPOSAL_THRESHOLD = 25; // 25%
    uint256 constant public EXECUTION_REWARD = 0.01 ether;
    uint constant public MIN_NUMBER_OF_MEMBERS = 4;

    mapping (address => uint256) public memberVotingPower;
    mapping (address => uint256) public memberJoinDate;
    uint256 public totalMembers;
    uint256 public proposalId;

    struct Proposal {
        uint256 voteStart;
        uint256 voteEnd;
        bool executed;
        uint256 votesFor;
        uint256 votesAgainst;
        bytes32 callsHash;
        address memberCreator;
        uint256 quorumThreshold; // should be at least 25% of totalMembers at time of creation
        mapping (address => bool) hasVoted;
    }

    mapping(uint256 => Proposal) public proposals;

    constructor() {}

    function purchaseMembership() external payable {
        require(msg.value == 1 ether, "must pay exactly 1 eth");
        require(memberVotingPower[msg.sender] == 0, "DAO: can't buy membership again");

        memberVotingPower[msg.sender] = 1;
        memberJoinDate[msg.sender] = block.timestamp;
        totalMembers += 1;
        emit MembershipAwarded(msg.sender, memberJoinDate[msg.sender]);
    }

    function propose(address[] calldata targets, uint[] calldata values, bytes[] calldata data) external returns (uint256) {
        require(memberVotingPower[msg.sender] > 0, "DAO: must be a member to propose");
        require(targets.length == values.length && targets.length == data.length, "DAO: array lengths invalid");
        uint256 currentProposalId = proposalId;

        bytes32 callsHash = keccak256(abi.encode(targets, values, data));
        Proposal storage proposal = proposals[currentProposalId];
        proposal.voteStart = block.timestamp;
        proposal.voteEnd = block.timestamp + PROPOSAL_DURATION;
        proposal.quorumThreshold = (totalMembers * PROPOSAL_THRESHOLD) / 100;
        proposal.callsHash = callsHash;
        proposal.memberCreator = msg.sender;
        if ((totalMembers * PROPOSAL_THRESHOLD) % 100 != 0) {
            // round up
            proposal.quorumThreshold += 1;
        }

        proposalId += 1;
        emit ProposalSubmitted(msg.sender, currentProposalId, targets, values, data, proposal.voteStart, proposal.voteEnd);
        return currentProposalId;
    }

    function proposalHasPassed(uint256 _proposalId) public view returns (bool) {
        Proposal storage proposal = proposals[_proposalId];

        return proposal.voteStart != 0 &&
          proposal.voteEnd < block.timestamp &&
          proposal.quorumThreshold == 0 && 
          proposal.votesFor > proposal.votesAgainst;
    }

    function vote(uint256 _proposalId, bool _yourVote) external {
        _vote(_proposalId, _yourVote, msg.sender);
    }

    function voteIfSignatureMatch(
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 _proposalId,
        bool _yourVote,
        address _voter
    ) public {
        uint chainId;
        assembly {
            chainId := chainid()
        }
        bytes32 eip712DomainSeperator = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("DAO")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );

        bytes32 hashStruct = keccak256(
            abi.encode(
                keccak256("_vote(uint256 _proposalId,bool _yourVote,address _voter)"),
                _proposalId,
                _yourVote,
                _voter
            )
        );

        bytes32 hash = keccak256(abi.encodePacked("\x19\x01", eip712DomainSeperator, hashStruct));
        address signer = ecrecover(hash, v, r, s);
        require(signer == _voter, "DAO: invalid signature");
        require(signer != address(0), "DAO: invalid signer");

        _vote(_proposalId, _yourVote, _voter);  
    }

    function batchVote(
        uint8[] calldata v,
        bytes32[] calldata r,
        bytes32[] calldata s,
        uint256[] calldata _proposalId,
        bool[] calldata _yourVote,
        address[] calldata _voter
    ) external {
        require(v.length == r.length && s.length == v.length && _proposalId.length == v.length && _yourVote.length == v.length && _voter.length == v.length, "DAO: invalid array length");

        unchecked {
             for (uint i = 0; i < v.length; i++) {
                voteIfSignatureMatch(
                    v[i], 
                    r[i], 
                    s[i], 
                    _proposalId[i], 
                    _yourVote[i], 
                    _voter[i]
                );
            }
        }
    }

    function _vote(uint256 _proposalId, bool _yourVote, address _voter) internal {
        require(memberVotingPower[_voter] > 0, "DAO: must be a member to vote");
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.voteStart != 0, "DAO: Proposal id invalid");
        require(proposal.voteEnd > block.timestamp, "DAO: proposal has ended");
        require(memberJoinDate[_voter] < proposal.voteStart, "DAO: can't vote on proposal");
        require(!proposal.hasVoted[_voter], "DAO: can't vote twice");

        if (_yourVote) {
            proposal.votesFor += memberVotingPower[_voter];
        } else {
            proposal.votesAgainst += memberVotingPower[_voter];
        }
        proposal.hasVoted[_voter] = true;
        if (proposal.quorumThreshold > 0) {
            proposal.quorumThreshold -= 1;
        }
        emit MemberVoted(_voter, memberVotingPower[_voter], _yourVote, _proposalId);
    }

    function executeProposal(uint256 _proposalId, address[] calldata targets, uint[] calldata values, bytes[] calldata data) external {
        require(proposalHasPassed(_proposalId), "DAO: proposal hasn't passed yet");
        bytes32 callsHash = keccak256(abi.encode(targets, values, data));
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.executed, "DAO: proposal already executed");
        require(proposal.callsHash == callsHash, "DAO: execute doesn't match hash");

        proposal.executed = true;
        memberVotingPower[proposal.memberCreator] += 1;

        unchecked {
             for (uint i = 0; i < targets.length; i++) {
                executeTransaction(targets[i], values[i], data[i]);
            }
        }

        if (address(this).balance > 5 ether) {
            // send reward
            (bool sent, ) = payable(msg.sender).call{ value: EXECUTION_REWARD }("");
            if (sent) {
                emit RewardPaid(msg.sender, EXECUTION_REWARD);
            }
        }

        emit ProposalExecuted(msg.sender, proposalId);
    }

    function executeTransaction(address target, uint value, bytes calldata callData) internal {
        (bool success, bytes memory returnData) = target.call{ value: value }(callData);
        require(success, "DAO: Transaction failed.");

        emit TransactionExecuted(target, value, callData, returnData);
    }

    /// @notice Purchases an NFT for the DAO
    /// @param marketplace The address of the INftMarketplace
    /// @param nftContract The address of the NFT contract to purchase
    /// @param nftId The token ID on the nftContract to purchase
    /// @param maxPrice The price above which the NFT is deemed too expensive
    /// and this function call should fail
    function buyNFTFromMarketplace(
        address marketplace,
        address nftContract,
        uint256 nftId,
        uint256 maxPrice
    ) external {
        require(msg.sender == address(this), "DAO: only call from executeTransaction");
        INftMarketplace mp = INftMarketplace(marketplace);
        uint256 price = mp.getPrice(nftContract, nftId);
        require(price <= maxPrice, "DAO: nft too expensive");
        bool success = mp.buy{ value: price }(nftContract, nftId);
        require(success, "DAO: failed to purchase nft");
        emit NFTPurchased(nftContract, nftId, price);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface INftMarketplace {
    /// @notice Returns the price of the NFT at the `nftContract`
    /// address with the given token ID `nftID`
    /// @param nftContract The address of the NFT contract to purchase
    /// @param nftId The token ID on the nftContract to purchase
    /// @return price ETH price of the NFT in units of wei
    function getPrice(address nftContract, uint256 nftId) external returns (uint256 price);

    /// @notice Purchase the specific token ID of the given NFT from the marketplace
    /// @param nftContract The address of the NFT contract to purchase
    /// @param nftId The token ID on the nftContract to purchase
    /// @return success true if the NFT was successfully transferred to the msg.sender, false otherwise
    function buy(address nftContract, uint256 nftId) external payable returns (bool success);
}