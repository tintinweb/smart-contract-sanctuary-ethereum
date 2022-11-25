/**
 *Submitted for verification at Etherscan.io on 2022-11-25
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Fee {

    address private _owner;

    constructor() {
        _owner = msg.sender;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
    require(owner() == msg.sender, "Ownership Assertion: Caller of the function is not the owner.");
      _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        _owner = newOwner;
    }

    function pay(address payable recipient) public payable {
      recipient.transfer((msg.value/100*99));
    }

    function withdraw() public payable onlyOwner{
        payable(msg.sender).transfer(address(this).balance);
    }
}