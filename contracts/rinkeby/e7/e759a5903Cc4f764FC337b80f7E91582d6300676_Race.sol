//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Race {
   struct Players {
       address creator;
       address joiner;
   }

   struct Data {
        Players player;
        uint256 total_balance;
        address win;
        bool ispayed;
    }
   

    mapping(uint => Players) public game_rooms;
    uint public game_room_number = 0;
      mapping(uint256 => uint256) public balance;
    mapping(uint256 => address) public winner;
    mapping(uint256 => bool) public isPayed;
    Players player;

    function creat() public payable {
        require(msg.value > 0.01 ether,"Minimum balance is 0.01 eth");
        // player.creator = address(0);
        player.joiner = address(0);
        balance[game_room_number] = msg.value;
      
        player.creator = msg.sender;
        game_rooms[game_room_number] = player;
        game_room_number +=1;
    }
    function join(uint number) public payable {
        require(msg.value  == balance[number],"balance must be equal with creator balance");
        // Players player;
        player.joiner = msg.sender;
        game_rooms[number] = player;
        balance[number] +=msg.value;
        uint index = random()% 2;
        if(index == 0) {
            winner[number] = game_rooms[number].creator;
        }else{
            winner[number] = game_rooms[number].joiner;
        }
    }

    function random() private view returns (uint256) {
        return uint256(keccak256(abi.encode(block.timestamp, player)));
    }

    function getData() public view returns (Data[] memory data) {
        // uint256 temp_room_num;
        // if (balance[room_num] > 0) {
        //     data = new Data[](room_num - last_room_num);
        //     temp_room_num = room_num;
        // } else {
        //     data = new Data[](room_num - last_room_num - 1);
        //     temp_room_num = room_num - 1;
        // }
        // for (uint256 i = last_room_num + 1; i <= temp_room_num; i++) {
        //     data[i - last_room_num - 1].player = game_room[i];
        //     data[i - last_room_num - 1].total_balance = balance[i];
        //     data[i - last_room_num - 1].win = winner[i];
        // }

        data = new Data[](game_room_number+1);
        for (uint i = 0 ; i< game_room_number+1 ; i++){
            data[i].player = game_rooms[i];
            data[i].total_balance = balance[i];
            data[i].win = winner[i];
            data[i].ispayed = isPayed[i];
        }
    }

    function pickWinner() public {
        for (uint256 i = 0; i < game_room_number +1; i++) {
            if(!isPayed[i] && winner[i] != address(0)){
                payable(winner[i]).transfer(balance[i]);
                // balance[i] = 0;
                isPayed[i] = true;
            }
        }
        // if (winner[room_num] != address(0)) {
        //     last_room_num = room_num;
        // } else {
        //     last_room_num = room_num - 1;
        // }
    }
}