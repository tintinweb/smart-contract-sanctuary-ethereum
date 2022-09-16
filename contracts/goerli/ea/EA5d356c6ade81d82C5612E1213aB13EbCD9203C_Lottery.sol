//SPDX-License-Identifier: MIT 

pragma solidity ^0.8.0;

contract Lottery{
    //manager is in charge of the contract 
    address public manager;
    //new player in the contract using array[] to unlimit number 
    address[] public players;
    mapping(address => bool) public received;

    function lottery() public {
        manager = msg.sender;
    }

    function withdraw() public {
    require(msg.sender == manager,'Only the service provider can withdraw the payment.');
        payable (msg.sender).transfer(address(this).balance);
    }
    
    //to call the enter function we add them to players
    function enterLottery() payable external {
        require(msg.value == .01 ether,'Payment should be the invoiced amount.');
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