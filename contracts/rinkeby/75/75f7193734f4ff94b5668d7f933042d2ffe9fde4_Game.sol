// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "Context.sol";

contract Game is Context {

    address public owner;
    uint public joinPrice;
    mapping (address => uint) public balanceOf;

    address[] private list;
    address public winner;

    constructor () {
        owner = msgSender();
    } 

    modifier onlyOwner() {
        require(msgSender() == owner, "Error!");
        _;
    }
    
    function checkList() public view returns (uint, address[] memory) {
        return (list.length, list);
    }

    function join() public payable {
        require(msgValue() >= joinPrice, "Error!");
        balanceOf[msgSender()] = msgValue();
        list.push(msgSender());
    }

    function checkPool() public view returns (uint) {
        return address(this).balance;
    }    

    function setjoinPrice(uint _joinPrice) public onlyOwner {
        joinPrice = _joinPrice;
    }

    function getWinner() public onlyOwner {
        winner = list[random()];
        payable(winner).transfer(checkPool());
    }

    function random() private view returns (uint) {
        return block.timestamp % list.length;
    }
    
}