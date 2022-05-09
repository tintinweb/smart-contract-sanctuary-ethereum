/**
 *Submitted for verification at Etherscan.io on 2022-05-08
*/

pragma solidity 0.6.4;

contract Faucet {
    receive () external payable{}

    function withdraw(uint withdraw_amount) public {
        require(withdraw_amount <= 100000000000000000);
        msg.sender.transfer(withdraw_amount);
    }

}