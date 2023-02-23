/**
 *Submitted for verification at Etherscan.io on 2023-02-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Lock {
    uint256 count;
    address owner;
    string name = "Omer";

    constructor() payable {
        owner = payable(msg.sender);
    }

    function increment() public {
        count++;
    }

    function incrementByValue(uint value) public {
        count = count + value;
    }

    function decrement() public {
        count--;
    }

    function decrementByValue(uint value) public {
        count = count - value;
    }

    function changeName(string memory newName) public {
        name = newName;
    }

    function changeOwner(address newOwner) public {
        owner = newOwner;
    }

    function getCount() public view returns(uint256){
        return count;
    }

    function getName() public view returns( string memory){
        return name;
    }
    function getOwner() public view returns(address){
        return owner;
    }
}