//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract SendMoney {
    uint256[] public money;

    mapping(string => uint256) public informations;

    function sendAmount(string memory _key, uint256 _amount) public {
        uint256 res = informations[_key] = _amount;
        money.push(res);
    }
}