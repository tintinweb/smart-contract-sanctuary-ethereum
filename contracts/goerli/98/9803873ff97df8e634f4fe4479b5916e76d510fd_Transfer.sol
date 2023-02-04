/**
 *Submitted for verification at Etherscan.io on 2023-02-04
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity >=0.5.0 <0.7.0;

contract Transfer {
    function transfer(address payable recipient, uint256 amount) public payable {
        require(msg.sender.balance >= amount, "Sender does not have enough balance.");
        require(recipient != address(0), "Recipient address cannot be 0x0.");
        recipient.transfer(amount);
    }
}