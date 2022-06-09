/**
 *Submitted for verification at Etherscan.io on 2022-06-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract Casino {
    address owner;

    constructor() {
        owner = msg.sender;
    }

    modifier ownerOnly() {
        require(msg.sender == owner, "Owner only");
        _;
    }

    event bet(
        address player,
        uint256 _betNumber,
        uint256 betAmount,
        uint256 winAmount
    );

    function getRandomNumber() internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        owner,
                        msg.sender,
                        block.timestamp,
                        block.difficulty
                    )
                )
            );
    }

    modifier sufficientBalance() {
        require(
            msg.value <= address(this).balance / 14,
            "Bet too high - insufficient contract reserves"
        );
        require(msg.value > 0, "Bet has to be bigger than 0");
        _;
    }

    modifier betOptions(uint256 _betNumber) {
        require(
            _betNumber <= 3,
            "Incorrect bet input, only 1 - black, 2 - red or 3 - green are accepted"
        );
        _;
    }

    function withDrawFunds(uint256 _withdrawAmount) external payable ownerOnly {
        payable(owner).transfer(_withdrawAmount);
    }

    function depositFunds() external payable {
        //delete before deployment
    }

    function getContractBalance()
        external
        view
        returns (uint256 contractBalance)
    {
        //delete before deplyoment
        contractBalance = address(this).balance;
    }

    function spin(uint256 _betNumber)
        public
        payable
        sufficientBalance
        betOptions(_betNumber)
    {
        uint256 spinOutput = getRandomNumber() % 15;
        address player = msg.sender;
        uint256 winAmount;
        if (spinOutput < 6 && _betNumber == 1) {
            winAmount = msg.value * 2;
            payable(player).transfer(winAmount);
        } else if (spinOutput > 5 && spinOutput < 14 && _betNumber == 2) {
            winAmount = msg.value * 2;
            payable(player).transfer(winAmount);
        } else if (spinOutput == 14 && _betNumber == 3) {
            winAmount = msg.value * 14;
            payable(player).transfer(winAmount);
        } else {
            winAmount = 0;
        }
        emit bet(msg.sender, _betNumber, msg.value, winAmount);
    }
}