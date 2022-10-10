/**
 *Submitted for verification at Etherscan.io on 2022-10-10
*/

pragma solidity ^0.4.23;

contract Trucks {
    constructor() public{
    }

    event isSolved();

    function getBalance() public view returns (uint256){
        return address(this).balance;
    }

    function payforflag() public returns (bool){
        address _to = 0x498d4BAddD959314591Dc14cb10790e8Df68b1b1;
        require(address(this).balance>0);
        emit isSolved();
        _to.transfer(address(this).balance);

    }
}