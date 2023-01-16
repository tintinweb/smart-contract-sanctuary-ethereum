/**
 *Submitted for verification at Etherscan.io on 2023-01-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

//
contract DNAMock{
    mapping( address => uint ) public addressMintedMap1;
    mapping( address => uint ) public addressMintedMap2;
    mapping( address => uint ) public addressMintedMap3;
    //
    constructor(address account, uint[] memory amount_list){
        addressMintedMap1[account] = amount_list[0];
        addressMintedMap2[account] = amount_list[1];
        addressMintedMap3[account] = amount_list[2];
    }

    function addMinted(address account, uint[] memory amount_list) public {
        addressMintedMap1[account] += amount_list[0];
        addressMintedMap2[account] += amount_list[1];
        addressMintedMap3[account] += amount_list[2];
    }

}