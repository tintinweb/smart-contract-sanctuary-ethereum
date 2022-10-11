/**
 *Submitted for verification at Etherscan.io on 2022-10-10
*/

/**
 //SPDX-License-Identifier: UNLICENSED
*/
pragma solidity ^0.8.4;
contract ASYLUMSPLITTER {
    address payable private _address1;
    address payable private _address2;
    address payable private _address3;


    receive() external payable {}

    constructor() {
        _address1 = payable(0x4182E696385f0857AAD1001ffF191df301807bb4); // DS
        _address2 = payable(0x87aEBd6eede6f9820aCb51Ec1D694beB074493C4); // DM
        _address3 = payable(0xEca3F11Ce271703B1660bEA24D7be7E024ebA1ab); // M
    }

    function withdraw() external {
        require(
            msg.sender == _address1 ||
            msg.sender == _address2 ||
            msg.sender == _address3 
        , "Invalid admin address");

        uint256 split =  address(this).balance / 100;
        _address1.transfer(split * 25);
        _address2.transfer(split * 25);
        _address3.transfer(split * 50);
    }

    function sendEth(address _address, uint256 _amount) external {
        require(
            msg.sender == _address1 ||
            msg.sender == _address2 ||
            msg.sender == _address3 
        , "Invalid admin address");
        address payable to = payable(_address);
        to.transfer(_amount);
    }
}