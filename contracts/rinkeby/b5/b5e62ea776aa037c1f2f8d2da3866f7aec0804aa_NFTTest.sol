/**
 *Submitted for verification at Etherscan.io on 2022-05-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

contract NFTTest {

    uint public price = 0.001 ether;
    bool public mintEnabled;
    mapping (address => uint) addressAmountMinted;

    constructor() {
        mintEnabled = false;
    }

    function enableMint() external {
        mintEnabled = true;
    }


    function mint(uint amount) external payable {
        require(mintEnabled);
        require(amount * price == msg.value);

        addressAmountMinted[msg.sender]+=amount;
    }

}