// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LoyaltyToken {
    // Token details
    string public name;
    string public symbol;
    mapping(address => uint256) private balances;
    uint256 tokensAlloted; //Total reward points that have been given to different users
    address public companyWallet; // Company wallet address

    // Events
    event ReviewTokenAwarded(address indexed reviewer);

    // Constructor
    constructor() {
        name = "Loyalty Token";
        symbol = "LOYAL";
        tokensAlloted = 0;
        companyWallet = msg.sender;
    }

    // Function to award tokens to a reviewer
    function awardTokens(address _reviewer) public {
        
        balances[_reviewer] += 10;
        tokensAlloted += 10;

        emit ReviewTokenAwarded(_reviewer);

        
    }

    function getBalance(address awardee) public view returns(uint256 balance){
        return balances[awardee];
    }

 
}