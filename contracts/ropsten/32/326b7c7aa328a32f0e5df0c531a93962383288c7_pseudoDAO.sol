/**
 *Submitted for verification at Etherscan.io on 2022-08-31
*/

/**
 *Submitted for verification at Etherscan.io on 2022-08-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

error alreadyMember();
error transferFailed();
error notMember();
error alreadyExist();
error notDelegated();
error alreadyVoted();
error proposalNotActive(uint256 proposalNumber);
error notOwner();
error run_renounceOwnership_instead();

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract Ownable {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        checkOwner();
        _;
    }

    function checkOwner() internal view {
        if (owner != msg.sender) {
            revert notOwner();
        }
    }

    function renounceOwnership() public onlyOwner {
        owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner == address(0)) {
            revert run_renounceOwnership_instead();
        }
        owner = newOwner;
    }
}

contract pseudoDAO is Ownable {
    struct Propasal {
        address payable to;
        address contractAddress;
        uint256 amount;
        uint256 voteCount;
        bool executed;
        bool canceled;
        bool isERC20;
    }

    uint256 public ProposalCount;
    uint256 public MemberCount;
    uint256[] public existProposals;

    mapping(uint256 => Propasal) Proposals;
    mapping(address => bool) private Members;
    mapping(uint256 => mapping(address => bool)) Votes;

    constructor() payable {
        ProposalCount = 0;
        MemberCount = 0;
    }

    event newProposal(
        address indexed to,
        uint256 indexed value,
        uint indexed blockNumber
    );
    event newMember(address indexed member_address);
    event deletedMember(address indexed member_address);
    event voteCast(address indexed voter, uint256 proposalId);
    event proposalExecuted(uint256 indexed proposalId);
    event proposalPassThreshold(uint256 indexed proposalId);
    event deposit(address, uint);

    receive() external payable{
        emit deposit(msg.sender, msg.value);
    }
    fallback() external payable{
        emit deposit(msg.sender, msg.value);
    }

    function propasalThreshold() private view returns (uint256) {
        return MemberCount / uint256(2);
    }

    function isMember(address _address) public view returns (bool) {
        return Members[_address];
    }

    function addMember(address memberAddress) public onlyOwner {
        if (Members[memberAddress]) {
            revert alreadyMember();
        } else {
            Members[memberAddress] = true;
            MemberCount += 1;
            emit newMember(memberAddress);
        }
    }

    function deleteMember(address memberAddress) public onlyOwner {
        if (!Members[memberAddress]) {
            revert notMember();
        } else {
            Members[memberAddress] = false;
            MemberCount -= 1;
            emit deletedMember(memberAddress);
        }
    }

    function isActive(uint256 proposalId) public view returns (bool) {
        Propasal storage proposal = Proposals[proposalId];
        return !(proposal.executed || proposal.canceled);
    }

    function proposalHash(
        address to,
        uint256 value,
        uint blockNumber,
        address tokenContract
    ) public pure returns (uint256) {
        return uint256(keccak256(abi.encode(to, value, blockNumber,tokenContract)));
    }

    function cancelProposal(uint256 proposalId) public onlyOwner {
        Propasal storage proposal = Proposals[proposalId];
        proposal.canceled = true;
    }

    function submitProposal(
        address to,
        uint256 value,
        address tokenContract
    ) public returns (uint256) {
        if (!Members[msg.sender]) revert notMember();

        uint blockNumber = block.number;
        uint256 proposalId = proposalHash(to, value, blockNumber,tokenContract);
        Propasal storage proposal = Proposals[proposalId];

        if (proposal.to != address(0)) revert alreadyExist();

        existProposals.push(proposalId);
        proposal.to = payable(to);
        proposal.amount = value;
        proposal.contractAddress = tokenContract;
        if(tokenContract != address(0))
        {
            proposal.isERC20 = true;           
        }

        ProposalCount += 1;

        emit newProposal(to, value, blockNumber);
        return proposalId;
    }

    function isExecutable(uint256 proposalId) private view returns (bool) {
        Propasal storage proposal = Proposals[proposalId];
        if (proposal.voteCount > propasalThreshold() && isActive(proposalId)) {
            return true;
        } else {
            return false;
        }
    }

    function castVote(uint256 proposalId, string memory declaration) public {
        if(!isMember(msg.sender)) revert notMember();

        Propasal storage proposal = Proposals[proposalId];
        if (isActive(proposalId)) {
            if (!Votes[proposalId][msg.sender]) {
                if (
                    keccak256(abi.encodePacked((declaration))) ==
                    keccak256(abi.encodePacked(("Approve")))
                ) {
                    Votes[proposalId][msg.sender] = true;
                    proposal.voteCount += 1;
                    emit voteCast(msg.sender, proposalId);
                    if (proposal.voteCount > propasalThreshold()) {
                        emit proposalPassThreshold(proposalId);
                    }
                } else {
                    revert notDelegated();
                }
            } else {
                revert alreadyVoted();
            }
        } else{
            revert proposalNotActive(proposalId);
        }
    }

    function numberOfVotes(uint256 proposalId) public view returns (uint256) {
        Propasal storage proposal = Proposals[proposalId];
        return proposal.voteCount;
    }

    function execute(uint256 proposalId) public onlyOwner {
        require(isExecutable(proposalId),"Proposal not executable!");
        Propasal storage proposal = Proposals[proposalId];
        
        if(proposal.isERC20){
            IERC20 token = IERC20(proposal.contractAddress);
            try token.transfer(proposal.to, proposal.amount){
                proposal.executed = true;
                emit proposalExecuted(proposalId);
            } catch{
                revert transferFailed();
            }
        }
        else{
            (bool success, ) = (proposal.to).call{
            value: proposal.amount
            }("");
            require(success);
            proposal.executed = true;
            emit proposalExecuted(proposalId);
        }
    }
}