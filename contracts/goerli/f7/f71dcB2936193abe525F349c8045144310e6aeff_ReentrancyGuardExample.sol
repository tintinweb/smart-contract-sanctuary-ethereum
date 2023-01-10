pragma solidity ^0.8.7;

contract ReentrancyGuardExample {
    bool mutex = false;

   event Test(string _value);

    function exampleFunction() public {
        require(!mutex, "Reentrancy detected");
        mutex = true;

        // Contract code goes here

        mutex = false;

        emit Test("hello WORLD");

    }
}