/**
 *Submitted for verification at Etherscan.io on 2022-04-25
*/

// SPDX-License-Identifier: MIT
// File: contracts/Owned.sol


pragma solidity ^0.8.7;


contract owned {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Caller should be Owner");
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/Interfaces/IVoting.sol



pragma solidity >=0.8.4;


interface IVoting {

    struct Votes {
        uint256 approvals;
        uint256 disapprovals;
    }

    struct Voter {
        string proposal;
        address voterAddress;
        bool vote;
        uint40 timestamp;
    }
    
    enum Status {
      Vote_now,
      soon,
      Closed
    }

    enum Type {
        core,
        community
    }

    struct Proposal {
        string proposal;
        bool exists;
        uint256 voteCount;
        Type proposalType;
        Status proposalStatus;
        uint40 startTime;
        uint40 endTime;
        Votes votes;
    }

    event addedProposal (string newProposals, uint40 timestamp);
    event votedProposal(string proposal, bool choice);
    function updateTokenPerVote(uint256 value) external;
    // function delegate(address to, string memory proposal, uint256 amount) external;
    function changeWithdrawAddress(address _newWithdrawAddress) external;
    function voteProposal(string memory proposal, bool choice) external; 
    function isBlocked(address _addr) external view  returns (bool);
    function blockAddress(address target, bool freeze) external;
    
}
// File: contracts/SPJVoting.sol



pragma solidity >=0.7.0 <0.9.0;


contract SPJVoting is IVoting, owned {

    IERC20 public SPJ;

    mapping(address => bool) public coreMember;
    mapping(address => bool) public blocked;
    mapping(string => Proposal) public proposals;
    mapping(string => Voter) public voters;
    mapping(address => mapping(string => bool)) public voted;

    address public withdrawAddress;

    uint256 public tokenPerVote = 1;

    function votingPower () public view returns(uint256){
        return IERC20(SPJ).balanceOf(msg.sender);
    }

    bool proposingLive;

    constructor(IERC20 coinAddress) {
        SPJ = coinAddress;
        withdrawAddress = msg.sender;
    }

    function changeWithdrawAddress(address _newWithdrawAddress) public onlyOwner override {
        withdrawAddress = _newWithdrawAddress;
    }

    function updateTokenPerVote(uint256 value) public onlyOwner override {
        tokenPerVote = value;
    }

    function blockAddress(address target, bool freeze) public onlyOwner override {
        blocked[target] = freeze;
    }

    function whitelist_as_core(address target, bool state) public onlyOwner {
        coreMember[target] = state;
    }
    
    function isBlocked(address _addr) public view  override returns (bool) {
        return blocked[_addr];
    }

     function toggleproposingStatus() public onlyOwner {
        proposingLive = !proposingLive;
    }

    string[] allProposals;
    Voter[] allVoters;

    function getAllProposals () public view returns(Proposal[] memory) {
        Proposal[] memory availableProposals = new Proposal[](allProposals.length);
        
        for (uint256 i = 0; i < allProposals.length; i++) {
                availableProposals[i] = proposals[allProposals[i]];
        }

        return availableProposals;
    }

    function getAllVoters () public view returns(Voter[] memory) {
        Voter[] memory availableVoters = new Voter[](allVoters.length);
        
        for (uint256 i = 0; i < allVoters.length; i++) {
                availableVoters[i] = allVoters[i];
        }

        return availableVoters;
    }


    function addProposals (string memory newProposal, uint40 startTime, uint40 endTime) public {
        require(proposingLive, "Not allowed to make a proposal yet");
        require(!isBlocked(msg.sender), "Sender is blocked");
        require(!proposals[newProposal].exists, "proposal already exists");

        if(coreMember[msg.sender] || msg.sender == owner){
            proposals[newProposal].proposalType = Type(0);
        }
        else{
            proposals[newProposal].proposalType = Type(1);
        }
        proposals[newProposal].proposal = newProposal;
        proposals[newProposal].exists = true;
        proposals[newProposal].voteCount = 0;
        proposals[newProposal].startTime = startTime;
        proposals[newProposal].endTime = endTime;

        if(startTime <= uint40(block.timestamp)){
        proposals[newProposal].proposalStatus = Status(0);
        }
        else{
        proposals[newProposal].proposalStatus = Status(1);
        }

        proposals[newProposal].votes = Votes({approvals: 0, disapprovals: 0});

        allProposals.push(newProposal);

        emit addedProposal(newProposal, startTime);

    }

    function updateProposalStatus (string memory proposal, uint8 _status) public onlyOwner{
        require(proposals[proposal].exists, "proposal does not exist");
        proposals[proposal].proposalStatus = Status(_status);
    }

    function voteProposal(string memory proposal, bool choice) public override {
        require(!isBlocked(msg.sender), "Sender is blocked");
        require(proposals[proposal].exists, "proposal does not exist");
        require(proposals[proposal].proposalStatus != Status.Closed, "proposal has been closed");
        require(proposals[proposal].startTime <= uint40(block.timestamp), "Not allowed to Vote yet");
        require(proposals[proposal].endTime > uint40(block.timestamp), "Voting has ended");

        require(votingPower() != 0, "Has no right to vote");
        require(!voted[msg.sender][proposal], "Already voted.");
        voted[msg.sender][proposal] = true;

        proposals[proposal].voteCount += 1;
        if(choice == true){
            proposals[proposal].votes.approvals += 1;
        }
        else{
             proposals[proposal].votes.disapprovals += 1;
        }
        IERC20(SPJ).transferFrom(msg.sender, address(this), tokenPerVote);
        voters[proposal].proposal = proposal;
        voters[proposal].voterAddress = msg.sender;
        voters[proposal].vote = choice;
        voters[proposal].timestamp = uint40(block.timestamp);

        allVoters.push(voters[proposal]);

        emit votedProposal(proposal, choice);
    }

    function withdraw() public onlyOwner {
      require(IERC20(SPJ).balanceOf(address(this)) > 0, "Balance is 0");
      require(withdrawAddress != address(0), "the withdraw address is invalid");
        (bool os, ) = payable(withdrawAddress).call{
            value: address(this).balance
        }("");
        IERC20(SPJ).transfer(withdrawAddress, IERC20(SPJ).balanceOf(address(this)));
        require(os);
   }

}