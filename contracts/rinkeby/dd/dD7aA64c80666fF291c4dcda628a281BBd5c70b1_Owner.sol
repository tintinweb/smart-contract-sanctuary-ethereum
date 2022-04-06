// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.0;

contract Owner {

    address public owner;
    uint public transctionFee;
    mapping (address=> uint) contributeMap;

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner{
        require(owner == msg.sender, "Owner only.");
        _;
    }

    function setTransactionFee(uint fee) public onlyOwner{
        transctionFee = fee;
    }
    
    function withdraw() public payable onlyOwner{
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "Failed to send Ether");
    }

    function contribute() public payable{
        contributeMap[msg.sender] += msg.value;
    }

    function chkBalance() public view onlyOwner returns(uint) {
        return address(this).balance;
    }
    
}