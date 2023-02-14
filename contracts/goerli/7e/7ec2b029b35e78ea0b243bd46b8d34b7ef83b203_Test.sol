/**
 *Submitted for verification at Etherscan.io on 2023-02-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
 
 
contract Test {

    event Log(uint256 amo, string func);

    function sendEth() external payable {
        payable(address(this)).transfer(1 ether);
        
    }

    function getThisCBalance() external view returns(uint256) {
        return address(this).balance;
    }

    function sendTo() external {
        payable(address(this)).transfer(1 ether);
    }

    receive() external payable {
        emit Log(msg.value, "receieve");
    }
}