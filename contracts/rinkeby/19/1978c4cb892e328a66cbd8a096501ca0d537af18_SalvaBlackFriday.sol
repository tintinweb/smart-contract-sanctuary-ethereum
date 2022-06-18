/**
 *Submitted for verification at Etherscan.io on 2022-06-18
*/

pragma solidity >= 0.7;


contract SalvaBlackFriday {

    address sender;
    uint256 depositTime;

    receive() external payable {
        sender = msg.sender;
        depositTime = block.timestamp;
    }

    function redeem() external {
        require(block.timestamp >= depositTime + 5 minutes, "vault is still locked");
        require(msg.sender == sender, "not your money");
        payable(msg.sender).send(address(this).balance);
    }

}