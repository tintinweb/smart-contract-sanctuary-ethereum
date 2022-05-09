/**
 *Submitted for verification at Etherscan.io on 2022-05-08
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;		
interface IBank{
    function balCheck(address holder) external view returns(uint);
}
contract BankTransfer{
    address public BankContractAddress;
    constructor(address bankContractAddress){
        BankContractAddress = bankContractAddress;
    }
    function UPI(address holder) public view returns(uint){
        return IBank(BankContractAddress).balCheck(holder);
    }
}