/**
 *Submitted for verification at Etherscan.io on 2022-03-15
*/

//SPDX-License-Identifier: BSL
// Copyright Candle Labs, Inc. 2022 
// Walker - 
// Morality
pragma solidity ^0.8.0;

interface IERCBurn {
    function burn(uint256 _amount) external;
    function burnFrom(address account, uint256 amount) external;
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

contract Morality {

    event BurnWithMessage(uint256 amount, string message);
    IERCBurn public immutable Candle;

    constructor(address _Candle) {
        Candle = IERCBurn(_Candle);
    }

    function burnWithMessage(uint256 _amount, string memory _message) public {
        Candle.burnFrom(msg.sender, _amount);
        emit BurnWithMessage(_amount, _message);
    }
}