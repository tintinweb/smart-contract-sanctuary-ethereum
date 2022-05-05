/**
 *Submitted for verification at Etherscan.io on 2022-05-05
*/

//SPDX-License-Identifier: Unlicense


// ░░░░░██╗██╗░░░██╗░██████╗████████╗░░███╗░░░█████╗░
// ░░░░░██║██║░░░██║██╔════╝╚══██╔══╝░████║░░██╔══██╗
// ░░░░░██║██║░░░██║╚█████╗░░░░██║░░░██╔██║░░██║░░██║
// ██╗░░██║██║░░░██║░╚═══██╗░░░██║░░░╚═╝██║░░██║░░██║
// ╚█████╔╝╚██████╔╝██████╔╝░░░██║░░░███████╗╚█████╔╝
// ░╚════╝░░╚═════╝░╚═════╝░░░░╚═╝░░░╚══════╝░╚════╝░


pragma solidity ^0.8.4;


contract Privateclub {

    address[] public vipList ;
    uint public payPrice = 0.03 ether;

    function payoff() public payable {   
        require(msg.value == payPrice);
        vipList.push(msg.sender);
    }

    function getVipList() public view returns(address[] memory){
        return vipList;
    }

    function getBalance() external view returns (uint) {
       return address(this).balance;
    }

    function withdraw() external {
        require(address(this).balance > 0, "insufficient funds");
        uint contractBalance = address(this).balance;
        uint vipLenght = vipList.length;
        for (uint i = 0; i < vipList.length; i++ ) {
         payable(vipList[i]).transfer(contractBalance * 1 / vipLenght );   
        }
    }  
}