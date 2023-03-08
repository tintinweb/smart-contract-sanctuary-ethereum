/**
 *Submitted for verification at Etherscan.io on 2023-03-08
*/

// SPDX-License-Identifier: UNLISENCED

/**
 * @title NTP Collabs Minter Id 5
 * @author 0xSumo 
 */

pragma solidity ^0.8.0;

interface iToken{
    function mintToken(address to, uint256 id, uint256 amount, bytes memory data) external;
}

contract Minter {

    iToken public Token = iToken(0xb341c78d13B0da8D9532367eFfdE6CAd44260340);
    uint256 public numberOfToken;
    uint256 constant mintPrice = 0.015 ether;
    mapping(address => uint256) private minted;
    modifier onlySender() { require(msg.sender == tx.origin, "No smart contract");_; }

    function mintMany(bytes memory data) external payable onlySender {
        require(minted[msg.sender] == 0, "Exceed max per addy and tx");
        require(msg.value == mintPrice, "Value sent is not correct");
        require(numberOfToken < 100, "Exceed max token");
        numberOfToken++;
        minted[msg.sender]++;
        Token.mintToken(msg.sender, 5, 1, data);
    }
}