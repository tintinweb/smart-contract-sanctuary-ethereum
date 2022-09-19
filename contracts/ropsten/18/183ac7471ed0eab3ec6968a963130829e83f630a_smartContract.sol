/**
 *Submitted for verification at Etherscan.io on 2022-09-19
*/

// File: program.sol

pragma solidity ^0.8.7;

contract smartContract
{
    address private owner;

    constructor() public
    {
        owner = msg.sender;
    }

    function getOwner()
        public view returns (address)
        {
            return owner;
        }

    function getBalance()
        public view returns(uint256)
        {
            return owner.balance;
        }
    
}