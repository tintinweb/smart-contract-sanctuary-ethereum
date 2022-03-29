/**
 *Submitted for verification at Etherscan.io on 2022-03-29
*/

pragma solidity ^0.5.0;
  // SPDX-License-Identifier: MIT

contract Donation{
    address payable public owner = msg.sender;

    address[] private donators;
    function GetDonation() public payable{
        require (msg.value > 0.001 ether);
        donators.push(msg.sender);
    }
    function returdoantors() public view returns (address[] memory){
        return donators;
    }
    function transferforowner() public {
        require (msg.sender == owner);
        owner.transfer(address(this).balance);
    }

}