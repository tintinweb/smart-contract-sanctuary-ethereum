// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Proposal.sol";
contract CollectorDAO {
    mapping (address => bool) public members;
    uint256 public memberCount;
    uint256 public proposalCount;
    mapping (uint256 => address) public proposals;
    uint8 constant public minQuorumPercentage = 25;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the proposal struct used by the contract
    bytes32 public constant PROPOSAL_TYPEHASH = keccak256("Proposal(uint256 proposalId,uint8 support)");

    function buyMembership(address onBehalfOf) public payable {
        require(msg.value == 1 ether, "SEND ONLY 1 ETHER TO BECOME MEMBER");
        require(!members[onBehalfOf], "ALREADY A MEMBER");
        members[onBehalfOf] = true;
        memberCount++;
    }

    modifier onlyMember {
        require(members[msg.sender], "Member only: you must be a member to use this function");
        _;
    }

    function createProposal(address[] memory targetAddresses,
                            string[] memory functions,
                            bytes[] memory arguments,
                            uint256[] memory valuesToSend) onlyMember public {
        Proposal newProposal = new Proposal(proposalCount++, targetAddresses, functions, arguments, valuesToSend);
        proposals[newProposal.proposalId()] = address(newProposal);
    }

    modifier quorumReachedForProposal(uint256 proposalId) {
        Proposal proposalToCheck = Proposal(proposals[proposalId]);
        require(address(proposalToCheck) != address(0), "CANNOT FIND PROPOSAL ADDRESS");

        require(proposalToCheck.yesVoteCount() * 100 / memberCount >= minQuorumPercentage, "QUORUM NOT REACHED");
        _;
    }

    function executeProposal(uint256 proposalId) quorumReachedForProposal(proposalId) onlyMember public {
        // calculate the value to send to the execute function
        Proposal proposalToExecute = Proposal(proposals[proposalId]);
        require(address(this).balance >= proposalToExecute.totalValueToBeSent(), "NOT ENOUGH ETH IN DAO COLLECTOR");
        proposalToExecute.execute{value: proposalToExecute.totalValueToBeSent()}();
    }

    function castVote(uint256 proposalId, bool support) onlyMember public {
        _castVote(msg.sender, proposalId, support);
    }

    function castVoteBySig(uint256 proposalId, bool support, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes("CollectorDAO")), block.chainid, address(this)));
        bytes32 structHash = keccak256(abi.encode(PROPOSAL_TYPEHASH, proposalId, support));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "INVALID SIGNATURE");
        require(members[signatory], "SIGNATORY NOT A MEMBER !!");
        return _castVote(signatory, proposalId, support);
    }

    function _castVote(address sender, uint256 proposalId, bool support) internal {
        Proposal targetProposal = Proposal(proposals[proposalId]);
        require(address(targetProposal) != address(0), "CANNOT FIND PROPOSAL ADDRESS");
        targetProposal.addVote(support, sender);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Proposal {
    address owner; // owner is the collector DAO
    mapping (address => bool) votingMembers;
    uint256 public proposalId;
    uint256 public callCount;
    address[] public targetAddresses;
    string[] public functions; // "buyNFT(uint256)";
    bytes[] public arguments; // encoded args
    uint256[] public valuesToSend; // value to send for each calls
    uint256 public totalValueToBeSent; // calculated in ctor
    uint256 public createdOn;
    
    uint8 public yesVoteCount;
    uint8 public noVoteCount;

    constructor (uint256 _proposalId, address[] memory _targetAddresses, string[] memory _functions, bytes[] memory _arguments, uint256[] memory _valuesToSend) {
        owner = msg.sender;
        proposalId = _proposalId;
        callCount = _targetAddresses.length;
        targetAddresses = _targetAddresses;
        functions = _functions;
        arguments = _arguments;
        valuesToSend = _valuesToSend;
        yesVoteCount = 0;
        noVoteCount = 0;

        totalValueToBeSent = 0;
        for(uint256 i = 0; i < _valuesToSend.length; i++ ) {
            totalValueToBeSent += _valuesToSend[i];
        }
        createdOn = block.timestamp;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function execute() onlyOwner payable public {
        for(uint256 i = 0; i < targetAddresses.length; i++) {
            address targetAddr = targetAddresses[i];
            string memory functionToCall = functions[i];
            bytes memory args = arguments[i];
            uint256 valueToSend = valuesToSend[i];

            bytes4 encodedFunctionToCall = bytes4(keccak256(bytes(functionToCall)));
            bytes memory data = abi.encodePacked(encodedFunctionToCall, args);
            (bool success,) = targetAddr.call{value: valueToSend}(data);
            require(success, "CALL ERRORED");
        }
    }

    /// @notice delete de proposal and send back eth to the owner
    function removeProposal() onlyOwner public {
        require(block.timestamp >= createdOn + 14 days, "PROPOSAL NOT OLD ENOUGH");
        address payable addr = payable(address(owner));
        selfdestruct(addr);
    }

    function addVote(bool approval, address votingMember) public onlyOwner {
        require(!votingMembers[votingMember], "MEMBER HAVE ALREADY VOTED ON THE PROPOSAL");
        votingMembers[votingMember] = true;
        if(approval) {
            yesVoteCount++;
        }
        else {
            noVoteCount++;
        }
    }
}