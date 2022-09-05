//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Greeter {
   address owner;
    uint n_players;
    uint256 price;
    address[] players;
    constructor(){
        owner = msg.sender;
        n_players = 0;
    }

    function addPlayer() public  payable {
        if(n_players == 0)
            price = msg.value;
        require(n_players < 2 && msg.value >= price);
        players.push(msg.sender);
        n_players ++;
    }

    function finalize(address winner) public payable {
        require(n_players == 2);
        require(winner == players[0]||winner == players[1]);
        address payable to = payable(winner);
        to.transfer(address(this).balance * 95/100);
        n_players = 0;
        delete players;
    }

    function withdrawMoney() public {
        address payable to = payable(owner);
        to.transfer(address(this).balance);
    }

    function getprice() public view returns(uint256){
        return price;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}