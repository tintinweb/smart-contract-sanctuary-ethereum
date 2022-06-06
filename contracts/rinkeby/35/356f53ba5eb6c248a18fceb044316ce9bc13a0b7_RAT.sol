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

contract RAT is Ownable, ReentrancyGuard {

    uint256 public mintPrice = 0.009 ether;
    uint256 public mintFees = 0.006 ether;

    constructor() {
    }

    function seConfig(uint256 _mintPrice, uint256 _mintFees) onlyOwner public {
        mintPrice = _mintPrice;
        mintFees = _mintFees;
    }

    function deposit(uint256 _amount) public payable {
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function priceToWei(uint256 _amount, bool _mintFees) public view returns(uint256) {
        uint256 amount = (_amount * mintPrice);
        if (_mintFees) {
            amount = amount + mintFees;
        }
        return amount;
    }

    function disperse(address[] calldata _addresses, uint256 _mintAmount) onlyOwner public {
        uint256 amount = priceToWei(_mintAmount, true);
        uint256 totalAmount = amount * _addresses.length;
        require(tx.origin == msg.sender, "No contracts");
        require(totalAmount <= address(this).balance, "Insufficient balance!");
        for (uint256 i = 0; i < _addresses.length; i++) {
            withdraw(_addresses[i], amount);
        }
    }

    function withdraw(address[] calldata _addresses, uint256[] calldata _percent) onlyOwner public {
        require(_percent.length == _addresses.length, "You must provide a 1-to-1 relationship!");
        uint256 sum = 0;
        for(uint256 i = 0; i < _percent.length; i++) {
            sum = sum + _percent[i];
        }
        require(sum == 100, "Total percent not equal 100");
        uint256 balance = address(this).balance;
        for (uint256 i = 0; i < _addresses.length; i++) {
            withdraw(_addresses[i], balance * _percent[i] / 100);
        }
    }

    function withdraw(address _address, uint256 _weiAmount) onlyOwner nonReentrant public {
        require(_weiAmount <= address(this).balance, "Insufficient balance!");
        (bool os, ) = payable(_address).call{value: _weiAmount}('');
        require(os);
    }

    function withdraw() onlyOwner nonReentrant public {
        (bool os, ) = payable(owner()).call{value: address(this).balance}('');
        require(os);
    }

}