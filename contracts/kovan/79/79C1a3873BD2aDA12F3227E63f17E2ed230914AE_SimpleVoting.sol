// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * Minimal Interface of the Balancer token
 * on the Kovan Network
 * containing only one function that we are interested in
 */

interface IBalance {
    /// @dev balanceOf returns the number of tokens owned by the given address
    /// @param owner - address to fetch number of tokens for
    /// @return Returns the number of tokens owned
    function balanceOf(address owner) external view returns (uint256);
}

contract SimpleVoting is Ownable {

    enum addOrRemove {
        Add,
        Remove
    }

    // Create a struct named Proposal containing all relevant information
    struct Proposal { 
        // Whether to add or remove address in Gnosis safe
        addOrRemove addOrRemove_;
        // Address to add or remove in Gnosis safe
        address address_;
        // deadline - the UNIX timestamp until which this proposal is active. Proposal can be executed after the deadline has been exceeded.
        uint256 deadline;
        // yayVotes - number of yay votes for this proposal
        uint256 yayVotes;
        // nayVotes - number of nay votes for this proposal
        uint256 nayVotes;
        // executed - whether or not this proposal has been executed yet. Cannot be executed before the deadline has been exceeded.
        bool executed;
        // voters - a mapping of CryptoDevsNFT tokenIDs to booleans indicating whether that NFT has already been used to cast a vote or not
        //mapping(uint256 => bool) voters;
    }

    // A dynamically-sized array of `Proposal` structs.
    Proposal[] public proposalsArray;

    
    // This declares a new complex type which will
    // be used for variables later.
    // It will represent a single voter.
    struct Voter {
        uint weight; // weight is accumulated by delegation
        address delegate; // person delegated to
        mapping(uint256 => bool) voted; // index of the proposal mapped to whether the person has voted
        mapping(address => uint256) proposal_; // Maps the address to the proposal Index
    }

     
    // This declares a state variable that
    // stores a `Voter` struct for each possible address.
    mapping(address => Voter) public voters;
    

    // Create a mapping of ID to Proposal
    mapping(uint256 => Proposal) public proposals;
    // Number of proposals that have been created
    uint256 public numProposals;

    IBalance balInterface;

    // Balancer token address on the Kovan Network is 0x41286Bb1D3E870f3F750eB7E1C25d7E48c8A1Ac7;
    constructor(address balancerTokenAddress) {
        balInterface = IBalance(balancerTokenAddress);
    }

    // Create a modifier which only allows a function to be
    // called by someone who owns at least 1 Balancer Token
    modifier tokenHolderOnly() {
        require(balInterface.balanceOf(msg.sender)/(10**18) > 0, "NOT_A_DAO_MEMBER");
        _;
    }

    function checkIfTokenHolder () public view returns (bool) {
        return balInterface.balanceOf(msg.sender)/(10**18) > 0;
    }

    /// @dev createProposal allows a Token holder to create a new proposal in the DAO
    /// @param _addOrRemove - Choose whether to add or remove an address
    /// @param _address - Address to either add or remove from gnosis safe
    /// @return Returns the proposal index for the newly created proposal
    function createProposal(addOrRemove _addOrRemove, address _address)
        external
        tokenHolderOnly
        returns (uint256)
    {
        /*
        if (_addOrRemove == addOrRemove.Remove){
            require address exists as a signature in gnosis safe
        }
        */
        require (_address != address(0), "Zero Address Invalid");
        numProposals += 1;
        Proposal storage proposal = proposals[numProposals];
        proposal.addOrRemove_ = _addOrRemove;
        proposal.address_ = _address;
        // Set the proposal's voting deadline to be (current time + 5 minutes)
        proposal.deadline = block.timestamp + 5 minutes;

        return numProposals;
    }

    // Create a modifier which only allows a function to be
    // called if the given proposal's deadline has not been exceeded yet
    modifier activeProposalOnly(uint256 _proposalIndex) {
        require(
            proposals[_proposalIndex].deadline > block.timestamp,
            "DEADLINE_EXCEEDED"
        );
        _;
    }

    // Create an enum named Vote containing possible options for a vote
    enum Vote {
        YAY, // YAY = 0
        NAY // NAY = 1
    }

    
    /// Delegate your vote to the voter `_to`.
    function delegate(address _to, uint256 _proposalIndex) external activeProposalOnly(_proposalIndex) {
        // assigns reference
        Voter storage sender = voters[msg.sender];
        require(!sender.voted[_proposalIndex], "You already voted.");
        require(voters[_to].delegate != address(0), "INVALID ADDRESS.");

        sender.weight = balInterface.balanceOf(msg.sender)/(10**18);
        sender.voted[_proposalIndex] = true;
        sender.delegate = _to;
        Voter storage delegate_ = voters[_to];
        if (delegate_.voted[_proposalIndex]) {
            // If the delegate already voted,
            // directly add to the number of votes
            uint256 yesVotes = proposals[delegate_.proposal_[_to]].yayVotes;
            uint256 noVotes = proposals[delegate_.proposal_[_to]].nayVotes;
            if (yesVotes > noVotes) {
                proposals[delegate_.proposal_[_to]].yayVotes += sender.weight;
            } else {
                proposals[delegate_.proposal_[_to]].nayVotes += sender.weight;
            }
        } else {
            // If the delegate did not vote yet,
            // add to her weight.
            delegate_.weight += sender.weight;
        }
    }
    

    /// @dev voteOnProposal allows a Balancer Token holders to cast their vote on an active proposal
    /// @param _proposalIndex - the index of the proposal to vote on in the proposals array
    /// @param vote - the type of vote they want to cast
    function voteOnProposal(uint256 _proposalIndex, Vote vote)
        external
        tokenHolderOnly
        activeProposalOnly(_proposalIndex)
    {
        Voter storage voter = voters[msg.sender];
        require(!voter.voted[_proposalIndex], "You already voted.");
        Proposal storage proposal = proposals[_proposalIndex];

        voter.weight = balInterface.balanceOf(msg.sender)/(10**18);
        voter.delegate = msg.sender;

        if (vote == Vote.YAY) {
            proposal.yayVotes += voter.weight;
        } else {
            proposal.nayVotes += voter.weight;
        }
    }

    // Create a modifier which only allows a function to be
    // called if the given proposals' deadline HAS been exceeded
    // and if the proposal has not yet been executed
    modifier inactiveProposalOnly(uint256 proposalIndex) {
        require(
            proposals[proposalIndex].deadline <= block.timestamp,
            "DEADLINE_NOT_EXCEEDED"
        );
        require(
            proposals[proposalIndex].executed == false,
            "PROPOSAL_ALREADY_EXECUTED"
        );
        _;
    }
/*
    /// @dev executeProposal allows any CryptoDevsNFT holder to execute a proposal after it's deadline has been exceeded
    /// @param _proposalIndex - the index of the proposal to execute in the proposals array
    function executeProposal(uint256 _proposalIndex)
        external
        tokenHolderOnly
        inactiveProposalOnly(_proposalIndex)
    {
        Proposal storage proposal = proposals[_proposalIndex];

        // If the proposal has more YAY votes than NAY votes
        // purchase the NFT from the FakeNFTMarketplace
        if (proposal.yayVotes > proposal.nayVotes) {
            =!!! EXECUTE PROPOSAL !!!
        }
        proposal.executed = true;
    }
*/

    /// @dev withdrawEther allows the contract owner (deployer) to withdraw the ETH from the contract
    function withdrawEther() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    // The following two functions allow the contract to accept ETH deposits
    // directly from a wallet without calling a function
    receive() external payable {}

    fallback() external payable {}

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}