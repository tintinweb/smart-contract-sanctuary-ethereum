// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */
contract FetchBalance {
    constructor() {}

    function getBalance(address[] memory  _addrs) public view
            returns (uint256[] memory)
    {
        uint256[] memory _balance;
         for(uint i=0; i<_addrs.length; i++){
        _balance[i]=(address(_addrs[i]).balance);
     }
     return _balance;
    }
}