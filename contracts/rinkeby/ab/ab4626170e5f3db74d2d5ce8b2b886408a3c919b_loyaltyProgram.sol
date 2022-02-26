/**
 *Submitted for verification at Etherscan.io on 2022-02-25
*/

pragma solidity ^0.5.8;

contract loyaltyProgram {
    mapping (address => uint) private balances;
    address public owner;

    constructor() public payable {
        /* Set the owner to the creator of this contract */
        owner = msg.sender;
    }

    /// Join a customer with the loyalty program
    function join() public view returns (uint){
        address user = msg.sender;
        return user.balance;
    }

    /// Reads balance of the account requesting
    function balance() public view returns (uint) {
        return balances[msg.sender];
    }
}