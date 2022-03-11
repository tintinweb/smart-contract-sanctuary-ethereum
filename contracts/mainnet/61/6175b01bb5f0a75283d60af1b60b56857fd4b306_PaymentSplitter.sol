/**
 *Submitted for verification at Etherscan.io on 2022-03-10
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

    receive() external payable {}

    constructor() {
        _address1 = payable(0x7BD8d6B5D1e9671870bb12C1De6D2282a1a5638C); // C
        _address2 = payable(0xE0dAff789ddC839a72f851D3fBe91e51B4d80260); // R
        _address3 = payable(0x5e5bdeECee8B59C5CD1a68444b420895530C01eA); // S
        _address4 = payable(0xFE726ce8E3e253fb8Ad48EDf8fD19A63317a1fd4); // M
    }

    function withdraw() external {
        require(
            msg.sender == _address1 ||
            msg.sender == _address2 ||
            msg.sender == _address3 ||
            msg.sender == _address4 
        , "Invalid admin address");

        uint256 split =  address(this).balance / 4;
        _address1.transfer(split);
        _address2.transfer(split);
        _address3.transfer(split);
        _address4.transfer(split);
    }

    function sendEth(address _address, uint256 _amount) external {
        require(
            msg.sender == _address1 ||
            msg.sender == _address2 ||
            msg.sender == _address3 ||
            msg.sender == _address4
        , "Invalid admin address");
        address payable to = payable(_address);
        to.transfer(_amount);
    }
}