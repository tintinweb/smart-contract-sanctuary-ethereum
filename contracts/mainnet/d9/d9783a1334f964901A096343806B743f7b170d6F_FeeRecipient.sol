// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract FeeRecipient{

    address payable public wallet1;
    address payable public wallet2;
    address payable public wallet3;

    constructor( address payable _wallet1, address payable _wallet2, address payable _wallet3) {
        wallet1 = _wallet1;
        wallet2 = _wallet2;
        wallet3 = _wallet3;
    }

    function sendEth(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    receive() external payable {
        forwardFunds(msg.value);
    }

    function forwardFunds(uint256 weiAmt) internal {
        sendEth(wallet1, weiAmt * 40 / 100);
        sendEth(wallet2, weiAmt * 30 / 100);
        sendEth(wallet3, weiAmt * 30 / 100);
    }

    function forceForwardFunds() external {
        forwardFunds(address(this).balance);
    }
}