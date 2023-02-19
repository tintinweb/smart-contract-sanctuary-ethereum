/**
 *Submitted for verification at Etherscan.io on 2023-02-19
*/

// SPDX-License-Identifier: MIT
// File: utils/SafeMath.sol



pragma solidity ^0.8.16;

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
// File: https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/utils/Context.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/access/Ownable.sol


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

// File: P2PBets.sol



pragma solidity ^0.8.16;



interface IERC20 {
    function totalSupply() external view returns (uint _totalSupply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}


contract P2PBets is Ownable {
  using SafeMath for uint256;

  struct PoolBet {
    uint id;
    uint matchId;
    uint option; // 0 local, 1 away
    address gambler;
    address accepter;
    uint256 totalBet; // amount of bet
    uint256 commission; // amount of bet
    uint status; // 0 pending, 1 resolved, 2 rollbacked
    uint timestamp; // timestamp
    uint accepterDate; // timestamp
  }

  mapping (uint => PoolBet) public poolBets;
  mapping (uint => uint256) public totalPool;
  mapping (address => uint) public referalIds;
  mapping (address => uint) public balance;
  uint256 public totalReward;

  uint public poolBetCounter;
  uint public refereeCommision = 2;
  uint public referalCommision = 15;
  bool public gamePoolActive = true;
  bool public withdrawActive = true;
  
  IERC20 tokenPlay;

  constructor (address _tokenPlayAddress) {
    tokenPlay = IERC20(_tokenPlayAddress);
  }

  event LogPublishPoolBet(
    uint indexed _id,
    uint matchId,
    uint option,
    address indexed _gambler,
    uint256 totalBet,
    uint timestamp
  );

  event LogAcceptedBet(
    uint indexed _id,
    address indexed accepter,
    uint timestamp
  );

  event LogResolvedBet(
    uint indexed _id,
    address indexed winner,
    uint timestamp
  );

  // Publish a new bet
  function publishPoolBet(uint matchId, uint option, uint256 _amount) public {
    // The challenger must deposit his bet
    require(tokenPlay.balanceOf(msg.sender) > 0, "Dont have funds to play"); // Add min bet ?
    require(gamePoolActive, "Game is not active");

    bool sent = tokenPlay.transferFrom(msg.sender, address(this), _amount);
    require(sent, "funds has to be sent");

    // A new bet
    poolBetCounter++;

    // Send commision
    uint256 commission = _amount.mul(refereeCommision).div(100); // calcular mejor

    uint totalPrice = _amount - commission;

    // Store this bet into the contract
    poolBets[poolBetCounter] = PoolBet(
      poolBetCounter,
      matchId,
      option,
      msg.sender,
      address(0x0),
      totalPrice,
      commission,
      0,
      block.timestamp,
      block.timestamp
    );

    // Trigger a log event
    emit LogPublishPoolBet(poolBetCounter, matchId, option, msg.sender, totalPrice, block.timestamp);
  }

  // Publish a new bet
  function acceptBet(uint betId) public {
    // The challenger must deposit his bet
    require(gamePoolActive, "Game is not active");

    require(poolBets[betId].status == 0, "Bet is not pending");

    uint256 comission = poolBets[betId].commission;
    require(tokenPlay.balanceOf(msg.sender) >= poolBets[betId].totalBet + comission, "Dont have funds to play"); // Add min bet ?

    bool sent = tokenPlay.transferFrom(msg.sender, address(this), poolBets[betId].totalBet + comission);
    require(sent, "funds has to be sent");

    poolBets[betId].status = 1;
    poolBets[betId].accepter = msg.sender;
    poolBets[betId].accepterDate = block.timestamp;
    emit LogAcceptedBet(poolBetCounter, msg.sender, block.timestamp);
  }

  function claim() public returns (bool) {
    require(balance[msg.sender] > 0, "You must to have balance");
    require(withdrawActive, "Withdraw must to be active");
    bool approve_done = tokenPlay.approve(address(this), balance[msg.sender] + 1);
    require(approve_done, "CA cannot approve tokens");
    bool sent = tokenPlay.transferFrom(address(this), msg.sender, balance[msg.sender]);
    require(sent, "funds has to be sent");
    balance[msg.sender] = 0;
    return sent;
  }

  function getUserBalance() public view returns (uint256) {
    return balance[msg.sender];
  }

  // Only the referee can resolve bets
  function resolveBet(uint betId, uint winnerOption) onlyOwner public returns (bool) {
    // getRatio for that pool
    require(poolBets[betId].status == 1, "Bet is not able to resolve");
    poolBets[betId].status = 2;
    if (winnerOption == poolBets[betId].option) {
        //balance al owner
        balance[poolBets[betId].gambler] += poolBets[betId].totalBet * 2;
        emit LogAcceptedBet(betId, poolBets[betId].gambler, block.timestamp);
    } else {
        balance[poolBets[betId].accepter] += poolBets[betId].totalBet * 2;
        emit LogAcceptedBet(betId, poolBets[betId].accepter, block.timestamp);
    }
    return true;
  }

  function getBetsIdsByGambler(address gambler) public view returns (uint[] memory) {
    uint[] memory betIds = new uint[](poolBetCounter);
    uint numberOfAvailableBets = 0;

    // Iterate over all bets
    for(uint i = 1; i <= poolBetCounter; i++) {
      // Keep the ID if the bet is still available
      
      if(poolBets[i].gambler == gambler) {
        betIds[numberOfAvailableBets] = poolBets[i].id;
        numberOfAvailableBets++;
      }
    }

    uint[] memory availableBets = new uint[](numberOfAvailableBets);

    // Copy the betIds array into a smaller availableBets array to get rid of empty indexes
    for(uint j = 0; j < numberOfAvailableBets; j++) {
      availableBets[j] = betIds[j];
    }

    return availableBets;
  }

  function getBetsIdsByStatus(uint status) public view returns (uint[] memory) {
    uint[] memory betIds = new uint[](poolBetCounter);
    uint numberOfAvailableBets = 0;

    // Iterate over all bets
    for(uint i = 1; i <= poolBetCounter; i++) {
      // Keep the ID if the bet is still available
      
      if(poolBets[i].status == status) {
        betIds[numberOfAvailableBets] = poolBets[i].id;
        numberOfAvailableBets++;
      }
    }

    uint[] memory availableBets = new uint[](numberOfAvailableBets);

    // Copy the betIds array into a smaller availableBets array to get rid of empty indexes
    for(uint j = 0; j < numberOfAvailableBets; j++) {
      availableBets[j] = betIds[j];
    }

    return availableBets;
  }


  // Fetch the total number of bets in the contract
  function getNumberOfBets() public view returns (uint) {
    return poolBetCounter;
  }

  function rollbackBet(uint betId) onlyOwner public {
    require(poolBets[betId].status == 0 || poolBets[betId].status == 1, "Bet is not pending OR accepted");
    poolBets[betId].status = 3;
    balance[poolBets[betId].gambler] += poolBets[betId].totalBet + poolBets[betId].commission;
    if (poolBets[betId].status == 1) {
        balance[poolBets[betId].accepter] += poolBets[betId].totalBet  + poolBets[betId].commission;
    }
  }

  function rollbackBetByUser(uint betId) public {
    require(poolBets[betId].status == 0, "Bet is not pending");
    require(poolBets[betId].gambler == msg.sender, "Bet is not pending");
    poolBets[betId].status = 3;
    bool approve_done = tokenPlay.approve(address(this), poolBets[betId].totalBet);
    require(approve_done, "CA cannot approve tokens");
    tokenPlay.transferFrom(address(this), msg.sender, poolBets[betId].totalBet);
  }

  // Set commission
  function setCommision(uint _newCommision) onlyOwner public {
    refereeCommision = _newCommision;
  }

  function setReferalCommision(uint _newCommision) onlyOwner public {
    referalCommision = _newCommision;
  }

  // Set commission
  function setGameActive(bool _gamePoolActive) onlyOwner public{
    gamePoolActive = _gamePoolActive;
  }

  function setWithdrawActive(bool _withdrawActive) onlyOwner public{
    withdrawActive = _withdrawActive;
  }

  function setTokenPlay(address _tokenPlayAddress) onlyOwner public{
    tokenPlay = IERC20(_tokenPlayAddress);
  }

  function unstuck(uint256 _amount, address _addy) onlyOwner public {
    if (_addy == address(0)) {
      (bool sent,) = address(msg.sender).call{value: _amount}("");
      require(sent, "funds has to be sent");
    } else {
      bool approve_done = IERC20(_addy).approve(address(this), IERC20(_addy).balanceOf(address(this)));
      require(approve_done, "CA cannot approve tokens");
      require(IERC20(_addy).balanceOf(address(this)) > 0, "No tokens");
      IERC20(_addy).transfer(msg.sender, _amount);
    }
  }

}