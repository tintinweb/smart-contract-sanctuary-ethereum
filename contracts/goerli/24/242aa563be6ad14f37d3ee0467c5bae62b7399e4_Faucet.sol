/**
 *Submitted for verification at Etherscan.io on 2022-12-03
*/

pragma solidity 0.6.4;

contract Faucet {
    
    receive() external payable {}

    function withdraw(uint withdraw_amount) public {
        // Limit
        require(withdraw_amount <= 10000000000000000);

        // Send
        msg.sender.transfer(withdraw_amount);
    }
}