/**
 *Submitted for verification at Etherscan.io on 2022-05-10
*/

pragma solidity ^0.4.25;


interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract Bunsan {
    function BunsanEth(address recipient, uint256 value) external payable {
        recipient.transfer(value);
        uint256 balance = address(this).balance;
        if (balance > 0)
            msg.sender.transfer(balance);
    }

    function BunsanEths(address[] recipients, uint256[] values) external payable {
    for (uint256 i = 0; i < recipients.length; i++)
        recipients[i].transfer(values[i]);
    uint256 balance = address(this).balance;
    if (balance > 0)
        msg.sender.transfer(balance);
    }
}