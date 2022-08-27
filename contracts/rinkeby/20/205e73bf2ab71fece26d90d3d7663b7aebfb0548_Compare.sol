// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/*

    簡單設計一個博亦遊戲

    基本功能：
        Account 跟 contract 玩遊戲
        籌碼：Ether
        
    For example: 比大小, 猜拳
        贏的話 Account 給 contract 錢，輸的話 contract 給 Account 錢

*/

//import "Context.sol";

import "Ownable.sol";

library Compare {
    function compare(string memory a, string memory b) public pure returns (bool) {
        if (_hash(a) == _hash(b)) {
            return true;
        } else {
            return false;
        }
    }

    function _hash(string memory _str) internal pure returns (bytes32) {
        return keccak256(bytes(_str));
    }
}



contract Gamble is Ownable {

    using Compare for string;

    event YouWin();
    event YouLose();
    event Draw();
    event GuessHigher();
    event GuessLower();
    event ExceededAvailableGuesses();

    uint private minimum = 1;
    uint private maximum = 100;
    uint public playPrice = 0.01 ether;

    mapping (address => uint) private guessCount;
    mapping (address => uint) private answer;
    mapping (address => uint) public balanceOf;

    modifier Pay() {
        require(balanceOf[msgSender()] >= playPrice, "Deposit more money");
        _;
    }

    function random() internal view returns (uint) {
        return (block.timestamp % 100) + 1;
        //           1 ~ 100
    }

    function deposit() public payable {
        balanceOf[msgSender()] += msgValue();
    }

    function withdrawForOwner() public onlyOwner { 
        sendValue(payable(owner()), address(this).balance);
    }

    function withdraw() public {
        sendValue(payable(msgSender()), balanceOf[msgSender()]);
        balanceOf[msgSender()] = 0;
    }

    function sendValue(address payable to, uint amount) internal {
        require(address(this).balance >= amount, "Not enough money");
        to.transfer(amount);
    }

    function Guess(uint guess) public Pay {

        require(guess >= minimum && guess <= maximum, "Out of Range");

        if (guessCount[msgSender()] == 0) {
            answer[msgSender()] = random();
            balanceOf[msgSender()] -= playPrice;
        }

        guessCount[msgSender()] += 1;

        if (guessCount[msgSender()] <= 5) {
            
            if (guess == answer[msgSender()]) {
                uint amount = playPrice * (6 - guessCount[msgSender()]);
                balanceOf[msgSender()] += amount;
                guessCount[msgSender()] = 0;
                emit YouWin();
            } else if (guess < answer[msgSender()]) {
                minimum = guess;
                emit GuessHigher();
            } else {
                maximum = guess;
                emit GuessLower();
            }

        } else {
            emit ExceededAvailableGuesses();
            emit YouLose();
            guessCount[msgSender()] = 0;
        }

    }

    function RPS(string memory _hand) public Pay {

        require(_hand.compare("R") || _hand.compare("P") || _hand.compare("S"), "Invalid");

        uint hand = random() % 3;  // R=0, P=1, S=2
        balanceOf[msgSender()] -= playPrice;

        if (_hand.compare("R")) {
            if (hand == 1) {
                emit YouLose();
            } else if (hand == 2) {
                emit YouWin();
                balanceOf[msgSender()] += playPrice*2;
            } else {
                emit Draw();
                balanceOf[msgSender()] += playPrice;
            }
        } else if (_hand.compare("P")) {
            if (hand == 2) {
                emit YouLose();
            } else if (hand == 0) {
                emit YouWin();
                balanceOf[msgSender()] += playPrice*2;
            } else {
                emit Draw();
                balanceOf[msgSender()] += playPrice;
            }
        } else {
            if (hand == 0) {
                emit YouLose();
            } else if (hand == 1) {
                emit YouWin();
                balanceOf[msgSender()] += playPrice*2;
            } else {
                emit Draw();
                balanceOf[msgSender()] += playPrice;
            }
        }

    }

}