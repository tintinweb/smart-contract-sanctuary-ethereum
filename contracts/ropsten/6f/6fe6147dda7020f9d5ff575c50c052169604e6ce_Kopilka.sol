/**
 *Submitted for verification at Etherscan.io on 2022-06-17
*/

// File: contracts/Give & withdrawl.sol


pragma solidity ^0.8.0;

contract Kopilka{

    address public contractOwner;

    constructor() {
        contractOwner = msg.sender;
    }

    function PutEth() public payable {}

    function getBal() public view returns(uint){
        return address(this).balance;
    }
    function withdrawlAll(address payable _to) public {
        require (contractOwner == _to);
        _to.transfer(address(this).balance);

    }

}