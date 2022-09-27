// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;



error Raffle__TransferFailed();
error Raffle__SendMoreToEnterRaffle();


contract Raffle{
    address private immutable manager;
    address payable[] private players;
    uint private immutable i_entranceFee;


    event RequestedRaffleWinner(uint256 indexed requestId);
    event RaffleEnter(address indexed player);
    event WinnerPicked(address indexed player);


    constructor(uint entranceFee){
        manager =msg.sender;
        i_entranceFee = entranceFee;
    }


    function enter() payable public{
        if(msg.value<i_entranceFee){
            revert Raffle__SendMoreToEnterRaffle();
        }
        players.push(payable(msg.sender));
        emit RaffleEnter(msg.sender);
    }
    function random()view public returns(uint){
        return uint(sha256(abi.encodePacked(players,manager,block.number,block.timestamp)));
    }


    function pickwinner()public{
        uint index= (random()%players.length);
        emit RequestedRaffleWinner(random());
        (bool success, ) = players[index].call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
        emit WinnerPicked((players[index]));
        players=new address payable[](0);

        
    }
}