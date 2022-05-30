/**
 *Submitted for verification at Etherscan.io on 2022-05-30
*/

//"SPDX-License-Identifier: GPL-3.0"
pragma solidity >=0.7.0 <0.9.0;

interface IBetting{

    

    struct Bet{

        uint8 matchID;
        string bettingType;
        uint8 oddForWinning;
        uint256 amount;

    }
    
    function placeBet(uint8 matchID, string memory bettingType, uint8 oddForWinning) external payable;
    function payWinningBets(uint8 matchId, string memory winninType) external;


}



contract Betting is IBetting{



    mapping(address => bool)  admins;
    mapping(address => Bet) bets;
    address[] private  players;
    uint256 deadline;
   
    
     
     receive() external payable Admin{}


    event UpdatedBet(address sender, string s);
    event Win(address sender, string s, uint256 amount);

   modifier Admin {
       require(admins[msg.sender], "Not an admin");
       _;
   }

   modifier MBet{
        require(block.timestamp < deadline, "Deadline passed");
        require(!checkPlayerExists(msg.sender), "You arleady made a bet");
        require(address(msg.sender).balance > 0, "Your balance is 0");
        require(msg.value > 0, "Bet cannot be 0");
        _;
   }

    


    constructor () payable {
        require(msg.value >= 1000000000000000000,"You cannot deploy contract without at least 1 ETH");
        admins[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4] = true;
        admins[0xaf38b54fdd07da22AeF124f5eEF8692fBbE8b885] = true;
        deadline = 1653671262 + 10 days;
        
    }

    function addAdmin(address _newAdmin) public{
        admins[_newAdmin] = true;
        return;
    }

    function getPlayers() external view returns(address[] memory){
        return players;
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }


    function placeBet(uint8 matchID, string memory bettingType, uint8 oddForWinning) override external payable MBet {
        require(keccak256(abi.encodePacked(bettingType)) == keccak256(abi.encodePacked("Tie")) || keccak256(abi.encodePacked(bettingType)) == keccak256(abi.encodePacked("Team A")) || keccak256(abi.encodePacked(bettingType)) == keccak256(abi.encodePacked("Team B")), "Betting type must be 'Team A' or 'Team B' or 'Tie'");
        bets[msg.sender] = Bet(matchID, bettingType, oddForWinning, msg.value);

        players.push(msg.sender);
      
        string memory b = "Bet received!";
        emit UpdatedBet(msg.sender ,b);

    }

    function checkPlayerExists(address player) private view returns(bool){
      for(uint256 i = 0; i < players.length; i++){
         if(players[i] == player) 
            return true;
      }
      return false;
   }

    

    function payWinningBets(uint8 _matchID, string memory _winningType) override external Admin{
        require(players.length != 0, "No bets at the time");
        require(keccak256(abi.encodePacked(_winningType)) == keccak256(abi.encodePacked("Tie")) || keccak256(abi.encodePacked(_winningType)) == keccak256(abi.encodePacked("Team A")) || keccak256(abi.encodePacked(_winningType)) == keccak256(abi.encodePacked("Team B")), "Betting type must be 'Team A' or 'Team B' or 'Tie'");
    
        address payable[50] memory winners;
        address[] memory tempplayers = new address[](50);
        uint8 count = 0;
        uint8 tempcount = 0;

        for(uint8 i = 0; i < players.length; i++){
               
                if(bets[players[i]].matchID == _matchID && keccak256(abi.encodePacked(bets[players[i]].bettingType)) == keccak256(abi.encodePacked(_winningType))){
                     
                    winners[count++] = payable(players[i]);
                    
                    
                }else{
                    if(bets[players[i]].matchID != _matchID)
                        tempplayers[tempcount++] = players[i];
                }
        }
        players = tempplayers;

       require(winners.length != 0, "We don't have winners");

       for(uint8 i = 0; i <= count; i++){

            if(winners[i]!= address(0)){
                        
                uint256 amount = bets[winners[i]].amount;
                uint8 odd = bets[winners[i]].oddForWinning;
                uint256 winningAmount = (amount * odd ) * 95 / 100;
                 winners[i].transfer(winningAmount);
                string memory s = "You win";
                 emit Win(winners[i], s, winningAmount);
                        
            }

       }

       delete winners;
    
    }


    
 
}