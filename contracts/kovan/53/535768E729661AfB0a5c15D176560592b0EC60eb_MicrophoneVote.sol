/**
 *Submitted for verification at Etherscan.io on 2022-07-29
*/

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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

// File: contracts/activity/MicrophoneVote.sol

// contracts/GameItem.sol

pragma solidity >=0.8.0;

interface INFT {
    function balanceOf(address owner) external view returns (uint256 balance);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}

contract MicrophoneVote is Ownable{

    struct Proposal{
        uint id;
        string description;
        uint voteCount;
        bool isExist;
    }

    mapping(uint => Proposal) public proposals;
    uint public proposalCount;
    INFT[] public nfts;
    mapping(uint=>bool) public tidUsed;
    mapping(address=>uint) public addressUsed;
    uint[] public commonIds;
    uint public start;
    uint public end;

    event ProposalVote(uint indexed id, uint indexed tokenId, address sender);

    constructor() {

    }

    function addNft(INFT[] calldata _nfts) public onlyOwner {
        nfts = _nfts;
    }

    function configOnTime(uint _start, uint _end) public onlyOwner {
        start = _start;
        end = _end;
    }

    function createProposal(uint id, string calldata description) public onlyOwner {
        require(!proposals[id].isExist, "proposal is exist");
        Proposal memory p;
        p.id = id;
        p.description = description;
        p.isExist = true;
        p.voteCount = 0;
        proposals[id] = p;
        proposalCount += 1;
    }

    function delProposal(uint id) public onlyOwner {
        require(proposals[id].isExist, "proposal is exist");
        delete proposals[id];
        proposalCount -= 1;
    }

    function tokenUnvotedCount(address to) public view returns (uint count) {
        for(uint i = 0; i < nfts.length; i++) {
            uint balance = nfts[i].balanceOf(to);
            for(uint k = 0; k < balance; k++) {
                uint tokenId = nfts[i].tokenOfOwnerByIndex(to, k);
                if(!tidUsed[tokenId]) {
                    count += 1;
                }
            }
        }
    }

    function tokenUnvotedIds(address to) internal returns (uint[] storage tokenIds) {
        tokenIds = commonIds;
        for(uint i = 0; i < nfts.length; i++) {
            uint balance = nfts[i].balanceOf(to);
            for(uint k = 0; k < balance; k++) {
                uint tokenId = nfts[i].tokenOfOwnerByIndex(to, k);
                if(!tidUsed[tokenId]) {
                    tokenIds.push(tokenId);
                }
            }
        }
    }

    function vote(uint proposalId) external {
        require(proposals[proposalId].isExist, "proposal is not exist");
        require(block.timestamp > start && block.timestamp < end, "vote not on time");
        address sender = msg.sender;
        require(tokenUnvotedCount(sender) > 0, "no votes left");
        Proposal storage p = proposals[proposalId];
        // address sender = msg.sender;
        uint[] storage tokenIds = tokenUnvotedIds(sender);
        addressUsed[sender] = proposalId;
        for(uint i = 0; i < tokenIds.length; i ++) {
            p.voteCount += 1;
            tidUsed[tokenIds[i]] = true;
            emit ProposalVote(proposalId, tokenIds[i], sender);
        }
        delete commonIds;
    }
}