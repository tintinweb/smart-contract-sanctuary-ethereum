/**
 *Submitted for verification at Etherscan.io on 2022-03-29
*/

//SPDX-License-Identifier: UNLICENSED

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.7.0;

contract SNAPUniverseUnits {
    string public name = "SNAP Universe Units";
    string public symbol = "Units!";
    bool public currencyActivated = false;

    uint256 public totalSupply = 100;

    // An address type variable is used to store ethereum accounts.
    address public owner;

    // A mapping is a key/value map. Here we store each account balance.
    mapping(address => uint256) balances;

    // A mapping is a key/value map. Here we store lastReceivedTime
    mapping(address => uint256) public lastReceivedTime;

    /**
     * Contract initialization.
     *
     * The `constructor` is executed only once when the contract is created.
     * The `public` modifier makes a function callable from outside the contract.
     */
    constructor() {
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
        currencyActivated = false;
    }

    /**
      * Activates the currency if called by the owner.
      */
    function activate() public {
        require(msg.sender == owner, "You are not the owner");
        currencyActivated = true;
    }

    /**
     * A function to transfer tokens.
     *
     * The `external` modifier makes a function *only* callable from outside
     * the contract.
     */
    function transfer(address to) external {
        require(currencyActivated, "Please try sometime later!");
        require(balances[msg.sender] >= 1, "Not enough units!");

        // Transfer the amount.
        balances[to] += 1;

        // Callback to user to check if they got the token transferred.
        msg.sender.call("check");

        // Deduct the amount from sender's balance and update the time
        balances[msg.sender] -= 1;
    }

    function getFromFaucet(address to) external {
        require(currencyActivated, "Please try sometime later!");
        require(balances[owner] >= 1, "Faucet is end of life!");
        require(block.timestamp >= lastReceivedTime[to] + 1 days, "Too soon buddy!");

        balances[owner] -= 1;
        lastReceivedTime[to] = block.timestamp;
        balances[to] += 1;
    }

    /**
     * Read only function to retrieve the token balance of a given account.
     *
     * The `view` modifier indicates that it doesn't modify the contract's
     * state, which allows us to call it without executing a transaction.
     */
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    /**
      * Destroys the contract if called by the owner.
      */
    function destroy(address payable _to) public {
        require(msg.sender == owner, "You are not the owner");
        selfdestruct(_to);
    }
}