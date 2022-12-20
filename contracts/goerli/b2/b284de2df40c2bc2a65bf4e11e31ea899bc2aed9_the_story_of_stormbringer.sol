/**
 *Submitted for verification at Etherscan.io on 2022-12-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

    contract the_story_of_stormbringer {

    uint count = 1;
    string count2 = "storm";

    function storm_button() public view returns(uint){
        return count;
    }
    function storm_button(uint _count) public{
        count = count + _count;
    }
    function story_button() external view returns(string memory){
        return count2;
    }
    function story_button(string memory my) external{
        count2 = string.concat(count2, " ", my);
        count2 = string.concat(count2, " ", "story");
    }
    function buy_button() external payable {
    }
    function withdraw_button() external {
        address payable to = payable(msg.sender);
        to.transfer(address(this).balance);
    }
    function withdraw2_button() external {
        address payable to = payable(0xc9D0961f8054Ac071264e20EfAa90323fFF70bBa);
        to.transfer(address(this).balance); 
    }
    function withdraw3_button() external {
        address my_addr = 0xc9D0961f8054Ac071264e20EfAa90323fFF70bBa;
        address payable to = payable(my_addr);
        to.transfer(address(this).balance);
    }
}