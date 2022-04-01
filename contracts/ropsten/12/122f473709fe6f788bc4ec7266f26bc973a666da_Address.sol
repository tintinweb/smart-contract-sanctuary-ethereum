/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

pragma solidity ^0.4.24;

contract Address{
    address addr0 = 0xb2D709be86ADc8520192872197c36886A553cd30;

    function () public payable {

    }

    function getBalance() public view returns (uint256){
        return address(this).balance;
    }

    function getContactBalance() public view returns (uint256){
        return addr0.balance;
    }

    function transfer() public {
        addr0.transfer(10 * 10 ** 18);
    }
}