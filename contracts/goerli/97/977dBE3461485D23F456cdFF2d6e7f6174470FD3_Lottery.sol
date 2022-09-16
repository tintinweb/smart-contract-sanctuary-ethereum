//SPDX-License-Identifier: MIT 

pragma solidity ^0.8.0;

contract Lottery{
    //manager is in charge of the contract 
    address public manager;
    //new player in the contract using array[] to unlimit number 
    address[] public players;

    function lottery() public {
        manager = msg.sender;
    }
    //to call the enter function we add them to players
    function enter() public payable{
        //each player is compelled to add a certain ETH to join
        address payable wallet = payable (address(this));
        wallet.transfer(1);
        players.push(msg.sender);
    }
    //creates a random hash that will become our winner
    function random() private view returns(uint){
        return  uint (keccak256(abi.encode(block.timestamp,  players)));
    }
    function pickWinner() public restricted{
        //only the manager can pickWinner
        //require(msg.sender == manager);
        //creates index that is gotten from func random % play.len
        uint index = random() % players.length;
        //pays the winner picked randomely(not fully random)
        payable (players[index]).transfer(address(this).balance);
        //empies the old lottery and starts new one
        players = new address[](0);
    }

    modifier restricted(){
        require(msg.sender == manager);
        _;

    }
}