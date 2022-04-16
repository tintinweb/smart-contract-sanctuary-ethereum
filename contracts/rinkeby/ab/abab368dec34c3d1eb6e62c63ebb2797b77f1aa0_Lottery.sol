/**
 *Submitted for verification at Etherscan.io on 2022-04-16
*/

//SPDX-License-Identifier: GPL-3.0

pragma solidity <=0.7.0 <0.9.0;
contract Lottery{
    address payable[] public players;
    address payable public admin;

    constructor(){
      admin = payable(msg.sender);
    }

    receive() external payable {
        //require that the transaction value to the contract is 1 ether
        require(msg.value == 1 ether , "Must send 1 ether amount");
        
        //makes sure that the admin can not participate in lottery
        require(msg.sender != admin, "Admin cant play");
        
        // pushing the account conducting the transaction onto the players array as a payable adress
        players.push(payable(msg.sender));

    }

    

    function getBalance() public view returns(uint){
        return address(this).balance;
    }

    function random() internal view returns(uint){
       return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }

    function pickWinner() public {
        require( admin == msg.sender , "you are a fucker");
        require( players.length >=3, "Not enough players");

        address payable winner;

        winner=players[random() % players.length];

        winner.transfer(getBalance());

        players = new address payable[](0);
    }




}