// SPDX-License-Identifier: MIT

// $$$$$$$$\  $$$$$$\  $$$$$$$\        $$\       $$$$$$\ $$$$$$$$\ $$$$$$$$\ $$$$$$$$\ $$$$$$$\ $$\     $$\ 
// \__$$  __|$$  __$$\ $$  __$$\       $$ |     $$  __$$\\__$$  __|\__$$  __|$$  _____|$$  __$$\\$$\   $$  |
//    $$ |   $$ /  $$ |$$ |  $$ |      $$ |     $$ /  $$ |  $$ |      $$ |   $$ |      $$ |  $$ |\$$\ $$  / 
//    $$ |   $$ |  $$ |$$$$$$$  |      $$ |     $$ |  $$ |  $$ |      $$ |   $$$$$\    $$$$$$$  | \$$$$  /  
//    $$ |   $$ |  $$ |$$  ____/       $$ |     $$ |  $$ |  $$ |      $$ |   $$  __|   $$  __$$<   \$$  /   
//    $$ |   $$ |  $$ |$$ |            $$ |     $$ |  $$ |  $$ |      $$ |   $$ |      $$ |  $$ |   $$ |    
//    $$ |    $$$$$$  |$$ |            $$$$$$$$\ $$$$$$  |  $$ |      $$ |   $$$$$$$$\ $$ |  $$ |   $$ |    
//    \__|    \______/ \__|            \________|\______/   \__|      \__|   \________|\__|  \__|   \__|    

pragma solidity ^0.8.9;

contract MyContract {
    //manager is in charge of the contract 
    address public manager;

    address[] public players;
    
    uint public ticketPrice = 0.001 ether;
    uint public fee = 20;
    
    address public winner;
    uint public lastPrize;

    bool public active;
    
    address public lastContract;

    constructor(address _lastContract) {
        lastContract = _lastContract;
        manager = msg.sender;
        active = true;
    }

    //to call the enter function we add them to players
    function enter(uint amount) public payable{
        //each player is compelled to add a certain ETH to join
        require(active == true, "Finished");
        require(msg.value >= (ticketPrice * amount), "Not enought amount");
        for(uint i = 0; i<amount; i++) {
            players.push(msg.sender);
        }
    }

    //creates a random hash that will become our winner
    function random() private view returns(uint){
        return  uint (keccak256(abi.encode(block.timestamp,  players)));
    }

    function pickWinner() public restricted{
        //only the manager can pickWinner
        //creates index that is gotten from func random % play.len
        uint index = random() % players.length;
        //pays the winner picked randomely
        uint _fee = address(this).balance / fee;
        uint _prize = address(this).balance - _fee;
        payable (manager).transfer(_fee);
        payable (players[index]).transfer(address(this).balance);
        winner = players[index];
        lastPrize = _prize;
        active = false;
        //empies the old lottery and starts new one
        // players = new address[](0);
    }

    function getPlayers() public view returns(address[] memory){
        return players;
    }

    function getPrize() public view returns(uint){
        uint _fee = address(this).balance / fee;
        return address(this).balance - _fee;
    }

    function getWinner() public view returns(address){
        return winner;
    }

    function end() public restricted{
        active = false;
    }

    modifier restricted(){
        require(msg.sender == manager, "You are not the manager");
        _;
    }


}