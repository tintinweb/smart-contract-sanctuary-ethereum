/**
 *Submitted for verification at Etherscan.io on 2022-04-24
*/

pragma solidity ^0.4.24;

contract Lottery{
// -- the whole logic
// 1. Administrator: in charge of lottery drawing and return, add modifier function to limit the two functions
// 2. Address [] players
// 3. Number of current sessions: 1 will be added after each drawing and withdrawal

// 4. The lottery:
// (1) select a random number to determine the winning address
// (2) Allocate the bonus pool, divided into bonus and management fee
// (3) Transfer money to the winning address and the administrator address
// (4) stage number +1, clear the pool
// 5. awards:
// (1) transfer money to a loop address based on the array length
// (2) +1, empty the pool
// 6. 
// (1) require(the bet amount must be 1 Ether)
// (2) Add the betting address to the pool


	// Administrator address
    address public manager;
    // Winner
    address public winner;
    // Round number
    uint256 public round = 1;
    // All participating lottery players (administrators can also participate in the game)
    address[] public players;
	// The person who deploys the contract is the administrator
    constructor() public{
        manager = msg.sender;
    }


    // The default unit of the contract is wei
    function play() payable public{
    	// Requires a minimum investment of 0.05ETH
        require(msg.value == 0.05 ether);
        // Add the punter to the pool
        players.push(msg.sender);
    }
	

//1. Random winning requires a random index value, we use the difficulty value, current time, the number of participants as seeds to generate a large number of generated index.
//2. Check the validity before the lottery, if no one can not participate in the lottery.
//3. Round++, enter the next round.
    function KaiJiang() onlyManager public{
		// A random subscript value indicates the winner
        bytes memory tmp1 = abi.encodePacked(block.timestamp, block.difficulty, players.length);
        bytes32 tmp2 = keccak256(tmp1);
        uint256 tmp3 = uint256(tmp2);
        
		// Determine the address of the winner
        uint256 index = tmp3 % players.length;
        winner = players[index];
        
		// Transfer the money according to the 9-1 split rule
        uint256 contractMoney = address(this).balance;
        uint256 winnerMoney = contractMoney / 100 * 90;
        uint256 managerMoney = contractMoney - winnerMoney;
        winner.transfer(winnerMoney);
        manager.transfer(managerMoney);
		
		// At the end of this period count +1, and empty the pool
        round++;
        delete players;
    }
    
	// The administrator returns the prize
    function TuiJiang() onlyManager public{
    	//遍历数组，逐一转账
        for(uint i = 0; i < players.length; i++){
            players[i].transfer(1 ether);
        }

        round++;
        // Empty the players pool
        delete players;
    }
	
	// constrain
    modifier onlyManager{
    	// Restricted function, non-administrators are not allowed to call lottery and return functions
        require(msg.sender == manager);
        _;
    }

    // return the currency in the pool
    function getBalance() view public returns(uint){
        return address(this).balance;
    }

    // return the number of players
    function getPlayersLength() view public returns(uint){
        return players.length;
    }

    //Return the prize pool address as an array
    function getPlayers() view public returns(address []){
        return players;
    }
	
	// Return the manager address
    function getManager() view public returns(address){
        return manager;
    }
	
	// Return winner address
    function getWinner() view public returns(address){
        return winner;
    }
	
	// Return round number
    function getRound() view public returns(uint256){
        return round;
    }
}