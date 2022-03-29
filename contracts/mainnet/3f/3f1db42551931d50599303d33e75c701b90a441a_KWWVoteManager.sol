/**
 *Submitted for verification at Etherscan.io on 2022-03-29
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Context.sol


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

// File: contracts/IBoatsVoting.sol


pragma solidity >=0.7.0 <0.9.0;

interface IBoatsVoting {
  struct TypeVote{
      uint256 finalPrice;
      uint256 priceSum;
      uint256 avg;
      uint16 voters;
      int16 agreeToAvg;
  }
  struct BoatData {
    uint256 vote1;
    uint48 timestampVoted1;
    uint48 timestampVoted2;
    bool vote2;
  }

    function makeVote1(uint16 tokenId, uint256 vote, uint8 boatState) external;
    function getLastVoteTime(uint8 voteType) external view returns(int);
    function getVoteTimeByDate(uint256 timestamp, uint8 voteType) external view returns (int);
    function setVoteDay1(uint8 newDay) external;
    function setVoteDay2(uint8 newDay) external;
    function setBoatDetails(uint16 idx, BoatData memory data) external;
    function setDurationHours(uint8 newHours) external;
    function getCurrentOnlineVote() external view returns (uint8);
    function getBoatDetails(uint16 idx) external view returns(BoatData memory);
}
// File: contracts/IVoting.sol


pragma solidity ^0.8.4;


interface IVotingBoatData {
    function getBoatState(uint16 tokenId) external view returns(uint8);
}

interface IVotingBoatNFT {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface IVoting {
    function makeVote1(uint16 tokenId, uint256 vote, uint8 boatState) external ;
    function makeVote2(uint16 tokenId, bool vote, uint8 boatState) external;
    function updatePrice(uint8 boatState) external;
    function getCurrentOnlineVote() external view returns (uint8);
    function getCurrentVoteEndTime() external view returns(int256);
    function getPrice(uint8 boatState) external view returns(uint256);
    function getVoteDetails(uint8 boatState) external view returns(IBoatsVoting.TypeVote memory);
    function getBoatDetails(uint16 idx) external view returns(IBoatsVoting.BoatData memory);
}
// File: contracts/KWWVoteManager.sol


pragma solidity ^0.8.4;

//import "./KWWBoatsVoting.sol";
//import "./KWWBoats.sol";


//import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract KWWVoteManager is Ownable{
    IVoting votingContract;
    IVotingBoatNFT boatsNFTContract;
    //KWWDataBoats boatsDataContract;
    IVotingBoatData boatsDataContract;

    constructor(address _voting, address _nft, address _data){
        setVoting(_voting);
        setBoatsNFT(_nft);
        setBoatsData(_data);
    }


    /*
        EXECUTION METHODS
    */

    function makeVote1(uint16 token, uint256 votePrice) public {
        require(boatsNFTContract.ownerOf(token) == msg.sender, "Caller is not the owner of the token");
        uint8 boatState = boatsDataContract.getBoatState(token);
        votingContract.makeVote1(token, votePrice, boatState);
    }

    function makeVote2(uint16 token, bool voteDecision) public {
        require(boatsNFTContract.ownerOf(token) == msg.sender, "Caller is not the owner of the token");
        uint8 boatState = boatsDataContract.getBoatState(token);
        votingContract.makeVote2(token, voteDecision, boatState);
    }

    function updatePrice(uint16 token) public {
        uint8 boatState = boatsDataContract.getBoatState(token);
        votingContract.updatePrice(boatState);
    }

    function updateStatePrice(uint8 boatState) public {
        votingContract.updatePrice(boatState);
    }


    /*
        GETTERS
    */
    function getOnlineVote() public view returns(uint8){
        return votingContract.getCurrentOnlineVote();
    }

    function getOnlineVoteEndTime() public view returns(int){
        return votingContract.getCurrentVoteEndTime();
    }

    function getBoatPrice(uint16 token) public view returns(uint256){
        uint8 boatState = boatsDataContract.getBoatState(token);
        return votingContract.getPrice(boatState);
    }

    function getStateVoteDetails(uint16 token) public view returns(IBoatsVoting.TypeVote memory){
        uint8 boatState = boatsDataContract.getBoatState(token);
        return votingContract.getVoteDetails(boatState);
    }

    function getBoatDetails(uint16 token) public view returns(IBoatsVoting.BoatData memory){
        return votingContract.getBoatDetails(token);
    }



    /*
        ONLY OWNER
    */

    function setVoting(address _voting) public onlyOwner{
        votingContract = IVoting(_voting);
    }
        
    function setBoatsNFT(address _nft) public onlyOwner{
        boatsNFTContract = IVotingBoatNFT(_nft);
    }
        
    function setBoatsData(address _data) public onlyOwner{
        boatsDataContract = IVotingBoatData(_data);
    }
}