/**
 *Submitted for verification at Etherscan.io on 2022-11-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

contract rpcGame{

    enum Choice {
        NoChoice,
        Rock,
        Scissors,
        Paper,
        Unknow
    }

    struct Player {
        address playerAddress;
        bytes32 turnHash;
        Choice choice;
    }

    struct GameRoom {
        Player player1;
        Player player2;
        int nPlayers;
    }

    event RedyToDecode(int roomID);
    event PublishWinner(int roomID, address winnerAddress);

    mapping(int => GameRoom) public rooms;

    modifier onlyFreeRoom(int roomID) {
        require(rooms[roomID].nPlayers < 2, "Room is full");
        _;  
    }

    modifier onlyUnique(int roomID) {
        GameRoom storage room = rooms[roomID];
        require(
            (room.player1.playerAddress != msg.sender) && (room.player2.playerAddress != msg.sender), 
            "You are already in game"
            );
        _;
    }

    modifier onlyAfterTurns(int roomID) {
        require(rooms[roomID].nPlayers == 2, "Too early. Your turn might be compromised");
        _;
    }

    modifier onlyByPlayers(int roomID) {
        GameRoom memory room = rooms[roomID];
        require((msg.sender == room.player1.playerAddress) || (msg.sender == room.player2.playerAddress), "Not your game");
        _;
    }

    function joinRoom(int roomID, bytes32 turn) public onlyUnique(roomID) onlyFreeRoom(roomID) {
        GameRoom storage room = rooms[roomID];
        Player storage player;

        if(room.nPlayers == 0){
            player = room.player1;
        }
        else {
            player = room.player2;
        }
        player.playerAddress = msg.sender;
        player.turnHash = turn;
        ++rooms[roomID].nPlayers;
    }

    function decodeTurn(int roomID, bytes32 salt) public onlyByPlayers(roomID) onlyAfterTurns(roomID) {
        Player storage player;
        GameRoom storage room = rooms[roomID];

        if(room.player1.playerAddress == msg.sender){
            player = room.player1;
        } 
        else {
            player = room.player2;
        }

        player.choice = getChoice(salt, player.turnHash);
        if((room.player1.choice > Choice.NoChoice) && (room.player2.choice > Choice.NoChoice)){
            defineWinner(roomID);
            delete(rooms[roomID]);
        }
    }

    function getChoice(bytes32 salt, bytes32 turnHash) pure private returns (Choice) {
        for (uint i=1; i<uint(Choice.Unknow); ++i){
            if(keccak256(abi.encodePacked(i, salt)) == turnHash){
                return Choice(i);
            }
        }
        revert("Not valid salt");
    }

    function defineWinner(int roomID) private {
        GameRoom storage room = rooms[roomID];
        uint choice1 = uint(room.player1.choice);
        uint choice2 = uint(room.player2.choice);

        if (choice1 == choice2){
            emit PublishWinner(roomID, address(0));
        }

        if ((choice1 - choice2 + 3) % 3 == 2) {
            emit PublishWinner(roomID, room.player1.playerAddress);
        }
        else {
            emit PublishWinner(roomID, room.player2.playerAddress);
        }
    }
}