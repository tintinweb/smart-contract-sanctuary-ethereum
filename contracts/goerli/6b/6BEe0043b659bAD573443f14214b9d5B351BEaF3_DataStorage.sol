/**
 *Submitted for verification at Etherscan.io on 2023-03-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract DataStorage {
    struct Receipt {
        string ipfsCid;
    }

    struct Product {
        string ipfsCid;
    }

    Receipt[] receipts;
    Product[] products;

    mapping(uint256 => string[]) private receiptsByDate;

    address public owner;
    mapping(address => bool) public admins;

    event ReceiptAdded(string ipfsCid);
    event ProductAdded(string ipfsCid);
    event AdminAdded(address admin);
    event AdminRemoved(address admin);

    constructor() {
        owner = msg.sender;
        admins[msg.sender] = true;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can execute this function");
        _;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "Only admins can execute this function");
        _;
    }

    function addReceipt(string memory _ipfsCid) public onlyAdmin {
        Receipt memory receipt = Receipt(_ipfsCid);
        receipts.push(receipt);
        receiptsByDate[block.timestamp].push(_ipfsCid);
        emit ReceiptAdded(_ipfsCid);
    }

    function addProduct(string memory _ipfsCid) public onlyAdmin {
        Product memory product = Product(_ipfsCid);
        products.push(product);
        emit ProductAdded(_ipfsCid);
    }

    function getReceiptByIndex(uint256 _index) public view returns (string memory) {
        require(_index < receipts.length, "Invalid index");
        return receipts[_index].ipfsCid;
    }

    function getProductByIndex(uint256 _index) public view returns (string memory) {
        require(_index < products.length, "Invalid index");
        return products[_index].ipfsCid;
    }

    function addAdmin(address _address) public onlyOwner {
        admins[_address] = true;
        emit AdminAdded(_address);
    }

    function removeAdmin(address _address) public onlyOwner {
        admins[_address] = false;
        emit AdminRemoved(_address);
    }

    function isAdmin(address _address) public view returns (bool) {
        return admins[_address];
    }

    function getReceiptsCount() public view returns (uint256) {
        return receipts.length;
    }

    function getProductsCount() public view returns (uint256) {
        return products.length;
    }
}