// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

    // Adding interface from NFTmarketplace and CryptoDevNft to call their function
    // Purpose of adding interface is to let our contrcat know what function takes as argumnets and what it returns
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
interface ICryptoDevsNFT {
    /// @dev balanceOf returns the number of NFTs owned by the given address
    /// @param owner - address to fetch number of NFTs for
    /// @return Returns the number of NFTs owned
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


contract CryptoDevDAO is Ownable {


    /**
     * Functionality we need in our DAO
     1. Store created proposal in state of contract
     2. Allow CryptoDevNFT holder to create new proposal
     3. Allow holders to vote on proposal given that they haven't already voted and proposal hasn't passed it's deadline
     4. Allow holders to execute a proposal after it's deadline has been exceeded, and buy NFT if it passes
     */

    // Struct to store proposal
    struct Proposal {
        // nftTokenId - the tokenID of the NFT to purchase from FakeNFTMarketplace if the proposal passes
        uint256 nftTokenId;
        // UNIX timestamp until which it's valid. And only after which it can be executed
        uint256 deadline;
        uint256 yVotes;
        uint256 nVotes;
        bool executed;
        // from CryptoDevNFT tokenId to bool- to keep track of whether the nft has been used to cast vote or not
        mapping(uint256 => bool) voters;
    }

    // Create a mapping of ID to proposal
    mapping(uint256 => Proposal) public proposals;
    // Number of proposals that have been created
    uint256 public numProposals;

    ICryptoDevsNFT cryptoDevsNFT;
    IFakeNFTMarketplace nftMarketplace;

    // payable to let the deployer send some Eth to the treasury of DAO. msg.sender will automatically be owner by Ownable contrcat
    constructor(address _nftMarketplace, address _cryptoDevsNFT) payable {
        nftMarketplace = IFakeNFTMarketplace(_nftMarketplace);
        cryptoDevsNFT = ICryptoDevsNFT(_cryptoDevsNFT);
    }

    modifier onlyHoldersOfCryptoDevNFT () {
        require(cryptoDevsNFT.balanceOf(msg.sender) > 0, "You are not a DAO member");
        _;
    }

    /// @dev createProposal allows a CryptoDevsNFT holder to create a new proposal in the DAO
    /// @param _nftId - the tokenID of the NFT to be purchased from FakeNFTMarketplace if this proposal passes
    /// @return Returns the proposal index for the newly created proposal
    function createProposal(uint256 _nftId) external onlyHoldersOfCryptoDevNFT returns (uint256) {
        // Check whether _nftId provided is availabel or not
        require(nftMarketplace.available(_nftId), "NFT not available for sell");
        Proposal storage proposal = proposals[numProposals];
        proposal.nftTokenId = _nftId;
        // Set the proposal's voting deadline to be (current time + 5 minutes)
        proposal.deadline = block.timestamp + 5 minutes;
        //Increase the numProposals
        numProposals++;
        return numProposals - 1;
    }


    // Create a modifier which only allows a function to be
    // called if the given proposal's deadline has not been exceeded yet
    modifier activeProposalOnly(uint256 _proposalId) {
        require(
            proposals[_proposalId].deadline > block.timestamp,
            "Deadline exceeded"
        );
        _;
    }
    
    // Create an enum named Vote containing possible options for a vote
    enum Vote {
        YES, // 0
        NO   // 1
    } 

    /// @dev voteOnProposal allows a CryptoDevsNFT holder to cast their vote on an active proposal
    /// @param _proposalId - the index of the proposal to vote on in the proposals array
    /// @param vote - the type of vote they want to cast
    function voteOnProposal(uint256 _proposalId, Vote vote) external onlyHoldersOfCryptoDevNFT activeProposalOnly(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        // Get the amount of NFT the caller has
        uint256 nftOwned = cryptoDevsNFT.balanceOf(msg.sender);
        // To keep trcak of number of votes available to user - coz user can call this function more than once(call, buyNFT, call Again)
        uint256 numVotes = 0;
        // Get the id of all these NFTS
        for (uint i = 0; i < nftOwned; i++){
            uint256 id = cryptoDevsNFT.tokenOfOwnerByIndex(msg.sender, i);
            // Check if that ID is used to vote or not
            if (proposal.voters[id] == false) {
                numVotes++;
                proposal.voters[id] = true;
            }
        }
        require(numVotes > 0, "Already Voted");
        if (vote == Vote.YES) {
            proposals[_proposalId].yVotes++;
        } else {
            proposals[_proposalId].nVotes++;
        }

    }

    // Modifier to check whether the deadline has benn passed or not and check whether the proposal is executed or not
    modifier inactiveProposalOnly(uint256 _proposalId) {
        require(!proposals[_proposalId].executed, "Already executed");
        require(proposals[_proposalId].deadline <= block.timestamp, "DEADLINE_NOT_EXCEEDED");
        _;
    }

    function executeProposal(uint256 _proposalId) external onlyHoldersOfCryptoDevNFT inactiveProposalOnly(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.yVotes > proposal.nVotes, "Majority voted against the Proposal");
        proposal.executed = true;
        uint256 nftPrice = nftMarketplace.getPrice();
        require(address(this).balance >= nftPrice, "Not enough funds");
        nftMarketplace.purchase{value: nftPrice}(proposal.nftTokenId);
    }

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