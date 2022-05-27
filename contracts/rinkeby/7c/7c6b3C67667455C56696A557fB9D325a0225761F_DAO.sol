/**
 *Submitted for verification at Etherscan.io on 2022-05-27
*/

pragma solidity ^0.8.13;

contract DAO {
    /**
	* DAO Contract
	* 1. Collects investor's money (ether)
	* 2. Keep track of investor's contributions with shares
	* 3. Allow investors to transfer shares
	* 4. Allow investment proposals to be created and voted
	* 5. Execute successful investment proposals (i.e send money)
	*/
	struct Proposal{
		uint id;
		string name;
		uint amount;
		address payable recipient;
		uint votes;
		uint end;
		bool executed;
	}

	mapping(address => bool) public investors;
	mapping(address => uint) public shares;
	mapping(uint => Proposal) public proposals;
	mapping(address => mapping(uint => bool)) votes;
	
	uint public totalShares;
	uint public availableFunds;
	uint public contributionEnd;
	uint public nextProposalId;
	uint public voteTime;
	uint public quorum;
	address public admin;

    constructor(uint contributionTime,  uint _voteTime,uint _quorum) {
	    require(_quorum > 0 && _quorum < 100, 'quorum must be between 0 and 100');
        contributionEnd = block.timestamp + contributionTime;
	    voteTime = _voteTime;
        quorum = _quorum;
        admin = msg.sender;
    }

    function contribute() payable external {
        //require(block.timestamp < contributionEnd,'Sorry contribution period to this DAO has ended');
        investors[msg.sender] = true;
        shares[msg.sender] += msg.value;
        totalShares += msg.value;
        availableFunds +=msg.value;
    }

    function redeem(uint amount) external{
        require(shares[msg.sender] >= amount, 'Insufficient shares available');
        require(availableFunds >= amount, 'Insufficient shares available for transfer');
        shares[msg.sender] -= amount;
        totalShares -= amount;
        availableFunds -= amount;
        payable(msg.sender).transfer(amount);
    }

    function transfer(uint amount, address to) external{
        require(shares[msg.sender] >= amount, 'Insufficient shares available');
        shares[msg.sender] -= amount;
        investors[to] = true;
        shares[to] += amount;
    } 

	function createProposal(string memory name, uint amount, address payable recipient) external onlyInvestors() {
		require(availableFunds >= amount, 'Not enough funds');
		proposals[nextProposalId] = Proposal(
			nextProposalId,
			name,
			amount,
			recipient,
			0,
			block.timestamp + voteTime,
			false
		);

		availableFunds -=amount;
		nextProposalId++;
	}
	
	function vote(uint proposalId) external onlyInvestors() {
		Proposal storage proposal = proposals[proposalId];
		require(votes[msg.sender][proposalId] == false,'Already voted for this proposal');
		require(block.timestamp < proposal.end, 'Voting period has ended');
		proposal.votes += shares[msg.sender];
		votes[msg.sender][proposalId] = true;
	}

	function executeProposal(uint proposalId) external onlyAdmin() {
		Proposal storage proposal = proposals[proposalId];
		require(block.timestamp < proposal.end, 'Execution period has ended');
		require(proposal.executed == false, 'Proposal already executed');
		require((proposal.votes / totalShares) * 100 >= quorum, 'Not enough votes to execute the proposal');
		_transferEther(proposal.amount,proposal.recipient);
	}

	function withdraw (uint amount, address payable to) external{
		_transferEther(amount,to);
	}

	function _transferEther(uint amount, address payable to) internal  onlyAdmin(){
		require(amount <= availableFunds, 'Not enough funds');
		to.transfer(amount);
		availableFunds -= amount;
	}

	//For ether returns of proposal investments
	receive() external payable {
		availableFunds += msg.value;
	}

	function getProposals() public view returns (Proposal[] memory)  {
		Proposal[] memory ret = new Proposal[](nextProposalId);

		for (uint i = 0; i < nextProposalId; i++) {
			ret[i] = proposals[i];
		}

		return ret;
	}

    modifier onlyInvestors(){
        require(investors[msg.sender] == true, 'Only investors can perform this activity');
        _;
    }

	modifier onlyAdmin(){
		require(msg.sender == admin, 'Only admin can perform this activity');
		_;
	}
}