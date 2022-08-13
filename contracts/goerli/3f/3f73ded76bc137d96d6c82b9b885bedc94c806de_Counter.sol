/**
 *Submitted for verification at Etherscan.io on 2022-08-13
*/

// File: MyTest.sol


// Doing a youtube example for learning purposes.

pragma solidity 0.8.7;

contract Counter {
    uint Count = 0;
    uint public CountP=0;
    string public MyName = "Gameroom";
    event Increment(uint value);
    event Decrement(uint value);
    function getCount() view public returns(uint) {
        return Count;
    }
    function increment() public {
        CountP++;
        Count++;
        emit Increment(Count);
    }
    function decrement() public {
        CountP--;
        Count--;
        emit Decrement(Count);
    }
    function SetName(string memory _NameToSet) public returns(string memory _NewName) {
        MyName = _NameToSet;
        return MyName;
    }
}