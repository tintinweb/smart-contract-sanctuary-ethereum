/**
 *Submitted for verification at Etherscan.io on 2022-06-01
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0 < 0.9.0; // definition of the compiler version 

contract Lottery
{
//Global variables
    address             public manager; //Variable for storing the deployers address
    address payable[]   public players; //Variable for storing player's addresses
    address             public winner;  //Variable for storing the winner's address

//Function modifiers restrict the execution of the function until the condition is met
    modifier restricted()       //only manager can execute a function
            {
            require(msg.sender == manager);
            _;
            }

    modifier minimumPlayers()   //minumum number of participants
            {
            require(players.length >1);
            _;
            }
    modifier minimumEth()       //minimum amount to enter the lottery
            {
            require(msg.value > 10000000000000000);
            _;
            }

//Functions
    constructor()          //This constructor function reads and assign the deployer address to the manager
            {
            manager = msg.sender;
            }

    receive()            //Function that allows receving >0.01 ETH into the contract  
        external
        payable
        minimumEth
            {
            players.push(payable(msg.sender));
            }

    function ShowAll()          //Function that shows all participants
        public
        view
        returns(address payable[] memory)
            {
            return players;
            }

    function PlayersNo()        //Function that shows the total number of participants
        public
        view
        returns(uint)
            {
            return players.length;
            }
    function Random()           //Function generates pseudo random number, never specified exact time prior to a draw to make it random. Maybe give 2 minutes range.
        private
        view
        returns(uint)
            {
            return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,players)));
            }

    function PickWinner()       //FUnction picks the winner's wallet, sends the rewards ballance to the wallet and resets the players array
        public
        restricted
        minimumPlayers
            {
            uint index = Random() % players.length;
            players[index].transfer(address(this).balance);
            winner = players[index];
            players = new address payable[](0);                 
            }

  function ShowWinner()       //Function shows the winner
        public
        view
        returns(address)
            {
            return winner;
            }


}