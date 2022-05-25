/**
 *Submitted for verification at Etherscan.io on 2022-05-24
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;


contract NextMillionaire {

    // owner of contract
    address public admin;

    // list of players (array)
    // payable = they can receive ether
    address payable[] public players;

    // lottery id
    uint256 public lotteryId;

    //lottery end timestamp
    uint256 public endtime;

    // nonce to be used for randomnumber generator and to prevent replay attacks
    uint256 public nonce;

    // the configurale entry entryFee
    uint256 public entryFee;

    //struct for lottery state
    enum LOTTERY_STATE{
        OPEN,        
        CLOSED
    }

    LOTTERY_STATE public lotteryState;

    // winners history
    mapping(uint => address payable) public lotteryHistory;

    //events
    event StartedLottery(uint256 lotterId);
    event PlayerJoined(uint256 lotterId, address indexed winner);
    
   /**
   * constructor to set the initial values of the lottery
   * admin - set to the contract deployer
   * lotteryId - start at 1 and increments everytime a new lottery starts
   * nonce - to start value at 1 and used to prevent any replay attacks  
   */
    constructor(){
        admin = msg.sender;
        lotteryId = 1; 
        lotteryState = LOTTERY_STATE.CLOSED;      
    }

   /**
   * getWinnerByLottery- get the winner of lottery address when lottery id is supplied
   * @param lottery -the past lotteryId
   * returns the address of the winner of the lotteryId  
   */
    function getWinnerByLottery(uint lottery) public view returns(address payable){
        return lotteryHistory[lottery];
    }

   /**
   * getBalance- get the balance of the contract to know the balace of the present lottery running 
   * returns the balance of the contract  
   */
    function getBalance() public view returns(uint){
        // returns how much is payed in this contract!
        return address(this).balance;
    }

   /**
   * getPlayers- get the players of the contract 
   * returns the players struct of the contract  
   */
    function getPlayers() public view returns(address payable[] memory){
        return players;
    }

   /**
   * registerForLottery- lets players to register to the lottery by paying 1 ether 
   *  
   */
    function registerForLottery() public payable {
        // Check if a game is already running
        require(lotteryState == LOTTERY_STATE.OPEN, "Game has not been started yet");
        // Check the 1 hour time limit to participate in the game
        require(block.timestamp <= endtime, " The time limit ended for the game-try next one");
        // Check if the value sent by the user matches the entryFee
        require(msg.value >= entryFee, "Value sent is not equal to entryFee - 1 ether");        
        // add the sender to the players list
        players.push(payable(msg.sender));
        emit PlayerJoined(lotteryId, msg.sender);
    }

   /**
   * getRandomNumber- Randon number to be used to pick the winner of the lottery 
   *  
   */
    function getRandomNumber() public view returns(uint){
        // hash a random num
        return uint(keccak256((abi.encodePacked(
        nonce,        
        block.timestamp,
        block.difficulty,
        msg.sender))));        
    }

    // Modifier -just owner can call this function
    modifier onlyOwner(){
        require(msg.sender == admin);
        _;
    }

   /**
   * startLottery- only admin can start the lottery
   *  Admin sets the end time and entryfee for the lottery
   */

    function startLottery() external onlyOwner{
        require(lotteryState == LOTTERY_STATE.CLOSED, "Lottery is running,check back later");
        endtime = block.timestamp + 3 minutes;
        entryFee = 1 ether;
        lotteryState =LOTTERY_STATE.OPEN;
        unchecked {
            nonce++;
        }
        emit StartedLottery(lotteryId);
    }

   /**
   * pickWinner- only admin can pick the winnner of the lottery
   *  Lottery winner gets paid the contract balance
   */
    function pickWinner() external onlyOwner{  
        require(lotteryState ==LOTTERY_STATE.OPEN, "Not in correct state");  
        require(block.timestamp >= endtime, "wait for end of lottery time");    
        uint index = getRandomNumber() % players.length;
        // pay to the winner
        players[index].transfer(address(this).balance);

        // add player to winners
        lotteryHistory[lotteryId] = players[index];

        // increment id of lottery
        // FIRST TRANSFER MONEY THAN CHANGE THE STATE
        // TO PREVENT REENTRY ATTACKS
        unchecked{ 
            lotteryId++;
        }
        // reset array for next round
        players = new address payable[](0);
        //set the lottery state to CLOSED
        lotteryState = LOTTERY_STATE.CLOSED;        
    }
}