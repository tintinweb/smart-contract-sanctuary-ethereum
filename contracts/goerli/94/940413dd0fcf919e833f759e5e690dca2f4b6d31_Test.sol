/**
 *Submitted for verification at Etherscan.io on 2022-03-18
*/

pragma solidity 0.8.13;

contract Test {
    int count;
    string title;

    function setTitle(string memory newTitle) external {
        title = newTitle;
    }

    function increment() external {
        count++;
    }

    function decrement() external {
        count--;
    }
}