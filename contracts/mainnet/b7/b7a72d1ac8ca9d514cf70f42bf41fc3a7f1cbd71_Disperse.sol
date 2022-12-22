pragma solidity ^0.4.25;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

contract Disperse {
    function disperseEther(address[] recipients) external payable {
        uint256 split = msg.value / recipients.length;
        for (uint256 i = 0; i < recipients.length; i++) {
            recipients[i].transfer(split);
        }

        uint256 balance = address(this).balance;
        if (balance > 0) {
            msg.sender.transfer(balance);
        }
    }
}