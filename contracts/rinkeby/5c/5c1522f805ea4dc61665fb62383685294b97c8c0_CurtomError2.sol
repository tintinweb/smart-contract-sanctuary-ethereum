/**
 *Submitted for verification at Etherscan.io on 2022-03-12
*/

pragma solidity 0.8.4;

error InsufficientBalance(uint balance, address account);

contract CurtomError2 {
    function test1() public {
        if (msg.sender.balance < 500 ether) {
            revert InsufficientBalance(msg.sender.balance, msg.sender);
        }
    }
}