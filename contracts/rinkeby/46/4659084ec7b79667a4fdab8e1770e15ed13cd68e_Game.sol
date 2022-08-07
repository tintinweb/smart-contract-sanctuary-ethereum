// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "Context.sol";

contract Game is Context{

    address public owner;
    uint private joinPrice;
    address public winner;
    address[] public list;
    mapping(address => uint) public balanceOf;

    constructor() {
        owner = msgSender();
    }

    modifier onlyOwner {
        require(msgSender() == owner, "Error");
        _;
    }

    function checkList() public view returns (uint, address[] memory) {
        return (list.length, list);
    }

    function join() public payable {
        balanceOf[msgSender()] += msgValue();
        list.push(msgSender());
    }

    function checkPool() public view returns (uint) {
        return address(this).balance;
    }

    function setjoinPrice(uint _joinPrice) public onlyOwner {
        joinPrice = _joinPrice;
    }

    function getWinner() public onlyOwner {
        uint rand = random();
        winner = list[rand];
        payable(winner).transfer(checkPool());
    }

    function random() private view returns (uint) {
        return block.timestamp % list.length;
    }
}