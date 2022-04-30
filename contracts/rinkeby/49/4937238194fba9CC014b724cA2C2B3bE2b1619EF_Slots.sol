/**
 *Submitted for verification at Etherscan.io on 2022-04-30
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

contract Slots {
    uint256 public slotsBalance;
    uint256 public minValue = 0.001 ether;
    uint256 public sumPlayersMoney = 0;
    uint256 modulus = 6;
    uint256 randNonce = 0;

    struct Game {
        uint256 result;
        uint256 randNumber1;
        uint256 randNumber2;
        uint256 randNumber3;
    }

    mapping(address => uint256) winnerBalance;
    mapping(address => Game[]) gamesResult;

    address owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function changeMinValue(uint256 newMinValue) public onlyOwner {
        minValue = newMinValue * (1 ether);
    }

    function deposit() public payable onlyOwner {
        slotsBalance += msg.value;
    }

    function getBalanceSlots() public view returns (uint256) {
        return slotsBalance;
    }

    function getPlayerBalance() public view returns (uint256) {
        return winnerBalance[msg.sender];
    }

    function getLastPlayerGame()
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 length = gamesResult[msg.sender].length - 1;
        return (
            gamesResult[msg.sender][length].result,
            gamesResult[msg.sender][length].randNumber1,
            gamesResult[msg.sender][length].randNumber2,
            gamesResult[msg.sender][length].randNumber3
        );
    }

    function roll() public payable {
        require(minValue <= msg.value);
        uint256 randNumber1 = randomValue();
        randNonce += 1;
        uint256 randNumber2 = randomValue();
        randNonce += 1;
        uint256 randNumber3 = randomValue();
        randNonce += 1;
        uint256 result = calculatePrize(randNumber1, randNumber2, randNumber3);
        if (result == 0) {
            slotsBalance += msg.value;
        } else {
            winnerBalance[msg.sender] += result;
            sumPlayersMoney += result;
        }
        gamesResult[msg.sender].push(
            Game(result, randNumber1, randNumber2, randNumber3)
        );
    }

    function randomValue() private view returns (uint256) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp +
                        block.difficulty +
                        randNonce +
                        ((
                            uint256(keccak256(abi.encodePacked(block.coinbase)))
                        ) / (block.timestamp)) +
                        block.gaslimit +
                        ((uint256(keccak256(abi.encodePacked(msg.sender)))) /
                            (block.timestamp)) +
                        block.number
                )
            )
        );

        return (seed - ((seed / modulus) * modulus));
    }

    function calculatePrize(
        uint256 rand1,
        uint256 rand2,
        uint256 rand3
    ) private view returns (uint256) {
        if (rand1 == 6 && rand2 == 6 && rand3 == 6) {
            return minValue * 5;
        } else if (rand1 == 5 && rand2 == 5 && rand3 == 5) {
            return minValue * 3;
        } else if (rand1 == 4 && rand2 == 4 && rand3 == 4) {
            return minValue * 3;
        } else if (rand1 == 3 && rand2 == 3 && rand3 == 3) {
            return minValue * 3;
        } else if (rand1 == 2 && rand2 == 2 && rand3 == 2) {
            return minValue * 3;
        } else if (rand1 == 1 && rand2 == 1 && rand3 == 1) {
            return minValue * 3;
        } else if ((rand1 == rand2) || (rand1 == rand3) || (rand2 == rand3)) {
            return minValue;
        } else {
            return 0;
        }
    }

    function withdraw(uint256 amount) public {
        require(winnerBalance[msg.sender] <= amount);
        winnerBalance[msg.sender] -= amount;
        slotsBalance -= amount;
        sumPlayersMoney -= amount;
        payable(msg.sender).transfer(amount);
    }

    function witdrawOwnerSlots(uint256 amount) public payable onlyOwner {
        uint256 allowWithdrawlMoney = slotsBalance - sumPlayersMoney;
        require(allowWithdrawlMoney < 0);
        require(allowWithdrawlMoney <= amount);
        payable(msg.sender).transfer(amount);
    }
}