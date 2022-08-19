//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./utils/Pausable.sol";
import "./utils/Ownable.sol" ;

contract Lottery is Pausable, Ownable {
 


  uint256 roundId;
  
  mapping (uint => address[]) internal playersByRoundId;      // PlayerID => participant_address
  mapping(uint => mapping(address => uint[] )) internal guessesByUser;      //participant_address => guess
  mapping(uint=>address[]) internal winnersByRound;

    //  lotteryId => user => Guesses[]
       enum Status {ACTIVE,RESOLVED}
       
       struct  Round {
        uint ID;
        string subject;
        uint prize;
        uint ticketPrice;
        uint answer;
        uint StartingTime;
        uint aliveForWithSec;
        bool isActive;
    }
  mapping(uint256 =>  Round) public round;


  event Guess(
      address indexed from,
      uint indexed PlayerID,
      uint indexed _guess,
      uint value
  );
  event Distribution(
      address[] indexed winners,
      uint indexed winningAmount
  );
    
    constructor() {
      roundId = 1;
    }
    

  function makeGuess(uint _roundID, uint guess) 
  public
  payable 
  returns(bool){
    require(round[_roundID].isActive == true, "Sorry This round is not activated." );
    require(msg.sender != owner(), "Sorry Owner, transparency first !!!");
    require(guess != 0x20,"cannot be empty");
    require(msg.value == round[_roundID].ticketPrice,"Price is not right !");
    require(round[_roundID].aliveForWithSec >= block.timestamp,"Sorry this round is finished" );
    
     bool j = false;
        for (uint i = 0; i < playersByRoundId[_roundID].length; i++) {
            if (playersByRoundId[_roundID][i] == msg.sender) { j=true;}
        }if(j==false) {playersByRoundId[_roundID].push(msg.sender);}

        guessesByUser[_roundID][msg.sender].push(guess);
    return true;
  }
 function finishRound(uint _roundId) public onlyOwner{
   require(round[_roundId].isActive == true, "Sorry This round is not activated." );
   require(round[_roundId].StartingTime != 0, "Round does not exist");
   round[_roundId].isActive = false;
 }

 function answersOfUserByRound(uint _roundId, address _User) public view returns(uint[] memory){
   return guessesByUser[_roundId][_User];
 }
             
function drawWinner( uint _roundID, uint _roundAnswer)
  public 
  onlyOwner
   {
      require(round[_roundID].isActive == true ,"Round already closed.");
      
      round[_roundID].answer = _roundAnswer;
       
            //mapping (uint => address[]) public playersByRoundId;      // PlayerID => participant_address
            //mapping(uint => mapping(address => uint[] )) public guessesByUser;      //participant_address => guess
            // mapping(uint=>address[]) public winnersByRound;
    for(uint i; i< playersByRoundId[_roundID].length;i++) {
      address addr = playersByRoundId[_roundID][i];
          for(uint j; j<(guessesByUser[_roundID][playersByRoundId[_roundID][i]].length  ) ;j++ ){
                  if (guessesByUser[_roundID][addr][j]==_roundAnswer){
                    winnersByRound[_roundID].push(addr);
                    }
          }
    } 
        payPrize(_roundID);
    round[_roundID].isActive = false;
  }
    function payPrize(uint _roundID) private onlyOwner {
      for(uint i; i< winnersByRound[_roundID].length;i++){
         address payable receiver = payable(winnersByRound[_roundID][i]);
         uint IndividualPrize = round[_roundID].prize/winnersByRound[_roundID].length;
        receiver.transfer(IndividualPrize);
      }
    }
  function WinnersByRoundId(uint _roundId) public view returns(address[] memory ){
       return winnersByRound[_roundId];
  }
  function createNewRound( string memory _subject, uint _prize, uint _ticketPrice, uint _aliveForWithSec ) public onlyOwner {


          round[roundId] = Round ({
                  ID : roundId,
                   subject: _subject,
                   prize: _prize,
                   ticketPrice: _ticketPrice,
                   answer : 0,
                   StartingTime: block.timestamp,
                   aliveForWithSec: block.timestamp+_aliveForWithSec,
                   isActive: true
              });





    roundId++;
  }


receive() external payable {
       
      }
        function getEth() payable public returns(string memory){
        return "Thanks";
    }
  
    function EtherBalance() public view returns(uint){
        return address(this).balance;
    }

    function withdrawAdmin() public payable onlyOwner {
        address payable receiver = payable(owner());
        require(address(this).balance != 0, "Balance is Null");
        receiver.transfer(address(this).balance);
    }

 
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;



/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    
}

// SPDX-License-Identifier: MIT
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
abstract contract Ownable  {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
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
        require(owner() == msg.sender, "Ownable: caller is not the owner");
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