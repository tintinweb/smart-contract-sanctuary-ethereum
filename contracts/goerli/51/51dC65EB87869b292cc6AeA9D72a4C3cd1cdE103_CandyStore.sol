/**
 *Submitted for verification at Etherscan.io on 2022-11-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract CandyStore {
    address payable public owner;
    //mapping(address => uint256) public candyBalance;
    mapping(address => mapping(uint256 => uint256)) candyBalance;
    mapping(uint256 => uint256) candyPrice;

    constructor() {
        owner = payable(msg.sender);
        candyBalance[address(this)][0] = 1000;
        candyBalance[address(this)][1] = 1000;
        candyPrice[0] = 1000;
        candyPrice[1] = 5000;
    }

    function getCandyStoreBalance(uint256 _candytype)
        public
        view
        returns (uint256)
    {
        return candyBalance[address(this)][_candytype];
    }

    function getCandyPrice(uint256 _candytype) public view returns (uint256) {
        return candyPrice[_candytype];
    }

    // Let the owner restock the vending machine
    function restock(uint256 _candytype, uint256 amount) public {
        require(msg.sender == owner, "Only the owner can restock.");
        candyBalance[address(this)][_candytype] += amount;
    }

    // Purchase donuts from the vending machine
    function purchase(uint256 Duplo, uint256 Milka) public payable {
        require(
            candyBalance[address(this)][0] >= Duplo,
            "Not enough candy in stock to complete this purchase"
        );
        require(
            candyBalance[address(this)][1] >= Milka,
            "Not enough candy in stock to complete this purchase"
        );
        require(
            msg.value >= ((Duplo * candyPrice[0]) + (Milka * candyPrice[1]))/(10 ** 18),
            "You must pay at least 0.001 ETH per candy"
        );
        candyBalance[address(this)][0] -= Duplo;
        candyBalance[address(this)][1] -= Milka;
        candyBalance[msg.sender][0] += Duplo;
        candyBalance[msg.sender][1] -= Milka;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}