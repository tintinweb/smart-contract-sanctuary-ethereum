//// SPDX-License-Identifier: UNLICENCED
pragma solidity ^0.8.0;
import "./Betting.sol";

contract BettingController{
    Betting public contractAdd;
    bool public running = false;

    function createNewRace(string[] memory _cars, address[] memory _mem) public{
        require(running == false, "Race In Progress");
        Betting newContract = new Betting(_cars, _mem);
        contractAdd = newContract;
        running = true;
    }

    function getWinner() public{
        contractAdd.getWinner();
        running = false;
    }
}