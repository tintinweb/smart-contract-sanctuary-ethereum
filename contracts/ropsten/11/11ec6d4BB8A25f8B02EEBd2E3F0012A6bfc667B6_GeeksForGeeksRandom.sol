/**
 *Submitted for verification at Etherscan.io on 2022-06-14
*/

// Solidity program to
// demonstrate on how
// to generate a random number
pragma solidity ^0.4.25;
 
// Creating a contract
contract GeeksForGeeksRandom
{
 
// Initializing the state variable
uint public timewarp;
bool public called;
uint256 public startTime = now;
 
// Defining a function to generate
// a random number

   function random() private view returns (uint) {
        return uint (keccak256(block.difficulty, now,  players));
    }

    function getNumber () public {
        timewarp = random() %  5400  ;

    }

    function test () public onlyAfter (startTime + 5 seconds  + timewarp) { 
         called = true;
    }


           modifier onlyAfter(uint _time) {
      require(
         now >= _time,
         "Function called too early."
      );
      _;
    
       }

address[] players;
mapping (address => uint256) public roundActive;
mapping (address => uint256) public coinsHad;
uint256 public lotteryRound;
bool lotteryActive;


    function lotterytart() public {
        require (lotteryActive == false, "PotOGold already active");
        lotteryActive = true;
        lotteryRound = lotteryRound +1;
    } 

     function enterLottery() public {
          require (lotteryActive == true, "lottery inactive");
          players.push(msg.sender);
          roundActive[msg.sender] =  lotteryRound;

     }


/// see whats up with this... see if this works... it did execute the else statement,
// now make sure its picking another until gets active winner.... might need to do a loop
//// or just keep everything the same and launch a new contract everytime
///what if i code an actual game with solidity
     function pickWinner() public returns (address) {
        
          for (roundActive[players[index]]; roundActive[players[index]] != lotteryRound;) {
               uint index = random() % players.length ;}
               coinsHad[players[index]] = 1000;
          lotteryActive = false;
           return players[index];
          
     }

  //   function removeSelf() public {
  //        added[msg.sender] = false;
  //   }
          



//    function getPlayers() public view returns (address[]) {
 //       return players;
    

     

}


///think i  might be good with click games.. maybe work on vesting contract when I get back
///to make more decentralized fees for dev AND hodlers;.. more value to token!!!!
///make sure everything named right...