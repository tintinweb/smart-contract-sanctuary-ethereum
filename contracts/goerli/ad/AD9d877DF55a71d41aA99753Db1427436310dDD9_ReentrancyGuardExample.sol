pragma solidity ^0.8.7;

contract ReentrancyGuardExample {
    bool mutex = false;

    function exampleFunction() public {
        require(!mutex, "Reentrancy detected");
        mutex = true;

        // Contract code goes here

        mutex = false;
    }
}