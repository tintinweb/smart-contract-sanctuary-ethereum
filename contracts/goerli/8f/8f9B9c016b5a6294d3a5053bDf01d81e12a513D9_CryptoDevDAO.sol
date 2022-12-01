// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

/*//////////////////////////////////////////////////////////////   
                            Imports
//////////////////////////////////////////////////////////////*/
import '@openzeppelin/contracts/access/Ownable.sol';
import './INFTMarketplace.sol';
import './INFTCollection.sol';

/*//////////////////////////////////////////////////////////////   
                            Custom Errors
//////////////////////////////////////////////////////////////*/
error nftHolderOnly_NotADAOMember();
error createProposal_NFTNotForSale();
error activeProposalOnly_DeadlineExceeded();
error voteOnProposal_AlreadyVoted();
error inactiveProposalOnly_DeadlineNotExceeded();
error inactiveProposalOnly_ProposalAlreadyExecuted();
error excuteProposal_NotEnoughFunds();
error withdraw_FailedToSendEther();

/// @title Crypto Dev DAO
/// @author Kehinde A.
/// @notice A Crypto Dev DAO. Anyone with a CryptoDevs NFT can create a proposal to purchase a different NFT from an NFT marketplace. Everyone with a CryptoDevs NFT can vote for or against the active proposals. Each NFT counts as one vote for each proposal. If majority of the voters vote for the proposal by the deadline, the NFT purchase is automatically executed.
contract CryptoDevDAO is Ownable {
    /*//////////////////////////////////////////////////////////////   
                            State Variables
    //////////////////////////////////////////////////////////////*/
    //possible options for a vote
    enum Vote {
        YAY, // YAY = 0
        NAY // NAY = 1
    }

    /// @notice Create a struct named Proposal containing all relevant information
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
        mapping(uint256 => bool) voters;
    }

    // Create a mapping of ID to Proposal
    mapping(uint256 => Proposal) public proposals; //Private ??

    // Number of proposals that have been created
    uint256 private numProposals;

    //Initializing NFTmarketplace contract
    INFTMarketplace nftMarketplace;

    //Initializing NFTmarketplace contract
    INFTCollection cryptoDevsNFT;

    /*//////////////////////////////////////////////////////////////   
                            Modifier
    //////////////////////////////////////////////////////////////*/
    // Create a modifier which only allows a function to be
    // called by someone who owns at least 1 CryptoDevsNFT
    modifier nftHolderOnly() {
        if (cryptoDevsNFT.balanceOf(msg.sender) <= 0) {
            revert nftHolderOnly_NotADAOMember();
        }
        _;
    }

    modifier activeProposalOnly(uint256 proposalIndex) {
        if (proposals[proposalIndex].deadline <= block.timestamp) {
            revert activeProposalOnly_DeadlineExceeded();
        }
        _;
    }

    // Create a modifier which only allows a function to be
    // called if the given proposals' deadline HAS been exceeded
    // and if the proposal has not yet been executed
    modifier inactiveProposalOnly(uint256 proposalIndex) {
        if (proposals[proposalIndex].deadline > block.timestamp) {
            revert inactiveProposalOnly_DeadlineNotExceeded();
        }
        if (proposals[proposalIndex].executed != false) {
            revert inactiveProposalOnly_ProposalAlreadyExecuted();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////   
                            Constructor Functions
    //////////////////////////////////////////////////////////////*/

    // Create a payable constructor which initializes the contract
    // instances for FakeNFTMarketplace and CryptoDevsNFT
    constructor(address _nftMarketplace, address _cryptoDevsNFT) payable {
        nftMarketplace = INFTMarketplace(_nftMarketplace);
        cryptoDevsNFT = INFTCollection(_cryptoDevsNFT);
    }

    /*//////////////////////////////////////////////////////////////   
                            Functions
    //////////////////////////////////////////////////////////////*/
    /// @dev createProposal allows a CryptoDevsNFT holder to create a new proposal in the DAO
    /// @param _nftTokenId - the tokenID of the NFT to be purchased from FakeNFTMarketplace if this proposal passes
    /// @return Returns the proposal index for the newly created proposal
    function createProposal(uint256 _nftTokenId)
        external
        nftHolderOnly
        returns (uint256)
    {
        if (!(nftMarketplace.available(_nftTokenId))) {
            // Check to see if desired NFT is avaiable
            revert createProposal_NFTNotForSale();
        }
        Proposal storage proposal = proposals[numProposals];
        proposal.nftTokenId = _nftTokenId;

        //Set the proposal's voting deadline to be (current time + 5 minutes)
        proposal.deadline = block.timestamp + 5 minutes;

        numProposals++;

        return numProposals - 1;
    }

    /// @dev voteOnProposal allows a CryptoDevsNFT holder to cast their vote on an active proposal
    /// @param proposalIndex - the index of the proposal to vote on in the proposals array
    /// @param vote - the type of vote they want to cast
    function voteOnProposal(uint256 proposalIndex, Vote vote)
        external
        nftHolderOnly
        activeProposalOnly(proposalIndex)
    {
        Proposal storage proposal = proposals[proposalIndex];

        uint256 voterNFTBalance = cryptoDevsNFT.balanceOf(msg.sender);
        uint256 numVotes;

        // Calculate how many NFTs are owned by the voter
        // that haven't already been used for voting on this proposal
        for (uint256 i; i < voterNFTBalance; ++i) {
            uint256 tokenId = cryptoDevsNFT.tokenOfOwnerByIndex(msg.sender, i);
            if (proposal.voters[tokenId] == false) {
                numVotes++;
                proposal.voters[tokenId] = true;
            }
        }

        if (numVotes <= 0) {
            revert voteOnProposal_AlreadyVoted();
        }

        //increments the yayVotes & NayVotes
        if (vote == Vote.YAY) {
            proposal.yayVotes += numVotes;
        } else {
            proposal.nayVotes += numVotes;
        }
    }

    /// @dev executeProposal allows any CryptoDevsNFT holder to execute a proposal after it's deadline has been exceeded
    /// @param proposalIndex - the index of the proposal to execute in the proposals array
    function executeProposal(uint256 proposalIndex)
        external
        nftHolderOnly
        inactiveProposalOnly(proposalIndex)
    {
        Proposal storage proposal = proposals[proposalIndex];

        // If the proposal has more YAY votes than NAY votes
        // purchase the NFT from the FakeNFTMarketplace
        if (proposal.yayVotes > proposal.nayVotes) {
            uint256 nftPrice = nftMarketplace.getNFTPrice();
            if (address(this).balance < nftPrice) {
                revert excuteProposal_NotEnoughFunds();
            }
            nftMarketplace.purchase{value: nftPrice}(proposal.nftTokenId);
        }
        proposal.executed = true;
    }

    /// @dev withdrawEther allows the contract owner (deployer) to withdraw the ETH from the contract
    function withdrawEther() external onlyOwner {
        uint256 amount = address(this).balance;
        (bool sent, ) = owner().call{value: amount}('');
        if (!sent) {
            revert withdraw_FailedToSendEther();
        }
    }

    // The following two functions allow the contract to accept ETH deposits
    // directly from a wallet without calling a function
    receive() external payable {}

    fallback() external payable {}

    //Sell function

    /*//////////////////////////////////////////////////////////////   
                        Getter Functions
    //////////////////////////////////////////////////////////////*/
    function getNumProposals() external view returns (uint256) {
        return numProposals;
    }

    function getProposalNftTokenId(uint256 _nftTokenId)
        external
        view
        returns (uint256)
    {
        Proposal storage proposal = proposals[_nftTokenId];
        return proposal.nftTokenId;
    }

    function getProposalDeadline(uint256 _nftTokenId)
        external
        view
        returns (uint256)
    {
        Proposal storage proposal = proposals[_nftTokenId];
        return proposal.deadline;
    }

    function getProposalYayVotes(uint256 _nftTokenId)
        external
        view
        returns (uint256)
    {
        Proposal storage proposal = proposals[_nftTokenId];
        return proposal.yayVotes;
    }

    function getProposalNayVotes(uint256 _nftTokenId)
        external
        view
        returns (uint256)
    {
        Proposal storage proposal = proposals[_nftTokenId];
        return proposal.nayVotes;
    }

    function getProposalExecuted(uint256 _nftTokenId)
        external
        view
        returns (bool)
    {
        Proposal storage proposal = proposals[_nftTokenId];
        return proposal.executed;
    }

    function getProposalVoters(uint256 _nftTokenId, uint256 index)
        external
        view
        returns (bool)
    {
        Proposal storage proposal = proposals[_nftTokenId];
        return proposal.voters[index];
    }
}

/**
 * deploy script X
 * Check revert logic
 * add params to error
 * Testing
 * Frontend
 * Contract deployed at: 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9
 */

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
pragma solidity ^0.8.5;

interface INFTMarketplace {
    /// @dev getPrice() returns the price of an NFT from the FakeNFTMarketplace
    /// @return Returns the price in Wei for an NFT
    function getNFTPrice() external view returns (uint256);

    /// @dev available() returns whether or not the given _tokenId has already been purchased
    /// @return Returns a boolean value - true if available, false if not
    function available(uint256 _tokenId) external view returns (bool);

    /// @dev purchase() purchases an NFT from the FakeNFTMarketplace
    /// @param _tokenId - the fake NFT tokenID to purchase
    function purchase(uint256 _tokenId) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface INFTCollection {
    /**@dev Returns a token ID owned by "owner" at given "index" of its token list.
     * Use along with {baslanceOf} to enumerate all of "owner's" tokens.
     */

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId);

    /**
     * @dev Returns the number of tokens in "owner's" account
     */

    function balanceOf(address owner) external view returns (uint256 balance);
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