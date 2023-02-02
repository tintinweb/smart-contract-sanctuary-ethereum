// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract HelloWorld{
    address public buadres = msg.sender;
    uint256 public nnumber;
    function returnName() public view returns(address) {
        return buadres;
    }
    function storeValue(uint256 number,uint256 number2) public returns(uint256){
        nnumber = number+number2;
        return nnumber;
    }
}