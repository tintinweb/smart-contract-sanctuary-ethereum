/**
 *Submitted for verification at Etherscan.io on 2022-08-13
*/

// SPDX-License-Identifier: CC-BY-SA-4.0

// Version of Solidity compiler this program was written for
pragma solidity 0.8.16;

// Our first contract is a faucet!
contract Faucet {
    // Accept any incoming amount
    receive() external payable {}

    // Give out ether to an address
    function withdraw(address payable addRetirar, uint transfer_amount) public {
        // Limit withdrawal amount
        require(transfer_amount <= 100000000000000000);

        // Send the amount to the address that requested it
        addRetirar.transfer(transfer_amount);
    }
}