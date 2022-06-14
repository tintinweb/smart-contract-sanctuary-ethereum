// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "Ownable.sol";

// iconic NFTs interface
interface IdaoNft{
    function balanceOf(address _owner) external view returns (uint256);}


contract FocusDao is Ownable {

   
    uint256 nextproposal;
    uint256[] public validTokens;
    IdaoNft nftContract;
    

    struct Proposal {
        uint256 id;
        bool exists;
        string description;
        uint256 deadline;
        uint256 votesFor;
        uint256 votesAgainst;
        address[] canVote;
        uint256 maxVotes;
        mapping(address => bool) voteStatus;
        bool countConducted;
        bool passed;
    }

    mapping(uint256 => Proposal) public proposal;

    event proposalCreated(
        uint256 id,
        string description,
        uint256 maxVotes,
        address proposer
    );

    event newVote(
        uint256 votesUp,
        uint256 votesDown,
        address voter,
        uint256 proposal,
        bool votedFor
    );
    
    event proposalCount(
        uint256 id,
        bool passed
    );

    event updateNFTContract( address _address);


    constructor(address nftAddress){
        // owner = msg.sender;
        nextproposal = 1;
        nftContract = IdaoNft(nftAddress);
        validTokens = [0];
    }

    function setNFTContract(address _address) external onlyOwner {
        nftContract = IdaoNft(_address);
        emit updateNFTContract(_address);
    }


    function checkProposalEligibility(address _proposalist) private view returns (bool) {
        for(uint i = 0; i < validTokens.length; i++){
            if(nftContract.balanceOf(_proposalist) >= 1){
                return true;
            }
        }
        return false;
    }

    function checkVoteEligibility(uint256 _id, address _voter) private view returns (bool) {
        for (uint256 i=0; i < proposal[_id].canVote.length; i++){
            if(proposal[_id].canVote[i] == _voter) {
                return true;
            }
        }

        return false;
    }
    
    function createProposal(string memory _description, address[] memory _canVote) public {
        require(checkProposalEligibility(msg.sender), "Only NFT holders can put forth Proposals");

        Proposal storage newProposal = proposal[nextproposal];
        newProposal.id = nextproposal;
        newProposal.exists = true;
        newProposal.description = _description;
        newProposal.deadline = block.number + 100;
        newProposal.canVote = _canVote;
        newProposal.maxVotes = _canVote.length;

        emit proposalCreated(nextproposal, _description, _canVote.length, msg.sender);
        nextproposal ++;
    }

    function voteOnProposal(uint256 _id, bool _vote) public {
        require(proposal[_id].exists, "This Proposal does not exist");
        require(block.number <= proposal[_id].deadline, "The deadline has passed for this Proposal");
        require(checkVoteEligibility(_id, msg.sender), "You can not vote on this Proposal");
        require(!proposal[_id].voteStatus[msg.sender], "You have already voted on this Proposal");
        
        Proposal storage p = proposal[_id];

        p.voteStatus[msg.sender] = true;
        
        if(_vote) {
            p.votesFor++;
        }else {
            p.votesAgainst++;
        }

        emit newVote(p.votesFor, p.votesAgainst, msg.sender, _id, _vote);
    }

    function countVotes(uint256 _id) public onlyOwner {
        require(proposal[_id].exists, "This Proposal does not exist");
        require(block.number > proposal[_id].deadline, "Voting has not concluded");
        require(!proposal[_id].countConducted, "Count already conducted");

        Proposal storage p = proposal[_id];

        if (p.votesFor > p.votesAgainst) {
            p.passed = true;
        }

        p.countConducted = true;

        emit proposalCount(_id, p.passed);
    }

    function addTokenId(uint256 _tokenId) public onlyOwner {
        validTokens.push(_tokenId);
    }

    

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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