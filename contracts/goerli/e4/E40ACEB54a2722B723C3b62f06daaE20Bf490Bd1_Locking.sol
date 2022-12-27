// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Locking {
    mapping(address => uint256) public mgCvgBalances; // track balances

    constructor() {}

    function setMgCvgBalance(address _user, uint256 _amount) external {
        mgCvgBalances[_user] = _amount;
    }

    function balanceOfMgCvgPerAddress(address _user) public view returns (uint256) {
        return mgCvgBalances[_user];
    }
}