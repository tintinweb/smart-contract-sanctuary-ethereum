pragma solidity ^0.4.24;

import "./utils/SafeMath.sol";
import './RefereeOnly.sol';

contract PoolBetQatar is RefereeOnly {
  using SafeMath for uint256;

  struct PoolBet {
    uint id;
    uint teamBet; // 0..31, teams of world cup
    address gambler;
    uint256 totalBet; // amount of bet
    uint timestamp; // timestamp
  }

  mapping (uint => PoolBet) public poolBets;
  mapping (uint => uint256) public totalPool;
  mapping (address => uint) public referalIds;
  uint256 public totalReward;

  uint poolBetCounter;
  uint public refereeCommision = 5;
  uint public referalCommision = 15;
  bool public gamePoolActive = true;

  event LogPublishPoolBet(
    uint indexed _id,
    uint teamBet,
    address indexed _gambler,
    uint256 totalBet,
    uint timestamp
  );

  // Publish a new bet
  function publishPoolBet(uint teamBet, uint referalId) payable public {
    // The challenger must deposit his bet
    require(msg.value > 0, "Has to send"); // Add min bet ?
    require(gamePoolActive, "Game is not active");

    // A new bet
    poolBetCounter++;

    // Send commision
    uint256 comission = msg.value.mul(refereeCommision).div(100); // calcular mejor

    if (referalId < poolBetCounter && referalId > 0) {
      uint256 referalCommission = comission.mul(referalCommision).div(100);
      poolBets[referalId].gambler.transfer(referalCommission);
      comission = comission.sub(referalCommission);
    } 

    referee.transfer(comission);


    // Calculate Reward
    uint256 totalPrice = msg.value.sub(comission);

    // set reward
    totalReward += totalPrice;

    // Store this bet into the contract
    poolBets[poolBetCounter] = PoolBet(
      poolBetCounter,
      teamBet,
      msg.sender,
      totalPrice,
      block.timestamp
    );
    referalIds[msg.sender] = poolBetCounter;

    // Set totalPool
    totalPool[teamBet] += totalPrice;

    // Trigger a log event
    emit LogPublishPoolBet(poolBetCounter, teamBet, msg.sender, totalPrice, block.timestamp);
  }

  // Fetch the total number of bets in the contract
  function getPoolRatio(uint teamBet) public view returns (uint256) {
    if (totalPool[teamBet] == 0) {
      return totalReward;
    } else {
      uint256 ratio = totalReward.div(totalPool[teamBet]);
      return ratio;
    }
  }


  // Fetch the total number of bets in the contract
  function getNumberOfBets() public view returns (uint) {
    return poolBetCounter;
  }

  // Set commission
  function setCommision(uint _newCommision) refereeOnly public returns (uint) {
    refereeCommision = _newCommision;
  }

  function setReferalCommision(uint _newCommision) refereeOnly public returns (uint) {
    referalCommision = _newCommision;
  }

  // Set commission
  function setGameActive(bool _gamePoolActive) refereeOnly public returns (bool) {
    gamePoolActive = _gamePoolActive;
  }

  function unstuck_bnb() refereeOnly public {
    address(msg.sender).transfer(address(this).balance);
  }

}

pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
    string private constant ERROR_ADD_OVERFLOW = "MATH_ADD_OVERFLOW";
    string private constant ERROR_SUB_UNDERFLOW = "MATH_SUB_UNDERFLOW";
    string private constant ERROR_MUL_OVERFLOW = "MATH_MUL_OVERFLOW";
    string private constant ERROR_DIV_ZERO = "MATH_DIV_ZERO";

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b, ERROR_MUL_OVERFLOW);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0, ERROR_DIV_ZERO); // Solidity only automatically asserts when dividing by 0
        uint256 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a, ERROR_SUB_UNDERFLOW);
        uint256 c = _a - _b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a, ERROR_ADD_OVERFLOW);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, ERROR_DIV_ZERO);
        return a % b;
    }
}

pragma solidity ^0.4.24;

contract RefereeOnly {

  address referee;

  modifier refereeOnly() {
    require(msg.sender == referee, "You are not referee");
    _;
  }

  constructor() public {
    referee = msg.sender;
  }
}