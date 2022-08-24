/**
 *Submitted for verification at Etherscan.io on 2022-08-24
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.6;

contract lottery{
    address public manager;
    address payable[] public player;


    constructor() {
        manager = msg.sender;
    }

    function AlreadyEnter() view private returns(bool){
        for(uint i=0;i<player.length;i++){
            if(player[i]==msg.sender)
            return true;
        }
        return false;
    }

    function enter() payable public{
        require(msg.sender != manager, "manager cannot enter");
        require(AlreadyEnter() == false, "Player already entered");
        require(msg.value >= 1 ether,"Minimum amount must be payed");
        player.push(payable(msg.sender));
    }

    function random() view private returns(uint){
        return uint(sha256(abi.encodePacked(block.difficulty,block.number,player)));
    }

    function PickWinner() public{
        require(msg.sender == manager,"Only manager can pick the winner");
        uint index = random()%player.length;
        address contractAddress = address(this);
        player[index].transfer(contractAddress.balance);
        player = new address payable[](0);
    } 
    function getplayer() view public returns (address payable[] memory){
        return player;
    }
}