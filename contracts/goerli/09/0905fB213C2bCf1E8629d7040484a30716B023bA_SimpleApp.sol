//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

contract SimpleApp  {
    uint256 private counter;

    function resetCounter() public {
        counter = 0;
    }

    function incrementCounter() public {
        counter++;
    }

    function decrementCounter() public {
        require(counter > 0, "Counter already zero");
        counter--;
    }

    function getCounter() public view returns (uint256) {
        return counter;
    }

    function getSender() public view returns (address){
        return msg.sender;
    }
}