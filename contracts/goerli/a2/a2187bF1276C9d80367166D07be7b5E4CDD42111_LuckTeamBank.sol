/**
 *Submitted for verification at Etherscan.io on 2022-12-09
*/

pragma solidity >=0.7.0 <0.9.0;

interface USDC {
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract LuckTeamBank { 
    uint constant multiplier = 100;

    USDC public USDc;
    address private _owner;
    uint private startTime; 
    uint private rate;
    uint private game_time; 
    uint[] private player_num;
    uint256[] private team_amount; 

    struct Player {
        address player;
        uint256 amount;
        uint team;
    }

    Player[] private players;

    constructor() {
        USDc = USDC(0xA2025B15a1757311bfD68cb14eaeFCc237AF5b43);  
        _owner = msg.sender;
        startTime = 0; 
        rate = 20;
        game_time = 600; 
        player_num = [0, 0]; 
        team_amount = [0, 0]; 
    } 
  
    event msgGame(string, Player[], uint, uint256); 
    event msgService(string, uint);

    function changeOwner(address owner) public {
        require(msg.sender == _owner, "No permission");
        _owner = owner;
    }

    
    function changeVariable(uint r, uint g) public {
        require(msg.sender == _owner, "No permission");
        rate = r;
        game_time = g;
    }

    function initGame() public {
        require(msg.sender == _owner, "No permission");  
        if( startTime == 0 ) {
            delete players;
            player_num = [0, 0]; 
            team_amount = [0, 0]; 
            emit msgService("game_inited", block.timestamp); 
        } else {
            emit msgService("game_not_end", block.timestamp); 
        }  
    } 

    function endGame() public {        
        require(msg.sender == _owner, "No permission");

        if( startTime != 0 && (block.timestamp - startTime) < game_time ) {
            emit msgService("game_cant_end", block.timestamp); 
        }
        if( startTime == 0){            
            emit msgService("game_not_started", block.timestamp); 
        } 

        if( startTime != 0 && (block.timestamp - startTime) >= game_time ) { 

            uint winner = 0;
            if(player_num[0] < player_num[1]) {
                winner = 0;
            }else if(player_num[0] == player_num[1]){
                if(team_amount[0] > team_amount[1]){
                    winner = 0;
                }else if(team_amount[0] == team_amount[1]){
                    winner = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) % 2;
                }else{
                    winner = 1;
                }
            }else {
                winner = 1;
            }  
             
            emit msgGame("game_result", players, winner, 0);   
            emit msgService("transaction_started", block.timestamp);

            for(uint i = 0; i < players.length; i++) {        
              if(players[i].team == winner){
                uint256 reward = players[i].amount + players[i].amount * (team_amount[((winner + 1) % 2)]  *  (100 - rate) / 100) / team_amount[winner];
                USDc.transfer(players[i].player, reward);  
                emit msgGame("reward_money", players, i, reward);
              }            
            }

            USDc.transfer(_owner, team_amount[((winner + 1) % 2)] * rate / 100);

            startTime = 0;
            player_num = [0, 0];
            team_amount = [0, 0];
            delete players;     
            emit msgService("game_inited", block.timestamp);      
        }      
    } 

    

    function depositMoney(uint256 amount, uint team) public {
        require(amount > 0, "Deposit amount should be greater than 0");
        require((team >= 0 && team < 2), "Team number can be only 0,1");

        if( startTime != 0 && (block.timestamp - startTime) > game_time ) {
            emit msgService("game_endded", block.timestamp);
            require(false, "game_endded");
        }

        USDc.transferFrom(msg.sender, address(this), amount);
        Player memory player = Player({player: msg.sender, amount: amount, team: team});   
        players.push(player);

        player_num[team] += 1;
        team_amount[team] += amount;

        emit msgService("player_number", players.length);
        
        if(players.length == 1){ 
            emit msgService("game_created", block.timestamp);
        }  
        if(players.length == 2){
            startTime = block.timestamp;
            emit msgService("game_started", startTime);
        } 
        if(players.length % 5 == 0){
            emit msgService("amount_rate", team_amount[0] * multiplier / team_amount[1]);
        }
    }
   
    function getGameTime() public view returns (uint) {
        return block.timestamp - startTime;
    }   

}