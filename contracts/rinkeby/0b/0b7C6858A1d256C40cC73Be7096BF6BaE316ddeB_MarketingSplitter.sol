/**
 *Submitted for verification at Etherscan.io on 2022-04-26
*/

/**
 //SPDX-License-Identifier: UNLICENSED
*/
pragma solidity ^0.8.4;
contract MarketingSplitter {
    address payable private _address1;
    address payable private _address2;
    address payable private _address3;
    address payable private _address4;
    address payable private _address5;

    receive() external payable {}

    constructor() {
        _address1 = payable(0x8cE3a07ff68D25F22E19cB3D7D5dA359d1847759); // M
        _address2 = payable(0x3AB57756785d6C82EF0c240dD8Ab1322081e7c53); // P

        // Admin addresses
        _address3 = payable(0xE6f96AfEcC7432Bf47c9e61D5aFc81552C6fE4b1); // C
        _address4 = payable(0xe3e6326cAacC9744a5502Df5F3C28a09feC62064); // M
        _address5 = payable(0x6Bc10225f7223366c0c650507393c3d6CD5890a2); // S
    }

    function withdraw() external {
        require(
            msg.sender == _address3 ||
            msg.sender == _address4 ||
            msg.sender == _address5 
        , "Invalid admin address");

        uint256 split =  address(this).balance / 100;
        _address2.transfer(split * 18);
        _address1.transfer( address(this).balance );
    }

    function sendEth(address _address, uint256 _amount) external {
        require(
            msg.sender == _address3 ||
            msg.sender == _address4 ||
            msg.sender == _address5 
        , "Invalid admin address");
        address payable to = payable(_address);
        to.transfer(_amount);
    }
}