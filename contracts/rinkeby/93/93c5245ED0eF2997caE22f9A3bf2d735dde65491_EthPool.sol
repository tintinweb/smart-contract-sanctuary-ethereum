/**
 *Submitted for verification at Etherscan.io on 2022-03-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract EthPool {
    // // Some string type variables to identify the token.
    // // The `public` modifier makes a variable readable from outside the contract.
    // string public name = "My Hardhat Token";
    // string public symbol = "MHT";

    // // The fixed amount of tokens stored in an unsigned integer type variable.
    // uint256 public totalSupply = 1000000;

    // // An address type variable is used to store ethereum accounts.
    // address public owner;

    // A mapping is a key/value map. Here we store each account balance.
    mapping(address => uint256) deposits;

    // /**
    //  * Contract initialization.
    //  *
    //  * The `constructor` is executed only once when the contract is created.
    //  */
    // constructor() {
    //     owner = msg.sender;
    // }

    // /**
    //  * A function to transfer tokens.
    //  *
    //  * The `external` modifier makes a function *only* callable from outside
    //  * the contract.
    //  */
    // function transfer(address to, uint256 amount) external {
    //     // Check if the transaction sender has enough tokens.
    //     // If `require`'s first argument evaluates to `false` then the
    //     // transaction will revert.
    //     require(deposits[msg.sender] >= amount, "Not enough tokens");

    //     // Transfer the amount.
    //     deposits[msg.sender] -= amount;
    //     deposits[to] += amount;
    // }

    // /**
    //  * Read only function to retrieve the token balance of a given account.
    //  *
    //  * The `view` modifier indicates that it doesn't modify the contract's
    //  * state, which allows us to call it without executing a transaction.
    //  */
    // function balanceOf(address account) external view returns (uint256) {
    //     return deposits[account];
    // }

  function deposit() payable external {
    // Send returns a boolean value indicating success or failure.
    // This function is not recommended for sending Ether.
    // bool sent = payable(owner).send(msg.value);

    // require(sent, "Failed to send Ether");
    deposits[msg.sender] = msg.value;
  }

  function withdraw() external {
    if (deposits[msg.sender] > 0) {
      bool sent = payable(msg.sender).send(deposits[msg.sender]);
      require(sent, "Failed to send Ether");
    }
  }
}