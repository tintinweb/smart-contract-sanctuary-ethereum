/**
 *Submitted for verification at Etherscan.io on 2022-02-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Save_string {
    mapping (address=> string) saved_text;

    function set_text(string memory text) public {
        saved_text[msg.sender] = text;
    }

    function get_text() public view returns (string memory){
        return saved_text[msg.sender];
    }
}