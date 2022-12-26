/**
 *Submitted for verification at Etherscan.io on 2022-12-26
*/

// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.0 < 0.9.0;


contract find_number {
    uint private answer = 73;
    uint b;

    function charge() external payable {

    }

    function check_number(uint _value) public {
        b = _value;
    }

    function check() view public returns(string memory) {

        string memory error = "Try again";
        string memory result = "Click get_eth";

        if(answer == b) {
            return result;
        } else {
            return error;
        }
    }

    function get_eth() external {
        if(answer == b) {
            address payable to = payable(msg.sender);
            to.transfer(address(this).balance);
        } else {
            
        }
    } 

}