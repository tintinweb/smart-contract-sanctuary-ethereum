//// SPDX-License-Identifier: UNLICENCED
pragma solidity ^0.8.0;
import "./Betting.sol";

contract BettingController{
    Betting public contractAdd;
    bool public running = false;
    address payable private owner;

    constructor(){
        owner = payable(msg.sender);
    }

    function createNewRace(string[] memory _cars, address[] memory _mem) public{
        require(running == false, "Race In Progress");
        Betting newContract = new Betting(_cars, _mem);
        contractAdd = newContract;
        running = true;
    }

    function getWinner() public{
        contractAdd.getWinner();
        contractAdd.transferAmount();
        running = false;
    }

    function getEth() public{
        require(msg.sender == owner, "Only owner can call");
        (bool sent, ) = owner.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }
}