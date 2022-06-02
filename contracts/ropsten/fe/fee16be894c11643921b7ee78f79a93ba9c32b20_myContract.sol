/**
 *Submitted for verification at Etherscan.io on 2022-06-02
*/

// File: contracts/myContract.sol

pragma solidity ^0.4.24; 

contract myContract{

    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    function transfer(address to, uint256 amount) public {
        to.transfer(amount);
    }

    function () public payable {}
}