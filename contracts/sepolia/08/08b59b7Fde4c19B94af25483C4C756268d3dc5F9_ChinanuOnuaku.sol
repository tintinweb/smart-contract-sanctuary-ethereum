/**
 *Submitted for verification at Etherscan.io on 2023-07-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// Token Smart Contract
contract ChinanuOnuaku {

    // 1. Token balance for address
    mapping (address => uint) public balances;

    // 2. Authorized amount allowed for others to spend
    mapping (address => mapping (address => uint)) public allowance;

    // 3. Token name
    string public name = "Chinanu Onuaku";

    // 4. Token Symbol
    string public symbol = "CNOK";

    // 5. Token Decimals
    uint public decimals = 18;

    // 6. Initial Supply
    uint public tokensIActuallyWant = 9000000;
    uint public totalTokenSupply = tokensIActuallyWant * 10 ** decimals;


    // 7. Assign the total supply to the owner
    constructor(){
        balances[msg.sender] = totalTokenSupply;
    }

    // 8. Get balance of token owners
    function balanceOf(address owner) public view returns (uint){
        return balances[owner];
    }

    // 9. Transfer and Approval event
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);


    // 10. 2 party transfer token from one wallet to another wallet address
    function transfer(address to, uint value) public returns(bool){

        // If transfer value is lower than the balance in the wallet
        require (balanceOf(msg.sender) >= value, 'Your balance is too low');

        // Increase the balance of the receiver
        balances[to] = balances[to] + value;

        // Deduct the balance of the sender
        balances[msg.sender] =  balances[msg.sender] - value;

        // Call the transfer function
        emit Transfer(msg.sender, to, value);

        // exit
        return true;
    }


    // 11. 3 party transfer token from one address to another address (requires approval)
    function transferFrom(address from, address to, uint value) public returns(bool){

        // If transfer value is lower than the balance in the wallet
        require(balanceOf(from) >= value, 'Your balance is too low');

        // If the transfer amount is higher than the authorized allowance
        require(allowance[from][msg.sender] >= value, 'You can not spend up to this amount');

        // Increase the balance of the receiver
        balances[to] += value;

        // Deduct the balance of the sender
        balances[from] -= value;

         // Call the transfer function
        emit Transfer(from, to, value);

        // exit
        return true;
    }


    // 12. Function to approve token transactions
    function approve(address spender, uint value) public returns(bool){
        // Check the authorized allowance of the spender
        allowance[msg.sender][spender] = value; 

        // Approve the transaction if they don't exceed their allowance
        emit Approval(msg.sender, spender, value);

        // exit
        return true;
    }   
}