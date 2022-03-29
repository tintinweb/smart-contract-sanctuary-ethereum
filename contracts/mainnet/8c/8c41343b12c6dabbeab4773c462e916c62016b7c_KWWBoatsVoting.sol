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

// File: contracts/KWWUtils.sol


pragma solidity >=0.7.0 <0.9.0;

library KWWUtils{

  uint64 constant DAY_IN_SECONDS = 86400;
  uint64 constant HOUR_IN_SECONDS = 3600;
  uint64 constant WEEK_IN_SECONDS = DAY_IN_SECONDS * 7;

  function pack(uint32 a, uint32 b) external pure returns(uint64) {
        return (uint64(a) << 32) | uint64(b);
  }

  function unpack(uint64 c) external pure returns(uint32 a, uint32 b) {
        a = uint32(c >> 32);
        b = uint32(c);
  }

  function random(uint256 seed) external view returns (uint256) {
    return uint256(keccak256(abi.encodePacked(
        tx.origin,
        blockhash(block.number - 1),
        block.difficulty,
        block.timestamp,
        seed
    )));
  }


  function getWeekday(uint256 timestamp) public pure returns (uint8) {
      //https://github.com/pipermerriam/ethereum-datetime
      return uint8((timestamp / DAY_IN_SECONDS + 4) % 7);
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
// File: contracts/KWWBoatsVoting.sol


pragma solidity ^0.8.4;





contract KWWBoatsVoting is IBoatsVoting, Ownable {
    address gameManager;

    int8 public voteDay1 = 2;
    int8 public voteDay2 = 3;
    uint8 public durationHours = 24;
    uint8 public daysBetweenVotes = 7;

    //tokenId => BoatData
    mapping(uint16 => BoatData) public boatsDetails;
    //boatState => State Vote data
    mapping(uint8 => TypeVote) public votes;

    /*
       EXECUTABLE FUNCTIONS
    */

    function setBoatDetails(uint16 idx, BoatData memory data)  public override onlyGameManager{
        boatsDetails[idx] = data;
    }

    function makeVote1(uint16 tokenId, uint256 vote, uint8 boatState) public override onlyGameManager{
        require(getCurrentOnlineVote() == 1, "Vote 1 is not online right now");
        require(getLastVoteTime(1) > getVoteTimeByDate(boatsDetails[tokenId].timestampVoted1 ,1), "Already Voted!");

        votes[boatState].priceSum += vote;
        votes[boatState].voters += 1;
        votes[boatState].avg = votes[boatState].priceSum / votes[boatState].voters;

        boatsDetails[tokenId].vote1 = vote;
        boatsDetails[tokenId].timestampVoted1 = uint48(block.timestamp);
    }

    function makeVote2(uint16 tokenId, bool vote, uint8 boatState) public onlyGameManager{
        require(getCurrentOnlineVote() == 2, "Vote 2 is not online right now");
        require(getLastVoteTime(2) > getVoteTimeByDate(boatsDetails[tokenId].timestampVoted2 ,2), "Already Voted!");

        votes[boatState].agreeToAvg += (vote ? int16(1) : int16(-1));
        
        boatsDetails[tokenId].vote2 = vote;
        boatsDetails[tokenId].timestampVoted2 = uint48(block.timestamp);
    }

    function updatePrice(uint8 boatState) public onlyGameManager {
        require(getCurrentOnlineVote() == 0, "Vote is online");
        require(votes[boatState].voters > 0, "No one voted this week");

        if(votes[boatState].agreeToAvg > 0){
            votes[boatState].finalPrice = votes[boatState].avg;
        }

        votes[boatState].voters = 0;
        votes[boatState].priceSum = 0;
        votes[boatState].avg = 0;
        votes[boatState].agreeToAvg = 0;
    }

    function setVoteDetails(uint8 boatState, TypeVote memory vote) public onlyGameManager {
        votes[boatState] = vote;
    }

    function setFinalPrice(uint8 boatState, uint256 finalPrice) public onlyGameManager {
        votes[boatState].finalPrice = finalPrice;
    }

    function setPriceSum(uint8 boatState, uint256 priceSum) public onlyGameManager {
        votes[boatState].priceSum = priceSum;
    }
    
    function setAvg(uint8 boatState, uint256 avg) public onlyGameManager {
        votes[boatState].avg = avg;
    }

    function setVoters(uint8 boatState, uint16 voters) public onlyGameManager {
        votes[boatState].voters = voters;
    }
    
    function setAgreeToAvg(uint8 boatState, int16 agreeToAvg) public onlyGameManager {
        votes[boatState].agreeToAvg = agreeToAvg;
    }

    function setVote1(uint16 tokenId, uint256 vote1) public onlyGameManager {
        boatsDetails[tokenId].vote1 = vote1;
    }

    function setVote2(uint16 tokenId, bool vote2) public onlyGameManager {
        boatsDetails[tokenId].vote2 = vote2;
    }
    
    function setTimestampVoted1(uint16 tokenId, uint48 timestampVoted1) public onlyGameManager {
        boatsDetails[tokenId].timestampVoted1 = timestampVoted1;
    }
    
    function setTimestampVoted2(uint16 tokenId, uint48 timestampVoted2) public onlyGameManager {
        boatsDetails[tokenId].timestampVoted2 = timestampVoted2;
    }
    
    /*
        GETTERS
    */

    function getBoatDetails(uint16 idx) public override view returns(BoatData memory){
        return boatsDetails[idx];
    }
    
    function getVoteDetails(uint8 boatState) public view returns(TypeVote memory){
        return votes[boatState];
    }

    function getAveragePrice(uint8 boatState) public view returns(uint256){
        return votes[boatState].avg;
    }

    function getPrice(uint8 boatState) public view returns(uint256){
        return votes[boatState].finalPrice;
    }

    function getLastVoteTime(uint8 voteType) public override view returns(int){
        return getVoteTimeByDate(block.timestamp, voteType);
    }

    function getVoteTimeByDate(uint256 timestamp, uint8 voteType) public override view returns (int){
        int8 voteDay = voteType == 1 ? voteDay1 : voteDay2;

        int8 delta = voteDay - int8(KWWUtils.getWeekday(timestamp));
        if(delta > 0) delta = delta - 7;
        int date = (int(timestamp) + delta * int64(KWWUtils.DAY_IN_SECONDS));
        return  date - date % int64(KWWUtils.DAY_IN_SECONDS);
    }

    function getCurrentVoteEndTime() public view returns(int256) {
        uint8 onlineVote = getCurrentOnlineVote();

        if(onlineVote == 1){
            return getLastVoteTime(1) + int64(durationHours * KWWUtils.HOUR_IN_SECONDS);
        }
        
        if(onlineVote == 2){
            return getLastVoteTime(2) + int64(durationHours * KWWUtils.HOUR_IN_SECONDS);
        }

        return 0;
    }

    function getCurrentOnlineVote() public override view returns (uint8) {
        int lastVote1 = getLastVoteTime(1);
        int lastVote2 = getLastVoteTime(2);

        //Vote1 Time
        if(lastVote1 > lastVote2 && lastVote1 + int64(durationHours * KWWUtils.HOUR_IN_SECONDS) > int(block.timestamp)){
            return 1;
        }

        if(lastVote2 + int64(durationHours * KWWUtils.HOUR_IN_SECONDS) > int(block.timestamp)){
            return 2;
        }

        return 0;
    }    

    /*
        MODIFIERS
    */

    modifier onlyGameManager() {
        require(gameManager != address(0), "Game manager not exists");
        require(msg.sender == owner() || msg.sender == gameManager, "caller is not the game manager");
        _;
    }

    /*
        ONLY OWNER
    */

    function setVoteDay1(uint8 newDay) public override onlyOwner {
      voteDay1 = int8(newDay);
    }

    function setVoteDay2(uint8 newDay) public override onlyOwner {
      voteDay2 = int8(newDay);
    }

    function setDurationHours(uint8 newHours) public override onlyOwner {
        require(newHours > 0, "Must be more than 0 and less than time between votes");
        durationHours = newHours;
    }

    function setGameManager(address _newAddress) public onlyOwner{
        gameManager = _newAddress;
    }
}