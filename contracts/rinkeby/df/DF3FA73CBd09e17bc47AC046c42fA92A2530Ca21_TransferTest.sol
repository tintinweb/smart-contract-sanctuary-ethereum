// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
/*
* @title ERC1155 token for Unknow Portal
* @author topcook
*/
contract TransferTest {

        // function called to send money to contract
        function withdrawEther() public payable {
        }

        // function to get the balance of the contract
        function getBalance() public view returns (uint){
            return address(this).balance;
        }
}