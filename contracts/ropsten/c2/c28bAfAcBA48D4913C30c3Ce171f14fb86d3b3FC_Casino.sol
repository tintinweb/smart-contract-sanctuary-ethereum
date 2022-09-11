/**
 *Submitted for verification at Etherscan.io on 2022-09-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// We need to have a way to fund this contract, and people to put ether in it

// Also there would have to be a way someone to retrive the founds from this smart contract

// First we will focus on the actual game function

contract Casino {
    // This amount of erher(wei) that people are plaing
    mapping(address => uint256) public gameWeiValues;

    mapping(address => uint256) public blockHashesToBeUsed;

    address public owner;

    address[] public lastThreeWinners;

    event FundsDeposited(address indexed sender, uint256 amount);
    event FundsWithdrawan(address indexed sender, uint256 amount);
    event BetPlaced(address indexed sender, uint256 amount);
    event BetFinished(
        address indexed sender,
        uint256 indexed randomNumber,
        uint256 indexed amount
    );

    constructor() {
        owner = msg.sender;
    }

    function withdrawFunds(uint256 amount) external {
        require(
            msg.sender == owner,
            "Lottery: Only the owner can withdraw funds"
        );
        require(
            amount <= address(this).balance,
            "Lottery: Can not withdraw more funds then there is in the Casino"
        );

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Lottery: ETH withdrawal failed");

        emit FundsWithdrawan(msg.sender, amount);
    }

    function getCasinoBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function playGame() external payable {
        if (blockHashesToBeUsed[msg.sender] == 0) {
            blockHashesToBeUsed[msg.sender] = block.number + 2;

            gameWeiValues[msg.sender] = msg.value;

            emit BetPlaced(msg.sender, msg.value);

            return;
        }

        require(
            msg.value == 0,
            "Lottery: Finish current game before starting new one"
        );

        require(
            blockhash(blockHashesToBeUsed[msg.sender]) != 0,
            "Lottery: Block not mined yet"
        );

        uint256 randomNumber = uint256(
            blockhash(blockHashesToBeUsed[msg.sender])
        );

        uint256 winningAmount;
        if (randomNumber % 2 == 0) {
            winningAmount = gameWeiValues[msg.sender] * 2;

            (bool success, ) = msg.sender.call{value: winningAmount}("");
            require(success, "Lottery: Winning payout failed");

            lastThreeWinners.push(msg.sender);

            if (lastThreeWinners.length > 3) {
                _removeAtIndex(0);
            }
        }

        blockHashesToBeUsed[msg.sender] = 0;
        gameWeiValues[msg.sender] = 0;

        emit BetFinished(msg.sender, randomNumber, winningAmount);
    }

    receive() external payable {
        emit FundsDeposited(msg.sender, msg.value);
    }

    function _removeAtIndex(uint256 i) private {
        lastThreeWinners[i] = lastThreeWinners[lastThreeWinners.length - 1];
        lastThreeWinners.pop();
    }
}