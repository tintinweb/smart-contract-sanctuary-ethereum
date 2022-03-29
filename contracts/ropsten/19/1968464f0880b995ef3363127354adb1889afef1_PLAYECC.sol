/**
 *Submitted for verification at Etherscan.io on 2022-03-29
*/

pragma solidity ^0.4.0;

contract ERC20 {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract PLAYECC {
    address token = 0x722dd3F80BAC40c951b51BdD28Dd19d435762180;
    address private admin = 0xe3B5823b5F677Ff515fba843905a55FeB5358D3d;
    uint public startPayPerc = 200;
	//uint public MinAmountToBet = 10000000000000000; // 0.001
	//uint public MaxAmountToBet = 1000000000000000000000; // 1000
	uint public lastBet = block.timestamp;
	uint private constant timeStep = 1 minutes;
	uint private constant pendigStep = 40;
	
	mapping(address => User) private users;
	mapping(address => LostGames) private games;
	
	struct User {
		address addr;
		address upline;
		uint numGames;
		uint amountW;
        uint amountL;
		uint totRefs;
        uint totRewards;
		
		LostGames[] pendingBets;
    }
	
	struct LostGames {
		address addr;
		uint blocktimestamp;
        uint bet;
		bool winner;
        uint withdrawn;
    }	
	
	LostGames newPendingBet;
	
	struct Game {
		address addr;
		uint blocknumber;
		uint blocktimestamp;
        uint bet;
		uint prize;
        bool winner;
    }
	
	Game[] lastPlayedGames;
	
	Game newGame;
    
    event Status(
		string _msg, 
		address user, 
		uint amount,
		bool winner
	);
    
    function Play() public payable {
		
		//if (msg.value <= MinAmountToBet) {
		//	revert();
		//} else { 
		
		User storage user = users[msg.sender];
		
		user.addr = msg.sender;
		user.numGames++;
		user.amountW = msg.value;
        
		
		// uint refReward = msg.value / 20;

		
		lastBet = block.timestamp;
		
			if ((block.timestamp % 2) == 0) {
				
				if (address(this).balance < (msg.value * ((1000 + startPayPerc + getBonusPercent()) / 1000))) {
					Status('YOU WON! Unfortunately we dont have enought money, we will send you everything we have!', msg.sender, msg.value, true);
					
					newGame = Game({
						addr: msg.sender,
						blocknumber: block.number,
						blocktimestamp: block.timestamp,
						bet: msg.value,
						prize: address(this).balance,
						winner: true
					});

					lastPlayedGames.push(newGame);
					
				} else {
					uint _prize = msg.value * ((1000 + startPayPerc + getBonusPercent()) / 1000);
					user.amountL += _prize;
					Status('YOU WON!', msg.sender, _prize, true);
					msg.sender.transfer(_prize);
					
					newGame = Game({
						addr: msg.sender,
						blocknumber: block.number,
						blocktimestamp: block.timestamp,
						bet: msg.value,
						prize: _prize,
						winner: true
					});

					lastPlayedGames.push(newGame);
					
				}
			
            } else {
				Status('You lost...', msg.sender, msg.value, false);
				
				newGame = Game({
					addr: msg.sender,
					blocknumber: block.number,
					blocktimestamp: block.timestamp,
					bet: msg.value,
					prize: 0,
					winner: false
				});
				
				lastPlayedGames.push(newGame);
				
				newPendingBet = LostGames({
					addr: msg.sender,
					blocktimestamp: block.timestamp,
					bet: msg.value,
					winner: false,
					withdrawn: 0
				});
				
				user.pendingBets.push(newPendingBet);
				
				
			}
		}
	
    
	
	function getGameCount() public constant returns(uint) {
		return lastPlayedGames.length;
	}

	function getGameEntry(uint index) public constant returns(address addr, uint blocknumber, uint blocktimestamp, uint bet, uint prize, bool winner) {
		return (lastPlayedGames[index].addr, lastPlayedGames[index].blocknumber, lastPlayedGames[index].blocktimestamp, lastPlayedGames[index].bet, lastPlayedGames[index].prize, lastPlayedGames[index].winner);
	}
	
	//function getGameLost(address _addr) constant returns (address addr, uint timestamp, uint bet, bool winner, uint withdrawn) {
	//	return (users.pendingBets[index].addr, user.pendingBets[_addr].timestamp, user.pendingBets[_addr].bet, user.pendingBets[_addr].winner, user.pendingBets[_addr].withdrawn);
	//}
	
	function getBonusPercent() public constant returns(uint) {
		return (block.timestamp - lastBet) / timeStep;
	}
	
}