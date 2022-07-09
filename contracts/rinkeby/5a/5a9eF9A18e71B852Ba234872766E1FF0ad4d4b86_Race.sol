//SPDX-License-Identifier: MIT 

pragma solidity ^0.8.0;

contract Race{
    
    struct Players {
        address creator;
        address joiner;
    }
    struct Data {
        Players player;
        uint total_balance;
    }
    // address[] public players;

     mapping(uint => Players) public game_room;
     mapping(uint => uint) public balance;
     mapping(uint => address) public winner;
     uint256 public room_num = 1;
    uint256 public last_room_num = 0;
    Players players;
   
   
  

    

    function enter() public payable{
        require(msg.value > .01 ether,"not enough funds");
        if(balance[room_num] > 0){

        require(msg.value == balance[room_num],"not equal amount");
        }
        if(players.creator != address(0)) {
            players.joiner = msg.sender;
        }else{
            players.creator = msg.sender;

        }
     
            game_room[room_num] = players;
            balance[room_num] += msg.value;
        if(players.joiner != address(0)){
             players.creator = address(0);
             players.joiner = address(0);
             uint index = random() % 2;
             if(index == 0){

             winner[room_num] = game_room[room_num].creator;
             }else{
             winner[room_num] = game_room[room_num].joiner;

             }
             room_num += 1;
        }
       
           
      
    }
    function random() private view returns(uint){
        return  uint (keccak256(abi.encode(block.timestamp,  players)));
    }
    function pickWinner() public  {
      
     
      
        for(uint i = last_room_num+1 ; i < room_num;i++){

        payable (winner[i]).transfer(balance[i]);
        balance[i]=0;

        }
        if(winner[room_num] != address(0)){

        last_room_num = room_num;
        }else{
        last_room_num = room_num-1;

        }
        
    }
    function getData() public view returns(Data[] memory data) {
        uint temp_room_num ;
        if(balance[room_num] > 0){

        data = new Data[](room_num - last_room_num);
        temp_room_num = room_num;
        }else{
        data = new Data[](room_num - last_room_num-1);
        temp_room_num = room_num-1;
       
   
        }
         for(uint i = last_room_num+1; i <= temp_room_num;i++){

        data[i-last_room_num-1].player = game_room[i];
        data[i-last_room_num-1].total_balance = balance[i];
        }

        
        
    }
    
   
}