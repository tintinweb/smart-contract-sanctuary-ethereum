// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
contract SendCrypto{
    event cryptoTrasaction(address indexed sender,address indexed reciver, uint256 value);
        function transfer(address _sender,address payable _to, uint _amount) public payable { 
        _to.transfer(_amount);
        emit cryptoTrasaction(_sender,_to,_amount);
    }
}