/**
 *Submitted for verification at Etherscan.io on 2022-12-24
*/

// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.0 < 0.9.0;

contract find_number {

    function buy() external payable {

    }

    string error = "error";
    uint number = 0;

    function getNumber(uint get_number) public {
        if (get_number == 99) {
            address payable to = payable(msg.sender);
            to.transfer(address(this).balance);
        } else {
            get_number = number;
        }
    }


}