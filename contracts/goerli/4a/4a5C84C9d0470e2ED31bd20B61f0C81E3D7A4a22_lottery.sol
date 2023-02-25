/**
 *Submitted for verification at Etherscan.io on 2023-02-25
*/

//SPDX-License-Identifier: UNLICENCED
pragma solidity ^0.8.0;

contract lottery{
    address payable public manager;
    address payable[] private player;
    bool public isContractActive;
    address payable public lastgamewinner;
    address public updatedversionofthiscontract;

    constructor(){
        manager=payable(msg.sender);
        isContractActive=true;
    }

    function ContractBalance() view public returns(uint){
        return address(this).balance;
    }

    function noofpaticipents() view public returns(uint){
        return player.length;
    }

    function getPlayers() public view returns(address payable[] memory) {
        return player;
    }
    
    modifier FunctionControl(){
        require(msg.value >= 0.01 ether , "Minimum price is 0.01 Eather");
        require(isContractActive,"This version of contract is not active");
        _;
    }
    modifier Restricted(){
        require(payable(msg.sender) == manager , "Only manager can use this function");
        _;
    }

    function isContractActivefn(bool s,address updatedv) public Restricted payable {
        isContractActive=s;
        updatedversionofthiscontract=updatedv;
    }

    function Enter() public FunctionControl payable{
    player.push()=payable(msg.sender);
    }

    function pickWinner() public Restricted payable{
        uint rno = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, player)));
        //1% developer fee
        bool feesent = manager.send((address(this).balance)/100);
        require(feesent,"Failed to send to manager");

        //send money to winner of contest by automatic random selection process

        bool prizesent = player[rno % player.length].send(address(this).balance);
        require(prizesent,"Failed");


        lastgamewinner = player[rno % player.length];
        //reset game
        player=new address payable[](0);
    }


    
}