/**
 *Submitted for verification at Etherscan.io on 2022-12-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;
 
contract TornadoMock {
     event Withdrawal(address indexed _from, uint _fee);

      function fakeWithdrawal() public {
        //simulate a fakeWithdrawl from Tornado Cash
        emit Withdrawal(msg.sender, block.timestamp);
    }   
}