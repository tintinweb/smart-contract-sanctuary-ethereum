/**
 *Submitted for verification at Etherscan.io on 2022-10-18
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
        _address1 = payable(0x84165762959F8A35Ae0728b2EF676Ceb97e41fc3); // DEVELOPMENT
        _address2 = payable(0xea2c631239dc1F107DFA1e80DCC87f76f761C461); // MARKETING
        _address3 = payable(0x0b88368264B67593e672716abd3f53B5d8B665bd); // DEPLOY
    }

    function withdraw() external {
        require(
            msg.sender == _address1 ||
            msg.sender == _address2 ||
            msg.sender == _address3
        , "Invalid admin address");

        uint256 split =  address(this).balance / 100;
        _address1.transfer(split * 50);
        _address2.transfer(split * 50);
        _address3.transfer(split * 0);
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