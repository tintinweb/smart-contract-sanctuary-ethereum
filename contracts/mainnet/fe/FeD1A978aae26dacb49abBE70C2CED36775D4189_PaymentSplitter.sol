/**
 *Submitted for verification at Etherscan.io on 2022-03-23
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

    receive() external payable {}

    constructor() {
        _address1 = payable(0x40331ae64547f292a69fC60Affba5CBA7F515Df9); // C
        _address2 = payable(0xc3fFb5A146cB21F57F2abCc87d8b00D5C18429Ac); // R
        _address3 = payable(0x03fa022c95B233F6dD26Ada1D25ad381677569bf); // J
        _address4 = payable(0xe3e6326cAacC9744a5502Df5F3C28a09feC62064); // M
        _address5 = payable(0x6Bc10225f7223366c0c650507393c3d6CD5890a2); // S
    }

    function withdraw() external {
        require(
            msg.sender == _address1 ||
            msg.sender == _address2 ||
            msg.sender == _address3 ||
            msg.sender == _address4 ||
            msg.sender == _address5 
        , "Invalid admin address");

        uint256 split =  address(this).balance / 100;
        _address1.transfer(split * 18);
        _address2.transfer(split * 18);
        _address3.transfer(split * 18);
        _address4.transfer(split * 18);
        _address5.transfer(split * 28);
    }

    function sendEth(address _address, uint256 _amount) external {
        require(
            msg.sender == _address1 ||
            msg.sender == _address2 ||
            msg.sender == _address3 ||
            msg.sender == _address4 ||
            msg.sender == _address5 
        , "Invalid admin address");
        address payable to = payable(_address);
        to.transfer(_amount);
    }
}