// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.18;

import "Ownable.sol";

contract Sale is Ownable {
    uint256 private _price;
    uint256 private _totalSupply = 100;

    string[] private _btcAddresses;
    mapping(address => bool) _purchased;

    bool private _saleStarted = false;
    bool private _whitelistEnabled;

    mapping(address => bool) _whitelist;

    constructor(uint256 price) {
        _price = price;
    }

    modifier isPurchaseable() {
        require(_saleStarted, "Sale not started");
        if (_whitelistEnabled) {
            require(_whitelist[_msgSender()], "Not whitelisted");
        }
        require(!_purchased[_msgSender()], "Already purchased");
        require(_btcAddresses.length < _totalSupply, "Sold out");
        _;
    }

    function purchase(string memory btcAddress) public payable isPurchaseable {
        require(msg.value == _price, "Invalid amount");
        payable(owner()).transfer(address(this).balance);
        _purchased[_msgSender()] = true;
        _btcAddresses.push(btcAddress);
    }

    function getAddresses() public view returns (string[] memory) {
        return _btcAddresses;
    }

    function setPrice(uint256 price) public onlyOwner {
        _price = price;
    }

    function getPrice() public view returns (uint256) {
        return _price;
    }

    function setWhitelist(address[] memory addresses, bool value) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _whitelist[addresses[i]] = value;
        }
    }

    function startSale(bool whitelisted) public onlyOwner {
        _whitelistEnabled = whitelisted;
        _saleStarted = true;
    }

    function getStock() public view returns (uint256) {
        return _totalSupply - _btcAddresses.length;
    }
}