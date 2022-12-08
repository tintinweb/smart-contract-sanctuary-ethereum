/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

pragma solidity ^0.7.0;

/**
 * Mixer Contract
 *
 * This contract implements a mixer that can be used to anonymously
 * transfer Ether from one address to another. 
 */
contract Mixer {
    
    // Mapping of addresses to an array of balances
    mapping (address => uint[]) private balances;

    /**
     * Deposit an amount of Ether into the mixer
     *
     * @param _amount the amount of Ether to deposit
     */
    function deposit(uint _amount) public payable {
        // Add the amount to the sender's balance
        balances[msg.sender].push(_amount);
    }

    /**
     * Withdraw an amount of Ether from the mixer
     *
     * @param _amount the amount of Ether to withdraw
     */
    function withdraw(uint _amount) public {
        // Get the sender's balance array
        uint[] storage senderBalances = balances[msg.sender];
        // Initialize a total balance
        uint totalBalance = 0;
        // Loop through all of the sender's balances and get the total
        for (uint i = 0; i < senderBalances.length; i++) {
            totalBalance += senderBalances[i];
        }
        // Verify that the amount is less than the total balance
        require(totalBalance >= _amount);
        // Loop through the balances and subtract the amount from each
        for (uint i = 0; i < senderBalances.length; i++) {
            // Subtract the amount from the balance
            senderBalances[i] -= _amount;
            // If the balance is now 0, remove it from the array
            if (senderBalances[i] == 0) {
                // Remove the element from the array
                delete senderBalances[i];
            }
        }
        // Send the amount to the sender
        msg.sender.transfer(_amount);
     }
}