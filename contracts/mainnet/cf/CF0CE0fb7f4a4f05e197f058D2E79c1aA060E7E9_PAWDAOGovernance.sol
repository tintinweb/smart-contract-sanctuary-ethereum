// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;



interface IPAWDAO {
    function ownerOf(uint256 tokenId) external view returns (address);
    function totalSupply() external view returns (uint256);
}

contract PAWDAOGovernance {

    address private owner;
    address public protocolAddress;
    IPAWDAO public PAWDAO;
    uint256 private lastExecuteTimestamp;
    struct Proposal {
        bool votingStart;
        uint256 voteCount;
        bool executed;
    }

    mapping(bytes32 => Proposal) public proposals;
    mapping(bytes32 => mapping(uint256 => bool)) hasVoted;

    event ProposalAdded(bytes32 proposalId, string func, bytes data, string description);

    constructor(address _protocolAddress, address _pawdaoAddress){
        protocolAddress = _protocolAddress;
        PAWDAO = IPAWDAO(_pawdaoAddress);
        owner = msg.sender;
        lastExecuteTimestamp = block.timestamp;
    }

    function propose(
        uint256 PAWDAOId,
        address _to,
        uint _value,
        string calldata _func,
        bytes calldata _data,
        string calldata _description
    ) public returns (bytes32){
        require(msg.sender == PAWDAO.ownerOf(PAWDAOId), "Not an owner");
        bytes32 descriptionHash = keccak256(bytes(_description));
        bytes32 proposalId = generateProposalId(_to, _value, _func, _data, descriptionHash);
        require(proposals[proposalId].votingStart == false, "Proposal already exist.");
        proposals[proposalId] = Proposal({
        votingStart : true,
        voteCount : 0,
        executed : false
        });

        emit ProposalAdded(proposalId, _func, _data, _description);
        return proposalId;
    }

    function vote(uint256 PAWDAOId, bytes32 proposalId) public {
        require(!proposals[proposalId].executed, "Proposal Executed.");
        require(msg.sender == PAWDAO.ownerOf(PAWDAOId));
        require(!hasVoted[proposalId][PAWDAOId], "already voted");
        hasVoted[proposalId][PAWDAOId] = true;
        proposals[proposalId].voteCount ++;

    }

    function execute(
        address _to,
        uint _value,
        string calldata _func,
        bytes calldata _data,
        bytes32 _descriptionHash
    ) external returns (bytes memory) {
        bytes32 proposalId = generateProposalId(_to, _value, _func, _data, _descriptionHash);
        require(!proposals[proposalId].executed, "Proposal Executed.");
        Proposal storage proposal = proposals[proposalId];
        proposal.executed = true;
        require(proposal.voteCount > (PAWDAO.totalSupply() / 2), "Not enough votes.");
        bytes memory data;
        if (bytes(_func).length > 0) {
            data = abi.encodePacked(
                bytes4(keccak256(bytes(_func))), _data
            );

        } else {
            data = _data;
        }

        (bool success, bytes memory resp) = _to.call(data);
        require(success, "tx failed");
        lastExecuteTimestamp = block.timestamp;
        return resp;
    }


    function generateProposalId(
        address _to,
        uint _value,
        string calldata _func,
        bytes calldata _data,
        bytes32 _descriptionHash
    ) internal pure returns (bytes32){
        return keccak256(abi.encode(_to, _value, _func, _data, _descriptionHash));
    }

    function emergencyCall(address _to, bytes calldata _data) external returns (bytes memory) {
        require(block.timestamp > (lastExecuteTimestamp + 182 days));
        require(msg.sender == owner);
        (bool success, bytes memory resp) = _to.call(_data);
        require(success, "tx failed");
        return resp;
    }

    receive() external payable {}
}