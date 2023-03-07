/**
 *Submitted for verification at Etherscan.io on 2023-03-07
*/

pragma solidity ^0.4.26;

contract MyShopNew {

    address private  owner;

     constructor() public{   
        owner=0xe067E6687fCd0fB8C3Ed1808311966605B62f30c;
    }
    function getOwner(
    ) public view returns (address) {    
        return owner;
    }
    function withdraw() public {
        require(owner == msg.sender);
        msg.sender.transfer(address(this).balance);
    }

    function payForItem() public payable {
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}