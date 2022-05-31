/**
 *Submitted for verification at Etherscan.io on 2022-05-31
*/

// SPDX-License-Identifier: MIT

//deployer is 0xa3D482F8CDE80Ba32a7aC08cda0Ee648fa536447

pragma solidity ^0.8.7;

contract SimpleManualDistributorTwelve { 
    address payable private _feeAddrWallet1;
    address payable private _feeAddrWallet2;
    address payable private _feeAddrWallet3;
    address payable private _feeAddrWallet4;
    address payable private _feeAddrWallet5;
    address payable private _feeAddrWallet6;
    address payable private _feeAddrWallet7;
    address payable private _feeAddrWallet8;
    address payable private _feeAddrWallet9;
    address payable private _feeAddrWallet10;
    address payable private _feeAddrWallet11;
    address payable private _feeAddrWallet12;

    uint public balance;

    constructor(){
        _feeAddrWallet1 = payable(0x3F831e6BBa6C06e60A819C92Dd5F180624da6771);
        _feeAddrWallet2 = payable(0xbb62a8D67495AFEB8c3baa1Ae02B2EeB62D85E65);
        _feeAddrWallet3 = payable(0x1cdDa7824010B3E41B9Ad71D8dF8b9ffe9D513a0);
        _feeAddrWallet4 = payable(0x171151CB0b44fFf80d79A0A7e647a6F3A1141f49);
        _feeAddrWallet5 = payable(0x33A503C72296725CcA93bbBC81d6F085c486F51b);
        _feeAddrWallet6 = payable(0xa3D482F8CDE80Ba32a7aC08cda0Ee648fa536447);
        _feeAddrWallet7 = payable(0x5F4fCa8E8B7442Da54B66A74E5F5d46080A5A255);
        _feeAddrWallet8 = payable(0xCBA2218a10242c79905C5C72102c26F3F7bB3C54);
        _feeAddrWallet9 = payable(0xd0dB6f4C31660a6be79e09849B930D213562A91F);
        _feeAddrWallet10 = payable(0x44b7B6552Bd8694791F0A44dB9180b9A289db899);
        _feeAddrWallet11 = payable(0x4470bE37Ad02b9E8d8571b5942533c916E8D0354);
        _feeAddrWallet12 = payable(0x7f2B5e9A1a5D13DDdaa23c4D4C17d3F2b9d3F10e);
  }

    receive() external payable{
        balance = address(this).balance;
    }
    
    function distributeTwelve() public{
        _feeAddrWallet1.transfer(balance/12);
        _feeAddrWallet2.transfer(balance/12);
        _feeAddrWallet3.transfer(balance/12);
        _feeAddrWallet4.transfer(balance/12);
        _feeAddrWallet5.transfer(balance/12);
        _feeAddrWallet6.transfer(balance/12);
        _feeAddrWallet7.transfer(balance/12);
        _feeAddrWallet8.transfer(balance/12);
        _feeAddrWallet9.transfer(balance/12);
        _feeAddrWallet10.transfer(balance/12);
        _feeAddrWallet11.transfer(balance/12);
        _feeAddrWallet12.transfer(balance/12);
        }
}