/**
 *Submitted for verification at Etherscan.io on 2022-02-18
*/

pragma solidity 0.6.4;

contract Faucet {
    // Hey Chakra!
    // Receive any incoming amount
    receive() external payable {}

    // Send ETH to requestor
    function withdraw(uint withdraw_amount) public {

        // Limit withdrawal amount
        require(withdraw_amount <= 100000000000000000);

        // Send the ETH to the requestor address
        msg.sender.transfer(withdraw_amount);
    }
    
}