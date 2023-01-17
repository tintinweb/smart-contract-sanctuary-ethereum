// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

// interfaces imported
import "./ICryptoDevsNFT.sol";
import "./IFakeNFTMarketplace.sol";

// ownable needs to be inherited, and not just left imported in any contract... 
// that implements 'ownership' functionalities
// "Ownable" will be added to the CryptoDevsDAO bytecode and execs _trasnferOwnership() in its constructor...
// making (msg.sender) the owner of the CryptoDevsDAO
contract CryptoDevsDAO is Ownable {
    // We will write contract code here
    
    // Create an enum named Vote containing possible options for a vote
    enum Vote {
        YAY,    // 0
        NAY     // 1
    }
    // Create a struct named Proposal containing all relevant information
    // When it is said, that proposal need to be saved in the contact storage... 
    // it means, all its args. (uint256, address, bool string, etc.) should be state vars... 
    // and better keep it inside a struct - The Power of Struct
    struct Proposal {
        // nftTokenId - the tokenID of the NFT to purchase from FakeNFTMarketplace if the proposal passes
        uint256 nftTokenId;
        // deadline - the UNIX timestamp until which this proposal is active. Proposal can be executed after the deadline has been exceeded.
        uint256 deadline;
        // yayVotes - number of yay votes for this proposal
        uint256 yayVotes;
        // nayVotes - number of nay votes for this proposal
        uint256 nayVotes;
        // executed - whether or not this proposal has been executed yet. Cannot be executed before the deadline has been exceeded.
        bool executed;
        // voters - a mapping of CryptoDevsNFT tokenIDs to booleans indicating whether that NFT has already been used to cast a vote or not
        mapping(uint256 => bool) voters;    // better name is 'voteCasted' vis-a-vis NFT-ID
    }

    // Create a mapping of ID to Proposal
    mapping(uint256 => Proposal) public proposals;
    // Number of proposals that have been created
    uint256 public numProposals;

    // declare interface-instances, initialized inside constructor
    IFakeNFTMarketplace nftMarketplace;

    ICryptoDevsNFT cryptoDevsNFT;

    // Create a modifier which only allows a function to be
    // called by someone who owns at least 1 CryptoDevsNFT
    modifier nftHolderOnly {
        require(cryptoDevsNFT.balanceOf(msg.sender) > 0, "NOT_A_DAO_MEMBER");
        _;
    }

    // Create a modifier which only allows a function (e.g. vote()) to be
    // called if the given proposal's deadline has not been exceeded yet
    
    // why an arg proposalId
    // bcz there can be multiple proposals running concurrently
    // so, proposalId is a must to know which proposal we're going to cast our vote for
    modifier activeProposalOnly(uint256 proposalId) {
        require(proposals[proposalId].deadline > block.timestamp, "DEADLINE_EXCEEDED");
        _;
    }

    // Create a modifier which only allows a function to be called
    // condition # 1: if the given proposals' deadline HAS been exceeded
    // condition # 2: and, if the proposal has not yet been executed
    // hence, 2 require() needed
    modifier inactiveProposalOnly(uint256 proposalId) {
        // "=" is a must in below condition as timestamp must be at least 1 ms ahead of the deadline
        require(proposals[proposalId].deadline <= block.timestamp, "DEADLINE_NOT_EXCEEDED");
        require(proposals[proposalId].executed == false, "PROPOSAL_ALREADY_EXECUTED");
        _;
    }

    // all state vars. and modifers set, moving on to functions() incl. constructor() now

    // Create a payable constructor which initializes the contract
    // instances for FakeNFTMarketplace and CryptoDevsNFT
    // The payable allows this constructor to accept an ETH deposit when it is being deployed
    constructor(address _nftMarketplace, address _cryptoDevsNFT) payable {
        nftMarketplace = IFakeNFTMarketplace(_nftMarketplace);
        cryptoDevsNFT = ICryptoDevsNFT(_cryptoDevsNFT);
    }

    /// @dev createProposal allows a CryptoDevsNFT holder to create a new proposal in the DAO
    /// @param _nftTokenId - the tokenID of the NFT to be purchased from FakeNFTMarketplace if this proposal passes
    /// @return Returns the proposal index for the newly created proposal
    function createProposal(uint256 _nftTokenId)
    external
    nftHolderOnly
    returns (uint256)  {
        require(nftMarketplace.available(_nftTokenId), "NFT_NOT_FOR_SALE");
            // numProposals = 0
            // taking zero-based indexing for the created proposals... 
            // mapping: proposals[numProposals] returns a struct:Proposal
            // we want this to be in storage to persist outside the function's exec
            // and not just be in a transient memopry while f() getting executed.
            // instantiating an instance f Proposal-struct here only
        Proposal storage proposal = proposals[numProposals];
        proposal.nftTokenId = _nftTokenId;
            // Set the proposal's voting deadline to be (current time + 5 minutes)
            // block.timestamp returns the timestamnp when this tx is mined and runs successfully (no revert)
            // minutes is a keyword
        proposal.deadline = block.timestamp + 5 minutes;
            // 2 first and foremost members of struct set
            // rest 4 (incl. voters mapping) members will be set in later f(), not here
        numProposals++;

        return numProposals-1;  // basis zero-based "indexing" of our mapping
    }

    /// @dev voteOnProposal allows a CryptoDevsNFT holder to cast their vote on an active proposal
    /// @param proposalId - the id of the proposal to vote on in the proposals mapping
    /// @param vote - the type of vote they want to cast

    // 3 of the remaining 4 members of struct will be used here

   function voteOnProposal(uint256 proposalId, Vote vote) 
   external
   nftHolderOnly
   activeProposalOnly(proposalId) {
        // again, storage: so that all changes made here to 'proposal' persist outside this f()
        Proposal storage proposal = proposals[proposalId];
        // more NFTs in hand, more the voting power (1 NFT:1 vote, NOT like 1 address : 1 vote)
        uint256 voterNFTBalance = cryptoDevsNFT.balanceOf(msg.sender);
        // numVotes to check how any votes an NFT holder can cast vis-a-vis UNused NFTs
        uint256 numVotes = 0;
        // Calculate how many NFTs are owned by the voter
        // that haven't already been used for voting on this proposal
        for (uint256 i = 0; i < voterNFTBalance; i++) {
            // start retrieving all tokenIds 1-by-1 and assess its voting-status
            uint256 tokenId = cryptoDevsNFT.tokenOfOwnerByIndex(msg.sender, i);
            // voters mapping better named as voteCasted
            if(proposal.voters[tokenId] == false) {
                numVotes++; // init = 0, now = 1
                proposal.voters[tokenId] == true;
            }
        }
        // by now, 1 thing sure that it is an nftTokenHolder
        // if numVotes still 0 after the loop, then it has already used the NFT to cast vote
        require(numVotes > 0, "ALREADY_VOTED");
        // if any msg.sender faces "ALREADY_VOTED", his mistake, gas gone and tx failed despite mined
        // he should have kept a tyrack by himself whether its vote casted or not yet
        if (vote == Vote.YAY) {
            proposal.yayVotes += numVotes;
            // All numVotes will be casted in a single go by the voter...  
            // no such option of casting lesser no. of votes
        }
        // else if for more than 2 values of enum
        else {
            proposal.nayVotes += numVotes;
        }
    }

    // last member: 'executed' of struct is used here
    /// @dev executeProposal allows any CryptoDevsNFT holder to execute a proposal after it's deadline has been exceeded and it passed voting
    /// @param proposalId - the id of the proposal to execute in the proposals mapping
    function  executeProposal(uint256 proposalId) 
    external
    nftHolderOnly
    inactiveProposalOnly(proposalId)
    {
        Proposal storage proposal = proposals[proposalId];
        // If the proposal has more YAY votes than NAY votes
        // purchase the NFT from the FakeNFTMarketplace
        if (proposal.yayVotes > proposal.nayVotes) {
            uint256 nftPrice = nftMarketplace.getPrice();
            require(address(this).balance >= nftPrice, "NOT_ENOUGH_FUNDS");
            nftMarketplace.purchase{value: nftPrice}(proposal.nftTokenId);
            // () arg. will be here bcz purchase(nft's tokenId)
            // the proposal returned above in 'storage' already has the requisite Nft-Token-Id as its member
        }
        proposal.executed = true;
        // at the end, so that it can not be executed again... modifier set to revert
    }

    /// @dev withdrawEther allows the contract owner (deployer) to withdraw the ETH from the contract
    // if at all the deployer wants to do so as it's the owner
    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "Nothing to withdraw; contract balance empty");
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Ether withdrawal failed");
        // payable(owner()).transfer(amount) - usage prohibited now
    }

    // The following two functions allow the contract to accept ETH deposits
    // directly from a wallet without calling a function
    receive() external payable {}

    fallback() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * Minimal interface for CryptoDevsNFT containing only two functions
 * that we are interested in
 */
interface ICryptoDevsNFT {
/// @dev balanceOf returns the number of NFTs owned by the given address
    /// @param owner - address to fetch number of NFTs for
    /// @return Returns the number of NFTs owned
    // this will return full tokens as it's NFT (non-divisible) unlike ERC20 that return amount/qty. in wei (not full tokens)
    function balanceOf(address owner) external view returns (uint256);

    /// @dev tokenOfOwnerByIndex returns a tokenID at given index for owner
    /// @param owner - address to fetch the NFT TokenID for
    /// @param index - index of NFT in owned tokens array to fetch
    /// @return Returns the TokenID of the NFT
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * Interface for the FakeNFTMarketplace
 */
interface IFakeNFTMarketplace {
    /// @dev getPrice() returns the price of an NFT from the FakeNFTMarketplace
    /// @return Returns the price in Wei for an NFT
    function getPrice() external view returns (uint256);

    /// @dev available() returns whether or not the given _tokenId has already been purchased
    /// @return Returns a boolean value - true if available, false if not
    function available(uint256 _tokenId) external view returns (bool);

    /// @dev purchase() purchases an NFT from the FakeNFTMarketplace
    /// @param _tokenId - the fake NFT tokenID to purchase
    function purchase(uint256 _tokenId) external payable;
}