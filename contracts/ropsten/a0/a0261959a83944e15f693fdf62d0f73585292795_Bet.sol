/**
 *Submitted for verification at Etherscan.io on 2022-05-12
*/

// SPDX-License-Identifier: MIT
pragma solidity >0.4.99;

contract Bet{

    uint256 public minimumBet;
    address private constant house = 0x2A1Db54C108b6889aAadcBA62eD5E65b90C70bC6;

    uint256 public comission;

    struct Player{
        uint256 amountBet;
        mapping(uint256 => Room) roomTeam;
        // address payable direction;
    }
    struct Room{
        uint256 teamSelected;
    }
    address payable[] public players;

    mapping(address => Player) public playerInfo;

    constructor(){
        minimumBet=10000000000000000;
        comission=1000000000000000;
        
    }
    function playerExists() public view returns(bool) {     
        for(uint256 i = 0; i < players.length; i++){
            if(players[i] == msg.sender) return true;
        }
        return false;
    }
    function playerIndex()public view returns(uint256){
        uint256 ref=players.length+1;
        for(uint256 i = 0; i < players.length; i++){
            if(players[i] == msg.sender) {
                ref=i;
                break;
                }
        }
        return ref;
    }
    function sameBetAmount(uint256 betValue) public view returns(bool){
        return betValue==minimumBet;
    }
    function hasBetRoom(uint256 roomId) public view returns(bool){
 
        return playerInfo[msg.sender].roomTeam[roomId].teamSelected!=0;
    }
    function getBetTeamInRoom(uint256 roomId) public view returns(uint256){
        return playerInfo[msg.sender].roomTeam[roomId].teamSelected;    
    }
    function isWinner(uint256 teamWinner,uint256 roomId) public view returns(bool){
        return playerInfo[msg.sender].roomTeam[roomId].teamSelected==teamWinner;
    }

    function bet(uint256  teamSelected,uint256 roomId) external payable {
        // require(!checkPlayerExists(msg.sender));
        require(sameBetAmount(msg.value));
        
        playerInfo[msg.sender].roomTeam[roomId].teamSelected=teamSelected;
        players.push(payable(msg.sender));
    }
    function changeRoomBet(uint256  teamSelected,uint256 newRoomId,uint256 oldRoomId) external {
        require(playerExists());
        require(hasBetRoom(oldRoomId));
        delete playerInfo[msg.sender].roomTeam[oldRoomId];
        playerInfo[msg.sender].roomTeam[newRoomId].teamSelected=teamSelected;
        // playerInfo[msg.sender].teamSelected=teamSelected;
    }
    function getRoomFunds(uint256 teamWinner,uint256 roomId) external payable{
        require(playerExists());
        require(hasBetRoom(roomId));
        require(isWinner(teamWinner,roomId));
        address payable account=payable (msg.sender);
        account.transfer((minimumBet*2)-(comission*2));

        payable(house).transfer(comission*2);
        delete playerInfo[msg.sender].roomTeam[roomId];
        // delete players[playerIndex(msg.sender)]; 

        address payable playerAddress;
        for(uint256 i = 0; i < players.length; i++){ 
            playerAddress = players[i];
            if(playerInfo[playerAddress].roomTeam[roomId].teamSelected!=teamWinner)
            {
                delete playerInfo[playerAddress].roomTeam[roomId];
                break;
            }
        //    
        //     if(playerInfo[playerAddress].roomId==_roomId && playerInfo[playerAddress].teamSelected!=_teamWinner)
        //     {
        //         delete playerInfo[playerAddress];
        //         delete players[i];
        //         break;
        //     }
        
        }
    }

    function getAllFunds() external{
        payable(house).transfer(address(this).balance);
        for(uint256 i=0; i<players.length; i++)
        {
            delete playerInfo[players[i]];
        }
        delete players;
    }
    
}