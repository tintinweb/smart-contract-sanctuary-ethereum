// SPDX-License-Identifier:MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ICryptoDevs.sol";
import "./IFackNFTMarketplace.sol";

pragma solidity ^0.8.0;

contract DAO is Ownable {
    struct Proposal {
        // nft tokenId
        uint256 nftTokenId;
        // the UNIX timestamp until with this proposal is active
        uint256 deadline;
        // vote yes for this proposal
        uint256 yayVotes;
        // vote no for this proposal
        uint256 nayVotes;
        // whether or not this proposal has been executed yet.
        // Cannot be executed before the deadLine has been exceeded
        bool executed;
        // a mapping of NFT tokenIds to booleans indicating whether that
        // NFT has already been used to cast a vote
        mapping(uint256 => bool) voters;
    }
    enum Vote {
        YAY,
        NAY
    }

    // a mapping of ID to Proposal
    mapping(uint256 => Proposal) public proposals;
    uint256 public numPropsals;
    ICryptoDevs cryptoDevs;
    IFackNFTMarketplace nftMarketplace;

    constructor(address _nftMarketplace, address _cryptoDevsNFT) payable {
        cryptoDevs = ICryptoDevs(_cryptoDevsNFT);
        nftMarketplace = IFackNFTMarketplace(_nftMarketplace);
    }

    modifier nftHolderOnly() {
        require(cryptoDevs.balanceOf(msg.sender) > 0, "NOT a DAO member");
        _;
    }

    modifier activeProposalOnly(uint256 proposalIndex) {
        require(
            proposals[proposalIndex].deadline > block.timestamp,
            "DEADLINE_EXCEDDED"
        );
        _;
    }
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

    function createProposal(uint _nftTokenId)
        external
        nftHolderOnly
        returns (uint256)
    {
        require(nftMarketplace.available(_nftTokenId), "NFT not for sale");
        Proposal storage proposal = proposals[numPropsals];
        proposal.nftTokenId = _nftTokenId;
        proposal.deadline = block.timestamp + 5 minutes;
        numPropsals++;
        return numPropsals - 1;
    }

    function voteOnProposal(uint256 proposalIndex, Vote vote)
        external
        nftHolderOnly
        activeProposalOnly(proposalIndex)
    {
        Proposal storage proposal = proposals[proposalIndex];
        uint256 voterNFTBalance = cryptoDevs.balanceOf(msg.sender);
        uint256 numVotes = 0;
        for (uint256 i = 0; i < voterNFTBalance; i++) {
            uint256 tokenId = cryptoDevs.tokenOfOwnerByIndex(msg.sender, i);
            numVotes++;
            proposal.voters[tokenId] = true;
        }
        require(numVotes > 0, "Already voted");
        if (vote == Vote.YAY) {
            proposal.yayVotes += numVotes;
        } else {
            proposal.nayVotes += numVotes;
        }
    }

    function executeProposal(uint256 proposalIndex)
        external
        nftHolderOnly
        inactiveProposalOnly(proposalIndex)
    {
        Proposal storage proposal = proposals[proposalIndex];
        if (proposal.yayVotes > proposal.nayVotes) {
            uint256 nftPrice = nftMarketplace.getPrice();
            require(address(this).balance >= nftPrice, "Not enough funds");
            nftMarketplace.purchase{value: nftPrice}(proposal.nftTokenId);
        }
        proposal.executed = true;
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

// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

interface IFackNFTMarketplace {
    function getPrice() external view returns (uint256);

    function available(uint256 _tokenId) external view returns (bool);

    function purchase(uint256 _tokenId) external payable;
}

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

interface ICryptoDevs {
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId);

    function balanceOf(address owner) external view returns (uint256 balance);
}

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