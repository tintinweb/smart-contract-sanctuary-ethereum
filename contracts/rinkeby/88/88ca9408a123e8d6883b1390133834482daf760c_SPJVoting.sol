/**
 *Submitted for verification at Etherscan.io on 2022-04-19
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

    struct Voter {
        uint256 weight;
        address delegate;
        uint256 vote;
    }

    struct Votes {
        uint256 approvals;
        uint256 disapprovals;
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
        Votes votes;
    }

    event addedProposal (string newProposals, uint40 timestamp);
    event votedProposal(string proposal, bool choice);

    function delegate(address to, string memory proposal, uint256 amount) external;
    function voteProposal(string memory proposal, bool choice) external; 
    function isBlocked(address _addr) external view  returns (bool);
    function blockAddress(address target, bool freeze) external;
    
}
// File: contracts/SPJVoting.sol



pragma solidity >=0.7.0 <0.9.0;





contract SPJVoting is IVoting, owned {

    IERC20 public SPJ;


    mapping(address => Voter) public voters;
    mapping(address => bool) public coreMember;
    mapping (address => bool) public blocked;
    mapping (string => Proposal) public proposals;
    mapping(address => mapping(string => bool)) public voted;

    bool proposingLive;

    constructor(IERC20 coinAddress) {
        SPJ = coinAddress;
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

     function toggleproposingStatus() public {
        proposingLive = !proposingLive;
    }

    Proposal[] allProposals;

    function getAllProposals () public view returns(Proposal[] memory) {
        Proposal[] memory availableProposals = new Proposal[](allProposals.length);
        
        for (uint256 i = 0; i < allProposals.length; i++) {
                availableProposals[i] = allProposals[i];
        }

        return availableProposals;
    }


    function addProposals (string memory newProposal, uint40 timestamp) public {
        require(!isBlocked(msg.sender), "Sender is blocked");
        require(!proposals[newProposal].exists, "proposal already exists");
        Proposal memory proposal = proposals[newProposal];

        if(coreMember[msg.sender] || msg.sender == owner){
            proposals[newProposal].proposalType = Type(0);
        }
        else{
            proposals[newProposal].proposalType = Type(1);
        }
        proposals[newProposal].proposal = newProposal;
        proposals[newProposal].exists = true;
        proposals[newProposal].voteCount = 0;
        proposals[newProposal].startTime = timestamp;

        if(timestamp <= uint40(block.timestamp)){
        proposals[newProposal].proposalStatus = Status(0);
        }
        else{
        proposals[newProposal].proposalStatus = Status(1);
        }

        proposal.votes = Votes({approvals: 0, disapprovals: 0});

        allProposals.push(proposals[newProposal]);

        emit addedProposal(newProposal, timestamp);

    }

    function delegate(address to, string memory proposal, uint256 amount) public  override {
        Voter storage sender = voters[msg.sender];
        sender.weight = IERC20(SPJ).balanceOf(msg.sender);
        require(!voted[msg.sender][proposal], "Already voted.");
        require(to != msg.sender, "Self-delegation is disallowed.");
        require(to != address(0), "Self-delegation is disallowed.");
        require(!isBlocked(msg.sender), "Sender is blocked");
        require(!isBlocked(to), "to address is blocked");

        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;

            require(to != msg.sender, "Found loop in delegation.");
        }
        voted[msg.sender][proposal] = true;
        sender.delegate = to;
        voters[to].weight = IERC20(SPJ).balanceOf(to);
        Voter storage delegate_ = voters[to];
        if (voted[to][proposal]) {
            proposals[proposal].voteCount += 1;
        } else {
            delegate_.weight += amount;
            sender.weight -= amount;
        }
    }

    function updateProposalStatus (string memory proposal, uint8 _status) public onlyOwner{
        require(proposals[proposal].exists, "proposal does not exist");
        proposals[proposal].proposalStatus = Status(_status);
    }

    function voteProposal(string memory proposal, bool choice) public override {
        require(proposingLive, "Not allowed to create a proposal");
        require(proposals[proposal].exists, "proposal does not exist");
        require(proposals[proposal].proposalStatus != Status.Closed, "proposal has been closed");
        require(proposals[proposal].startTime <= uint40(block.timestamp), "Not allowed to Vote yet");
        Voter storage sender = voters[msg.sender];
        sender.weight = IERC20(SPJ).balanceOf(msg.sender);
        require(sender.weight != 0, "Has no right to vote");
        require(!voted[msg.sender][proposal], "Already voted.");
        voted[msg.sender][proposal] = true;

        proposals[proposal].voteCount += 1;
        if(choice == true){
            proposals[proposal].votes.approvals += 1;
        }
        else{
             proposals[proposal].votes.disapprovals += 1;
        }
        IERC20(SPJ).transferFrom(msg.sender,address(this), 1);
        sender.weight -= 1;

        emit votedProposal(proposal, choice);
    }

}