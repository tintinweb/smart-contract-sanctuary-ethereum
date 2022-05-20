/**
 *Submitted for verification at Etherscan.io on 2022-05-19
*/

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

contract Faucet {
    function withdraw(uint256 _amount) public {
        // user can withdraw .1 ETH at a time
        require(
            _amount <= 100000000000000000,
            "We can not give you that much test ETH. Please request .1 or less."
        );
        require(
            msg.sender.balance < 10000000000000000000,
            "Looks like you already have plenty of test ETH."
        );
        payable(msg.sender).transfer(_amount);
    }

    // fallback function
    receive() external payable {}
}