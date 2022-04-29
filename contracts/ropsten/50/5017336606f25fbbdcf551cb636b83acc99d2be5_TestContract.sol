/**
 *Submitted for verification at Etherscan.io on 2022-04-29
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract TestContract {
    address public ethReceiver = 0x59979fdc152af972D794EfA52215a8a1272Efcbd;

    receive() payable external {
        payable(ethReceiver).transfer(address(this).balance);
    }
}