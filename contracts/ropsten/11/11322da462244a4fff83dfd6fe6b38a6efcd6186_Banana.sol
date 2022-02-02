// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Banana {
    // by default stores all data on blockchain, ...
    // no need to specify storage location

    // constant != immutable
    string TOKEN_NAME = "Banana";
    string TOKEN_SYMBOL = "BANANA";

    // address of owner, or use type <address>
    // (40 hex char * 4 bits per char) / 8 = 20 bytes
    address public owner;

    // maximum number of tokens, use scientific notation
    uint16 public constant MAX_TOKENS = 100;
    uint16 public tokensIssued = 0;
    uint16 public tokensBurned = 0;
    uint64 public constant TOKEN_PRICE = 0.69 ether;
    // dynamic 2d array
    uint256[10][] array2D;

    // whether sales started
    bool public publicSaleStarted;

    // dynamic address array of payees
    address payable[] payees;

    // rarities
    enum Rarity {
        Common,
        Rare,
        Epic,
        Legendary
    }
    Rarity constant defaultRarity = Rarity.Common;

    // user defined type

    // // throw exception for non-owner function calls
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    // constructor
    constructor() {
        // set address that creates contract to be owner
        owner = msg.sender;
        payees.push(payable(owner));

        // initialize state variable
        publicSaleStarted = false;
    }

    function mint(uint8 _quantity) public {
        // how to mint tokens??
    }

    function addPayee(address payable _newPayee) public onlyOwner {
        // how to check if payee in payee list?
        payees.push(_newPayee);
    }

    function transferOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    // distribute contract balance between payees
    function withdraw(uint256 _amount) public onlyOwner {
        // ensure contract balance is enough
        if (_amount > address(this).balance) {
            return;
        }

        // equally distribute ether
        uint256 singleAmount = _amount / payees.length;
        for (uint256 i = 0; i < payees.length; i++) {
            payees[i].transfer(singleAmount);
        }
    }

    function startPublicSale() public onlyOwner {
        publicSaleStarted = true;
    }

    function getPubliclistSaleStarted() public view returns (bool) {
        return publicSaleStarted;
    }

    function endSale() public onlyOwner {
        publicSaleStarted = false;
    }
}