/**
 *Submitted for verification at Etherscan.io on 2022-06-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

//Interface for interacting with erc20



interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);


    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function balanceOf(address owner) external returns (uint256);

    


}

contract GivToken{
    address constant tCELL = 0x68Ce8643Bc288849C26Be2a4D7f97C0cf03bb993;
    uint constant day = 86400;
    mapping(address =>  uint) time;


    function givme()  public {
        require(time[msg.sender]+day <= block.timestamp,"Have to wait a day");

        IERC20(tCELL).transfer(msg.sender,100*1e18);
        time[msg.sender] = block.timestamp;
    }


}