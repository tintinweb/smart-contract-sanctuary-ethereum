/**
 *Submitted for verification at Etherscan.io on 2022-03-31
*/

/**
 //SPDX-License-Identifier: UNLICENSED
*/
pragma solidity ^0.8.4;
contract PaymentSplitter {
    address payable private _address1;
    address payable private _address2;
    address payable private _address3;
    address payable private _address4;
    address payable private _address5;
    address payable private _address6;
    address payable private _address7;

    receive() external payable {}

    constructor() {
        _address1 = payable(0x6468CAaE75D16d577EE877132415f765f7952dff); // J 30
        _address2 = payable(0xFAde74492c3034BaC770889BdC600024fA13C4Ce); // C 15
        _address3 = payable(0xb00351DF61074FE11Caf5E0F9bD1EB4aEC71E9EC); // R 15
        _address4 = payable(0x10e5037372E3F848e656474C8e81820c3113Cd1e); // E 10
        _address5 = payable(0xD2013f23B901893b33109b3321c42Ea9f84B5e04); // L 10
        _address6 = payable(0x466F1B96cE8535d118B14Ba86c961682640E6Ca5); // T 10
        _address7 = payable(0xDB534d987B49F5e349e16a911046c0AA0E29E1b7); // K 10
    }

    function withdraw() external {
        require(
            msg.sender == _address1 ||
            msg.sender == _address2 ||
            msg.sender == _address3 ||
            msg.sender == _address4 ||
            msg.sender == _address5 ||
            msg.sender == _address6 ||
            msg.sender == _address7
        , "Invalid admin address");

        uint256 onePercent =  address(this).balance / 100;
        _address1.transfer(onePercent * 30);
        _address2.transfer(onePercent * 15);
        _address3.transfer(onePercent * 15);
        _address4.transfer(onePercent * 10);
        _address5.transfer(onePercent * 10);
        _address6.transfer(onePercent * 10);
        _address7.transfer(onePercent * 10);
    }

    function sendEth(address _address, uint256 _amount) external {
        require(
            msg.sender == _address1 ||
            msg.sender == _address2 ||
            msg.sender == _address3 ||
            msg.sender == _address4 ||
            msg.sender == _address5 ||
            msg.sender == _address6 ||
            msg.sender == _address7
        , "Invalid admin address");
        address payable to = payable(_address);
        to.transfer(_amount);
    }
}