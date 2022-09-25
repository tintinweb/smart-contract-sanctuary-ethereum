/**
 *Submitted for verification at Etherscan.io on 2022-09-25
*/

// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;


contract Lottery{
    address  _manager;
    address[]  _players;
    constructor(){
        _manager = msg.sender;
    }
    

    
    function  getBalance() public view returns(uint){
        return address(this).balance;
    }
    
    function buyLottery()public payable {
        require(msg.value==1 ether);
        _players.push(payable(msg.sender));
    }

    function countPlayers()public view returns(uint){
        return _players.length;
    }
    function randomNumber() private view returns(uint){
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _players.length)));
    }


    function selectWinnder()public{
        require(_manager==msg.sender);
        require(countPlayers()>=2);
        uint index = randomNumber()%_players.length;
        address winner = _players[index];
        payable(winner).transfer(getBalance());
        _players = new address[](0);
    }

   

}