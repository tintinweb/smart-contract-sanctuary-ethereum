/**
 *Submitted for verification at Etherscan.io on 2022-09-07
*/

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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: contracts/Betting.sol


pragma solidity ^0.8.14;


//@TODO CANCELED MatchResult
//@TODO onlyOwner withdrawal
//@TODO Oracle implementation
contract Betting is Ownable {

  enum MatchResult{ PENDING, TEAM_A, TEAM_B, DRAW }

  uint contractFee = 4;
  uint devFee = 1;

  struct Match {
    string teamAName;
    string teamBName;
    uint16 rateA;
    uint16 rateB;
    uint16 rateDraw;
    uint64 endBetTime;
    MatchResult result;
    bool finished;
  }

  struct Bet {
    uint matchId;
    MatchResult result;
  }

  struct MultiBet {
    mapping (uint => Bet) bets;
    uint value;
    bool received;
    uint betsCount;
    uint prize;
  }

  Match[] public matches;

  MultiBet[] public Bets;
  mapping (uint => address) public BetToOwner;
  mapping (address => uint[]) public OwnerToBets;

  function createMatch(
    string memory _teamAName, 
    string memory _teamBName, 
    uint16 _rateA, 
    uint16 _rateB, 
    uint16 _rateDraw, 
    uint64 _endBetTime) public onlyOwner returns(uint) 
  {
    require(keccak256(bytes(_teamAName)) != keccak256(bytes(_teamBName)));
    require(_rateA > 100, "_rateA");
    require(_rateB > 100, "_rateB");
    require(_rateDraw > 100, "_rateDraw");
    require(_endBetTime > block.timestamp, "_endBetTime");

    matches.push(Match(_teamAName, _teamBName, _rateA, _rateB, _rateDraw, _endBetTime, MatchResult.PENDING, false));
    return matches.length - 1;
  }

  function setMatchResult(uint _matchId, MatchResult _matchResult) public onlyOwner {
    require(_matchResult != MatchResult.PENDING);
    require(matches[_matchId].finished == false);

    matches[_matchId].result = _matchResult;
    matches[_matchId].finished = true;
  }

  function betMatches(uint[] calldata _matchIds, MatchResult[] calldata _matchResults) public payable returns(uint) {
    require(msg.value > 0, "msg.value");
    require(_matchIds.length == _matchResults.length, "_matchIds.length != _matchResults.length");
    
    uint i = 0;
    for (; i < _matchIds.length; i++) {
      require(matches[_matchIds[i]].endBetTime > block.timestamp);
      require(_matchResults[i] != MatchResult.PENDING);
    }

    MultiBet storage newMultiBet = Bets.push();
    newMultiBet.value = msg.value;
    newMultiBet.received = false;
    newMultiBet.betsCount = 0;

    for (i = 0; i < _matchIds.length; i++) {
      newMultiBet.bets[newMultiBet.betsCount] = Bet(_matchIds[i], _matchResults[i]);
      newMultiBet.betsCount += 1;
    }

    BetToOwner[Bets.length - 1] = msg.sender;
    OwnerToBets[msg.sender].push(Bets.length - 1);

    return Bets.length - 1;
  }

  function receiveBetPrize(uint _BetsId) public payable {
    require(BetToOwner[_BetsId] == msg.sender, "msg.sender");
    require(Bets[_BetsId].received == false, "received != false");
    
    uint i = 0;
    for (; i < Bets[_BetsId].betsCount; i++) {
      require(matches[Bets[_BetsId].bets[i].matchId].finished == true, "finished != true");
      require(matches[Bets[_BetsId].bets[i].matchId].result == Bets[_BetsId].bets[i].result, "result");
    }

    uint prize = Bets[_BetsId].value;
    uint16 rate = 0;
    for (i = 0; i < Bets[_BetsId].betsCount; i++) {
      if (matches[Bets[_BetsId].bets[i].matchId].result == MatchResult.TEAM_A) rate = matches[Bets[_BetsId].bets[i].matchId].rateA;
      if (matches[Bets[_BetsId].bets[i].matchId].result == MatchResult.TEAM_B) rate = matches[Bets[_BetsId].bets[i].matchId].rateB;
      if (matches[Bets[_BetsId].bets[i].matchId].result == MatchResult.DRAW) rate = matches[Bets[_BetsId].bets[i].matchId].rateDraw;

      prize = prize * rate / 100;     
    }
    
    Bets[_BetsId].received = true;
    Bets[_BetsId].prize = (prize * (100 - (contractFee + devFee)))/100;
    payable(msg.sender).transfer(Bets[_BetsId].prize);
    payable(owner()).transfer((prize * devFee)/100);
  }
}