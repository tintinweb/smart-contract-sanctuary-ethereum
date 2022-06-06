/**
 *Submitted for verification at Etherscan.io on 2022-06-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;

        _status = _NOT_ENTERED;
    }
}

contract Ownable {    
    address private _owner;
    constructor(){
        _owner = msg.sender;
    }
    function owner() public view returns(address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(isOwner(),"Function accessible only by the owner !!");
        _;
    }
    function isOwner() public view returns(bool) {
        return msg.sender == _owner;
    }
}

contract DP is Ownable, ReentrancyGuard {

    uint256 private mintPrice = 0.009 ether;
    uint256 private mintFees = 0.006 ether;

    constructor() {
    }

    modifier compliance() {
        require(tx.origin == msg.sender, "No contracts");
        _;
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function seConfig(uint256 _mintPrice, uint256 _mintFees) compliance onlyOwner public {
        mintPrice = _mintPrice;
        mintFees = _mintFees;
    }

    function getPriceToWei(uint256 _amount, bool _mintFees) compliance onlyOwner public view returns(uint256) {
        uint256 amount = (_amount * mintPrice);
        if (_mintFees) {
            amount = amount + mintFees;
        }
        return amount;
    }

    function getFeesToWei() compliance onlyOwner public view returns(uint256) {
        return mintFees;
    }

    function disperse(address[] calldata _addresses, uint256 _mintAmount) compliance onlyOwner public {
        uint256 amount = getPriceToWei(_mintAmount, true);
        uint256 totalAmount = amount * _addresses.length;
        require(totalAmount <= address(this).balance, "Insufficient balance!");
        for (uint256 i = 0; i < _addresses.length; i++) {
            withdrawAmount(_addresses[i], amount);
        }
    }

    function withdrawPercent(address[] calldata _addresses, uint256[] calldata _percent) compliance onlyOwner public {
        require(_percent.length == _addresses.length, "You must provide a 1-to-1 relationship!");
        uint256 sum = 0;
        for(uint256 i = 0; i < _percent.length; i++) {
            sum = sum + _percent[i];
        }
        require(sum == 100, "Total percent not equal 100");
        uint256 balance = address(this).balance;
        for (uint256 i = 0; i < _addresses.length; i++) {
            withdrawAmount(_addresses[i], balance * _percent[i] / 100);
        }
    }

    function withdrawAmount(address _address, uint256 _weiAmount) compliance onlyOwner nonReentrant public {
        require(_weiAmount <= address(this).balance, "Insufficient balance!");
        (bool os, ) = payable(_address).call{value: _weiAmount}('');
        require(os);
    }

    function withdrawAll() compliance onlyOwner nonReentrant public {
        (bool os, ) = payable(owner()).call{value: address(this).balance}('');
        require(os);
    }

}