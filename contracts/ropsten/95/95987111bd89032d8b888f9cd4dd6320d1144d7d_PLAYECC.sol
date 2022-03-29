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
    address private admin = 0x86521b85E2ba6a46158045d9512798a7b24Ac62B;
    uint public startPayPerc = 200;
	uint public MinAmountToBet = 10000000000000000; // 0.001
	uint public MaxAmountToBet = 1000000000000000000000; // 1000
	uint public lastBet = block.timestamp;
	uint private constant timeStep = 1 minutes;
	uint private constant pendigStep = 40;
	
	mapping(address => User) private users;
	
	struct Loses {
		address addr;
		uint timestamp;
        uint bet;
		bool winner;
        uint withdrawn;
    }	

	struct User {
		address addr;
		address upline;
		uint numGames;
		uint amountW;
        uint amountL;
		uint totRefs;
        uint totRewards;		
		Loses[] lostGames;
    }

	Game[] lastPlayedGames;
	
	struct Game {
		address addr;
		uint blocknumber;
		uint blocktimestamp;
        uint bet;
		uint prize;
        bool winner;
    }
	
	Game newGame;
	Loses newLose;
    
    event Status(
		string _msg, 
		address user, 
		uint amount,
		bool winner
	);
    
    function Play () public payable {
		
		if (msg.value <= MinAmountToBet) {
			revert();
		} else { 
		
		User storage user = users[msg.sender];
		
		user.addr = msg.sender;
		user.numGames++;
		user.amountW = msg.value;
		
		// uint refReward = msg.value / 20;

		// ERC20(token).transfer(user.upline, refReward);
		// users[ref].totRewards += refReward;
		lastBet = block.timestamp;
		
			if ((block.timestamp % 2) == 0) {
				
				if (address(this).balance < (msg.value * ((1000 + startPayPerc + getBonusPercent()) / 1000))) {
					Status('YOU WON! Unfortunately we dont have enought money...!', msg.sender, msg.value, true);
					
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
				
				//	newLose = Loses({
				//	addr: msg.sender,
				//	blocktimestamp: block.timestamp,
				//	bet: msg.value,
				//	winner: false,
				//	withdrawn: 0
				//});

				user.lostGames.push(newLose);
			}
		}
    }
	
	function getGameCount() public constant returns(uint) {
		return lastPlayedGames.length;
	}

	function getGameEntry(uint index) public constant returns(address addr, uint blocknumber, uint blocktimestamp, uint bet, uint prize, bool winner) {
		return (lastPlayedGames[index].addr, lastPlayedGames[index].blocknumber, lastPlayedGames[index].blocktimestamp, lastPlayedGames[index].bet, lastPlayedGames[index].prize, lastPlayedGames[index].winner);
	}
	
	//function getGameLost(address _addr) constant returns (address addr, uint blocktimestamp, uint bet, bool winner, uint withdrawn) {
	//	User storage user = users[_addr];
	//	return (user.pendingBets[index].addr, user.pendingBets[index].blocktimestamp, user.pendingBets[index].bet, user.pendingBets[index].winner, user.pendingBets[index].withdrawn);
	// }
	
	function getBonusPercent() public constant returns(uint) {
		return (block.timestamp - lastBet) / timeStep;
	}
	
}