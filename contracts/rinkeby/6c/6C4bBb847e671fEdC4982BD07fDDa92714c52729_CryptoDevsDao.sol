//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IFakeNFTMarketPlace {
    function purchase(uint256 _tokenId) external payable;

    function getPrice() external view returns(uint256);

    function available(uint256 _tokenId) external view returns(bool);
}

interface ICryptoDevsNFT {
    function balanceOf(address owner) external view returns(uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns(uint256);
}

contract CryptoDevsDao is Ownable {
    enum Vote {
        Yes,
        No
    }
    struct Proposal{
        //nft token to purchase
        uint256 nftTokenId;
        //proposal deadline
        uint256 deadline;
        //yes and no votes 
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;

        mapping(uint256 => bool) voters;
    }

    mapping(uint256 => Proposal) public proposals;
    uint256 public numProposals;

    //create a reference of the smart contracts with interface created above 

    IFakeNFTMarketPlace nftMarketPlace;
    ICryptoDevsNFT cryptoDevsNFT;

    constructor(address _nftMarketPlace, address _cryptoDevsNFT) payable {
        nftMarketPlace = IFakeNFTMarketPlace(_nftMarketPlace);
        cryptoDevsNFT = ICryptoDevsNFT(_cryptoDevsNFT);
    }

    modifier nftHoldersOnly() {
        require(cryptoDevsNFT.balanceOf(msg.sender) > 0, "You do not own a Crypto Devs nft");
        _;
    }

    modifier activeProposalOnly(uint256 _id) {
        require((proposals[_id].deadline) > block.timestamp, "proposal is active");
        _;
    }

    modifier inActiveProposalOnly(uint256 _id) {
        require((proposals[_id].deadline) <= block.timestamp);
        require((proposals[_id].executed) == false, "proposal is still active");
        _;
    }

    //create proposal that accepts tokenId of the nft you want to buy and return the id of the proposal
    function createProposal(uint256 _nftTokenId) external nftHoldersOnly returns(uint256) {
        require(nftMarketPlace.available(_nftTokenId), "nft is not available for sale");

        //create a variable "proposal" of type "Proposal"(created as a struct above)
        //initialize to the struct "Proposal" with index of "numProposals" (as represented by the mapping of proposals)
        Proposal storage proposal = proposals[numProposals];
        proposal.nftTokenId = _nftTokenId;
        proposal.deadline = block.timestamp + 5 minutes;

        numProposals++;
        return (numProposals - 1);
    }

    function voteOnProposal(uint256 _id, Vote _vote) external nftHoldersOnly activeProposalOnly(_id) {
        Proposal storage proposal = proposals[_id];

        uint256 voterBalance = cryptoDevsNFT.balanceOf(msg.sender);

        uint256 numOfVotes;
        for(uint256 i = 0; i < voterBalance; i++) {
            uint256 tokenId = cryptoDevsNFT.tokenOfOwnerByIndex(msg.sender, i);
            if(proposal.voters[tokenId] == false) {
                numOfVotes++;
                proposal.voters[tokenId] = true;
            }
        }

        require(numOfVotes > 0, "You have already voted!");
        if(_vote == Vote.Yes) {
            proposal.yesVotes += numOfVotes;
        }else {
            proposal.noVotes += numOfVotes;
        }
    }

    function executeProposal(uint256 _id) external nftHoldersOnly inActiveProposalOnly(_id) {
        Proposal storage proposal = proposals[_id];

        if(proposal.yesVotes > proposal.noVotes) {
            uint256 nftPrice = nftMarketPlace.getPrice();
            require(address(this).balance > nftPrice, "Insufficient fund");

            nftMarketPlace.purchase{value: nftPrice}(proposal.nftTokenId);
        }
        proposal.executed = true;
    }

    function withdrawEther() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    receive() external payable {}
    fallback() external payable {}
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