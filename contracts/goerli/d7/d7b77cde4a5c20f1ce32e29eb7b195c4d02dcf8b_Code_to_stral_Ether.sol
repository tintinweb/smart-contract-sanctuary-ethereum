/**
 *Submitted for verification at Etherscan.io on 2022-12-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
contract Code_to_stral_Ether {
    string count = "";
    mapping(address => uint) balance;
    function buy() external payable {
        balance[msg.sender] += msg.value;
    }
    function widthdraw() external {
        address payable to = payable(msg.sender);
        to.transfer(address(this).balance);
    }
    function view_story() public view returns(string memory){
        return count;
    }
    function add_story(string memory txt)public {
        count = string.concat(count, " ", txt);
    }
}