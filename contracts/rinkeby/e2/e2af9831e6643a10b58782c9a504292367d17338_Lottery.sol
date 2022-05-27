/**
 *Submitted for verification at Etherscan.io on 2022-05-27
*/

// SPDX-License-Identifier: MIT
// File: contracts/final_project1_40871228H.sol


pragma solidity ^0.8.0;

contract Lottery {

    struct Player {
        uint256 count;
        uint256 index;
    }
    address[] public addressIndex;
    mapping(address => Player) player;
    address[] public pool;

    address private _owner;

    uint256 public entranceFee;

    modifier isOwner(){
        require(msg.sender == _owner, "Caller is not owner");
        _;
    }

    enum LotSet{
        OPEN,
        CLOSED,
        CALCULATING
    }
    LotSet public lotset;

    constructor() {
        _owner = msg.sender;
        lotset = LotSet.CLOSED;
    }

    function enter() public payable{
        require(lotset == LotSet.OPEN, "lot not open yet.");
        require(msg.value >= entranceFee, "fee not enough.");

        if(newPlayer(msg.sender)){
            player[msg.sender].count = 1;
            addressIndex.push(msg.sender);
            player[msg.sender].index = addressIndex.length - 1;
        }else{
            player[msg.sender].count++;
        }

        pool.push(msg.sender);
        
    }

    function newPlayer(address playerAdd) private view returns(bool){
        if(addressIndex.length == 0) return true;
        return(addressIndex[player[playerAdd].index] != playerAdd);
    }

    function startLottery() public isOwner{
        require(lotset == LotSet.CLOSED, "lot already opened.");
        entranceFee = .01 ether;
        lotset = LotSet.OPEN;
    }

    function endLottery() public isOwner{
        require(lotset == LotSet.OPEN, "not open, cannot end");
        require(pool.length > 0, "pool is empty");
        
        lotset = LotSet.CALCULATING;

        (bool sent, ) = pool[randomNum()].call{value: address(this).balance}("");
        require(sent, "Sent failed.");

        pool = new address[](0);
        addressIndex = new address[](0);

        lotset = LotSet.CLOSED;
    }

    function randomNum() private view returns(uint256){
        return uint256(keccak256(abi.encodePacked(msg.sender, block.difficulty, block.timestamp))) % pool.length;
    }

    function playerNum() public view returns(uint256){
        require(lotset == LotSet.OPEN, "not open, no player.");
        return pool.length;
    }

    function poolPrice() public view returns(uint256){
        require(lotset == LotSet.OPEN, "not open, no pool price.");
        return address(this).balance;
    }
}