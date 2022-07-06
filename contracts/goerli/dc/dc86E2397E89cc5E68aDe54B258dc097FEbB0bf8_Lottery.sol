/**
 *Submitted for verification at Etherscan.io on 2022-07-06
*/

//SPDX-License-Identifier: MIT

pragma solidity >=0.8.7;

contract Lottery {
    address payable Owner;
    address Winner;

    enum LotteryState {
        OPEN,
        CLOSED
    }
    LotteryState CurrentState;

    // Creates list of lottery contestants
    address[] private entries;

    // Enters a new contestant into the lottery via entries array. Checks if the lottery is open
    // and if the new contestant has already been entered.
    function EnterLottery(address payable UserAddress) public payable {
        require(CurrentState == LotteryState.OPEN, "Lottery is closed.");
        require(UserAddress.balance >= 1e15, "Not Enough ETH.");
        bool Repeated;
        for (uint i = 0; i < entries.length; i++) {
            address addr = entries[i];
            // check if address is unique
            require(
                UserAddress != addr,
                "This address has already been entered."
            );
            Repeated = false;
            // if the address is not already list
        }
        require(Repeated == false); //redudant
        UserAddress.transfer(1e15);
        entries.push(UserAddress);
    }

    function ViewContestants() public view returns (address[] memory) {
        return entries;
    }

    function ViewJackpotTotal() public view returns (uint) {
        uint Jackpot = address(this).balance;
        return Jackpot;
    }

    function RunLottery() public returns (address) {
        require(msg.sender == Owner, "Cannot preform this action.");
        CurrentState = LotteryState.CLOSED;
        uint PsudoRand = entries.length % 2;
        Winner = entries[PsudoRand];
        return Winner;
    }

    function ViewWinners() public view returns (address) {
        require(
            CurrentState == LotteryState.CLOSED,
            "The winner has not been selected."
        );
        return Winner;
    }
}