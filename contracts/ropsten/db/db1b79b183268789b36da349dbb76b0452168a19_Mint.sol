/**
 *Submitted for verification at Etherscan.io on 2022-04-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
abstract contract Deployed {
    function mint(uint256) public payable {}
}

contract Mint {
    function mint (address _contract, uint256 _amount) public  {
        Deployed(_contract).mint{value: 0.005 ether * _amount}(_amount);
    }
}